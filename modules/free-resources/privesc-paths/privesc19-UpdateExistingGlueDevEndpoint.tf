resource "aws_iam_policy" "privesc19-UpdateExistingGlueDevEndpoint" {
  name        = "privesc19-UpdateExistingGlueDevEndpoint"
  path        = "/"
  description = "Allows privesc via glue:UpdateDevEndpoint and glue:GetDevEndpoint"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
	      "glue:UpdateDevEndpoint",
        "glue:GetDevEndpoint"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "privesc19-UpdateExistingGlueDevEndpoint-role" {
  name                = "privesc19-UpdateExistingGlueDevEndpoint-role"
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

resource "aws_iam_user" "privesc19-UpdateExistingGlueDevEndpoint-user" {
  name = "privesc19-UpdateExistingGlueDevEndpoint-user"
  path = "/"
}

resource "aws_iam_access_key" "privesc19-UpdateExistingGlueDevEndpoint-user" {
  user = aws_iam_user.privesc19-UpdateExistingGlueDevEndpoint-user.name
}


resource "aws_iam_user_policy_attachment" "privesc19-UpdateExistingGlueDevEndpoint-user-attach-policy" {
  user       = aws_iam_user.privesc19-UpdateExistingGlueDevEndpoint-user.name
  policy_arn = aws_iam_policy.privesc19-UpdateExistingGlueDevEndpoint.arn
}

resource "aws_iam_role_policy_attachment" "privesc19-UpdateExistingGlueDevEndpoint-role-attach-policy" {
  role       = aws_iam_role.privesc19-UpdateExistingGlueDevEndpoint-role.name
  policy_arn = aws_iam_policy.privesc19-UpdateExistingGlueDevEndpoint.arn
}
