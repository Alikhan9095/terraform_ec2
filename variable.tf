variable "aws_region" {
  description = "AWS region where resource will be created"
  type        = string
}

variable "aws_profile" {
  description = "AWS cli profil used fr this learing env"
  type        = string
}

variable "ami_ssm_parameter_name" {
  description = "SSM parameter conataining the ubuntu AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "environment" {
  description = "Environment name, such as dev or prod"
  type        = string
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
}

variable "managed_by" {
  description = "Tool Managing the resource"
  type        = string
}
