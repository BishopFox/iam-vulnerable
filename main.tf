terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region                  = "us-east-1"    
  #shared_credentials_file = var.aws_local_creds_file
  profile                 = var.aws_local_profile
}

data "aws_caller_identity" "current" {}

module "privesc-paths" {
  source = "./modules/free-resources/privesc-paths"
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
  aws_root_user = format("arn:aws:iam::%s:root", data.aws_caller_identity.current.account_id)
}

module "tool-testing" {
  source = "./modules/free-resources/tool-testing"
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
  aws_root_user = format("arn:aws:iam::%s:root", data.aws_caller_identity.current.account_id)
}

###################
# Module: Lambda
# Uncomment the next module to create a lambda and related resources
###################

#module "lambda" {
# source = "./modules/non-free-resources/lambda"
# aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
#}

###################
# Module: EC2
# Uncomment the next module to create an ec2 instance and related resources
###################

#module "ec2" {
# source = "./modules/non-free-resources/ec2"
# aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
#}

 
###################
# Module: Glue
# Uncomment the next module to create a glue dev endpoint and related resources
###################

#module "glue" {
#   source = "./modules/non-free-resources/glue"
#   aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
#}

###################
# Module: SageMaker
# Uncomment the next module to create a sagemaker notebook and related resources
###################
 
#module "sagemaker" {
#   source = "./modules/non-free-resources/sagemaker"
#   aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
#}

###################
# Module: CloudFormation
# Uncomment the next module to create a cloudformation stack related resources
###################

#module "cloudformation" {
#   source = "./modules/non-free-resources/cloudformation"
#   aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
#   shared_high_priv_servicerole = format("arn:aws:iam::%s:role/privesc-high-priv-service-role", data.aws_caller_identity.current.account_id)   
#}

