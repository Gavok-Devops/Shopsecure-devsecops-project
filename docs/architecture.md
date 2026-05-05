# ShopSecure — Architecture Overview

## System Architecture

```
                          ┌─────────────────┐
                          │   CloudFront     │
                          │   (CDN + WAF)    │
                          └────────┬────────┘
                                   │ HTTPS
                          ┌────────▼────────┐
                          │ Application LB   │
                          │  (ALB + ACM)     │
                          └────────┬────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                    │
    ┌─────────▼──────┐  ┌─────────▼──────┐  ┌─────────▼──────┐
    │   Frontend     │  │  Auth Service  │  │ Product Service │
    │   (React/NGINX)│  │  (Node.js)     │  │ (Python FastAPI)│
    └────────────────┘  └────────────────┘  └────────────────┘
              │                    │                    │
    ┌─────────▼──────┐  ┌─────────▼──────────────────────────┐
    │  Order Service │  │         Data Layer                  │
    │    (Go/Gin)    │  │  ┌──────────┐  ┌──────────────┐    │
    └────────────────┘  │  │ RDS PG   │  │ ElastiCache  │    │
              │         │  │ (Multi-AZ│  │   (Redis)    │    │
    ┌─────────▼──────┐  │  └──────────┘  └──────────────┘    │
    │Payment Service │  │  ┌──────────┐  ┌──────────────┐    │
    │  (Node.js)     │  │  │    S3    │  │     SQS      │    │
    └────────────────┘  │  └──────────┘  └──────────────┘    │
                        └────────────────────────────────────┘
```

## Network Architecture

```
VPC (10.0.0.0/16)
├── Public Subnets (10.0.0.0/20, 10.0.16.0/20, 10.0.32.0/20)
│   ├── NAT Gateways (1 per AZ)
│   ├── Application Load Balancer
│   └── Bastion Host (optional)
└── Private Subnets (10.0.160.0/20, 10.0.176.0/20, 10.0.192.0/20)
    ├── EKS Node Groups (System + Application)
    ├── RDS PostgreSQL (Multi-AZ)
    └── ElastiCache Redis
```

## DevSecOps Pipeline Flow

```
Developer Push
     │
     ▼
GitHub (Source)
     │
     ▼
Jenkins CI ──────────────────────────────────────┐
  1. Secret Scan (gitleaks)                      │
  2. Unit Tests + Coverage                       │
  3. SAST (SonarQube Quality Gate)               │
  4. Dependency Check (OWASP)                    │
  5. Build Docker Image                          │
  6. Container Scan (Trivy)  ──── FAIL ──► Block │
  7. Push to ECR                                 │
  8. Update GitOps Repo ◄──────────────────────┘
     │
     ▼
ArgoCD (GitOps CD)
  - Detects git change
  - Syncs K8s manifests
  - Validates resources
  - Rolling deployment
     │
     ▼
EKS Production Cluster
     │
     ▼
Prometheus scrapes /metrics
     │
     ▼
Grafana dashboards + alerts
```

## Services & Ports

| Service         | Language   | Port | Protocol |
|----------------|-----------|------|----------|
| frontend        | React/NGINX | 8080 | HTTP     |
| auth-service    | Node.js    | 8080 | HTTP     |
| product-service | Python     | 8080 | HTTP     |
| order-service   | Go         | 8080 | HTTP     |
| payment-service | Node.js    | 8080 | HTTP     |

All services expose `/health/live`, `/health/ready`, and `/metrics` on the same port.

## Security Controls

| Layer | Control |
|-------|---------|
| Network | VPC private subnets, NACLs, Security Groups, WAF |
| K8s API | Private endpoint, RBAC, OIDC/IRSA |
| Workload | Pod Security Standards (restricted), NetworkPolicy, non-root |
| Secrets | AWS Secrets Manager + External Secrets Operator |
| Images | ECR scan-on-push, Trivy in CI (blocks HIGH/CRITICAL) |
| Code | SonarQube Quality Gate, OWASP Dependency Check, gitleaks |
| Audit | CloudTrail, EKS audit logs → CloudWatch |
