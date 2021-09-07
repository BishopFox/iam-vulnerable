resource "aws_iam_policy" "privesc-high-priv-lambda-policy2" {
  name        = "privesc-high-priv-lambda-policy2"
  path        = "/"
  description = "High priv policy used by lambdas"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "*"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Source: https://gist.github.com/smithclay/e026b10980214cbe95600b82f67b4958
# Simple AWS Lambda Terraform Example

data "archive_file" "lambda_zip" {
    type          = "zip"
    source_file   = "modules/non-free-resources/lambda/index.js"
    output_path   = "modules/non-free-resources/lambda/lambda_function.zip"
}


resource "aws_lambda_function" "test_lambda" {
  filename         = "modules/non-free-resources/lambda/lambda_function.zip"
  function_name    = "test_lambda"
  role             = aws_iam_role.privesc-high-priv-lambda-role2.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "nodejs12.x"
}
resource "aws_iam_role" "privesc-high-priv-lambda-role2" {
  name                = "privesc-high-priv-lambda-role2"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [aws_iam_policy.privesc-high-priv-lambda-policy2.arn]
}

#resource "aws_iam_role_policy_attachment" "iam_for_lambda_tf-attach-policy" {
#  role       = aws_iam_role.iam_for_lambda_tf.name
#  policy_arn = aws_iam_policy.privesc-high-priv-lambda-policy.arn
#}
