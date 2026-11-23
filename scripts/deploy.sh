#!/bin/bash
set -e

PROFILE="shoplite"
REGION="us-east-1"
OWNER="Walid"
ENVIRONMENT="dev"

echo "=== Deploying ShopLite infrastructure ==="

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
