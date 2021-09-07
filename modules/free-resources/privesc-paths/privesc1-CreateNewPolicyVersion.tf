resource "aws_iam_policy" "privesc1-CreateNewPolicyVersion" {
  name        = "privesc1-CreateNewPolicyVersion"
  path        = "/"
  description = "Allows privesc via iam:CreatePolicyVersion"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "iam:CreatePolicyVersion"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "privesc1-CreateNewPolicyVersion-role" {
  name                = "privesc1-CreateNewPolicyVersion-role"
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


resource "aws_iam_user" "privesc1-CreateNewPolicyVersion-user" {
  name = "privesc1-CreateNewPolicyVersion-user"
  path = "/"
}

resource "aws_iam_access_key" "privesc1-CreateNewPolicyVersion-user" {
 user = aws_iam_user.privesc1-CreateNewPolicyVersion-user.name
}


resource "aws_iam_user_policy_attachment" "privesc1-CreateNewPolicyVersion-user-attach-policy" {
  user       = aws_iam_user.privesc1-CreateNewPolicyVersion-user.name
  policy_arn = aws_iam_policy.privesc1-CreateNewPolicyVersion.arn
}

resource "aws_iam_role_policy_attachment" "privesc1-CreateNewPolicyVersion-role-attach-policy" {
  role       = aws_iam_role.privesc1-CreateNewPolicyVersion-role.name
  policy_arn = aws_iam_policy.privesc1-CreateNewPolicyVersion.arn

}  