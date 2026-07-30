# Cloud Engineering Project 10: Secure Conversion King AI Engine(Multi-AZ Private Compute Isolation & ALB Load Balancing)

## Overview

I have architected and deployed a highly available, production-grade web infrastructure on AWS designed to host the **Conversion King AI Engine**. Built according to cloud security best practices, this project establishes a hardened compute footprint by placing all EC2 application instances strictly within private subnets across multiple Availability Zones (`us-east-1a` and `us-east-1b`).

External inbound web traffic is securely received by a public-facing **Application Load Balancer (ALB)** and proxied to the private worker nodes, while outbound internet access for system updates and dependency installation is routed through a stateful **NAT Gateway**. The application layer utilizes a Python 3 Flask backend served via **Gunicorn WSGI**, configured as a persistent system daemon managed by **Systemd** to ensure automated process recovery and self-healing uptime.

---

## The Problem

Deploying application servers directly to public cloud infrastructure without proper network boundaries creates significant security risks and operational vulnerabilities:

### Direct Compute Ingress Exposure

Hosting web applications on EC2 instances inside public subnets with public IP addresses exposes backend infrastructure to continuous automated scanning, brute-force attacks, and direct network exploitation.

### Single Point of Failure (SPOF)

Running non-load-balanced compute instances in a single Availability Zone leaves services vulnerable to localized datacenter outages and unexpected traffic spikes.

### Unmanaged Process Lifecycles

Running Python web applications interactively or via ad-hoc scripts causes services to drop permanently whenever an underlying process crashes or an instance reboots.

---

## The Solution

### Multi-AZ Isolated Network Topology

Confined all application worker nodes within isolated private subnets across two Availability Zones, forcing all public ingress traffic to flow strictly through an Application Load Balancer.

### Stateful Outbound Network Egress

Deployed a NAT Gateway in the public subnet paired with custom VPC route tables, allowing private compute nodes to download software packages and communicate with AWS service endpoints without exposing incoming ports to the public internet.

### Least-Privilege Security Group Chaining

Implemented security group cross-referencing between `conversion-king-alb-sg` and `app-ec2-sg`, ensuring compute instances only accept HTTP traffic originating directly from the ALB's security group ID.

### Persistent Systemd Service Daemon

Packaged the Flask/Gunicorn application layer into a native Linux `systemctl` service (`conversion-king.service`), guaranteeing automated startup on system boot and instant process restarts upon failure.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Load Balancing Tier | AWS Application Load Balancer (`conversion-king-alb`) |
| Target Group Management | AWS Target Groups (`conversion-king-tg`) with HTTP Health Checks |
| Compute Infrastructure | AWS Auto Scaling Group (`conversion-king-asg`) on EC2 (`t3.micro` / Amazon Linux 2023) |
| Application Framework | Python 3, Flask Framework, Redis Drivers, Boto3 AWS SDK |
| WSGI Production Server | Gunicorn 3-Worker Daemon Architecture |
| Network Infrastructure | Amazon VPC, Public & Private Subnets, Internet Gateway, Elastic IP, NAT Gateway |
| Operational Management | AWS Systems Manager Session Manager |

---

## Architecture Diagram



---

## Project Procedure

## 1. Multi-AZ Network Fabric Construction

### VPC & Subnet Allocation

Architected a dedicated VPC (`vpc-07ea859557cef4970`) containing public subnets for edge infrastructure and private subnets for application workloads across `us-east-1a` and `us-east-1b`.

### NAT Gateway Provisioning

Allocated an Elastic IP (`32.194.120.158`) and deployed a public NAT Gateway (`nat-00a852119caf0a2ac`) in `subnet-00af679cefc8479a4`.

### Private Egress Route Binding

Associated private route tables (`rtb-06929cd6dba31464d` and `rtb-01282127d432e4634`) with the NAT Gateway for `0.0.0.0/0` outbound routing, granting private instances internet egress without public IP exposure.

---

## 2. Security Perimeter & Security Group Chaining

### ALB Security Group

`alb-sg / sg-096798c57043e599a`

Configured inbound HTTP Port 80 from `0.0.0.0/0` to accept public requests and outbound HTTP Port 80 to destination `0.0.0.0/0`.

### EC2 Compute Security Group

`app-ec2-sg / sg-036c10d0ecc3ad379`

Restricted inbound HTTP Port 80 strictly to source `sg-096798c57043e599a` (`alb-sg`), preventing direct connections. Configured outbound rules to allow all traffic (`0.0.0.0/0`) for package downloads and SSM Agent connectivity.

---

## 3. Application Stack & Systemd Daemon Deployment

### Environment Preparation

Connected to private compute instances via **AWS Systems Manager (SSM) Session Manager** without using SSH keys.

### Virtual Environment Setup

Configured Python 3 environments in `/app/venv` and installed production dependencies:

```text
flask
gunicorn
boto3
redis
psycopg2-binary
```

### Application Code Authoring

Created `/app/app.py` defining health check endpoints `/` and `/health`, returning system status JSON metrics.

### Service Daemon Orchestration

Authored `/etc/systemd/system/conversion-king.service` to manage Gunicorn background workers:

```ini
[Unit]
Description=Conversion King AI Flask Service
After=network.target

[Service]
User=root
WorkingDirectory=/app
ExecStart=/app/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:80 app:app
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

### Service Enablement

Enabled and launched the background service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now conversion-king
sudo systemctl status conversion-king
```

---

## 4. Load Balancer & Target Group Orchestration

### Target Group Registration

Associated private instances (`i-06d3d06ef54b2c3f2` and `i-0fe20d737916be41c`) with `conversion-king-tg`, monitoring HTTP Port 80 on path `/`.

### ALB Listener Mapping

Configured `conversion-king-alb` listener rules to forward incoming Port 80 traffic directly to `conversion-king-tg`.

---

## Infrastructure as Code (IaC) Architecture

To ensure repeatable deployments, the multi-AZ load-balanced compute environment can be provisioned using modular Terraform files:

```text
terraform-aws-conversion-king/
├── main.tf              # Provider configuration and global settings
├── variables.tf         # Abstracted VPC CIDRs, instance types, and naming conventions
├── vpc.tf               # Multi-AZ VPC, subnets, Internet Gateway, EIP, and NAT Gateway
├── security_groups.tf   # ALB SG and EC2 SG with cross-referenced security group rules
├── alb.tf               # Application Load Balancer, Listener, and Target Group resources
├── compute.tf           # Auto Scaling Group, Launch Template, and Systemd User Data script
└── outputs.tf           # ALB Public DNS name and Target Group ARN outputs
```

---

## Detailed File-by-File Technical Breakdown

### `main.tf`

Configures the AWS Provider and default environment tags.

### `variables.tf`

Parameterizes instance hardware types (`t3.micro`), AWS regions (`us-east-1`), and VPC CIDR blocks.

### `vpc.tf`

Provisions public and private subnets across multiple AZs and maps private route tables to the active NAT Gateway interface.

### `security_groups.tf`

Enforces security group chaining by setting the source of the EC2 ingress rule to the ALB security group ID.

### `alb.tf`

Defines the Internet-facing ALB, HTTP listener on Port 80, and target group health check parameters (`/health`).

### `compute.tf`

Provisions an Auto Scaling Group and defines an automated `user_data` script to install Python, configure virtual environments, write application files, and launch `conversion-king.service`.

### `outputs.tf`

Exports the Load Balancer DNS name for validation testing.

---

## Technical Difficulties Faced & Engineering Resolutions

## Challenge 1: Outbound Egress Block Causing SSM and Cloud-Init Timeouts

### Root Cause Analysis

During initial provisioning, `app-ec2-sg` lacked outbound internet rules. The SSM Agent failed to connect to `ssm.us-east-1.amazonaws.com` with I/O timeout errors, and the boot script failed to download Python dependencies via `pip`.

### Architectural Resolution

Added an outbound rule to `app-ec2-sg` allowing all traffic to destination `0.0.0.0/0`, granting private instances outbound egress through the NAT Gateway.

---

## Challenge 2: One-Time Execution Constraint of EC2 User Data

### Root Cause Analysis

EC2 cloud-init scripts execute only once upon initial launch. Rebooting instances after fixing egress rules did not re-trigger package installation, leaving Gunicorn uninstalled.

### Architectural Resolution

Terminated the misconfigured instances to trigger the Auto Scaling Group to launch fresh replacements, while executing the Systemd setup script via SSM Session Manager on active nodes.

---

## Challenge 3: Security Group Cross-Referencing Mismatches

### Root Cause Analysis

The Target Group continuously reported `Request timed out` health status due to mismatched security group references between `alb-sg` and `app-ec2-sg`.

### Architectural Resolution

Verified that `alb-sg` (`sg-096798c57043e599a`) permitted outbound HTTP traffic to `0.0.0.0/0` and ensured `app-ec2-sg` (`sg-036c10d0ecc3ad379`) explicitly allowed inbound HTTP traffic on Port 80 from source `sg-096798c57043e599a`.

---

## Verification and Results

### Verified Private Subnet & Egress Connectivity

Private EC2 instances successfully route outbound requests through the NAT Gateway while remaining completely hidden from public ingress scanning.

### Validated Active Gunicorn WSGI Service

Executed local terminal health checks via SSM, confirming that `conversion-king.service` actively returns `HTTP/1.1 200 OK`.

### Confirmed 2/2 Healthy Target Group Registration

The Target Group console registered both private instances across `us-east-1a` and `us-east-1b` as **Healthy**.

### Validated Live Public ALB Response

Navigated to the public ALB DNS URL and confirmed successful JSON payload delivery:

```text
conversion-king-alb-1302602968.us-east-1.elb.amazonaws.com
```

```json
{
  "service": "Conversion King AI Engine",
  "status": "healthy",
  "tier": "EC2 Worker Node"
}
```

---

## Verification Screenshots

### 1. VPC Private Route Tables with Active NAT Gateway Target

Displays the VPC private route tables configured with a `0.0.0.0/0` destination pointing directly to the active public NAT Gateway interface. This confirms that compute nodes inside private subnets have stateful outbound internet access for package updates while maintaining zero public ingress exposure.
<img width="1715" height="779" alt="Screenshot 1" src="https://github.com/user-attachments/assets/a5c6c54b-5bb6-4448-b170-a65fd2cf3b17" />

<img width="1696" height="778" alt="Screenshot 2" src="https://github.com/user-attachments/assets/616f1664-b080-452b-99ab-ecf6f5dcc97b" />




### 2. AWS Systems Manager (SSM) Active Terminal Session Verification

Shows an active AWS Systems Manager (SSM) terminal session on a private EC2 worker node verifying that `conversion-king.service` is in an active running state. A local `curl` command validates that Gunicorn is listening on Port 80 and returning `HTTP/1.1 200 OK`.
<img width="1439" height="567" alt="Screenshot 3" src="https://github.com/user-attachments/assets/9cd29270-4aa2-41b8-922e-5aab115fe5bf" />


### 3. Target Group Console Displaying 2/2 Healthy Registered Instances

Displays the AWS Target Group console (`conversion-king-tg`) with 2 out of 2 registered EC2 instances returning a green **Healthy** status across both Availability Zones (`us-east-1a` and `us-east-1b`). This verifies that the Application Load Balancer health checks are successfully communicating with the private application servers.
<img width="1386" height="661" alt="Screenshot 4" src="https://github.com/user-attachments/assets/cf6b52ee-e5a3-4389-8d66-d4b7f6754b17" />


### 4. Live Application Load Balancer Public DNS HTTP JSON Response

Captures a web browser connecting to the public Application Load Balancer DNS URL and rendering the live Conversion King AI Engine JSON payload. This confirms full end-to-end traffic routing from the public internet down to the private backend compute nodes.
<img width="1040" height="375" alt="Screenshot 5" src="https://github.com/user-attachments/assets/2754189f-49f2-4750-92d5-f43e34b2b026" />


---

## Future Improvements

### HTTPS & SSL/TLS Termination

Attach an AWS Certificate Manager (ACM) SSL certificate to the ALB to enforce encrypted HTTPS traffic on Port 443 and map a custom domain via Amazon Route 53.

### AWS WAF Protection

Deploy an AWS Web Application Firewall (WAF) in front of the ALB to rate-limit requests, prevent DDoS attempts, and block common web application exploits.

### Automated CI/CD Pipeline

Implement a GitHub Actions deployment pipeline with integrated Trivy container/code security scanning to automate deployment updates to the EC2 worker nodes.

---

## Notes

This project demonstrates an end-to-end deployment framework for isolating web compute workloads within private cloud networks while delivering scalable public access via an Application Load Balancer. It highlights core cloud architecture skills in VPC subnet isolation, NAT Gateway routing, security group chaining, WSGI service daemon management, and high-availability load balancing.

---

## Bottom Line

The Conversion King AI Engine infrastructure demonstrates robust cloud engineering principles by separating public entry points from private compute instances. By isolating worker nodes inside private subnets, routing outbound traffic through a NAT Gateway, enforcing least-privilege security group rules between the ALB and EC2 tiers, and managing Gunicorn/Flask services via Systemd daemons, this setup delivers high availability, strong network isolation, and self-healing operational stability.
