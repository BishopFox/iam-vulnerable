resource "aws_iam_policy" "privesc3-CreateEC2WithExistingInstanceProfile" {
  name        = "privesc3-CreateEC2WithExistingInstanceProfile"
  path        = "/"
  description = "Allows privesc via ec2:RunInstances and iam:passrole and includes some other helpful permissions"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
	      "iam:PassRole",
        "ec2:DescribeInstances",
        "ec2:RunInstances",
        "ec2:CreateKeyPair",
        "ec2:AssociateIamInstanceProfile"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "privesc3-CreateEC2WithExistingInstanceProfile-role" {
  name                = "privesc3-CreateEC2WithExistingInstanceProfile-role"
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



resource "aws_iam_user" "privesc3-CreateEC2WithExistingInstanceProfile-user" {
  name = "privesc3-CreateEC2WithExistingInstanceProfile-user"
  path = "/"
}


resource "aws_iam_access_key" "privesc3-CreateEC2WithExistingInstanceProfile-user" {
  user = aws_iam_user.privesc3-CreateEC2WithExistingInstanceProfile-user.name
}


resource "aws_iam_user_policy_attachment" "privesc3-CreateEC2WithExistingInstanceProfile-user-attach-policy" {
  user       = aws_iam_user.privesc3-CreateEC2WithExistingInstanceProfile-user.name
  policy_arn = aws_iam_policy.privesc3-CreateEC2WithExistingInstanceProfile.arn
}

resource "aws_iam_role_policy_attachment" "privesc3-CreateEC2WithExistingInstanceProfile-role-attach-policy" {
  role       = aws_iam_role.privesc3-CreateEC2WithExistingInstanceProfile-role.name
  policy_arn = aws_iam_policy.privesc3-CreateEC2WithExistingInstanceProfile.arn

}


