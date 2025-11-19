#!/bin/bash
# Simple user-data script to install runtime and deploy the SimpleShop app placeholder.
# You can replace this with your own app deployment steps.

set -e

# Variables passed from Terraform templatefile
db_host="${db_host}"
db_port="${db_port}"
db_name="${db_name}"
db_username="${db_username}"
db_password="${db_password}"

# Update OS
if command -v yum >/dev/null 2>&1; then
  sudo yum update -y
  PKG_MGR="yum"
elif command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y
  PKG_MGR="apt-get"
else
  echo "Unsupported package manager. Please install runtime manually." >&2
  exit 0
fi

# Install basic tools
if [ "$PKG_MGR" = "yum" ]; then
  sudo yum install -y git
elif [ "$PKG_MGR" = "apt-get" ]; then
  sudo apt-get install -y git
fi

# Placeholder: Install Node.js or your preferred runtime manually after creation.
# This script just drops a simple index.html so you see something immediately.

sudo mkdir -p /var/www/simpleshop
sudo tee /var/www/simpleshop/index.html >/dev/null <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>SimpleShop Cloud Migration Lab</title>
  <style>
    :root {
      --bg-gradient: linear-gradient(135deg, #0f172a, #1e3a8a 55%, #06b6d4);
      --card-bg: rgba(15, 23, 42, 0.75);
      --text-light: #f8fafc;
      --accent: #fbbf24;
      --accent-2: #34d399;
      --accent-3: #38bdf8;
      --accent-4: #f472b6;
    }

    * {
      box-sizing: border-box;
    }

    body {
      margin: 0;
      font-family: "Segoe UI", "Inter", sans-serif;
      background: #0f172a;
      color: var(--text-light);
      min-height: 100vh;
      background-image: var(--bg-gradient);
      background-attachment: fixed;
    }

    header {
      text-align: center;
      padding: 4rem 1.5rem 2rem;
    }

    header h1 {
      font-size: clamp(2rem, 4vw, 3.5rem);
      margin-bottom: 0.75rem;
    }

    header p {
      max-width: 720px;
      margin: 0 auto;
      line-height: 1.6;
      font-size: 1.1rem;
    }

    .badge {
      display: inline-flex;
      align-items: center;
      gap: 0.4rem;
      background: rgba(15, 23, 42, 0.65);
      padding: 0.4rem 0.9rem;
      border-radius: 999px;
      font-size: 0.9rem;
      margin-bottom: 1rem;
      color: var(--accent);
      text-transform: uppercase;
      letter-spacing: 0.08em;
    }

    main {
      max-width: 1100px;
      margin: 0 auto;
      padding: 0 1.5rem 4rem;
      display: grid;
      gap: 2rem;
    }

    .card {
      background: var(--card-bg);
      border-radius: 24px;
      padding: 2rem;
      box-shadow: 0 40px 80px rgba(15, 23, 42, 0.45);
      backdrop-filter: blur(12px);
    }

    .grid {
      display: grid;
      gap: 1.25rem;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
    }

    .grid article {
      padding: 1.5rem;
      border-radius: 18px;
      background: rgba(15, 23, 42, 0.55);
      border: 1px solid rgba(255, 255, 255, 0.06);
      min-height: 220px;
      display: flex;
      flex-direction: column;
      gap: 0.8rem;
    }

    .grid h3 {
      margin: 0;
      font-size: 1.15rem;
    }

    .grid p {
      margin: 0;
      line-height: 1.5;
      color: #e2e8f0;
      font-size: 0.95rem;
    }

    .pill {
      display: inline-flex;
      align-items: center;
      gap: 0.4rem;
      padding: 0.35rem 0.85rem;
      border-radius: 999px;
      font-size: 0.85rem;
    }

    .pill.azure {
      background: rgba(56, 189, 248, 0.2);
      color: var(--accent-3);
    }

    .pill.aws {
      background: rgba(251, 191, 36, 0.2);
      color: var(--accent);
    }

    ul.best-practices {
      list-style: none;
      padding: 0;
      margin: 0;
      display: grid;
      gap: 0.9rem;
    }

    ul.best-practices li {
      display: grid;
      grid-template-columns: auto 1fr;
      gap: 0.8rem;
      align-items: start;
      background: rgba(56, 189, 248, 0.12);
      border-left: 4px solid var(--accent-3);
      padding: 1rem;
      border-radius: 12px;
    }

    footer {
      text-align: center;
      font-size: 0.9rem;
      color: #cbd5f5;
    }

    .db-meta {
      display: grid;
      gap: 0.5rem;
      margin-top: 1rem;
    }

    .db-meta div {
      background: rgba(15, 23, 42, 0.55);
      padding: 0.8rem 1rem;
      border-radius: 10px;
      border: 1px solid rgba(255, 255, 255, 0.05);
      font-family: "Consolas", "Fira Code", monospace;
      font-size: 0.95rem;
    }
  </style>
</head>
<body>
  <header>
    <div class="badge">🚀 AWS → Azure Migration Lab</div>
    <h1>SimpleShop Modernization Journey</h1>
    <p>
      Welcome to the live migration experience! This EC2 instance, provisioned automatically via Terraform, illustrates how we take a familiar AWS workload and land it safely in Azure using
      Azure Migrate, modern governance, and DevOps automation.
    </p>
  </header>

  <main>
    <section class="grid">
      <article>
        <span class="pill aws">AWS Today</span>
        <h3>Monolithic Web Tier</h3>
        <p>
          SimpleShop serves product and order APIs from Amazon EC2 with Amazon RDS in a private subnet. Everything runs inside a dedicated VPC with tiered security groups controlling ingress/egress.
        </p>
      </article>
      <article>
        <span class="pill azure">Azure Tomorrow</span>
        <h3>Landing Zone Ready</h3>
        <p>
          Azure Migrate discovers, assesses, and replicates this VM into an Azure VNet. From there we can add Application Gateway, Monitor, and Azure Database for PostgreSQL to level up availability and insights.
        </p>
      </article>
      <article>
        <span class="pill azure">Automation</span>
        <h3>Terraform + GitOps</h3>
        <p>
          IaC keeps AWS and Azure environments reproducible. Git history captures every change, enabling controlled cutovers and easy rollbacks during the demo.
        </p>
      </article>
      <article>
        <span class="pill aws">Data Layer</span>
        <h3>Amazon RDS → Azure DB</h3>
        <p>
          Use Azure Database Migration Service (DMS) to move schema and data with minimal downtime. Connection strings are parameterized to simplify the switchover.
        </p>
      </article>
    </section>

    <section class="card">
      <h2>Migration Best Practices</h2>
      <ul class="best-practices">
        <li>
          <strong>Assess & Right-size</strong>
          <span>Run Azure Migrate assessments to capture performance baselines, dependencies, and cost projections before moving anything.</span>
        </li>
        <li>
          <strong>Design for Resilience</strong>
          <span>Plan for at least two AZs (subnets) for data services. Post-migration, leverage Azure Availability Zones or Scale Sets.</span>
        </li>
        <li>
          <strong>Secure the Path</strong>
          <span>Use NSGs, Azure Firewall, and Key Vault for secrets. Map AWS Security Groups to NSGs one-to-one during landing.</span>
        </li>
        <li>
          <strong>Automate the Runbook</strong>
          <span>Codify infra and migration waves. Pair Terraform (source) with Azure DevOps/GitHub Actions for target deployments.</span>
        </li>
        <li>
          <strong>Observe & Optimize</strong>
          <span>Enable Azure Monitor + Application Insights immediately after cutover to capture telemetry and tune cost/perf.</span>
        </li>
      </ul>
    </section>

    <section class="card">
      <h2>Live Environment Metadata</h2>
      <p>This instance was automatically built with Terraform. Key runtime values:</p>
      <div class="db-meta">
        <div><strong>DB Host:</strong> ${db_host}</div>
        <div><strong>DB Port:</strong> ${db_port}</div>
        <div><strong>DB Name:</strong> ${db_name}</div>
        <div><strong>DB User:</strong> ${db_username}</div>
      </div>
    </section>

    <footer>
      © $(date +%Y) SimpleShop Migration Lab · Crafted for AWS → Azure demos · Customize this page in aws/user_data.sh
    </footer>
  </main>
</body>
</html>
EOF

# Install and configure a simple web server (nginx) to serve the landing page
if [ "$PKG_MGR" = "yum" ]; then
  sudo yum install -y nginx
elif [ "$PKG_MGR" = "apt-get" ]; then
  sudo apt-get install -y nginx
fi

sudo rm -f /etc/nginx/conf.d/default.conf 2>/dev/null || true
sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
sudo rm -f /etc/nginx/sites-available/default 2>/dev/null || true
sudo tee /etc/nginx/conf.d/simpleshop.conf >/dev/null <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;
    root /var/www/simpleshop;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

sudo systemctl enable nginx
sudo systemctl restart nginx
