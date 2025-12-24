## Security Groups
# For Bastion Host
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Allow SSH from my IP"
  vpc_id      = aws_vpc.main.id

  # Ingress: Alow SSH (Port 22) from IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] # Use our variables IP
  }

  # Egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project_name}-bastion-sg" }
}

# For Glue
resource "aws_security_group" "glue" {
  name        = "${var.project_name}-glue-sg"
  description = "Security group for Glue jobs"
  vpc_id      = aws_vpc.main.id

 # Ingress
  ingress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"  # -1 means "All traffic"
      self        = true
    }

  # Egress (ขาออก): อนุญาตให้ออกไปได้ทุกที่ (เพื่อคุยกับ S3, RDS, Redshift)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project_name}-glue-sg" }
}

# For RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow PostgreSQL access from Bastion and Glue"
  vpc_id      = aws_vpc.main.id

  # Ingress (ขาเข้า):
  # Alow only from Bastion Host (First loading data from EC2 to RDS)
  ingress {
    from_port       = 5432 # PostgreSQL port
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project_name}-rds-sg" }
}

# For Redshift
resource "aws_security_group" "redshift" {
  count       = var.create_redshift ? 1 : 0
  name        = "${var.project_name}-redshift-sg"
  description = "Allow Redshift access from Bastion, Glue, and my IP"
  vpc_id      = aws_vpc.main.id

  # Ingress (ขาเข้า):
  # from Bastion (Unnecessary for this case)
  ingress {
    from_port       = 5439 # Port ของ Redshift
    to_port         = 5439
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
  # From Glue (For loading data to Redshift)
  ingress {
    from_port       = 5439
    to_port         = 5439
    protocol        = "tcp"
    security_groups = [aws_security_group.glue.id]
  }
  # From IP (For DBT or BI Tool (In this case is DBT))
  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] # From our IP
  }
  ingress {
      from_port   = 5439
      to_port     = 5439
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project_name}-redshift-sg" }
}