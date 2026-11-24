#!/bin/bash
# Destroys all ShopLite infrastructure, including the artifacts bucket
# (all objects and versions). The Secrets Manager secret is NOT touched.
set -euo pipefail

PROFILE="shoplite"
REGION="us-east-1"
ENVIRONMENT="dev"

AWS="aws --profile $PROFILE --region $REGION"

if [ "${1:-}" != "--yes" ]; then
  echo "This will DESTROY all ShopLite stacks and EMPTY the artifacts bucket."
  read -r -p "Type 'destroy' to continue: " CONFIRM
  [ "$CONFIRM" = "destroy" ] || { echo "Aborted."; exit 1; }
fi

stack_exists() {
  $AWS cloudformation describe-stacks --stack-name "$1" > /dev/null 2>&1
}

delete_stack() {
  if stack_exists "$1"; then
    $AWS cloudformation delete-stack --stack-name "$1"
    $AWS cloudformation wait stack-delete-complete --stack-name "$1"
  else
    echo "   Stack $1 not found, skipping."
  fi
}

# Delete every object version and delete marker (bucket is versioned)
empty_bucket() {
  local bucket="$1" kind payload count
  for kind in Versions DeleteMarkers; do
    while true; do
      count=$($AWS s3api list-object-versions --bucket "$bucket" --max-items 1000 \
        --query "length($kind || \`[]\`)" --output text)
      [ "$count" -gt 0 ] || break
      payload=$($AWS s3api list-object-versions --bucket "$bucket" --max-items 1000 \
        --query "{Objects: $kind[].{Key:Key,VersionId:VersionId}, Quiet: \`true\`}" --output json)
      $AWS s3api delete-objects --bucket "$bucket" --delete "$payload" > /dev/null
    done
  done
}

echo "=== Destroying ShopLite infrastructure ==="

echo "1. Deleting application stack..."
delete_stack shoplite-app-ec2

echo "2. Emptying artifacts bucket..."
BUCKET=$($AWS cloudformation describe-stacks --stack-name shoplite-shared \
  --query "Stacks[0].Outputs[?OutputKey=='ArtifactsBucketName'].OutputValue" \
  --output text 2>/dev/null || true)
if [ -n "$BUCKET" ] && [ "$BUCKET" != "None" ]; then
  empty_bucket "$BUCKET"
  echo "   Bucket $BUCKET emptied."
else
  echo "   No bucket found, skipping."
fi

echo "3. Deleting shared resources stack..."
delete_stack shoplite-shared

echo "4. Deleting network stack..."
delete_stack shoplite-network

echo "=== ShopLite infrastructure destroyed successfully! ==="
echo "Note: secret shoplite/$ENVIRONMENT/web/flask-secret-key was left in place."
