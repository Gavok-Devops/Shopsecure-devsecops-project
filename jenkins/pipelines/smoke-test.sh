#!/usr/bin/env bash
# jenkins/pipelines/smoke-test.sh
set -euo pipefail

BASE_URL="${BASE_URL:-https://api.shopsecure.io}"
PASS=0
FAIL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

test_endpoint() {
  local name="$1"
  local url="$2"
  local expected_status="$3"
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url")

  if [ "$status" = "$expected_status" ]; then
    echo -e "${GREEN}PASS${NC}: $name  [HTTP $status]"
    ((PASS++))
  else
    echo -e "${RED}FAIL${NC}: $name  [expected $expected_status, got $status]"
    ((FAIL++))
  fi
}

echo "============================================"
echo " ShopSecure Smoke Tests"
echo " Target: $BASE_URL"
echo "============================================"

test_endpoint "Root health check"     "$BASE_URL/health"                200
test_endpoint "Product list"          "$BASE_URL/api/v1/products"       200
test_endpoint "Product search"        "$BASE_URL/api/v1/products?q=test" 200
test_endpoint "Auth status"           "$BASE_URL/api/v1/auth/status"    200
test_endpoint "Order endpoint (auth)" "$BASE_URL/api/v1/orders"         401
test_endpoint "Metrics exposed"       "$BASE_URL/metrics"               200
test_endpoint "404 handling"          "$BASE_URL/this-does-not-exist"   404

echo ""
echo "============================================"
echo " Results: ${PASS} passed, ${FAIL} failed"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
  echo "SMOKE TESTS FAILED — check logs above"
  exit 1
fi

echo "ALL SMOKE TESTS PASSED"
