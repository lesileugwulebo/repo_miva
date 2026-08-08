# GCP IAM Bindings (Representing multi-cloud role configuration)

# Security Auditors: Read-only access to GCP Compute & Networks
resource "google_project_iam_binding" "security_auditor" {
  project = var.gcp_project_id
  role    = "roles/viewer"

  members = [
    "user:${var.gcp_user_email}"
  ]
}

# Network Administrators: Access to VPC networks, firewalls, and routing
resource "google_project_iam_binding" "network_admin" {
  project = var.gcp_project_id
  role    = "roles/compute.networkAdmin"

  members = [
    "user:${var.gcp_user_email}"
  ]
}
