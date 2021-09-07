resource "aws_iam_policy" "privesc-ssmSendCommand-policy" {
  name        = "privesc-ssmSendCommand-policy"
  path        = "/"
  description = "Potentially allows privesc. You can execute commands on any instance that supports SSM. Hopefully you'll find an instance that has a highly privileged IAM role attached to it."

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ssm:listCommands",
          "ssm:listCommandInvocations",
          "ssm:sendCommand",
        ]
        Resource = "*"
      },
    ]
  })
}



resource "aws_iam_role" "privesc-ssmSendCommand-role" {
  name                = "privesc-ssmSendCommand-role"
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


resource "aws_iam_user" "privesc-ssmSendCommand-user" {
  name = "privesc-ssmSendCommand-user"
  path = "/"
}

resource "aws_iam_access_key" "privesc-ssmSendCommand-user" {
  user = aws_iam_user.privesc-ssmSendCommand-user.name
}



resource "aws_iam_user_policy_attachment" "privesc-ssmSendCommand-user-attach-policy" {
  user       = aws_iam_user.privesc-ssmSendCommand-user.name
  policy_arn = aws_iam_policy.privesc-ssmSendCommand-policy.arn
}


resource "aws_iam_role_policy_attachment" "privesc-ssmSendCommand-role-attach-policy" {
  role       = aws_iam_role.privesc-ssmSendCommand-role.name
  policy_arn = aws_iam_policy.privesc-ssmSendCommand-policy.arn

}  

