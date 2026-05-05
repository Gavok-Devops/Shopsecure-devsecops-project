#!/usr/bin/env bash
# scripts/bootstrap-backend.sh
# Run ONCE per AWS account before any terraform init
set -euo pipefail

REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="shopsecure-terraform-state-${ACCOUNT_ID}"
TABLE="shopsecure-terraform-locks"

echo "================================================"
echo " ShopSecure — Terraform Backend Bootstrap"
echo " Account: ${ACCOUNT_ID}"
echo " Region:  ${REGION}"
echo "================================================"

# ── S3 bucket ─────────────────────────────────────────────────────────────────
if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "S3 bucket already exists: $BUCKET"
else
  echo "Creating S3 bucket: $BUCKET"
  aws s3api create-bucket \
    --bucket "$BUCKET" \
    --region "$REGION"

  aws s3api put-bucket-versioning \
    --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled

  aws s3api put-bucket-encryption \
    --bucket "$BUCKET" \
    --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

  aws s3api put-public-access-block \
    --bucket "$BUCKET" \
    --public-access-block-configuration \
    "BlockPublicAcls=true,BlockPublicPolicy=true,IgnorePublicAcls=true,RestrictPublicBuckets=true"

  echo "S3 bucket created and secured."
fi

# ── DynamoDB lock table ───────────────────────────────────────────────────────
if aws dynamodb describe-table --table-name "$TABLE" --region "$REGION" &>/dev/null; then
  echo "DynamoDB table already exists: $TABLE"
else
  echo "Creating DynamoDB lock table: $TABLE"
  aws dynamodb create-table \
    --table-name "$TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"

  aws dynamodb wait table-exists --table-name "$TABLE" --region "$REGION"
  echo "DynamoDB table created."
fi

echo ""
echo "================================================"
echo " Bootstrap complete!"
echo " S3 Bucket:       $BUCKET"
echo " DynamoDB Table:  $TABLE"
echo ""
echo " Next: update backend bucket name in each"
echo " terraform/environments/*/main.tf, then run:"
echo "   terraform init"
echo "================================================"
