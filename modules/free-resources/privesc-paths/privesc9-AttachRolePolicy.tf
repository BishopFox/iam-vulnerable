resource "aws_iam_policy" "privesc9-AttachRolePolicy" {
  name        = "privesc9-AttachRolePolicy"
  path        = "/"
  description = "Allows privesc via iam:AttachRolePolicy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "iam:AttachRolePolicy"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "privesc9-AttachRolePolicy-role" {
  name                = "privesc9-AttachRolePolicy-role"
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

resource "aws_iam_user" "privesc9-AttachRolePolicy-user" {
  name = "privesc9-AttachRolePolicy-user"
  path = "/"
}

 resource "aws_iam_access_key" "privesc9-AttachRolePolicy-user" {
   user = aws_iam_user.privesc9-AttachRolePolicy-user.name
 }


resource "aws_iam_user_policy_attachment" "privesc9-AttachRolePolicy-user-attach-policy" {
  user       = aws_iam_user.privesc9-AttachRolePolicy-user.name
  policy_arn = aws_iam_policy.privesc9-AttachRolePolicy.arn
}

resource "aws_iam_role_policy_attachment" "privesc9-AttachRolePolicy-role-attach-policy" {
  role       = aws_iam_role.privesc9-AttachRolePolicy-role.name
  policy_arn = aws_iam_policy.privesc9-AttachRolePolicy.arn
}