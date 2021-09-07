resource "aws_iam_policy" "privesc-AssumeRole-high-priv-policy" {
  name        = "privesc-AssumeRole-high-priv-policy"
  path        = "/"
  description = "Allows privesc via targeted sts:AssumeRole"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action = "*"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "privesc-AssumeRole-starting-role" {
  name                = "privesc-AssumeRole-starting-role"
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

resource "aws_iam_role" "privesc-AssumeRole-intermediate-role" {
  name                = "privesc-AssumeRole-intermediate-role"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = aws_iam_role.privesc-AssumeRole-starting-role.arn
        }
      },
    ]
  })
}


resource "aws_iam_role" "privesc-AssumeRole-ending-role" {
  name                = "privesc-AssumeRole-ending-role"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = aws_iam_role.privesc-AssumeRole-intermediate-role.arn
        }
      },
    ]
  })
}



resource "aws_iam_user" "privesc-AssumeRole-start-user" {
  name = "privesc-AssumeRole-start-user"
  path = "/"
}
resource "aws_iam_access_key" "privesc-AssumeRole-start-user" {
  user = aws_iam_user.privesc-AssumeRole-start-user.name
}
resource "aws_iam_role_policy_attachment" "privesc-AssumeRole-high-priv-policy-role-attach-policy" {
  role       = aws_iam_role.privesc-AssumeRole-ending-role.name
  policy_arn = aws_iam_policy.privesc-AssumeRole-high-priv-policy.arn

}  