# AWS DevOps Agent Terraform Configuration

This Terraform configuration replicates the AWS DevOps Agent CLI onboarding guide setup, providing Infrastructure as Code for deploying and managing AWS DevOps Agent resources.

## Overview

AWS DevOps Agent helps you monitor and manage your AWS infrastructure using AI-powered insights. This Terraform configuration automates the setup process described in the [CLI onboarding guide](https://docs.aws.amazon.com/devopsagent/latest/userguide/getting-started-with-aws-devops-agent-cli-onboarding-guide.html).

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate permissions
- AWS DevOps Agent is only available in `us-east-1` region
- Required IAM permissions for creating roles and policies

## Resources Created

This configuration creates the following resources:

### IAM Resources
- **DevOpsAgentRole-AgentSpace**: IAM role for the Agent Space with required permissions
- **DevOpsAgentRole-WebappAdmin**: IAM role for the Operator App
- Associated policies and trust relationships

### DevOps Agent Resources
- **Agent Space**: The main container for your DevOps Agent configuration
- **AWS Account Association**: Links your AWS account for monitoring
- **Operator App**: (Optional) Enables the web-based operator interface
- **External Account Associations**: (Optional) For cross-account monitoring

## Usage

### Option 1: Automated Deployment (Recommended)

1. **Clone and Configure**
   ```bash
   git clone <this-repo>
   cd aws-devops-agent-terraform
   ```

2. **Run Automated Deployment**
   ```bash
   ./deploy.sh
   ```
   This script will:
   - Check prerequisites (Terraform, AWS CLI, credentials)
   - Create `terraform.tfvars` from example if needed
   - Initialize, validate, plan, and apply Terraform
   - Handle IAM propagation delays with retry logic

3. **Complete Setup**
   ```bash
   ./post-deploy.sh
   ```
   This script will:
   - Configure AWS DevOps Agent CLI if needed
   - Optionally enable the Operator App
   - Provide verification commands

4. **Clean Up (when needed)**
   ```bash
   ./cleanup.sh
   ```

### Option 2: Manual Deployment

1. **Clone and Configure**
   ```bash
   git clone <this-repo>
   cd aws-devops-agent-terraform
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Customize Variables**
   Edit `terraform.tfvars` with your specific configuration:
   ```hcl
   agent_space_name = "MyCompanyAgentSpace"
   agent_space_description = "DevOps monitoring for production workloads"
   enable_operator_app = true
   # external_account_ids = ["123456789012"]  # Optional
   ```

3. **Deploy**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Verify Setup**
   After deployment, use the AWS CLI to verify:
   ```bash
   aws devopsagent list-agent-spaces \
     --endpoint-url "https://api.prod.cp.aidevops.us-east-1.api.aws" \
     --region us-east-1
   ```

## Configuration Options

### Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region (must be us-east-1) | `us-east-1` | Yes |
| `agent_space_name` | Name for the Agent Space | `MyAgentSpace` | No |
| `agent_space_description` | Description for the Agent Space | `AgentSpace for monitoring my application` | No |
| `enable_operator_app` | Enable the operator web app | `true` | No |
| `auth_flow` | Authentication flow (iam/idc) | `iam` | No |
| `external_account_ids` | External AWS accounts to monitor | `[]` | No |
| `tags` | Tags for all resources | See variables.tf | No |

### Cross-Account Monitoring

To monitor external AWS accounts:

#### Option 1: Using the Setup Script (Recommended)

1. **Deploy the main infrastructure first**
   ```bash
   ./deploy.sh
   ./post-deploy.sh
   ```

2. **Generate cross-account role templates**
   ```bash
   ./setup-cross-account-roles.sh
   ```
   This script will:
   - Extract necessary values from your Terraform deployment
   - Generate trust policy and permissions files
   - Provide step-by-step commands for each external account

3. **Add external account IDs to your configuration**
   Edit `terraform.tfvars` and add:
   ```hcl
   external_account_ids = ["123456789012", "234567890123"]
   ```

4. **Apply the updated configuration**
   ```bash
   terraform apply
   ```

#### Option 2: Manual Cross-Account Setup

1. Add account IDs to `external_account_ids` in your `terraform.tfvars`
2. In each external account, create the cross-account role:

```bash
# In external account
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::MONITORING_ACCOUNT_ID:role/DevOpsAgentRole-AgentSpace"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "arn:aws:aidevops:us-east-1:MONITORING_ACCOUNT_ID:agentspace/AGENT_SPACE_ID"
        }
      }
    }
  ]
}
EOF

aws iam create-role \
  --role-name DevOpsAgentCrossAccountRole \
  --assume-role-policy-document file://trust-policy.json

aws iam attach-role-policy \
  --role-name DevOpsAgentCrossAccountRole \
  --policy-arn arn:aws:iam::aws:policy/AIOpsAssistantPolicy
```

## Outputs

The configuration provides several useful outputs:

- `agent_space_id`: The ID of your Agent Space
- `agent_space_arn`: The ARN of your Agent Space  
- `devops_agentspace_role_arn`: ARN of the Agent Space IAM role
- `devops_operator_role_arn`: ARN of the Operator App IAM role
- `manual_setup_instructions`: Next steps and verification commands

## Accessing DevOps Agent

After deployment:

1. **AWS Console**: Visit https://console.aws.amazon.com/devopsagent/
2. **CLI**: Use the AWS CLI with the DevOps Agent service model
3. **Operator App**: If enabled, access through the AWS console

## Limitations

- AWS DevOps Agent is currently in preview
- Only available in `us-east-1` region
- Some features may require manual configuration
- Cross-account roles must be created manually in external accounts

## Troubleshooting

### Common Issues

1. **Region Error**: Ensure you're using `us-east-1`
2. **Permission Errors**: Verify your AWS credentials have IAM permissions
3. **Role Trust Issues**: Check that trust policies include correct account IDs

### Verification Commands

```bash
# List Agent Spaces
aws devopsagent list-agent-spaces \
  --endpoint-url "https://api.prod.cp.aidevops.us-east-1.api.aws" \
  --region us-east-1

# Get specific Agent Space
aws devopsagent get-agent-space \
  --agent-space-id <AGENT_SPACE_ID> \
  --endpoint-url "https://api.prod.cp.aidevops.us-east-1.api.aws" \
  --region us-east-1

# List associations
aws devopsagent list-associations \
  --agent-space-id <AGENT_SPACE_ID> \
  --endpoint-url "https://api.prod.cp.aidevops.us-east-1.api.aws" \
  --region us-east-1
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.