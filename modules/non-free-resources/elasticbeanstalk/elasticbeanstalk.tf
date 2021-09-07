resource "aws_elastic_beanstalk_application" "privesc-elasticbeanstalk-app" {
  name        = "privesc-elasticbeanstalk-app"
  description = "privesc-elasticbeanstalk-app"
}

resource "aws_elastic_beanstalk_environment" "privesc-elasticbeanstalk-env" {
  name                = "privesc-elasticbeanstalk-env"
  application         = aws_elastic_beanstalk_application.privesc-elasticbeanstalk-app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.4 running Docker"
  instance_type       = "t2.micro"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = var.shared_high_priv_servicerole
  }
  
  setting {
      namespace = "aws:elasticbeanstalk:environment"
      name      = "ServiceRole"
      value     = var.shared_high_priv_servicerole
    }

}

resource "aws_elastic_beanstalk_application_version" "privesc-elasticbeanstalk-app-version" {
  name        = "privesc-elasticbeanstalk-app-version"
  application = aws_elastic_beanstalk_application.privesc-elasticbeanstalk-app.name
  bucket      = "my-test-bucket-for-ebs"
  key         = "latest.zip"
}