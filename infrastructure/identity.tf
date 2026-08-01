# Microsoft Entra Groups
resource "azuread_group" "cloud_admins" {
  display_name     = "MC-Cloud-Admins"
  security_enabled = true
  mail_enabled     = false
  description      = "Administrators for the AWS-Azure project"
}

resource "azuread_group" "network_admins" {
  display_name     = "MC-Network-Admins"
  security_enabled = true
  mail_enabled     = false
  description      = "Network administrators for VPN and routing"
}

resource "azuread_group" "security_auditors" {
  display_name     = "MC-Security-Auditors"
  security_enabled = true
  mail_enabled     = false
  description      = "Read-only cloud security auditors"
}

resource "azuread_group" "terraform_deployers" {
  display_name     = "MC-Terraform-Deployers"
  security_enabled = true
  mail_enabled     = false
  description      = "Approved Infrastructure-as-Code operators"
}

# Azure Role Assignments
resource "azurerm_role_assignment" "security_auditors_reader" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Security Reader"
  principal_id         = azuread_group.security_auditors.object_id
}

resource "azurerm_role_assignment" "network_admins" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Network Contributor"
  principal_id         = azuread_group.network_admins.object_id
}

resource "azurerm_role_assignment" "cloud_admins" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.cloud_admins.object_id
}

# AWS IAM Identity Center discovery
data "aws_ssoadmin_instances" "main" {}

locals {
  sso_instance_arn = try(
    tolist(data.aws_ssoadmin_instances.main.arns)[0],
    null
  )
  identity_store_id = try(
    tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0],
    null
  )
}

# AWS SSO Permission Sets
resource "aws_ssoadmin_permission_set" "security_auditor" {
  count            = local.sso_instance_arn != null ? 1 : 0
  name             = "MultiCloudSecurityAuditor"
  description      = "Read-only security review access"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT4H"
}

resource "aws_ssoadmin_managed_policy_attachment" "security_auditor" {
  count              = local.sso_instance_arn != null ? 1 : 0
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_auditor[0].arn
  managed_policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

resource "aws_ssoadmin_permission_set" "network_admin" {
  count            = local.sso_instance_arn != null ? 1 : 0
  name             = "MultiCloudNetworkAdministrator"
  description      = "Restricted networking administration"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT2H"
}

data "aws_iam_policy_document" "network_admin" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:CreateRoute",
      "ec2:ReplaceRoute",
      "ec2:DeleteRoute",
      "ec2:CreateTags",
      "ec2:ModifyVpnConnectionOptions",
      "ec2:ModifyVpnTunnelOptions",
      "cloudwatch:GetMetricData",
      "cloudwatch:ListMetrics",
      "logs:DescribeLogGroups",
      "logs:StartQuery",
      "logs:GetQueryResults"
    ]
    resources = ["*"]
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "network_admin" {
  count              = local.sso_instance_arn != null ? 1 : 0
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.network_admin[0].arn
  inline_policy      = data.aws_iam_policy_document.network_admin.json
}
