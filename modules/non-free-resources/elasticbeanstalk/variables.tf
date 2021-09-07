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

variable "shared_high_priv_servicerole" {
  description = "This is the arn of high priv service role that is attached to lambda's ec2's, etc. to facilitate privesc"
  type        = string
  default     = ""
}