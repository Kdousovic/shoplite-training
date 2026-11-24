#!/bin/bash
set -e

PROFILE="shoplite"
REGION="us-east-1"
OWNER="Walid"
ENVIRONMENT="dev"

echo "=== Deploying ShopLite infrastructure ==="

if ! aws secretsmanager describe-secret     --secret-id "shoplite/$ENVIRONMENT/web/flask-secret-key"     --profile $PROFILE --region $REGION > /dev/null 2>&1; then
  echo "WARNING: secret shoplite/$ENVIRONMENT/web/flask-secret-key not found."
  echo "         Create it in Secrets Manager before deploying the application."
fi

echo "1. Deploying network..."
aws cloudformation deploy \
  --template-file infra/network.yaml \
  --stack-name shoplite-network \
  --parameter-overrides Environment=$ENVIRONMENT Owner=$OWNER \
  --profile $PROFILE --region $REGION

echo "2. Deploying shared resources..."
aws cloudformation deploy \
  --template-file infra/shared.yaml \
  --stack-name shoplite-shared \
  --parameter-overrides Environment=$ENVIRONMENT Owner=$OWNER \
  --profile $PROFILE --region $REGION

echo "3. Deploying EC2 application infrastructure..."
aws cloudformation deploy \
  --template-file infra/app-ec2.yaml \
  --stack-name shoplite-app-ec2 \
  --parameter-overrides \
    Environment=$ENVIRONMENT \
    Owner=$OWNER \
    InstanceType=t3.micro \
  --capabilities CAPABILITY_IAM \
  --profile $PROFILE --region $REGION

echo "=== ShopLite infrastructure deployed successfully! ==="
echo
aws cloudformation describe-stacks --stack-name shoplite-app-ec2   --query "Stacks[0].Outputs[].[OutputKey,OutputValue]" --output table   --profile $PROFILE --region $REGION
aws cloudformation describe-stacks --stack-name shoplite-shared   --query "Stacks[0].Outputs[?OutputKey=='ArtifactsBucketName'].[OutputKey,OutputValue]" --output table   --profile $PROFILE --region $REGION
echo "Next: upload your bundle to the artifacts bucket and run 'aws deploy create-deployment' manually."
