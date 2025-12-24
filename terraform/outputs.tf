## Output Variables
output "vpc_id" {
  description = "The ID of the main VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "The ID of the public subnet."
  value       = aws_subnet.public.id
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets."
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

output "s3_bucket_name" {
  description = "The name of the S3 data lake bucket."
  value       = aws_s3_bucket.data_lake.bucket
}

output "bastion_public_ip" {
  description = "The public IP address of the Bastion host."
  value       = aws_instance.bastion.public_ip
}

output "rds_endpoint" {
  description = "The endpoint address of the RDS PostgreSQL instance."
  value       = aws_db_instance.main.endpoint
}

output "rds_port" {
  description = "The port for the RDS PostgreSQL instance."
  value       = aws_db_instance.main.port
}

output "redshift_endpoint" {
  description = "The endpoint address of the Redshift cluster."
  value       = var.create_redshift ? aws_redshift_cluster.main[0].endpoint : null
}

output "redshift_port" {
  description = "The port for the Redshift cluster."
  value       = var.create_redshift ? aws_redshift_cluster.main[0].port : null
}

output "redshift_role_arn" {
  description = "The ARN of the IAM role for Redshift to access S3."
  value       = var.create_redshift ? aws_iam_role.redshift_role[0].arn : null
}

output "glue_iam_role_arn" {
  description = "The ARN of the IAM role for Glue jobs."
  value       = aws_iam_role.glue_role.arn
}
