# Input Variables
variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "The name of the project, used for tagging resources."
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "The CIDR block for the public subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_1_cidr" {
  description = "The CIDR block for the private subnet in AZ 1."
  type        = string
  default     = "10.0.10.0/24" # Change from .2 to .10
}

variable "private_subnet_2_cidr" {
  description = "The CIDR block for the private subnet in AZ 2."
  type        = string
  default     = "10.0.11.0/24"
}

#----------------------------------------------

variable "my_ip" {
  description = "Your home/office IP address (CIDR format). e.g., '123.123.123.123/32'"
  type        = string
}

variable "ec2_key_pair_name" {
  description = "The name of the EC2 Key Pair you created in the AWS console."
  type        = string
  default     = "data-pipeline-key"
}

variable "db_username" {
  description = "Username for RDS and Redshift."
  type        = string
}

variable "db_password" {
  description = "Password for RDS and Redshift. Must meet complexity requirements."
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "The instance class for the RDS PostgreSQL database."
  type        = string
  default     = "db.t3.micro" # (Free Tier eligible)
}

variable "redshift_node_type" {
  description = "The node type for the Redshift cluster."
  type        = string
  default     = "ra3.xlplus"
}

variable "create_redshift" {
  description = "ตั้งเป็น true เพื่อสร้าง Redshift, false เพื่อข้าม (ประหยัดเงิน)"
  type        = bool
  default     = true # Default
}