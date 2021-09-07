resource "aws_cloudformation_stack" "privesc-cloudformationStack" {
  name = "privesc-cloudformationStack"
  iam_role_arn = var.shared_high_priv_servicerole

  template_body = <<STACK
{
  "Resources" : {
    "Secret1" : {
      "Type" : "AWS::SecretsManager::Secret",
      "Properties" : {
          "Description" : "Super strong password that nobody would ever be able to guess",
          "Name" : "iam-vulnerable",
          "SecretString" : "Summer2021!"
      }
    }
  }
}
STACK
}

