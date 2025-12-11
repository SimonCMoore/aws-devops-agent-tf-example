# Cross-Account Role Creation in External Accounts
# This creates the necessary roles in external accounts when create_cross_account_roles = true

# Dynamic provider configuration for external accounts
terraform {
  # Note: Provider aliases need to be configured manually for each external account
  # See README.md for detailed instructions
}

# Trust policy for cross-account roles in external accounts
data "aws_iam_policy_document" "cross_account_trust" {
  for_each = var.create_cross_account_roles ? var.external_accounts : {}
  
  statement {
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.devops_agentspace.arn]
    }
    
    actions = ["sts:AssumeRole"]
    
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = ["arn:aws:aidevops:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:agentspace/${awscc_devopsagent_agent_space.main.id}"]
    }
  }
}

# Cross-account roles in external accounts (requires provider aliases)
# Note: This requires manual provider configuration for each external account
# See the multi-account deployment section in README.md

locals {
  # Instructions for manual cross-account role creation
  cross_account_instructions = var.create_cross_account_roles ? {} : {
    for account_id, config in var.external_accounts : account_id => {
      account_id = account_id
      role_name  = "DevOpsAgentCrossAccountRole"
      trust_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              AWS = aws_iam_role.devops_agentspace.arn
            }
            Action = "sts:AssumeRole"
            Condition = {
              StringEquals = {
                "sts:ExternalId" = "arn:aws:aidevops:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:agentspace/${awscc_devopsagent_agent_space.main.id}"
              }
            }
          }
        ]
      })
      cli_commands = [
        "# Switch to account ${account_id}",
        "aws sts assume-role --role-arn ${config.role_arn} --role-session-name devops-agent-setup",
        "",
        "# Create the cross-account role",
        "aws iam create-role --role-name DevOpsAgentCrossAccountRole --assume-role-policy-document file://trust-policy-${account_id}.json",
        "",
        "# Attach managed policy",
        "aws iam attach-role-policy --role-name DevOpsAgentCrossAccountRole --policy-arn arn:aws:iam::aws:policy/AIOpsAssistantPolicy",
        "",
        "# Attach additional permissions",
        "aws iam put-role-policy --role-name DevOpsAgentCrossAccountRole --policy-name AIDevOpsAdditionalPermissions --policy-document file://additional-permissions.json"
      ]
    }
  }
}