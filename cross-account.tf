# Cross-Account IAM Resources for External Account Monitoring

# Cross-account policy for the main Agent Space role
data "aws_iam_policy_document" "cross_account_access" {
  count = length(var.external_accounts) > 0 ? 1 : 0
  
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    
    resources = [
      for account_id, config in var.external_accounts :
      "arn:aws:iam::${account_id}:role/DevOpsAgentCrossAccountRole"
    ]
  }
}

# Attach cross-account policy to Agent Space role if external accounts are specified
resource "aws_iam_role_policy" "cross_account_access" {
  count = length(var.external_accounts) > 0 ? 1 : 0
  
  name   = "DevOpsAgentCrossAccountAccess"
  role   = aws_iam_role.devops_agentspace.id
  policy = data.aws_iam_policy_document.cross_account_access[0].json
}

# Wait for cross-account IAM policies to propagate
resource "time_sleep" "wait_for_cross_account_iam" {
  count = length(var.external_accounts) > 0 ? 1 : 0
  
  depends_on = [
    aws_iam_role_policy.cross_account_access
  ]
  
  create_duration = "15s"
}

# Associate external AWS accounts (if any)
resource "awscc_devopsagent_association" "external_aws_accounts" {
  for_each = var.external_accounts
  
  agent_space_id = awscc_devopsagent_agent_space.main.id
  service_id     = "aws"
  
  configuration = {
    source_aws = {
      account_id         = each.value.account_id
      account_type       = "source"
      assumable_role_arn = "arn:aws:iam::${each.value.account_id}:role/DevOpsAgentCrossAccountRole"
      resources          = []
    }
  }
  
  depends_on = [
    awscc_devopsagent_association.primary_aws_account,
    time_sleep.wait_for_cross_account_iam
  ]
}