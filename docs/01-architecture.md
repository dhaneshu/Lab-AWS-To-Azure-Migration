# SimpleShop AWS → Azure Migration Lab – Architecture

## Overview

This lab demonstrates migrating a small, realistic web application running on **AWS** to **Azure** using **Azure Migrate**.

The sample application is called **SimpleShop** – a monolithic web app that exposes a simple Products/Orders experience backed by a relational database.

- **Source platform:** AWS
- **Target platform:** Azure
- **Primary migration tooling:** Azure Migrate (for server discovery, assessment, and migration)
- **Secondary migration tooling (optional):** Azure Database Migration Service (for database migration)
- **Intended demo length:** ~1 hour (with AWS environment prepared in advance)

The architecture is intentionally small but representative of a typical 3‑tier web application deployed on a single VM with a managed database.

---

## Source architecture on AWS

At a high level, the SimpleShop app on AWS looks like this:

```text
User Browser
    |
    |  HTTP/HTTPS
    v
Amazon EC2 (SimpleShop Web App)
    - Linux VM (e.g., t3.small)
    - Monolithic web app (Node.js / .NET / Java)
    - Exposes HTTP endpoints: /, /products, /orders
    |
    |  SQL over TLS
    v
Amazon RDS (MySQL or PostgreSQL)
    - SimpleShop database
    - Tables: products, orders (and any others you need)

Networking
    - Single VPC
    - Public subnet for EC2
    - Private subnet for RDS
    - Security groups controlling access
```

### AWS components

**1. Compute – Amazon EC2**

- One EC2 instance (Linux) hosts the entire web application.
- The app listens on port 80 (HTTP) or 443 (HTTPS) and is reachable via the instance public IP or a public DNS name.
- Application responsibilities:
  - Render a simple storefront UI.
  - Expose APIs to list products and create orders.
  - Read/write data from/to the RDS database.

**2. Database – Amazon RDS (MySQL/PostgreSQL)**

- One RDS instance running either MySQL or PostgreSQL.
- Contains the `simpleshop` database with a minimal schema, for example:
  - `products(id, name, price, description)`
  - `orders(id, product_id, quantity, total_price, created_at)`
- The RDS instance is placed in a private subnet and only accessible from the EC2 instance security group.

**3. Networking – VPC, Subnets, Security Groups**

- **VPC**: single VPC containing the app.
- **Subnets**:
  - Public subnet: EC2 instance.
  - Private subnet: RDS instance.
- **Security Groups**:
  - EC2 SG: allows inbound HTTP (80) from the internet (0.0.0.0/0) for demo simplicity, and SSH from trusted IPs.
  - RDS SG: allows inbound DB port (3306 for MySQL or 5432 for PostgreSQL) only from the EC2 SG.

**4. Observability and management** (optional but realistic)

- **Amazon CloudWatch Logs**: EC2 system logs and application logs.
- **Amazon CloudWatch Metrics**: basic CPU, memory (via agent), disk, and network metrics.

---

## Target architecture on Azure

On Azure, the goal is to migrate the EC2 VM to an equivalent Azure VM using **Azure Migrate**, then (optionally) migrate the database to **Azure Database for MySQL/PostgreSQL**.

```text
User Browser
    |
    |  HTTP/HTTPS
    v
Azure VM (SimpleShop Web App)
    - Linux VM
    - SimpleShop app migrated from EC2
    |
    |  SQL over TLS
    v
Azure Database for MySQL/PostgreSQL (optional endpoint of DB migration)

Networking
    - Azure Virtual Network (VNet)
    - Subnets for VM and database
    - Network Security Groups (NSGs)
```

### Azure components

**1. Compute – Azure Virtual Machines**

- A Linux-based Azure VM sized similarly to the source EC2 instance.
- The VM is provisioned by Azure Migrate during the migration process.
- The SimpleShop app is replicated and runs on this VM with the same OS and application stack as on AWS.

**2. Database – Azure Database for MySQL/PostgreSQL (optional)**

- Fully managed Azure database service used as the target for RDS migration.
- You can either:
  - Keep the database on RDS temporarily (hybrid scenario), or
  - Use **Azure Database Migration Service** to migrate schema and data to Azure Database.

**3. Networking – VNet, Subnets, NSGs**

- **Virtual Network (VNet)**: isolation boundary for the migrated workload.
- **Subnets**:
  - App subnet: Azure VM.
  - Data subnet: Azure Database (managed service).
- **Network Security Groups**:
  - Control inbound HTTP/HTTPS traffic to the VM.
  - Restrict database access to app subnet.

**4. Management and monitoring**

- **Azure Migrate**:
  - Discovery and inventory of the AWS VM.
  - Assessment of readiness and right-sizing.
  - Orchestrated migration (replication and cutover) to Azure VM.
- **Azure Monitor / VM Insights**:
  - Basic metrics and logs for the Azure VM.

---

## Service mapping: AWS → Azure

| Layer        | AWS Service                  | Azure Equivalent / Tooling                     | Notes |
|-------------|------------------------------|------------------------------------------------|-------|
| Compute     | Amazon EC2 (Linux VM)        | Azure Virtual Machine                           | Migrated using Azure Migrate (Server Migration). |
| Database    | Amazon RDS (MySQL/Postgres)  | Azure Database for MySQL/PostgreSQL + DMS      | DB migration is optional for a 1-hour demo; can be conceptual or pre-done. |
| Networking  | VPC                          | Azure Virtual Network (VNet)                    | Similar isolation/network boundary. |
| Networking  | Subnets                      | Subnets in VNet                                 | App and data subnets. |
| Security    | Security Groups              | Network Security Groups (NSGs)                  | Inbound/outbound rules. |
| Monitoring  | CloudWatch Logs & Metrics    | Azure Monitor, VM Insights                      | Post-migration monitoring. |
| Migration   | N/A (source)                 | Azure Migrate (Discovery, Assessment, Migration)| Central hub for migration operations. |
| DB Migration| N/A (source)                 | Azure Database Migration Service (DMS)          | Optional step for RDS → Azure DB migration. |

---

## Demo flow summary

1. **Show the AWS SimpleShop app** running on EC2 with RDS as the backend.
2. **Use Azure Migrate** to show the discovered EC2 VM and its assessment.
3. **Trigger or review a migration** of the EC2 VM to an Azure VM.
4. **Validate the app on Azure** by browsing to the migrated VM.
5. (Optional) **Explain or demonstrate** database migration from RDS to Azure Database for MySQL/PostgreSQL using Azure Database Migration Service.

Use this document as the high-level architecture reference for slides and as the entry point for the lab.
