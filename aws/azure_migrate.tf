# ----------------------
# Azure Migrate appliance helper VM (Windows)
# ----------------------

locals {
  azure_migrate_key_pair = coalesce(var.azure_migrate_key_pair_name, var.ec2_key_pair_name, "")
}

data "aws_ssm_parameter" "azure_migrate_windows_ami" {
  count = var.azure_migrate_ami_id == null ? 1 : 0
  name  = var.azure_migrate_windows_ssm_parameter
}

locals {
  azure_migrate_ami_id = var.azure_migrate_ami_id == null ? data.aws_ssm_parameter.azure_migrate_windows_ami[0].value : var.azure_migrate_ami_id
}

resource "aws_security_group" "azure_migrate" {
  count       = var.deploy_azure_migrate_appliance ? 1 : 0
  name        = "simpleshop-azure-migrate-sg"
  description = "Allows WinRM/RDP access to the Azure Migrate appliance"
  vpc_id      = aws_vpc.simpleshop.id

  ingress {
    description = "WinRM (HTTP)"
    from_port   = 5985
    to_port     = 5985
    protocol    = "tcp"
    cidr_blocks = [var.azure_migrate_admin_cidr]
  }

  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.azure_migrate_admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "simpleshop-azure-migrate-sg"
    App  = "simpleshop"
  }
}

resource "aws_iam_role" "azure_migrate" {
  count = var.deploy_azure_migrate_appliance ? 1 : 0
  name  = "simpleshop-azure-migrate-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "simpleshop-azure-migrate-role"
    App  = "simpleshop"
  }
}

resource "aws_iam_role_policy_attachment" "azure_migrate_ssm" {
  count      = var.deploy_azure_migrate_appliance ? 1 : 0
  role       = aws_iam_role.azure_migrate[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "azure_migrate" {
  count = var.deploy_azure_migrate_appliance ? 1 : 0
  name  = "simpleshop-azure-migrate-instance-profile"
  role  = aws_iam_role.azure_migrate[0].name
}

resource "aws_instance" "azure_migrate_appliance" {
  count = var.deploy_azure_migrate_appliance ? 1 : 0

  ami           = local.azure_migrate_ami_id
  instance_type = var.azure_migrate_instance_type

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.azure_migrate[0].id]
  associate_public_ip_address = true

  key_name = local.azure_migrate_key_pair != "" ? local.azure_migrate_key_pair : null

  iam_instance_profile = aws_iam_instance_profile.azure_migrate[0].name

  root_block_device {
    volume_size           = var.azure_migrate_root_volume_gb
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = <<-EOT
  <powershell>
    winrm quickconfig -quiet
    winrm set winrm/config/service @{AllowUnencrypted="true"}
    winrm set winrm/config/service/auth @{Basic="true"}
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "LocalAccountTokenFilterPolicy" -Value 1 -Type DWord
    netsh advfirewall firewall add rule name="Allow WinRM" dir=in action=allow protocol=TCP localport=5985
    netsh advfirewall firewall add rule name="Allow RDP" dir=in action=allow protocol=TCP localport=3389
    Set-Service -Name WinRM -StartupType Automatic
    Restart-Service WinRM
  </powershell>
  EOT

  tags = {
    Name = "simpleshop-azure-migrate-appliance"
    App  = "simpleshop"
  }
}

output "azure_migrate_appliance_public_ip" {
  description = "Public IP for the Azure Migrate appliance helper VM"
  value       = var.deploy_azure_migrate_appliance ? aws_instance.azure_migrate_appliance[0].public_ip : null
}

output "azure_migrate_appliance_private_ip" {
  description = "Private IP for the Azure Migrate appliance helper VM"
  value       = var.deploy_azure_migrate_appliance ? aws_instance.azure_migrate_appliance[0].private_ip : null
}
