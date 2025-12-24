## RDS
# RDS Subnet Group
resource "aws_db_subnet_group" "rds" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id] # Use Private Subnets

  tags = { Name = "${var.project_name}-rds-subnet-group" }
}
# RDS PostgreSQL Instance
resource "aws_db_instance" "main" {
  identifier             = "${var.project_name}-rds-instance"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "17.6" # Latest version
  instance_class         = var.db_instance_class
  db_name                = "main_db" # Database name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  skip_final_snapshot    = true
  publicly_accessible    = false # Can't access from public

  tags = { Name = "${var.project_name}-rds" }
}