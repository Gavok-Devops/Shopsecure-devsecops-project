#!/usr/bin/env bash
# scripts/inject-cert.sh
# Run after terraform apply to inject the ACM certificate ARN into ingress manifest
set -euo pipefail

REGION="us-east-1"
DOMAIN="teamcsolutions.com"

echo "Fetching ACM certificate ARN for $DOMAIN..."

CERT_ARN=$(aws acm list-certificates \
  --region "$REGION" \
  --query "CertificateSummaryList[?DomainName=='$DOMAIN' && Status=='ISSUED'].CertificateArn" \
  --output text)

if [ -z "$CERT_ARN" ]; then
  echo "ERROR: No ISSUED certificate found for $DOMAIN"
  echo "Run: aws acm list-certificates --region $REGION"
  exit 1
fi

echo "Certificate ARN: $CERT_ARN"

# Inject into ingress manifest
INGRESS_FILE="kubernetes/base/ingress.yaml"
sed -i '' "s|CERTIFICATE_ARN|$CERT_ARN|g" "$INGRESS_FILE" 2>/dev/null || \
sed -i    "s|CERTIFICATE_ARN|$CERT_ARN|g" "$INGRESS_FILE"

echo "✓ Certificate ARN injected into $INGRESS_FILE"
echo ""
echo "Next: kubectl apply -f $INGRESS_FILE"
