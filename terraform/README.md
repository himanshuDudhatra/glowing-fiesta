# Terraform AWS Infrastructure Deployment

This project deploys:

- 1 VPC
- 2 public subnets + 2 private subnets
- 1 Application Load Balancer (ALB) in the public subnets
- 1 Auto Scaling Group (ASG) using a Launch Template with `t3.medium` instance and container app in the private subnets

## 1) Install Terraform (v1.14.8)

> **Required version:** `1.14.8` — set in `versions.tf`. Using a different version will cause `terraform init` to fail.

### macOS (Homebrew)

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform@1.14.8
terraform -version
```

> If a different version is already installed via Homebrew, run `brew unlink terraform && brew link terraform@1.14.8`.

---

### Ubuntu / Debian (apt)

```bash
# Install prerequisites
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

# Add the HashiCorp Linux repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install specific version
sudo apt-get update && sudo apt-get install -y terraform=1.14.8-1

# Verify
terraform -version
```

---

### Windows

**Option 1 — Chocolatey (recommended):**

```powershell
choco install terraform --version=1.14.8
terraform -version
```

**Option 2 — winget:**

```powershell
winget install --id Hashicorp.Terraform --version 1.14.8
terraform -version
```

**Option 3 — Manual install:**

1. Download the **1.14.8** Windows `.zip` from the [official Terraform releases page](https://releases.hashicorp.com/terraform/1.14.8/).
2. Extract the `terraform.exe` binary to a directory of your choice (e.g. `C:\terraform`).
3. Add that directory to your `PATH` environment variable:
   - Search → *Edit the system environment variables* → **Environment Variables** → edit **Path** → **New** → paste the directory path.
4. Open a new PowerShell / Command Prompt and verify:

```powershell
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

app_instance_type = "t3.medium"

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

One-step destroy:

```bash
terraform destroy -auto-approve
```

# Justify The Architecture

I chose this architecture because my application can be deployed on a simple EC2 setup using an Auto Scaling Group and Launch Template, attached to an ALB. It works fine, and there’s no need for a complex architecture. It’s also easy to understand