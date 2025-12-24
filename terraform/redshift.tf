## Redshift
# Redshift Subnet Group
resource "aws_redshift_subnet_group" "main" {
  count       = var.create_redshift ? 1 : 0
  name        = "${var.project_name}-redshift-subnet-group"
  subnet_ids  = [aws_subnet.public.id]

  tags = { Name = "${var.project_name}-redshift-subnet-group" }
}
# Redshift Cluster
resource "aws_redshift_cluster" "main" {
  count                     = var.create_redshift ? 1 : 0
  cluster_identifier        = "${var.project_name}-redshift-cluster"
  database_name             = "main_db"
  master_username           = var.db_username
  master_password           = var.db_password
  node_type                 = var.redshift_node_type
  cluster_type              = "single-node"
  
  cluster_subnet_group_name = aws_redshift_subnet_group.main[0].name
  vpc_security_group_ids    = [aws_security_group.redshift[0].id]
  iam_roles                 = [aws_iam_role.redshift_role[0].arn]
  # publicly_accessible
  publicly_accessible       = true
  skip_final_snapshot       = true
  apply_immediately = true

  depends_on = [aws_iam_role_policy_attachment.redshift_s3[0]]
}