resource "aws_iam_policy" "privesc11-PutGroupPolicy" {
  name        = "privesc11-PutGroupPolicy"
  path        = "/"
  description = "Allows privesc via iam:PutGroupPolicy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "iam:PutGroupPolicy"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "privesc11-PutGroupPolicy-role" {
  name                = "privesc11-PutGroupPolicy-role"
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

resource "aws_iam_user" "privesc11-PutGroupPolicy-user" {
  name = "privesc11-PutGroupPolicy-user"
  path = "/"
}

 resource "aws_iam_access_key" "privesc11-PutGroupPolicy-user" {
   user = aws_iam_user.privesc11-PutGroupPolicy-user.name
 }


resource "aws_iam_user_policy_attachment" "privesc11-PutGroupPolicy-user-attach-policy" {
  user       = aws_iam_user.privesc11-PutGroupPolicy-user.name
  policy_arn = aws_iam_policy.privesc11-PutGroupPolicy.arn
}

resource "aws_iam_role_policy_attachment" "privesc11-PutGroupPolicy-role-attach-policy" {
  role       = aws_iam_role.privesc11-PutGroupPolicy-role.name
  policy_arn = aws_iam_policy.privesc11-PutGroupPolicy.arn
}

resource "aws_iam_group" "privesc11-PutGroupPolicy-group" {
  name = "privesc11-PutGroupPolicy-group"
  path = "/"
}

resource "aws_iam_group_membership" "privesc11-PutGroupPolicy-group-membership" {
  name = "privesc11-PutGroupPolicy-group-membership"

  users = [
    aws_iam_user.privesc11-PutGroupPolicy-user.name
  ]

  group = aws_iam_group.privesc11-PutGroupPolicy-group.name
}