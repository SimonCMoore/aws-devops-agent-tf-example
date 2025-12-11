# Outputs for AWS DevOps Agent Configuration

output "agent_space_id" {
  description = "The ID of the created Agent Space"
  value       = awscc_devopsagent_agent_space.main.id
}

output "agent_space_arn" {
  description = "The ARN of the created Agent Space"
  value       = awscc_devopsagent_agent_space.main.arn
}

output "agent_space_name" {
  description = "The name of the created Agent Space"
  value       = awscc_devopsagent_agent_space.main.name
}

output "devops_agentspace_role_arn" {
  description = "ARN of the DevOps Agent Space IAM role"
  value       = aws_iam_role.devops_agentspace.arn
}

output "devops_operator_role_arn" {
  description = "ARN of the DevOps Operator App IAM role"
  value       = aws_iam_role.devops_operator.arn
}

output "primary_account_association_id" {
  description = "ID of the primary AWS account association"
  value       = awscc_devopsagent_association.primary_aws_account.id
}

output "external_account_association_ids" {
  description = "IDs of external AWS account associations"
  value       = awscc_devopsagent_association.external_aws_accounts[*].id
}

output "operator_app_enabled" {
  description = "Whether the operator app is enabled"
  value       = var.enable_operator_app
}

output "account_id" {
  description = "Current AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}

# Instructions for manual steps
output "manual_setup_instructions" {
  description = "Instructions for completing the setup"
  value = <<-EOT
    
    AWS DevOps Agent Setup Complete!
    
    Agent Space ID: ${awscc_devopsagent_agent_space.main.id}
    
    Next Steps:
    1. For external accounts, create cross-account roles in each external account:
       - Use the trust policy with monitoring account: ${data.aws_caller_identity.current.account_id}
       - External ID: arn:aws:aidevops:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:agentspace/${awscc_devopsagent_agent_space.main.id}
    
    2. Access the DevOps Agent console at:
       https://console.aws.amazon.com/devopsagent/
    
    3. CLI commands to verify setup:
       aws devopsagent list-agent-spaces --endpoint-url "https://api.prod.cp.aidevops.us-east-1.api.aws" --region us-east-1
       aws devopsagent get-agent-space --agent-space-id ${awscc_devopsagent_agent_space.main.id} --endpoint-url "https://api.prod.cp.aidevops.us-east-1.api.aws" --region us-east-1
  EOT
}