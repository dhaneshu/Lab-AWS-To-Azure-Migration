# AWS Environment – SimpleShop Terraform Deployment

This folder contains Terraform configuration to provision the **AWS source environment** for the SimpleShop AWS → Azure migration lab.

It creates:

- A dedicated **VPC** with a public and private subnet.
- An **Amazon RDS** instance (PostgreSQL by default) in the private subnet.
- An **Amazon EC2** instance in the public subnet running a simple web server.
- Security groups that allow HTTP/SSH to the EC2 instance and DB access only from the EC2 instance.
- An IAM instance profile that grants the EC2 VM permissions to initiate IAM-authenticated connections to the RDS database (plus SSM access for remote management).
- (Optional) A **Windows Server Azure Migrate appliance** VM that shares the same VPC/subnet, sized per Microsoft guidance so you can run discovery/assessment directly from AWS.

Use this to quickly stand up the AWS side of the lab before demonstrating migration with **Azure Migrate**.

---

## 1. Prerequisites

- Terraform **v1.3+** installed locally.
- An AWS account with permissions to create VPC, subnets, security groups, EC2, RDS, and associated resources.
- An existing **EC2 key pair** in the chosen region (for SSH access to the EC2 instance).

```
aws ec2 create-key-pair `
  --key-name simpleshop-keypair `
  --query "KeyMaterial" `
  --output text > simpleshop-keypair.pem `
  --region <region>
```

- Your AWS credentials exported (e.g., via `aws configure` or environment variables `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and optionally `AWS_SESSION_TOKEN`).

---

## 2. Files

- `main.tf` – Core Terraform configuration (VPC, subnets, security groups, RDS, EC2).
- `variables.tf` – Input variables for region, CIDRs, DB settings, EC2 settings, etc.
- `user_data.sh` – User data script used to bootstrap the EC2 instance (installs nginx and serves a placeholder SimpleShop page).
- `azure_migrate.tf` – Resources for the Azure Migrate appliance helper VM (security group, IAM role, Windows instance).
- `README.md` – This file.

---

## 3. Configuration

You can customize the deployment via variables defined in `variables.tf`.

Key variables:

- `aws_region` – AWS region to deploy into (default: `us-east-1`).
- `aws_az_a` / `aws_az_b` – Primary & secondary AZs for the subnets (defaults: `us-east-1a`, `us-east-1b`).
- `vpc_cidr` – CIDR for the VPC (default: `10.10.0.0/16`).
- `public_subnet_cidr` – CIDR for the public subnet (default: `10.10.1.0/24`).
- `private_subnet_cidr_a` / `private_subnet_cidr_b` – CIDRs for the two private subnets used by RDS (defaults: `10.10.2.0/24` and `10.10.3.0/24`).
- `admin_ssh_cidr` – CIDR allowed to SSH into EC2 (set this to your IP/32 for security).
- `db_engine` – `postgres` or `mysql` (default: `postgres`).
- `db_engine_version` – Version of the DB engine (default: `14.10` for PostgreSQL).
- `db_instance_class` – Instance class (default: `db.t3.micro`).
- `db_allocated_storage` – Storage size in GB (default: `20`).
- `db_name` – Initial DB name (`simpleshop` by default).
- `db_username` – RDS master username.
- `db_password` – RDS master password (sensitive; **must** be set by you).
- `db_port` – DB port (default: `5432` for PostgreSQL).
- `ec2_ami_id` – AMI ID for the EC2 instance (must be set by you).
- `ec2_instance_type` – EC2 instance type (default: `t3.micro`).
- `ec2_key_pair_name` – Existing EC2 key pair name (must be set by you).
- `deploy_azure_migrate_appliance` – Set to `false` if you do not want Terraform to launch the helper VM (default: `true`).
- `azure_migrate_instance_type` – Appliance size (default: `c5.2xlarge`, which provides 8 vCPUs / 16 GiB RAM).
- `azure_migrate_root_volume_gb` – Root disk size (default: `100`, to satisfy the ~80 GB requirement).
- `azure_migrate_admin_cidr` – CIDR allowed to reach WinRM/RDP on the appliance (default: `0.0.0.0/0`, change to your IP/32).
- `azure_migrate_ami_id` – Optional explicit Windows AMI; if omitted we resolve the latest Windows Server 2022 image via SSM (`azure_migrate_windows_ssm_parameter`).
- `azure_migrate_key_pair_name` – Optional separate key pair for the Windows VM (falls back to `ec2_key_pair_name`).

You can provide overrides using a `terraform.tfvars` file or `-var` / `-var-file` flags.

Example `terraform.tfvars`:

```hcl
aws_region     = "us-east-1"
aws_az_a       = "us-east-1a"
aws_az_b       = "us-east-1b"
admin_ssh_cidr = "203.0.113.10/32" # replace with your IP
azure_migrate_admin_cidr = "203.0.113.10/32" # WinRM/RDP locked to same IP

deploy_azure_migrate_appliance = true
azure_migrate_instance_type    = "c5.2xlarge"
azure_migrate_root_volume_gb   = 100

db_engine_version = "14.10"        # pick a version supported in your region
db_password       = "ChangeMeStrongPassword!"

ec2_ami_id        = "ami-0abcdef1234567890" # replace with an Amazon Linux 2 or Ubuntu AMI
ec2_key_pair_name = "my-keypair-name"
azure_migrate_key_pair_name = "my-windows-keypair" # optional if you rely on SSM Session Manager
```

> **Notes:**
> - To find a suitable AMI for Amazon Linux 2 or Ubuntu, you can use the AWS Console or AWS CLI for your chosen region.
> - Verify that the `db_engine_version` you set is available in your region. You can list supported versions with:
>   ```powershell
>   aws rds describe-db-engine-versions `
>     --engine postgres `
>     --query "DBEngineVersions[].EngineVersion" `
>     --region us-east-1
>   ```

---

## 4. How to deploy

From the root of the repository, change into the `aws` folder and run Terraform:

```powershell
cd aws
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

During `terraform apply`, Terraform will:

- Create the VPC, subnets, and internet gateway.
- Create security groups for EC2 and RDS.
- Create the RDS instance.
- Create the EC2 instance with user data that installs nginx and serves a placeholder page.

At the end of the apply, Terraform outputs:

- `web_public_ip` – Public IP of the EC2 instance.
- `rds_endpoint` – Endpoint of the RDS instance.
- IAM is also enabled on the database so the EC2 role can request **token-based** connections if you prefer not to store static passwords on the VM. See the next section for details.

---

## 5. Verifying the environment

1. In your browser, navigate to:

   ```text
   http://<web_public_ip>/
   ```

   You should see a simple placeholder page indicating that the instance was provisioned by Terraform, along with DB connection info.

2. In the AWS Console:
   - Check **EC2 → Instances** for `simpleshop-web`.
   - Check **RDS → Databases** for `simpleshop-db`.
   - Check **VPC → Your VPCs/Subnets/Security groups** for resources tagged with `App = simpleshop`.

3. You can SSH into the EC2 instance using the key pair you configured:

   ```bash
   ssh -i /path/to/your-key.pem ec2-user@<web_public_ip>
   ```

   (Use `ubuntu` as the user if you used an Ubuntu AMI.)

From there, you can manually deploy the full SimpleShop application stack following the instructions in `docs/02-aws-preparation.md` (adjusting for the fact that Terraform has already created the network, RDS, and base EC2 instance for you).

---

## 6. Azure Migrate appliance helper VM

If `deploy_azure_migrate_appliance = true`, Terraform launches a Windows Server VM in the same public subnet as the app server so you can host the Azure Migrate appliance close to the workload. Key facts:

- **Sizing** – Defaults to `c5.2xlarge` (8 vCPUs / 16 GiB RAM) with a 100‑GB gp3 root disk, meeting Microsoft’s guidance.
- **AMI** – Uses the latest Windows Server 2022 image from the AWS SSM public parameters unless you override `azure_migrate_ami_id`.
- **Access** – Exposes WinRM (5985) and RDP (3389) to `azure_migrate_admin_cidr` and enables the Windows firewall rules + WinRM service at bootstrap time. It also attaches the `AmazonSSMManagedInstanceCore` policy, so you can connect through AWS Systems Manager Session Manager without opening RDP/WinRM to the internet.
- **App reachability** – Terraform automatically authorizes SSH traffic from this appliance’s security group to the `simpleshop-web` instance security group so discovery traffic can flow agentlessly without widening the SSH CIDR.

After `terraform apply` finishes, note the new outputs:

- `azure_migrate_appliance_public_ip`
- `azure_migrate_appliance_private_ip`

From a Windows admin workstation you can test WinRM connectivity:

```powershell
Test-WSMan -ComputerName <azure_migrate_appliance_public_ip>
```

Or open a Session Manager shell (recommended for demos) from the AWS Console without needing inbound rules beyond 5985/3389 for Azure Migrate itself. Once connected, follow the steps in `docs/03-azure-migration.md` to download the Azure Migrate installer, register the appliance using the project key, and scope discovery to the SimpleShop EC2 instance.

Set `deploy_azure_migrate_appliance = false` in your tfvars file if you want to skip provisioning this helper VM to save cost.

---

## 7. Using the IAM role for database access

The Terraform module now creates:

- An IAM role/instance profile (`simpleshop-web-role`) attached to the EC2 instance.
- An inline policy that allows the instance to call `rds-db:connect` on the SimpleShop RDS instance and the AWS-managed `AmazonSSMManagedInstanceCore` policy for Session Manager.
- IAM database authentication on the RDS instance.

To take advantage of token-based authentication instead of the static password used in `user_data.sh`, complete these optional steps:

1. **Create an IAM-enabled DB user (run on the RDS instance)**

   ```sql
   CREATE USER iam_app WITH LOGIN;
   GRANT rds_iam TO iam_app;
   GRANT CONNECT ON DATABASE simpleshop TO iam_app;
   ```

2. **Generate an auth token from the EC2 instance**

   ```bash
   TOKEN=$(aws rds generate-db-auth-token \
     --hostname ${rds_endpoint} \
     --port 5432 \
     --region ${aws_region} \
     --username iam_app)
   psql "host=${rds_endpoint} port=5432 user=iam_app password=$TOKEN dbname=simpleshop sslmode=require"
   ```

   Replace `${rds_endpoint}` with the Terraform output and `${aws_region}` with your region.

3. **(Optional) Update the app** to request tokens on startup instead of reading the `db_password` variable.

During an Azure Migrate demo you can now call out that the workload uses IAM-based least-privilege access to the database and Session Manager for remote management—migration tooling will replicate the OS state, but IAM roles remain managed on the AWS side for auditability.

---

## 8. Destroying the environment

When you are finished with the lab, you can destroy all Terraform-managed AWS resources from the `aws` folder:

```powershell
terraform destroy
```

Review the plan carefully to avoid deleting unintended resources.

---

## 9. Next steps

With the AWS environment provisioned, proceed to:

- `docs/02-aws-preparation.md` – for any additional application-level setup.
- `docs/03-azure-migration.md` – to discover and migrate the `simpleshop-web` EC2 instance to Azure using Azure Migrate.
