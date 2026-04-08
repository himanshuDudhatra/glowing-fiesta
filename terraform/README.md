# Terraform AWS EKS Deployment

This project deploys:

- 1 VPC
- 2 public subnets + 2 private subnets
- 1 EKS cluster
- 1 managed node group with exactly 2 `m6a.large` nodes in private subnets only

## 1) Install Terraform

macOS (Homebrew):

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
terraform -version
```

## 2) Configure AWS profile

Create/update an AWS profile:

```bash
aws configure --profile dev
```

Set credentials in your shell session:

```bash
export AWS_PROFILE=dev
export AWS_REGION=eu-west-1
```

Verify:

```bash
aws sts get-caller-identity
```

## 3) Create S3 bucket for remote Terraform state

Set a unique bucket name:

```bash
export TF_STATE_BUCKET="my-terraform-state-<unique-suffix>"
```

Create bucket in `eu-west-1`:

```bash
aws s3api create-bucket \
  --bucket "$TF_STATE_BUCKET" \
  --region eu-west-1 \
  --create-bucket-configuration LocationConstraint=eu-west-1
```

Enable bucket versioning (recommended):

```bash
aws s3api put-bucket-versioning \
  --bucket "$TF_STATE_BUCKET" \
  --versioning-configuration Status=Enabled
```

## 4) Update backend placeholders and initialize

Open `versions.tf` and replace these placeholder values in `backend "s3"`:

- `REPLACE_WITH_TF_STATE_BUCKET` -> your real S3 state bucket
- `REPLACE_WITH_STATE_KEY` -> for example `eks/terraform.tfstate`
- `REPLACE_WITH_AWS_REGION` -> for example `eu-west-1`

Then run from the `terraform` directory:

```bash
terraform init
```

## 5) Create `terraform.tfvars` (not committed)

This project does not commit `terraform.tfvars` to git. Create your local file in the `terraform` directory:

```bash
cat > terraform.tfvars <<'EOF'
aws_region = "eu-west-1"

vpc_name = "my-vpc"
vpc_cidr = "10.0.0.0/16"

azs             = ["eu-west-1a", "eu-west-1b"]
private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

enable_nat_gateway = true
enable_vpn_gateway = true

eks_cluster_name       = "dev-eks"
kubernetes_version     = "1.35"
endpoint_public_access = true

node_instance_types = ["m6a.large"]
node_min_size       = 2
node_max_size       = 2
node_desired_size   = 2

ami_type = "AL2023_x86_64_STANDARD"

common_tags = {
  Environment = "dev"
  Terraform   = "true"
}
EOF
```

## 6) Plan and apply deployment

```bash
terraform plan
terraform apply
```

Or one-step deployment:

```bash
terraform apply -auto-approve
```

## 7) Useful post-deploy command

Update kubeconfig for the new cluster:

```bash
aws eks update-kubeconfig --name "$(terraform output -raw eks_cluster_name)" --region eu-west-1
```

Then check nodes:

```bash
kubectl get nodes
```

