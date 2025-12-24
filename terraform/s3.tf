## S3
# Bucket
resource "aws_s3_bucket" "data_lake" {
  bucket  = "${var.project_name}-datalake-bucket-2025"  
  tags    = {
    Name  = "${var.project_name}-data-lake"
  }
  force_destroy = true
}

# Random Bucket Suffix Name
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# ${random_id.bucket_suffix.hex} for random
# force_destroy =  allow terraform destroy resource in s3