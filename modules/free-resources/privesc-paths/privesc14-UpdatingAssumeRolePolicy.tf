resource "aws_iam_policy" "privesc14-UpdatingAssumeRolePolicy" {
  name        = "privesc14-UpdatingAssumeRolePolicy"
  path        = "/"
  description = "Allows privesc via iam:UpdateAssumeRolePolicy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      
      {
        Action = [
	      "iam:UpdateAssumeRolePolicy",
        "sts:AssumeRole"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "privesc14-UpdatingAssumeRolePolicy-role" {
  name                = "privesc14-UpdatingAssumeRolePolicy-role"
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

resource "aws_iam_user" "privesc14-UpdatingAssumeRolePolicy-user" {
  name = "privesc14-UpdatingAssumeRolePolicy-user"
  path = "/"
}

resource "aws_iam_access_key" "privesc14-UpdatingAssumeRolePolicy-user" {
  user = aws_iam_user.privesc14-UpdatingAssumeRolePolicy-user.name
}


resource "aws_iam_user_policy_attachment" "privesc14-UpdatingAssumeRolePolicy-user-attach-policy" {
  user       = aws_iam_user.privesc14-UpdatingAssumeRolePolicy-user.name
  policy_arn = aws_iam_policy.privesc14-UpdatingAssumeRolePolicy.arn
}

resource "aws_iam_role_policy_attachment" "privesc14-UpdatingAssumeRolePolicy-role-attach-policy" {
  role       = aws_iam_role.privesc14-UpdatingAssumeRolePolicy-role.name
  policy_arn = aws_iam_policy.privesc14-UpdatingAssumeRolePolicy.arn
}