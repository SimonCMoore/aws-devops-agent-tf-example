#!/bin/bash

# AWS DevOps Agent Terraform Deployment Script

set -e

echo "🚀 AWS DevOps Agent Terraform Deployment"
echo "========================================"

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install Terraform first."
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install AWS CLI first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

# Check region
CURRENT_REGION=$(aws configure get region)
if [ "$CURRENT_REGION" != "us-east-1" ]; then
    echo "⚠️  Warning: Current AWS region is $CURRENT_REGION"
    echo "   AWS DevOps Agent requires us-east-1 region."
    echo "   You can override this in terraform.tfvars"
fi

echo "✅ Prerequisites check passed"

# Create terraform.tfvars if it doesn't exist
if [ ! -f "terraform.tfvars" ]; then
    echo "📝 Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo "✅ Please edit terraform.tfvars with your specific configuration"
    echo "   Then run this script again."
    exit 0
fi

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Validate configuration
echo "🔍 Validating Terraform configuration..."
terraform validate

# Plan deployment
echo "📋 Planning deployment..."
terraform plan -out=tfplan

# Ask for confirmation
echo ""
read -p "🤔 Do you want to apply this plan? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    rm -f tfplan
    exit 0
fi

# Apply deployment
echo "🚀 Applying deployment..."
terraform apply tfplan

# Clean up plan file
rm -f tfplan

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Check the outputs above for your Agent Space ID"
echo "2. Visit https://console.aws.amazon.com/devopsagent/ to access the console"
echo "3. For external accounts, follow the cross-account setup instructions in README.md"
echo ""
echo "🔍 To verify your setup:"
echo "aws devopsagent list-agent-spaces --endpoint-url 'https://api.prod.cp.aidevops.us-east-1.api.aws' --region us-east-1"