
locals {
  bucket_name = "aws-health-events-records-${var.aws_account_id}-${var.aws_region}"
}

# S3 bucket for storing Health events
resource "aws_s3_bucket" "health_events_bucket" {
  bucket = local.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "health_events_bucket_ownership" {
  bucket = aws_s3_bucket.health_events_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "health_events_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.health_events_bucket_ownership]
  bucket     = aws_s3_bucket.health_events_bucket.id
  acl        = "private"
}

resource "aws_s3_bucket_logging" "health_events_bucket_logging" {
  bucket = aws_s3_bucket.health_events_bucket.id

  target_bucket = aws_s3_bucket.health_events_bucket.id
  target_prefix = "access-logs/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "health_events_bucket_encryption" {
  bucket = aws_s3_bucket.health_events_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "health_events_bucket_public_access" {
  bucket = aws_s3_bucket.health_events_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudWatch Log Group for Firehose
resource "aws_cloudwatch_log_group" "firehose_log_group" {
  name              = "HealthEventsFirehoseLogs"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "firehose_log_stream" {
  name           = "HealthEventsFirehoStream"
  log_group_name = aws_cloudwatch_log_group.firehose_log_group.name
}

# IAM role for Firehose
resource "aws_iam_role" "firehose_role" {
  name = "HealthEventsFirehoseRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "firehose_cloudwatch_policy" {
  name = "cloudwatch-logs-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${var.aws_account_id}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/kinesisfirehose/*"
      }
    ]
  })
}

resource "aws_iam_policy" "firehose_s3_policy" {
  name = "AllowS3Access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowS3Access"
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.health_events_bucket.bucket}*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_cloudwatch_policy_attachment" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_cloudwatch_policy.arn
}

resource "aws_iam_role_policy_attachment" "firehose_s3_policy_attachment" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_s3_policy.arn
}

# Kinesis Firehose Delivery Stream
resource "aws_kinesis_firehose_delivery_stream" "health_events_firehose" {
  name        = "Aws-Health-Events-Delivery-Stream"
  destination = "extended_s3"

  server_side_encryption {
    enabled = true
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.health_events_bucket.arn
    
    prefix = "aws-health-events/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "Aws-Health-Events-Firehose-Error/"
    
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_log_group.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_log_stream.name
    }
  }
}

# IAM role for EventBridge
resource "aws_iam_role" "eventbridge_role" {
  name = "EventBridgeRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "eventbridge_policy" {
  name = "Amazon_EventBridge_Invoke_Firehose"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        Resource = aws_kinesis_firehose_delivery_stream.health_events_firehose.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_policy_attachment" {
  role       = aws_iam_role.eventbridge_role.name
  policy_arn = aws_iam_policy.eventbridge_policy.arn
}

# Glue Database
resource "aws_glue_catalog_database" "health_events_database" {
  name = "aws-health-event-records"
}

# IAM Role for Glue Crawler
resource "aws_iam_role" "glue_crawler_role" {
  name = "GlueCrawlerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "glue_crawler_policy" {
  name = "aws-health-events-GlueCrawlerRolePolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.health_events_bucket.bucket}*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:s3:::${aws_s3_bucket.health_events_bucket.bucket}*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_crawler_policy_attachment" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = aws_iam_policy.glue_crawler_policy.arn
}

resource "aws_iam_role_policy_attachment" "glue_service_role_attachment" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Glue Crawler
resource "aws_glue_crawler" "health_events_crawler" {
  name          = "aws-health-event-crawler"
  role          = aws_iam_role.glue_crawler_role.arn
  database_name = aws_glue_catalog_database.health_events_database.name
  
  s3_target {
    path = "s3://${aws_s3_bucket.health_events_bucket.bucket}"
  }
  
  schedule = "cron(0 */1 * * ? *)"
}

# Athena Named Query
resource "aws_athena_named_query" "health_view_query" {
  name        = "AWS_Health_Summary_View"
  description = "AWS Health event summary view for Dashboard reporting purpose"
  database    = aws_glue_catalog_database.health_events_database.name
  workgroup   = aws_athena_workgroup.health_events_workgroup.name
  query       = <<-EOT
    CREATE OR REPLACE VIEW "aws_health_view" AS
    SELECT DISTINCT
      "year"
    , "month"
    , "day"
    , "eventarn"
    , "service"
    , "communicationid"
    , "eventregion"
    , "eventtypecode"
    , "eventtypecategory"
    , date_format(date_parse(regexp_replace("starttime", ' GMT$', ''),'%a, %e %b %Y %H:%i:%s'), '%Y-%m-%d-%H:%i') AS event_starttime
    , date_format(date_parse(regexp_replace("endtime", ' GMT$', ''),'%a, %e %b %Y %H:%i:%s'), '%Y-%m-%d-%H:%i') AS event_endtime
    , date_format(date_parse(regexp_replace("lastupdatedtime", ' GMT$', ''),'%a, %e %b %Y %H:%i:%s'), '%Y-%m-%d-%H:%i') AS event_lastupdatedtime
    , "language"
    , "latestdescription"
    , "entityvalue" "affected_resource"
    , "deprecatedversion"
    , (CASE WHEN (endtime IS NOT NULL) THEN 'Closed' ELSE 'Open' END) event_status
    FROM
      "aws-health-event-records"."aws_health_events_records_686255945458_us_east_1"
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17
  EOT
}

# EventBridge Rule
resource "aws_cloudwatch_event_rule" "health_event_rule" {
  name        = "aws-health-events-records"
  description = "Capture AWS Health events"
  
  event_pattern = jsonencode({
    source      = ["aws.health", "custom.health"]
    "detail-type" = ["AWS Health Event"]
  })
}

resource "aws_cloudwatch_event_target" "health_event_target" {
  rule      = aws_cloudwatch_event_rule.health_event_rule.name
  target_id = "health-event-target"
  arn       = aws_kinesis_firehose_delivery_stream.health_events_firehose.arn
  role_arn  = aws_iam_role.eventbridge_role.arn
  
  input_transformer {
    input_paths = {
      eventArn          = "$.detail.eventArn"
      latestDescription = "$.detail.eventDescription[0].latestDescription"
      eventTypeCode     = "$.detail.eventTypeCode"
      entityValue       = "$.detail.affectedEntities[0].entityValue"
      service           = "$.detail.service"
      communicationId   = "$.detail.communicationId"
      lastUpdatedTime   = "$.detail.lastUpdatedTime"
      language          = "$.detail.eventDescription[0].language"
      startTime         = "$.detail.startTime"
      endTime           = "$.detail.endTime"
      eventRegion       = "$.detail.eventRegion"
      eventTypeCategory = "$.detail.eventTypeCategory"
      deprecatedVersion = "$.detail.eventMetadata.deprecated_versions"
    }
    
    input_template = <<EOF
{"eventArn": "<eventArn>","service": "<service>","communicationId":"<communicationId>","lastUpdatedTime": "<lastUpdatedTime>","eventRegion": "<eventRegion>","eventTypeCode": "<eventTypeCode>","eventTypeCategory": "<eventTypeCategory>","startTime": "<startTime>","endTime": "<endTime>","language": "<language>","latestDescription": "<latestDescription>","entityValue": "<entityValue>","deprecatedVersion": "<deprecatedVersion>"}
EOF
  }
}

# Data sources
data "aws_partition" "current" {}
