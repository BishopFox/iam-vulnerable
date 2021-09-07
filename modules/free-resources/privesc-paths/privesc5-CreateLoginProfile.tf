resource "aws_iam_policy" "privesc5-CreateLoginProfile" {
  name        = "privesc5-CreateLoginProfile"
  path        = "/"
  description = "Allows privesc via iam:CreateLoginProfile"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "iam:CreateLoginProfile"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "privesc5-CreateLoginProfile-role" {
  name                = "privesc5-CreateLoginProfile-role"
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

resource "aws_iam_user" "privesc5-CreateLoginProfile-user" {
  name = "privesc5-CreateLoginProfile-user"
  path = "/"
}

 resource "aws_iam_access_key" "privesc5-CreateLoginProfile-user" {
   user = aws_iam_user.privesc5-CreateLoginProfile-user.name
 }


resource "aws_iam_user_policy_attachment" "privesc5-CreateLoginProfile-user-attach-policy" {
  user       = aws_iam_user.privesc5-CreateLoginProfile-user.name
  policy_arn = aws_iam_policy.privesc5-CreateLoginProfile.arn
}

resource "aws_iam_role_policy_attachment" "privesc5-CreateLoginProfile-role-attach-policy" {
  role       = aws_iam_role.privesc5-CreateLoginProfile-role.name
  policy_arn = aws_iam_policy.privesc5-CreateLoginProfile.arn
}