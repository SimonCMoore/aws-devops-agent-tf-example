#!/bin/bash

# Script to create cross-account roles in external AWS accounts
# This script helps set up the necessary roles before running Terraform

set -e

echo "🔧 AWS DevOps Agent Cross-Account Role Setup"
echo "============================================"

# Check if terraform outputs are available
if ! terraform output agent_space_id &>/dev/null; then
    echo "❌ Terraform outputs not available. Please run 'terraform apply' first."
    exit 1
fi

# Get values from Terraform outputs
AGENT_SPACE_ID=$(terraform output -raw agent_space_id)
MONITORING_ACCOUNT=$(terraform output -raw account_id)
REGION=$(terraform output -raw region)
AGENTSPACE_ROLE_ARN=$(terraform output -raw devops_agentspace_role_arn)

echo "✅ Monitoring Account: $MONITORING_ACCOUNT"
echo "✅ Agent Space ID: $AGENT_SPACE_ID"
echo "✅ Region: $REGION"

# Create trust policy template
cat > cross-account-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "$AGENTSPACE_ROLE_ARN"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "arn:aws:aidevops:$REGION:$MONITORING_ACCOUNT:agentspace/$AGENT_SPACE_ID"
        }
      }
    }
  ]
}
EOF

# Create additional permissions policy
cat > cross-account-additional-permissions.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAwsSupportActions",
      "Effect": "Allow",
      "Action": [
        "support:CreateCase",
        "support:DescribeCases"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Sid": "AllowExpandedAIOpsAssistantPolicy",
      "Effect": "Allow",
      "Action": [
        "aidevops:GetKnowledgeItem",
        "aidevops:ListKnowledgeItems",
        "eks:AccessKubernetesApi",
        "synthetics:GetCanaryRuns",
        "route53:GetHealthCheckStatus",
        "resource-explorer-2:Search"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF

echo ""
echo "📋 Cross-account role setup files created:"
echo "   - cross-account-trust-policy.json"
echo "   - cross-account-additional-permissions.json"
echo ""
echo "🚀 For each external AWS account, run these commands:"
echo ""
echo "1. Switch to the external account:"
echo "   aws sts assume-role --role-arn arn:aws:iam::EXTERNAL_ACCOUNT_ID:role/OrganizationAccountAccessRole --role-session-name devops-agent-setup"
echo ""
echo "2. Create the cross-account role:"
echo "   aws iam create-role \\"
echo "     --role-name DevOpsAgentCrossAccountRole \\"
echo "     --assume-role-policy-document file://cross-account-trust-policy.json"
echo ""
echo "3. Attach the AWS managed policy:"
echo "   aws iam attach-role-policy \\"
echo "     --role-name DevOpsAgentCrossAccountRole \\"
echo "     --policy-arn arn:aws:iam::aws:policy/AIOpsAssistantPolicy"
echo ""
echo "4. Attach additional permissions:"
echo "   aws iam put-role-policy \\"
echo "     --role-name DevOpsAgentCrossAccountRole \\"
echo "     --policy-name AIDevOpsAdditionalPermissions \\"
echo "     --policy-document file://cross-account-additional-permissions.json"
echo ""
echo "5. Update your terraform.tfvars with the external account configuration"
echo "6. Run 'terraform apply' again to create the associations"
echo ""
echo "💡 Tip: You can also use AWS Organizations or AWS Control Tower to deploy these roles automatically across multiple accounts."