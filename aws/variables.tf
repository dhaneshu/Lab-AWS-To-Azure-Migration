variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "aws_az" {
  description = "(Deprecated) Single AZ, kept for backward compatibility"
  type        = string
  default     = "us-east-1a"
}

variable "aws_az_a" {
  description = "Primary AWS availability zone for subnets and resources"
  type        = string
  default     = "us-east-1a"
}

variable "aws_az_b" {
  description = "Secondary AWS availability zone for subnets and resources"
  type        = string
  default     = "us-east-1b"
}

variable "vpc_cidr" {
  description = "CIDR block for the SimpleShop VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.10.1.0/24"
}

variable "private_subnet_cidr" {
  description = "(Deprecated) CIDR block for the private subnet"
  type        = string
  default     = "10.10.2.0/24"
}

variable "private_subnet_cidr_a" {
  description = "CIDR block for the primary private subnet"
  type        = string
  default     = "10.10.2.0/24"
}

variable "private_subnet_cidr_b" {
  description = "CIDR block for the secondary private subnet"
  type        = string
  default     = "10.10.3.0/24"
}

variable "admin_ssh_cidr" {
  description = "CIDR block allowed to SSH into the EC2 instance (e.g., your public IP/32)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "azure_migrate_admin_cidr" {
  description = "CIDR block allowed to reach the Azure Migrate appliance via WinRM/RDP"
  type        = string
  default     = "0.0.0.0/0"
}

variable "deploy_azure_migrate_appliance" {
  description = "Whether to provision the Azure Migrate appliance helper VM"
  type        = bool
  default     = true
}

variable "db_engine" {
  description = "Database engine for RDS (e.g., mysql or postgres)"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Engine version for RDS"
  type        = string
  default     = "14.10"
}

variable "db_instance_class" {
  description = "Instance class for RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS (in GB)"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name for SimpleShop"
  type        = string
  default     = "simpleshop"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "simpleshopadmin"
}

variable "db_password" {
  description = "Master password for RDS (use tfvars or environment variable in real scenarios)"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "Database port (3306 for MySQL, 5432 for PostgreSQL)"
  type        = number
  default     = 5432
}

variable "ec2_ami_id" {
  description = "AMI ID for the SimpleShop EC2 instance (e.g., Amazon Linux 2 or Ubuntu AMI)"
  type        = string
}

variable "ec2_instance_type" {
  description = "EC2 instance type for the SimpleShop web server"
  type        = string
  default     = "t3.micro"
}

variable "ec2_key_pair_name" {
  description = "Existing EC2 key pair name for SSH access"
  type        = string
}

variable "azure_migrate_key_pair_name" {
  description = "Existing EC2 key pair for the Azure Migrate appliance (defaults to ec2_key_pair_name)"
  type        = string
  default     = null
}

variable "azure_migrate_instance_type" {
  description = "Instance type for the Azure Migrate appliance (needs >=8 vCPU / 16 GiB RAM)"
  type        = string
  default     = "c5.2xlarge"
}

variable "azure_migrate_root_volume_gb" {
  description = "Root volume size in GB for the appliance"
  type        = number
  default     = 100
}

variable "azure_migrate_ami_id" {
  description = "Optional custom AMI ID for the Windows appliance"
  type        = string
  default     = null
}

variable "azure_migrate_windows_ssm_parameter" {
  description = "SSM parameter name that resolves to the desired Windows Server 2019/2022 AMI"
  type        = string
  default     = "/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-Base"
}
