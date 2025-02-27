variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  # No default - you must provide this value
}
