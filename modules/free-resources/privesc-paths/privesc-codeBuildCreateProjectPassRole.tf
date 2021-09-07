resource "aws_iam_policy" "privesc-codeBuildCreateProjectPassRole-policy" {
  name        = "privesc-codeBuildCreateProjectPassRole-policy"
  path        = "/"
  description = "Allows privesc via codeBuild"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action = [
          "codebuild:CreateProject",          
          "codebuild:StartBuild",
          "codebuild:StartBuildBatch",          
          "iam:PassRole",
          "iam:ListRoles"          
        ]
        Resource = "*"
      },
    ]
  })
}



resource "aws_iam_role" "privesc-codeBuildCreateProjectPassRole-role" {
  name                = "privesc-codeBuildCreateProjectPassRole-role"
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


resource "aws_iam_user" "privesc-codeBuildCreateProjectPassRole-user" {
  name = "privesc-codeBuildCreateProjectPassRole-user"
  path = "/"
}

resource "aws_iam_access_key" "privesc-codeBuildCreateProjectPassRole-user" {
  user = aws_iam_user.privesc-codeBuildCreateProjectPassRole-user.name
}



resource "aws_iam_user_policy_attachment" "privesc-codeBuildCreateProjectPassRole-user-attach-policy" {
  user       = aws_iam_user.privesc-codeBuildCreateProjectPassRole-user.name
  policy_arn = aws_iam_policy.privesc-codeBuildCreateProjectPassRole-policy.arn
}


resource "aws_iam_role_policy_attachment" "privesc-codeBuildCreateProjectPassRole-role-attach-policy" {
  role       = aws_iam_role.privesc-codeBuildCreateProjectPassRole-role.name
  policy_arn = aws_iam_policy.privesc-codeBuildCreateProjectPassRole-policy.arn

}  

