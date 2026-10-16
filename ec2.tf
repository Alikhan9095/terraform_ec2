# Read the current Ubuntu 24.04 LTS AMI ID

data "aws_ssm_parameter" "ubuntu" {
  name = var.ami_ssm_parameter_name
}

resource "aws_instance" "web_ec2" {
  ami = data.aws_ssm_parameter.ubuntu.value

  instance_type = var.instance_type

  tags = {
    Name        = var.instance_name
    Environment = var.environment
    ManagedBy   = var.managed_by
  }
}
