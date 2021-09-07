variable "aws_assume_role_arn" {
  description = "This is the arn of an already existing principal that can assume into any roles that are created"
  type        = string
  default     = ""
}
