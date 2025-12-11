# AWS DevOps Agent Resources

# Create the Agent Space
resource "awscc_devopsagent_agent_space" "main" {
  name        = var.agent_space_name
  description = var.agent_space_description
  
  tags = [
    for key, value in var.tags : {
      key   = key
      value = value
    }
  ]
  
  depends_on = [
    aws_iam_role.devops_agentspace,
    aws_iam_role_policy_attachment.devops_agentspace_managed,
    aws_iam_role_policy.devops_agentspace_inline
  ]
}

# Associate the primary AWS account for monitoring
resource "awscc_devopsagent_association" "primary_aws_account" {
  agent_space_id = awscc_devopsagent_agent_space.main.id
  service_id     = "aws"
  
  configuration = jsonencode({
    aws = {
      assumableRoleArn = aws_iam_role.devops_agentspace.arn
      accountId        = data.aws_caller_identity.current.account_id
      accountType      = "monitor"
      resources        = []
    }
  })
  
  tags = [
    for key, value in var.tags : {
      key   = key
      value = value
    }
  ]
}

# Enable Operator App (conditional)
resource "awscc_devopsagent_operator_app" "main" {
  count = var.enable_operator_app ? 1 : 0
  
  agent_space_id        = awscc_devopsagent_agent_space.main.id
  auth_flow            = var.auth_flow
  operator_app_role_arn = aws_iam_role.devops_operator.arn
  
  tags = [
    for key, value in var.tags : {
      key   = key
      value = value
    }
  ]
  
  depends_on = [
    aws_iam_role.devops_operator,
    aws_iam_role_policy.devops_operator_inline
  ]
}