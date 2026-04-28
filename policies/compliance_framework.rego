package terraform
# CIS 2.1: CloudTrail logging must be enabled on all S3 buckets
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not resource.change.after.logging
    msg := sprintf("S3 bucket '%s' must have logging enabled (CIS 2.1)", [resource.address])
}

# CIS 3.1: CloudTrail should be enabled
deny contains msg if {
    resources := [r | r := input.resource_changes[_]; r.type == "aws_cloudtrail"]
    count(resources) == 0
    msg := "At least one CloudTrail should be enabled (CIS 3.1)"
}

# CIS 3.4: Ensure CloudTrail trails are integrated with CloudWatch Logs
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_cloudtrail"
    not resource.change.after.cloud_watch_logs_group_arn
    msg := sprintf("CloudTrail '%s' must log to CloudWatch Logs (CIS 3.4)", [resource.address])
}

# CIS 4.1: Ensure a log metric filter and alarm exist for unauthorized API calls
warn contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_cloudwatch_log_group"
    not resource.change.after.name
    msg := sprintf("CloudWatch Log Group '%s' should be monitored (CIS 4.1)", [resource.address])
}

# CIS 5.1: Ensure IAM policies are attached only to groups or roles
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_user_policy"
    msg := sprintf("IAM policy '%s' is attached to a user, should be attached to groups (CIS 5.1)", [resource.address])
}

# CIS 5.2: Ensure IAM policies that allow full ("*") permissions are removed
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_iam_policy"
    policy := json.unmarshal(resource.change.after.policy)
    statement := policy.Statement[_]
    
    statement.Effect == "Allow"
    statement.Action == "*"
    statement.Resource == "*"
    
    msg := sprintf("IAM policy '%s' grants full permissions, violates CIS 5.2", [resource.address])
}

# CIS 5.3: Ensure MFA Delete is enabled on S3 bucket
warn contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_versioning"
    versioning := resource.change.after.versioning_configuration
    versioning.mfa_delete != "Enabled"
    msg := sprintf("S3 bucket '%s' should have MFA Delete enabled (CIS 5.3)", [resource.address])
}

# CIS 5.4: Ensure all data in Amazon RDS is securely encrypted
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_db_instance"
    resource.change.after.storage_encrypted != true
    msg := sprintf("RDS instance '%s' is not encrypted (CIS 5.4)", [resource.address])
}

# CIS 5.5: Ensure all data in Amazon Redshift is securely encrypted
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_redshift_cluster"
    resource.change.after.encrypted != true
    msg := sprintf("Redshift cluster '%s' is not encrypted (CIS 5.5)", [resource.address])
}

# CIS 5.6: Ensure all data in ElastiCache Replication Groups is securely encrypted
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_elasticache_replication_group"
    resource.change.after.at_rest_encryption_enabled != true
    msg := sprintf("ElastiCache group '%s' does not have at-rest encryption (CIS 5.6)", [resource.address])
}

# Cost optimization policies
warn contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_instance"
    instance_type := resource.change.after.instance_type
    
    expensive_types := ["p3.8xlarge", "p3.16xlarge", "p4d.24xlarge"]
    instance_type == expensive_types[_]
    
    msg := sprintf("Instance '%s' is using expensive type '%s', verify necessity", [resource.address, instance_type])
}

# Environment tagging policy
deny contains msg if {
    resource := input.resource_changes[_]
    
    taggable_resources := [
        "aws_instance",
        "aws_db_instance",
        "aws_rds_cluster",
        "aws_elasticache_cluster",
        "aws_elasticache_replication_group",
        "aws_s3_bucket",
        "aws_vpc",
        "aws_subnet",
        "aws_security_group"
    ]
    
    resource.type == taggable_resources[_]
    tags := resource.change.after.tags
    
    not tags
    msg := sprintf("Resource '%s' must have tags (Environment, Project, Owner)", [resource.address])
}

deny contains msg if {
    resource := input.resource_changes[_]
    tags := resource.change.after.tags
    
    tags
    keys := object.keys(tags)
    
    required_tags := ["Environment", "Project"]
    missing_tags := [tag | tag := required_tags[_]; not keys[tag]]
    
    count(missing_tags) > 0
    msg := sprintf("Resource '%s' missing required tags: %s", [resource.address, missing_tags])
}
