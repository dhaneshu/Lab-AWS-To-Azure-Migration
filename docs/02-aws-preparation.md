# SimpleShop AWS → Azure Migration Lab – AWS Preparation Guide

This document describes how to prepare the **AWS source environment** for the SimpleShop AWS → Azure migration lab.

The goal is to have a small but realistic application running on AWS, ready to be discovered and migrated using **Azure Migrate**.

> **Time-saving tip:** Perform all of these steps **before** the 1-hour demo. In the demo, you will only show the final state and highlight key steps, not build everything from scratch.

---

## 1. Prerequisites

Before you start, ensure you have:

- An **AWS account** with permissions to create EC2, RDS, VPC, and security groups.
- An **IAM user/role** with administrator or equivalent permissions for lab setup.
- A local machine with:
  - A web browser.
  - SSH client (e.g., `ssh`) to connect to the EC2 instance.
- A chosen **AWS Region** (e.g., `us-east-1`) where you will create all resources.

You should also decide on:

- **Database engine**: MySQL or PostgreSQL (examples below use generic names; adapt to your choice).
- **Application stack**: Node.js, .NET, or Java (only affects app installation on EC2).

---

## 2. Create the VPC and networking (optional if reusing default VPC)

For a more realistic setup, create a dedicated VPC. For a quick lab, you can reuse the **default VPC** and focus on EC2/RDS.

### Option A – Use default VPC (simpler)

1. In the AWS Console, go to **VPC**.
2. Confirm there is a **default VPC** in your chosen region.
3. Note its **VPC ID** and **subnets**.
4. You will place:
   - EC2 in a default public subnet.
   - RDS in a default private subnet (or same subnet, depending on simplicity).

### Option B – Create a dedicated VPC (more realistic)

1. In the AWS Console, go to **VPC → Your VPCs → Create VPC**.
2. Use the "VPC and more" wizard (recommended) and create:
   - 1 VPC (e.g., `simpleshop-vpc`).
   - 1 public subnet (for EC2).
   - 1 private subnet (for RDS).
   - An Internet Gateway attached to the VPC.
   - A NAT Gateway for private subnet internet access (optional).
3. Note the **VPC ID** and subnet IDs for later.

---

## 3. Create the RDS database

The RDS database will store products and orders for SimpleShop.

### 3.1 Create RDS instance

1. In the AWS Console, go to **RDS → Databases → Create database**.
2. Choose:
   - **Standard create**.
   - Engine: **MySQL** or **PostgreSQL**.
   - Template: **Free tier** or **Dev/Test**.
3. Settings:
   - DB instance identifier: `simpleshop-db`.
   - Master username: `simpleshopadmin` (or similar).
   - Master password: choose a strong password and **store it securely**.
4. Connectivity:
   - VPC: your chosen VPC (default or `simpleshop-vpc`).
   - Public access: **No** (recommended) – use private access from EC2.
   - Subnet group: choose one that includes your private subnets.
   - VPC security group:
     - Create a new SG named `simpleshop-rds-sg`.
     - Initially, allow no inbound from the internet.
5. Additional configuration:
   - Initial database name: `simpleshop` (optional but recommended).
6. Create the database and wait for it to become **Available**.

### 3.2 Configure RDS security group

1. Go to **EC2 → Security Groups**.
2. Edit `simpleshop-rds-sg`:
   - Inbound rules: add a rule allowing the DB port from the EC2 security group (you will create this SG in the next section). For now, you can add a temporary rule allowing your IP so you can initialize the schema using a local client if desired.

You will revisit this after creating the EC2 SG.

---

## 4. Create the EC2 instance for the SimpleShop app

This EC2 instance hosts the monolithic web application.

### 4.1 Launch the instance

1. In the AWS Console, go to **EC2 → Instances → Launch instances**.
2. Name: `simpleshop-web`.
3. Application and OS Images (AMI):
   - Choose a Linux distribution (e.g., **Amazon Linux 2** or **Ubuntu 22.04**).
4. Instance type:
   - `t3.micro` or `t3.small` (enough for a demo).
5. Key pair:
   - Select an existing key pair or create a new one for SSH access.
6. Network settings:
   - VPC: same VPC as RDS.
   - Subnet: public subnet.
   - Auto-assign public IP: **Enable**.
   - Security group: create `simpleshop-web-sg` with:
     - Inbound rule: HTTP (80) from `0.0.0.0/0` (for demo).
     - Inbound rule: SSH (22) from your IP only.
7. Storage: default is fine (e.g., 8–16 GB gp2/gp3).
8. Launch the instance and wait for **Running** state.

### 4.2 Update RDS SG to allow EC2 access

1. Return to **EC2 → Security Groups**.
2. Grab the **Group ID** of `simpleshop-web-sg`.
3. Go to **RDS → Databases → `simpleshop-db` → Connectivity & Security**.
4. Edit the inbound rules of `simpleshop-rds-sg`:
   - Add a rule: `MySQL/Aurora` or `PostgreSQL` from **source = `simpleshop-web-sg`**.

This ensures only the EC2 app instance can connect to the database.

---

## 5. Install and configure the SimpleShop application on EC2

The exact commands depend on your chosen stack. Below is a generic outline for a Node.js app. Adapt for .NET/Java as needed.

### 5.1 Connect to the EC2 instance

Use your SSH key to connect (from your local machine):

```bash
ssh -i /path/to/your-key.pem ec2-user@<EC2-Public-IP>
```

(Use `ubuntu` instead of `ec2-user` if you chose Ubuntu.)

### 5.2 Install runtime and tools (example: Node.js)

On Amazon Linux 2, for example:

```bash
sudo yum update -y
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs git
```

On Ubuntu, use `apt` instead.

### 5.3 Deploy the app

You have several options:

- **Clone from Git** (recommended):
  - Push your SimpleShop app to a Git repo (e.g., GitHub) and clone it onto the EC2 instance.
- **Copy via SCP**:
  - Use `scp` to upload your app files.

Once on the VM:

```bash
cd /opt
sudo mkdir simpleshop
sudo chown "$USER" simpleshop
cd simpleshop
# Clone or copy your app here
npm install
```

Ensure your app reads DB connection parameters from environment variables or a config file, for example:

- `DB_HOST` = RDS endpoint (from RDS console)
- `DB_USER` = `simpleshopadmin`
- `DB_PASS` = your password
- `DB_NAME` = `simpleshop`

Export them or put them into a `.env` file.

### 5.4 Initialize the database schema (optional but recommended)

Use a DB client (CLI from EC2 or local) to create tables and seed sample data, e.g.:

```sql
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  description TEXT
);

CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  product_id INT NOT NULL,
  quantity INT NOT NULL,
  total_price DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

Insert a few rows into `products` for demo purposes.

### 5.5 Run the app and verify

Start the app (example for Node.js):

```bash
npm start
# or
node server.js
```

From your local browser, browse to:

```text
http://<EC2-Public-IP>/
```

Verify that:

- The homepage loads.
- You can list products.
- Creating an order results in a record in the `orders` table.

### 5.6 Optional: configure the app as a service

Use `pm2` or `systemd` so the app starts on boot:

- Install `pm2`:
  ```bash
  sudo npm install -g pm2
  pm2 start server.js --name simpleshop
  pm2 startup
  pm2 save
  ```

This is helpful so the app is running when you show the demo, even after reboots.

---

## 6. (Optional) Add basic monitoring

You can enable basic monitoring so you can later mention observability in the migration story.

- **CloudWatch agent** (optional) for detailed metrics.
- Confirm EC2 has basic metrics (CPU, network) visible in the EC2 console.

---

## 7. Validate the AWS environment for the demo

Before the actual demo day, verify:

1. You can **SSH** into the EC2 instance.
2. The **SimpleShop app is running** and reachable at `http://<EC2-Public-IP>/`.
3. Data is being read/written from/to **RDS**.
4. Security groups are correctly configured (no unexpected open ports).
5. Note down:
   - EC2 instance ID and name.
   - RDS database identifier and endpoint.
   - VPC and subnet names.

This completes the AWS side setup. Your environment is now ready to be discovered and migrated using **Azure Migrate**.

Next, follow `03-azure-migration.md` to prepare Azure Migrate and run the migration.
