resource "aws_iam_policy" "privesc7-AttachUserPolicy" {
  name        = "privesc7-AttachUserPolicy"
  path        = "/"
  description = "Allows privesc via iam:AttachUserPolicy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "iam:AttachUserPolicy"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "privesc7-AttachUserPolicy-role" {
  name                = "privesc7-AttachUserPolicy-role"
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

resource "aws_iam_user" "privesc7-AttachUserPolicy-user" {
  name = "privesc7-AttachUserPolicy-user"
  path = "/"
}

resource "aws_iam_access_key" "privesc7-AttachUserPolicy-user" {
  user = aws_iam_user.privesc7-AttachUserPolicy-user.name
}


resource "aws_iam_user_policy_attachment" "privesc7-AttachUserPolicy-user-attach-policy" {
  user       = aws_iam_user.privesc7-AttachUserPolicy-user.name
  policy_arn = aws_iam_policy.privesc7-AttachUserPolicy.arn
}

resource "aws_iam_role_policy_attachment" "privesc7-AttachUserPolicy-role-attach-policy" {
  role       = aws_iam_role.privesc7-AttachUserPolicy-role.name
  policy_arn = aws_iam_policy.privesc7-AttachUserPolicy.arn
}