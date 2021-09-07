resource "aws_iam_policy" "privesc12-PutRolePolicy" {
  name        = "privesc12-PutRolePolicy"
  path        = "/"
  description = "Allows privesc via iam:PutRolePolicy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "iam:PutRolePolicy"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "privesc12-PutRolePolicy-role" {
  name                = "privesc12-PutRolePolicy-role"
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

resource "aws_iam_user" "privesc12-PutRolePolicy-user" {
  name = "privesc12-PutRolePolicy-user"
  path = "/"
}

resource "aws_iam_access_key" "privesc12-PutRolePolicy-user" {
  user = aws_iam_user.privesc12-PutRolePolicy-user.name
}


resource "aws_iam_user_policy_attachment" "privesc12-PutRolePolicy-user-attach-policy" {
  user       = aws_iam_user.privesc12-PutRolePolicy-user.name
  policy_arn = aws_iam_policy.privesc12-PutRolePolicy.arn
}

resource "aws_iam_role_policy_attachment" "privesc12-PutRolePolicy-role-attach-policy" {
  role       = aws_iam_role.privesc12-PutRolePolicy-role.name
  policy_arn = aws_iam_policy.privesc12-PutRolePolicy.arn
}