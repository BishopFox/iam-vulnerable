resource "aws_iam_policy" "privesc10-PutUserPolicy" {
  name        = "privesc10-PutUserPolicy"
  path        = "/"
  description = "Allows privesc via iam:PutUserPolicy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "iam:PutUserPolicy"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "privesc10-PutUserPolicy-role" {
  name                = "privesc10-PutUserPolicy-role"
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

resource "aws_iam_user" "privesc10-PutUserPolicy-user" {
  name = "privesc10-PutUserPolicy-user"
  path = "/"
}

 resource "aws_iam_access_key" "privesc10-PutUserPolicy-user" {
   user = aws_iam_user.privesc10-PutUserPolicy-user.name
 }


resource "aws_iam_user_policy_attachment" "privesc10-PutUserPolicy-user-attach-policy" {
  user       = aws_iam_user.privesc10-PutUserPolicy-user.name
  policy_arn = aws_iam_policy.privesc10-PutUserPolicy.arn
}

resource "aws_iam_role_policy_attachment" "privesc10-PutUserPolicy-role-attach-policy" {
  role       = aws_iam_role.privesc10-PutUserPolicy-role.name
  policy_arn = aws_iam_policy.privesc10-PutUserPolicy.arn
}