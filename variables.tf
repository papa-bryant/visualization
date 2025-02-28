variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  # No default - you must provide this value
}

variable "vpc_id" {
  description = "VPC ID where Grafana workspace should be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for Grafana workspace"
  type        = list(string)
}

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "private_domain_name" {
  description = "Private domain name for Route53"
  type        = string
  default     = "internal.example.com"
}

variable "create_route53_zone" {
  description = "Whether to create a new Route53 private hosted zone"
  type        = bool
  default     = true
}

variable "existing_route53_zone_id" {
  description = "ID of an existing Route53 private hosted zone (if create_route53_zone is false)"
  type        = string
  default     = ""
}
