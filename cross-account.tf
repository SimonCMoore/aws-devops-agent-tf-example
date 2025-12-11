# Cross-Account IAM Resources for External Account Monitoring

# Cross-account policy for the main Agent Space role
data "aws_iam_policy_document" "cross_account_access" {
  count = length(var.external_account_ids) > 0 ? 1 : 0
  
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    
    resources = [
      for account_id in var.external_account_ids :
      "arn:aws:iam::${account_id}:role/DevOpsAgentCrossAccountRole"
    ]
  }
}

# Attach cross-account policy to Agent Space role if external accounts are specified
resource "aws_iam_role_policy" "cross_account_access" {
  count = length(var.external_account_ids) > 0 ? 1 : 0
  
  name   = "DevOpsAgentCrossAccountAccess"
  role   = aws_iam_role.devops_agentspace.id
  policy = data.aws_iam_policy_document.cross_account_access[0].json
}

# Associate external AWS accounts (if any)
resource "awscc_devopsagent_association" "external_aws_accounts" {
  count = length(var.external_account_ids)
  
  agent_space_id = awscc_devopsagent_agent_space.main.id
  service_id     = "aws"
  
  configuration = jsonencode({
    sourceAws = {
      accountId        = var.external_account_ids[count.index]
      accountType      = "source"
      assumableRoleArn = "arn:aws:iam::${var.external_account_ids[count.index]}:role/DevOpsAgentCrossAccountRole"
      resources        = []
    }
  })
  
  tags = [
    for key, value in var.tags : {
      key   = key
      value = value
    }
  ]
  
  depends_on = [
    aws_iam_role_policy.cross_account_access
  ]
}