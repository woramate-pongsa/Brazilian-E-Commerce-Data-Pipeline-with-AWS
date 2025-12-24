## IAM ROLES
# Role for Glue
resource "aws_iam_role" "glue_role" {
  name                = "${var.project_name}-glue-role"
  assume_role_policy  = jsonencode({
    Version           = "2012-10-17"
    Statement         = [{
      Action          = "sts:AssumeRole"
      Effect          = "Allow"
      Principal       = { Service = "glue.amazonaws.com" }
    }]
  })
  tags = { Name = "${var.project_name}-glue-role" }
}
# Attach IAM Role to Glue
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}
resource "aws_iam_role_policy_attachment" "glue_s3" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
resource "aws_iam_role_policy_attachment" "glue_vpc" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Role for Redshift
resource "aws_iam_role" "redshift_role" {
  count               = var.create_redshift ? 1 : 0
  name                = "${var.project_name}-redshift-role"
  assume_role_policy  = jsonencode({
    Version           = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "redshift.amazonaws.com" }
    }]
  })
  tags = { Name = "${var.project_name}-redshift-role" }
}
# Attach Role to Redshift for S3 read access 
resource "aws_iam_role_policy_attachment" "redshift_s3" {
  count       = var.create_redshift ? 1 : 0
  role        = aws_iam_role.redshift_role[0].name
  policy_arn  = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}