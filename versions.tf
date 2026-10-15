terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.23" # aws_ecs_express_gateway_service added in 6.23
    }
  }
}
