variable "aws_region" {
  type = string
}

variable "aws_profile" {
  type = string
}

variable "stack_name" {
  type        = string
  description = "Name for the stack"
  default     = "networking"
}

variable "environment" {
  type        = string
  description = "Environment of the deploy"
}

variable "vpc" {
  type = object({
    name                    = string
    cidr_block              = string
    private_subnets         = map(map(string))
    public_subnets          = map(map(string))
    nat_gateway_subnet_name = string
  })
  description = "VPC details"
}
