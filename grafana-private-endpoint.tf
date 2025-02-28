
# Create a security group for Grafana
resource "aws_security_group" "grafana_sg" {
  name        = "grafana-workspace-sg"
  description = "Security group for Amazon Managed Grafana workspace"
  vpc_id      = var.vpc_id
  
  # Allow HTTPS traffic from within the VPC
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  
  # Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "grafana-workspace-sg"
  }
}

# Create a Route53 private hosted zone (if it doesn't exist already)
resource "aws_route53_zone" "private_zone" {
  count = var.create_route53_zone ? 1 : 0
  
  name = var.private_domain_name
  
  vpc {
    vpc_id = var.vpc_id
  }
  
  tags = {
    Name = "${var.private_domain_name}-private-zone"
  }
}

# Create a Route53 CNAME record pointing to the Grafana workspace
resource "aws_route53_record" "grafana_cname" {
  zone_id = var.create_route53_zone ? aws_route53_zone.private_zone[0].zone_id : var.existing_route53_zone_id
  name    = "grafana.${var.private_domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_grafana_workspace.health_events_workspace.endpoint]
}
