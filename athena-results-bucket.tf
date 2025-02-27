# S3 bucket for Athena query results
resource "aws_s3_bucket" "athena_query_results_bucket" {
  bucket = "aws-health-events-athena-results-${var.aws_account_id}-${var.aws_region}"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "athena_query_results_bucket_ownership" {
  bucket = aws_s3_bucket.athena_query_results_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "athena_query_results_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.athena_query_results_bucket_ownership]
  bucket     = aws_s3_bucket.athena_query_results_bucket.id
  acl        = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "athena_query_results_bucket_encryption" {
  bucket = aws_s3_bucket.athena_query_results_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "athena_query_results_bucket_public_access" {
  bucket = aws_s3_bucket.athena_query_results_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create a lifecycle policy to automatically delete query results after 7 days
resource "aws_s3_bucket_lifecycle_configuration" "athena_query_results_lifecycle" {
  bucket = aws_s3_bucket.athena_query_results_bucket.id

  rule {
    id     = "delete-old-query-results"
    status = "Enabled"

    expiration {
      days = 7
    }
  }
}

# Workgroup for Athena that references the query results location
resource "aws_athena_workgroup" "health_events_workgroup" {
  name = "health-events-workgroup"
  
  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_query_results_bucket.bucket}/query-results/"
      
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}
