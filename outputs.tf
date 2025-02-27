output "health_event_rule_arn" {
  description = "ARN of the EventBridge rule for AWS Health events"
  value       = aws_cloudwatch_event_rule.health_event_rule.arn
}

output "health_events_bucket" {
  description = "S3 bucket name for storing AWS Health events"
  value       = aws_s3_bucket.health_events_bucket.bucket
}

output "health_events_database" {
  description = "AWS Glue database name for AWS Health events"
  value       = aws_glue_catalog_database.health_events_database.name
}

output "firehose_delivery_stream" {
  description = "Kinesis Firehose delivery stream name"
  value       = aws_kinesis_firehose_delivery_stream.health_events_firehose.name
}

output "athena_query_results_bucket" {
  description = "S3 bucket name for Athena query results"
  value       = aws_s3_bucket.athena_query_results_bucket.bucket
}

output "athena_workgroup_name" {
  description = "Athena workgroup name for health events queries"
  value       = aws_athena_workgroup.health_events_workgroup.name
}

output "grafana_workspace_endpoint" {
  description = "Amazon Managed Grafana workspace endpoint URL"
  value       = aws_grafana_workspace.health_events_workspace.endpoint
}