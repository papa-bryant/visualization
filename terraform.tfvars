aws_region = "us-east-1"
aws_account_id = "686255945458"  # Replace with your actual AWS account ID

# VPC Configuration
vpc_id = "vpc-0123456789abcdef0"
private_subnet_ids = ["subnet-0123456789abcdef1", "subnet-0123456789abcdef2"]
vpc_cidr_block = "10.0.0.0/16"

# Route53 Configuration
private_domain_name = "internal.example.com"
create_route53_zone = true
# existing_route53_zone_id = "Z0123456789ABCDEFGHIJ"  # Uncomment if using existing zone