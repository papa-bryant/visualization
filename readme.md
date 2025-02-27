# AWS Health Events Dashboard - Terraform Implementation

This Terraform project creates the infrastructure needed to collect, process, and visualize AWS Health events. It's a direct conversion of the CloudFormation template to Terraform.

## Architecture Overview

The solution implements the following components:

1. Amazon S3 bucket for storing AWS Health events
2. Amazon Kinesis Firehose for data delivery
3. Amazon CloudWatch logs for monitoring
4. AWS Glue Database and Crawler for data cataloging
5. Amazon Athena named query for creating a view
6. EventBridge rule for AWS Health events

## Prerequisites

- Terraform installed (version 1.0.0 or newer)
- AWS CLI configured with appropriate permissions
- An AWS account with permissions to create the necessary resources

## Deployment Instructions

### 1. Clone the repository

```bash
git clone <repository-url>
cd aws-health-events-dashboard
```

### 2. Configure variables

Create a `terraform.tfvars` file based on the example:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` to add your AWS Account ID:

```hcl
aws_region = "us-east-1"  # Change if needed
aws_account_id = "YOUR_ACCOUNT_ID"
```

### 3. Initialize and Apply Terraform Configuration

```bash
terraform init
terraform plan
terraform apply
```

## Post-Deployment Steps

After the infrastructure is deployed, follow these steps:

1. **Wait for AWS Health events**: Events will be captured by EventBridge, processed by Firehose, and stored in the S3 bucket.

2. **Run the Glue crawler**: The crawler is scheduled to run every hour, but you may want to run it manually the first time to create the table.

3. **Run the Athena query to create the view**: The Athena named query is created by Terraform, but you need to run it once manually to create the view.

4. **Set up Grafana dashboard**: Follow the steps in the AWS documentation to set up Grafana with Athena as a data source and create dashboards to visualize the AWS Health events.

## Resources Created

- Amazon S3 bucket for storing Health events
- Amazon CloudWatch log group and stream
- Amazon Kinesis Firehose delivery stream
- AWS Glue database and crawler
- Amazon Athena named query
- EventBridge rule and target
- Various IAM roles and policies

## Cleanup

To remove all resources created by this Terraform configuration:

```bash
terraform destroy
```

## Security Considerations

- The S3 bucket has server-side encryption enabled and blocks public access
- IAM roles follow the principle of least privilege
- CloudWatch logs are configured for monitoring

## Cost Considerations

The majority of costs will come from:
- AWS Glue Crawler (running hourly)
- Amazon Athena queries 
- S3 storage (minimal for most accounts)
- Kinesis Data Firehose (charged per GB of data)
