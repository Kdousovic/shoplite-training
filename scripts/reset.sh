#!/bin/bash
# Destroys every ShopLite stack (labs 1 to 6). Run from the repo root.
# Secrets, hand-made SSM parameters and the GitHub connection are kept.
set -euo pipefail

source env.sh
export MSYS_NO_PATHCONV=1
ENVIRONMENT="dev"

ACCOUNT=$(aws sts get-caller-identity --query Account --output text | tr -d '\r')
echo "This will DESTROY all ShopLite stacks in account $ACCOUNT ($AWS_REGION)."
echo "Reviews data, ECR images and artifacts will be lost for good."
read -r -p "Type 'destroy' to continue: " CONFIRM
[ "$CONFIRM" = "destroy" ] || { echo "Aborted."; exit 1; }

# Name of the stack that owns a resource, empty if there is none
stack_of() {
  aws cloudformation describe-stack-resources --physical-resource-id "$1" \
    --query "StackResources[0].StackName" --output text 2>/dev/null | tr -d '\r' || true
}

delete_stack() {
  if [ -n "$1" ] && aws cloudformation describe-stacks --stack-name "$1" > /dev/null 2>&1; then
    echo "Deleting $1..."
    aws cloudformation delete-stack --stack-name "$1"
    aws cloudformation wait stack-delete-complete --stack-name "$1"
  else
    echo "Stack ${1:-(not found)} skipped."
  fi
}

# Delete every object version and delete marker (bucket is versioned).
# Small batches: Windows limits the length of a command line.
empty_bucket() {
  local bucket="$1" kind payload count
  for kind in Versions DeleteMarkers; do
    while true; do
      count=$(aws s3api list-object-versions --bucket "$bucket" --max-keys 100 --no-paginate \
        --query "length($kind || \`[]\`)" --output text | tr -d '\r')
      [ "$count" -gt 0 ] || break
      payload=$(aws s3api list-object-versions --bucket "$bucket" --max-keys 100 --no-paginate \
        --query "{Objects: $kind[].{Key:Key,VersionId:VersionId}, Quiet: \`true\`}" --output json)
      aws s3api delete-objects --bucket "$bucket" --delete "$payload" > /dev/null
    done
  done
}

delete_stack shoplite-observability

delete_stack "$(stack_of shoplite-$ENVIRONMENT-catalog-pipeline)"
delete_stack "$(stack_of /shoplite/$ENVIRONMENT/catalog)"
delete_stack "$(stack_of shoplite-$ENVIRONMENT-web-pipeline)"

# reviews before its pipeline: that stack holds the role used to delete it
REVIEWS_PIPELINE_STACK=$(stack_of shoplite-$ENVIRONMENT-reviews-pipeline)
delete_stack shoplite-reviews
delete_stack "$REVIEWS_PIPELINE_STACK"

ECR_STACK=$(aws cloudformation describe-stacks \
  --query "Stacks[?Outputs[?ExportName=='shoplite-$ENVIRONMENT-CatalogRepositoryUri']].StackName" \
  --output text | tr -d '\r')
aws ecr delete-repository --repository-name "shoplite-$ENVIRONMENT-catalog" --force \
  > /dev/null 2>&1 || echo "ECR repository skipped."
delete_stack "$ECR_STACK"

delete_stack shoplite-app-ec2

BUCKET="shoplite-$ACCOUNT-$AWS_REGION-$ENVIRONMENT-artifacts"
if aws s3api head-bucket --bucket "$BUCKET" > /dev/null 2>&1; then
  echo "Emptying $BUCKET..."
  empty_bucket "$BUCKET"
fi
delete_stack shoplite-shared
delete_stack shoplite-network

echo "Done. Remaining ShopLite stacks (should be empty):"
aws cloudformation describe-stacks \
  --query "Stacks[?contains(StackName, 'shoplite')].[StackName,StackStatus]" --output text
