## AMI (Amazon Machine Image)
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon"]
}

## EC2
# Bastion Host (EC2)
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux_2.id # AMI ที่ดึงมา
  instance_type = "t2.micro"                     # Free Tier
  subnet_id     = aws_subnet.public.id           # Public Subnet
  key_name      = var.ec2_key_pair_name          # Key Pair
  
  vpc_security_group_ids = [aws_security_group.bastion.id] # Security group from Bastion

  tags = { Name = "${var.project_name}-bastion-host" }
}