variable "aws_local_profile" {
  description = "What local profile should terraform use to interact with your AWS account(s)"
  type        = string
  default     = "default"
}

variable "aws_local_creds_file" {
  description = "Location of your local credentials file"
  type        = string
  default     = "~/.aws/credentials"
}

variable "aws_assume_role_arn" {
  description = "This is the arn of an already existing principal that can assume into any roles that are created"
  type        = string
  default     = ""
}

variable "aws_root_user" {
  description = "This is the root user of the calling account"
  type        = string
  default     = ""
}