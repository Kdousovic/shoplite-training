#!/bin/bash
set -e

PROFILE="shoplite"
REGION="us-east-1"

echo "=== Destroying ShopLite infrastructure ==="

echo "1. Deleting application stack..."
aws cloudformation delete-stack \
  --stack-name shoplite-app-ec2 \
  --profile $PROFILE --region $REGION

aws cloudformation wait stack-delete-complete \
  --stack-name shoplite-app-ec2 \
  --profile $PROFILE --region $REGION

echo "2. Deleting shared resources stack..."
aws cloudformation delete-stack \
  --stack-name shoplite-shared \
  --profile $PROFILE --region $REGION

aws cloudformation wait stack-delete-complete \
  --stack-name shoplite-shared \
  --profile $PROFILE --region $REGION

echo "3. Deleting network stack..."
aws cloudformation delete-stack \
  --stack-name shoplite-network \
  --profile $PROFILE --region $REGION

aws cloudformation wait stack-delete-complete \
  --stack-name shoplite-network \
  --profile $PROFILE --region $REGION

echo "=== ShopLite infrastructure destroyed successfully! ==="
