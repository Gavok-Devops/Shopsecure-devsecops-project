# ShopSecure — Three-Tier DevSecOps E-Commerce Platform

A production-grade, cloud-native e-commerce platform on **AWS EKS** with a full DevSecOps pipeline.

## Architecture
| Tier | Technology |
|------|-----------|
| Frontend | React 18, NGINX, CloudFront |
| Backend API | Node.js (Auth), Python FastAPI (Products), Go (Orders), Node.js (Payments) |
| Data | Amazon RDS (PostgreSQL), ElastiCache (Redis), S3, SQS |

## Toolchain
- **Terraform** — Infrastructure as Code
- **Jenkins** — CI Pipeline (SAST, container scanning, ECR push)
- **ArgoCD** — GitOps CD
- **Prometheus + Grafana** — Observability

## Quick Start
See the [Implementation Runbook](docs/runbook.md) for step-by-step deployment.

### Prerequisites
```bash
aws configure
cd terraform/environments/prod
terraform init && terraform plan && terraform apply
aws eks update-kubeconfig --name shopsecure-prod --region us-east-1
```
