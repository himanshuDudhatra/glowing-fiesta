module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = var.enable_nat_gateway
  enable_vpn_gateway = var.enable_vpn_gateway

  tags = var.common_tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.17.1"

  name               = var.eks_cluster_name
  kubernetes_version = var.kubernetes_version

  endpoint_public_access = var.endpoint_public_access

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    general_purpose = {
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size
      instance_types = var.node_instance_types
      subnet_ids     = module.vpc.private_subnets
      ami_type       = var.ami_type
    }
  }

  tags = var.common_tags
}

resource "null_resource" "after_eks_created" {
  depends_on = [module.eks]
  provisioner "local-exec" {
    command = "aws eks --region ${var.aws_region} update-kubeconfig --name ${var.eks_cluster_name} --alias ${var.eks_cluster_name}"
  }
  provisioner "local-exec" {
    command = "export KUBE_CONFIG_PATH=~/.kube/config"
  }

  triggers = {
    always_run = timestamp()
  }
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.7.0"

  eks_addons = {
    kube-proxy = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
  }
  enable_aws_load_balancer_controller = true
  cluster_endpoint                    = module.eks.cluster_endpoint
  cluster_name                        = module.eks.cluster_id
  cluster_version                     = module.eks.cluster_version
  oidc_provider_arn                   = module.eks.oidc_provider_arn

  depends_on = [module.eks]
  tags       = var.common_tags
}

resource "kubectl_manifest" "microservice" {
  yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: simple-time-service
spec:
  selector:
    app: simple-time-service
  ports:
    - protocol: TCP
      port: 3000
      targetPort: 3000
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: simple-time-service
spec:
  replicas: 1
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  selector:
    matchLabels:
      app: simple-time-service
  template:
    metadata:
      labels:
        app: simple-time-service
    spec:
      containers:
        - name: simple-time-service
          image: himanshududhatra/simpletimeservice:latest
          imagePullPolicy: Always
          resources:
            limits:
              cpu: "10m"
              memory: "50Mi"
            requests:
              cpu: "5m"
              memory: "25Mi"
          ports:
            - containerPort: 3000
YAML

  depends_on = [module.eks, module.eks_blueprints_addons, null_resource.after_eks_created]
}

resource "kubectl_manifest" "microservice_ingress" {
  yaml_body = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-time-service
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/subnets: ${join(",", module.vpc.public_subnets)}
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: simple-time-service
                port:
                  number: 3000
YAML

  depends_on = [kubectl_manifest.microservice, module.eks_blueprints_addons, null_resource.after_eks_created]
}
