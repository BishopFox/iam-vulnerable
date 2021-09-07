resource "aws_iam_policy" "privesc4-CreateAccessKey" {
  name        = "privesc4-CreateAccessKey"
  path        = "/"
  description = "Allows privesc via iam:CreateAccessKey"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "iam:CreateAccessKey"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "privesc4-CreateAccessKey-role" {
  name                = "privesc4-CreateAccessKey-role"
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


resource "aws_iam_user" "privesc4-CreateAccessKey-user" {
  name = "privesc4-CreateAccessKey-user"
  path = "/"
}

resource "aws_iam_access_key" "privesc4-CreateAccessKey-user" {
 user = aws_iam_user.privesc4-CreateAccessKey-user.name
}

resource "aws_iam_user_policy_attachment" "privesc4-CreateAccessKey-user-attach-policy" {
  user       = aws_iam_user.privesc4-CreateAccessKey-user.name
  policy_arn = aws_iam_policy.privesc4-CreateAccessKey.arn
}

resource "aws_iam_role_policy_attachment" "privesc4-CreateAccessKey-role-attach-policy" {
  role       = aws_iam_role.privesc4-CreateAccessKey-role.name
  policy_arn = aws_iam_policy.privesc4-CreateAccessKey.arn

}