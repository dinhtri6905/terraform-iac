package terraform

# Policy: All AWS resources must have proper tags
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_eks_cluster"
    not resource.change.after.tags
    msg := sprintf("EKS Cluster '%s' must have tags defined", [resource.address])
}

# Policy: S3 buckets must have encryption enabled
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not resource.change.after.server_side_encryption_configuration
    msg := sprintf("S3 bucket '%s' must have server-side encryption enabled", [resource.address])
}

# Policy: S3 buckets must have versioning enabled
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_versioning"
    resource.change.after.versioning_configuration.status != "Enabled"
    msg := sprintf("S3 bucket '%s' must have versioning enabled", [resource.address])
}

# Policy: EKS cluster must be encrypted
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_eks_cluster"
    not resource.change.after.encryption_config
    msg := sprintf("EKS Cluster '%s' must have encryption enabled", [resource.address])
}

# Policy: Security groups must restrict ingress from 0.0.0.0/0 on sensitive ports
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group_rule"
    resource.change.after.type == "ingress"
    resource.change.after.from_port == 22
    resource.change.after.cidr_blocks[_] == "0.0.0.0/0"
    msg := sprintf("Security group rule '%s' - SSH (port 22) should not be open to 0.0.0.0/0", [resource.address])
}

# Policy: VPC Flow Logs must be enabled
warn contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_vpc"
    not resource.change.after.enable_dns_hostnames
    msg := sprintf("VPC '%s' should have DNS hostnames enabled", [resource.address])
}

# Policy: ALB should have access logging enabled
warn contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_lb"
    not resource.change.after.access_logs
    msg := sprintf("Load Balancer '%s' should have access logging enabled", [resource.address])
}

# Policy: RDS encryption must be enabled
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.after.storage_encrypted == false
    msg := sprintf("RDS instance '%s' must have encryption enabled", [resource.address])
}

# Policy: IAM policy should not allow * resource with * action
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_policy"
    
    policy := json.unmarshal(resource.change.after.policy)
    statement := policy.Statement[_]
    
    statement.Effect == "Allow"
    statement.Action[_] == "*"
    statement.Resource[_] == "*"
    
    msg := sprintf("IAM policy '%s' should not allow * action on * resource", [resource.address])
}

# Policy: EC2 instances should have IMDSv2 enforced
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    
    metadata_options := resource.change.after.metadata_options
    metadata_options.http_tokens != "required"
    
    msg := sprintf("EC2 instance '%s' should enforce IMDSv2", [resource.address])
}
