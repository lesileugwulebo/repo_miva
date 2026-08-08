# GCP Observability and Monitoring

# Create a dedicated log bucket in GCP for audit and flow logs
resource "google_logging_project_bucket_config" "audit_bucket" {
  project        = var.gcp_project_id
  location       = var.gcp_region
  bucket_id      = "${local.name_prefix}-gcp-audit-bucket"
  retention_days = 30
}

# Sink to route all audit logs and VPC flow logs to the dedicated bucket
resource "google_logging_project_sink" "audit_sink" {
  project     = var.gcp_project_id
  name        = "${local.name_prefix}-audit-sink"
  destination = "logging.googleapis.com/${google_logging_project_bucket_config.audit_bucket.id}"
  filter      = "logName:\"logs/cloudaudit.googleapis.com\" OR logName:\"logs/compute.googleapis.com%2Fvpc_flows\""

  unique_writer_identity = true
}
