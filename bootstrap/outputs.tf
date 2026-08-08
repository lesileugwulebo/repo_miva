output "s3_bucket_name" {
  description = "S3 Bucket hosting remote state."
  value       = aws_s3_bucket.state.bucket
}

output "dynamodb_table_name" {
  description = "DynamoDB Table hosting tfstate locks."
  value       = aws_dynamodb_table.locks.name
}
