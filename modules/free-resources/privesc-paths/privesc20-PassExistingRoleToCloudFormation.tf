resource "aws_iam_policy" "privesc20-PassExistingRoleToCloudFormation" {
  name        = "privesc20-PassExistingRoleToCloudFormation"
  path        = "/"
  description = "Allows privesc via iam:PassRole, cloudformation:CreateStack, and cloudformation:DescribeStacks"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
	 "Version": "2012-10-17",
	 "Statement": [
	   {
		 "Sid": "VisualEditor0",
		 "Effect": "Allow",
		 "Action": [
			 "iam:PassRole",
			 "cloudformation:CreateStack",
			 "cloudformation:DescribeStacks"
		 ],
		 "Resource": "*"
	  }
   ]
})
}

resource "aws_iam_role" "privesc20-PassExistingRoleToCloudFormation-role" {
  name                = "privesc20-PassExistingRoleToCloudFormation-role"
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

resource "aws_iam_user" "privesc20-PassExistingRoleToCloudFormation-user" {
  name = "privesc20-PassExistingRoleToCloudFormation-user"
  path = "/"
}

resource "aws_iam_access_key" "privesc20-PassExistingRoleToCloudFormation-user" {
  user = aws_iam_user.privesc20-PassExistingRoleToCloudFormation-user.name
}


resource "aws_iam_user_policy_attachment" "privesc20-PassExistingRoleToCloudFormation-user-attach-policy" {
  user       = aws_iam_user.privesc20-PassExistingRoleToCloudFormation-user.name
  policy_arn = aws_iam_policy.privesc20-PassExistingRoleToCloudFormation.arn
}

resource "aws_iam_role_policy_attachment" "privesc20-PassExistingRoleToCloudFormation-role-attach-policy" {
  role       = aws_iam_role.privesc20-PassExistingRoleToCloudFormation-role.name
  policy_arn = aws_iam_policy.privesc20-PassExistingRoleToCloudFormation.arn
}
