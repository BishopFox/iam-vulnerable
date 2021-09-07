resource "aws_iam_policy" "privesc-sageMakerCreateProcessingJobPassRole-policy" {
  name        = "privesc-sageMakerCreateProcessingJobPassRole-policy"
  path        = "/"
  description = "Allows privesc via sagemakerCreatePorcessingJob"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action = [
          "sagemaker:CreateProcessingJob",
          "iam:PassRole"          
        ]
        Resource = "*"
      },
    ]
  })
}



resource "aws_iam_role" "privesc-sageMakerCreateProcessingJobPassRole-role" {
  name                = "privesc-sageMakerCreateProcessingJobPassRole-role"
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


resource "aws_iam_user" "privesc-sageMakerCreateProcessingJobPassRole-user" {
  name = "privesc-sageMakerCreateProcessingJobPassRole-user"
  path = "/"
}

resource "aws_iam_access_key" "privesc-sageMakerCreateProcessingJobPassRole-user" {
  user = aws_iam_user.privesc-sageMakerCreateProcessingJobPassRole-user.name
}



resource "aws_iam_user_policy_attachment" "privesc-sageMakerCreateProcessingJobPassRole-user-attach-policy" {
  user       = aws_iam_user.privesc-sageMakerCreateProcessingJobPassRole-user.name
  policy_arn = aws_iam_policy.privesc-sageMakerCreateProcessingJobPassRole-policy.arn
}


resource "aws_iam_role_policy_attachment" "privesc-sageMakerCreateProcessingJobPassRole-role-attach-policy" {
  role       = aws_iam_role.privesc-sageMakerCreateProcessingJobPassRole-role.name
  policy_arn = aws_iam_policy.privesc-sageMakerCreateProcessingJobPassRole-policy.arn

}  

