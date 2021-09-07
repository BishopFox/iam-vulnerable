#Note: This one is not exploitable if the only thing in your account is the IAM-Vulnerable stuff. 
#      For this to be exploitable, you would need to make a revision of this policy and give all access, 
#      and then set it back to this policy. After that, you can demonstrate exploitation. (I could not figure
#      out how to make multiple versions of a policy with terraform)

resource "aws_iam_policy" "privesc2-SetExistingDefaultPolicyVersion" {
  name        = "privesc2-SetExistingDefaultPolicyVersion"
  path        = "/"
  description = "Allows privesc via iam:SetDefaultPolicyVersion."

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "iam:SetDefaultPolicyVersion"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "privesc2-SetExistingDefaultPolicyVersion-role" {
  name                = "privesc2-SetExistingDefaultPolicyVersion-role"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = var.aws_assume_role_arn
        }
      },
    ]
  })
}

resource "aws_iam_user" "privesc2-SetExistingDefaultPolicyVersion-user" {
  name = "privesc2-SetExistingDefaultPolicyVersion-user"
  path = "/"
}

 resource "aws_iam_access_key" "privesc2-SetExistingDefaultPolicyVersion-user" {
   user = aws_iam_user.privesc2-SetExistingDefaultPolicyVersion-user.name
 }


resource "aws_iam_user_policy_attachment" "privesc2-SetExistingDefaultPolicyVersion-user-attach-policy" {
  user       = aws_iam_user.privesc2-SetExistingDefaultPolicyVersion-user.name
  policy_arn = aws_iam_policy.privesc2-SetExistingDefaultPolicyVersion.arn
}

resource "aws_iam_role_policy_attachment" "privesc2-SetExistingDefaultPolicyVersion-role-attach-policy" {
  role       = aws_iam_role.privesc2-SetExistingDefaultPolicyVersion-role.name
  policy_arn = aws_iam_policy.privesc2-SetExistingDefaultPolicyVersion.arn

}