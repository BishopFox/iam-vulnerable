
# IAM Vulnerable
Use Terraform to create your own *vulnerable by design* AWS IAM privilege escalation playground.

![](.images/IAMVulnerable-350px.png)


IAM Vulnerable uses the Terraform binary and your AWS credentials to deploy over 250 IAM resources into your selected AWS account. Within minutes, you can start learning how to identify and exploit vulnerable IAM configurations that allow for privilege escalation.

:fox_face:  **Currently supported privilege escalation paths:         31**

# Table of Contents
- [IAM Vulnerable](#iam-vulnerable)
- [Recommended Approach](#recommended-approach)
- [Detailed Usage Instructions](#detailed-usage-instructions)
- [Quick Start](#quick-start)
  - [What resources were just created?](#what-resources-were-just-created)
  - [How much is this going to cost?](#how-much-is-this-going-to-cost)
- [A Modular Approach](#a-modular-approach)
  - [Free resource modules](#free-resource-modules)
  - [Non-free resource modules](#non-free-resource-modules)
- [Supported Privilege Escalation Paths](#supported-privilege-escalation-paths)
- [Other Use Cases](#other-use-cases)  
- [FAQ](#faq)

# Recommended Approach

1. **Select or create an AWS account** - Do NOT use an account that has any production resources or sensitive data.
2. **Create your vulnerable playground** - Use this repo to create the IAM principals and policies that support 31 unique AWS IAM privesc paths.
3. **Do your homework** - Learn about the 21 original privesc paths [pioneered by Spencer Gietzen](https://rhinosecuritylabs.com/aws/aws-privilege-escalation-methods-mitigation/).
4. **Hacky, hack** - Practice exploitation in your new playground [using Gerben Kleijn's guide](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws).
5. **Level up** - Run your tools against your new IAM privesc playground account (i.e., [Cloudsplaining](https://github.com/salesforce/cloudsplaining/), [AWSPX](https://github.com/FSecureLABS/awspx), [Principal Mapper](https://github.com/nccgroup/PMapper), [Pacu](https://github.com/RhinoSecurityLabs/pacu)).

# Detailed Usage Instructions

[Blog Post: IAM Vulnerable - An AWS IAM Privilege Escalation Playground](https://labs.bishopfox.com/tech-blog/iam-vulnerable-an-aws-iam-privilege-escalation-playground)

# Quick Start  

This quick start outlines an opinionated approach to getting IAM Vulnerable up and running in your AWS account as quickly as possible. You might have many of these steps already completed, or you might want to tweak things to work with your current configuration. Check out the [Other Use Cases](#other-use-cases) section in this repository for some additional configuration options.

1. Select or create an AWS account. (Do NOT use an account that has any production resources or sensitive data!)
2. [Create a non-root user with administrative access](https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started_create-admin-group.html) that you will use when running Terraform.
3. [Create an access key for that user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html).
4. [Install the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).
5. [Configure your AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html) with your newly created admin user as the default profile.
6. Confirm your CLI is working as expected by executing `aws sts get-caller-identity`.
7. [Install the Terraform binary](https://www.terraform.io/downloads.html) and add the binary location to your path.
8. `git clone https://github.com/BishopFox/iam-vulnerable`
9. `cd iam-vulnerable/`
10. `terraform init`
11. (Optional) `export TF_VAR_aws_local_profile=PROFILE_IN_AWS_CREDENTIALS_FILE_IF_OTHER_THAN_DEFAULT`  
12. (Optional) `export TF_VAR_aws_local_creds_file=FILE_LOCATION_IF_NON_DEFAULT`
13. (Optional) `terraform plan`
14. `terraform apply`
15. (Optional) Add the IAM vulnerable profiles to your AWS credentials file, and change the account number.
      * The following commands make a backup of your current AWS credentials file, then takes the example credentials file from the repo and replaces the placeholder account with your target account number, and finally adds all of the IAM Vulnerable privesc profiles to your credentials file so you can use them:
      * `cp ~/.aws/credentials ~/.aws/credentials.backup`
      * `tail -n +7 aws_credentials_file_example | sed s/111111111111/$(aws sts get-caller-identity | grep Account | awk -F\" '{print $4}')/g >> ~/.aws/credentials`

**Cleanup**

Whenever you want to remove all of the IAM Vulnerable-created resources, you can run these commands:
1. `cd iam-vulnerable/`
1. `terraform destroy`


## What resources were just created?

The Terraform binary just used your default AWS account profile credentials to create:
* **31 users, roles, and policies** each with a unique exploit path to administrative access of the playground account
* Some additional users, groups, roles, and policies that are required to fully realize certain exploit paths
* Some additional users, roles, and policies that test the detection capabilities of other tools

By default, every role created by this Terraform module is assumable by the user or role you used to run Terraform.
* If you'd like Terraform to use a profile other than the default profile, or you'd like to hard-code the `assume_role_policy` ARN, see [Other Use Cases](#other-use-cases).

## How much is this going to cost?
Deploying IAM vulnerable in its **default configuration will cost nothing**. See the next section to learn how to enable non-default modules that do incur cost, and how much each module will cost per month if you deploy it.

# A Modular Approach

IAM Vulnerable groups certain resources together in modules. Some of the modules are enabled by default (the ones that don't have any cost implications), and others are disabled by default (the ones that incur cost if deployed). This way, you can enable specific modules as needed.

For example, when you are ready to play with the exploit paths like `ssm:StartSession` that involve resources outside of IAM, you can deploy and tear down these resources on demand by uncommenting the module in the `iam-vulnerable/main.tf` file, and re-running `terraform apply`:

```
# Uncomment the next four lines to create an ec2 instance and related resources
#module "ec2" {
#  source = "./modules/non-free-resources/ec2"
#  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
#}
```
After you uncomment the `ec2` module, run:

```
terraform init
terraform apply
```
You have now deployed the required components to try the SSM privesc paths.


## Free Resource Modules

There is no cost to anything deployed within `free-resources`:

| Name | Default Status | Estimated Cost | Description |
| --- | --- | --- | --- |
| privesc-paths  | Enabled | None | Contains all of the IAM privesc paths |
| tool-testing  | Enabled | None | Contains test cases that evaluate the capabilities of the different IAM privesc tools |

## Non-free Resource Modules

Deploying these additional modules can result in cost:

| Name | Default Status | Estimated Cost | Description | Required for |
| --- | --- | --- | --- | --- |
| EC2  | Disabled | :heavy_dollar_sign: <br> $4.50/month | Creates an EC2 instance and a security group that allows SSH from anywhere | `ssm-SendCommand` <br> `ssm-StartSession` <br> `ec2InstanceConnect-SendSSHPublicKey` |
| Lambda | Disabled | :slightly_smiling_face: <br> Monthly cost depends on usage (cost should be zero) | Creates a Lambda function  | `Lambda-EditExistingLambdaFunctionWithRole` |
| Glue | Disabled | :heavy_dollar_sign::heavy_dollar_sign::heavy_dollar_sign::heavy_dollar_sign: <br> $4/hour | Creates a Glue dev endpoint | `Glue-UpdateExistingGlueDevEndpoint` |
| SageMaker | Disabled | Not sure yet | Creates a SageMaker notebook | `sageMakerCreatePresignedNotebookURL` |
| CloudFormation | Disabled |  :slightly_smiling_face: <br> $0.40/month for the secret created via CloudFormation. Nothing or barely nothing for the stack itself	| Creates a CloudFormation stack that creates a secret in secret manager | `privesc-cloudFormationUpdateStack` |



# Supported Privilege Escalation Paths

| Path Name | IAM Vulnerable Profile Name | Non-Default Modules Required | Exploitation References |
| --- | --- | --- | --- |
| **Category: IAM Permissions on Other Users** |   |   |   |
| IAM-CreateAccessKey | privesc4  | None  | :fox_face: [Well, That Escalated Quickly - Privesc 04](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws) <br> :lock: [s3cur3.it IAMVulnerable - Part 3](https://s3cur3.it/home/practicing-aws-security-with-iamvulnerable-part-3) |
| IAM-CreateLoginProfile | privesc5  | None  | :fox_face: [Well, That Escalated Quickly - Privesc 05](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws) <br> :lock: [s3cur3.it IAMVulnerable - Part 3](https://s3cur3.it/home/practicing-aws-security-with-iamvulnerable-part-3)  |
| IAM-UpdateLoginProfile | privesc6  | None  | :fox_face: [Well, That Escalated Quickly - Privesc 06](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws) <br> :lock: [s3cur3.it IAMVulnerable - Part 3](https://s3cur3.it/home/practicing-aws-security-with-iamvulnerable-part-3)  |
| **Category: PassRole to Service** |   |  |   |
| CloudFormation-PassExistingRoleToCloudFormation | privesc20  | None  |:fox_face: [Well, That Escalated Quickly - Privesc 20](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws)   |
| CodeBuild-CreateProjectPassRole| privesc-codeBuildProject  | None  |   |
| DataPipeline-PassExistingRoleToNewDataPipeline| privesc21  | None  | :fox_face: [Well, That Escalated Quickly - Privesc 21](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws)  |
| EC2-CreateInstanceWithExistingProfile| privesc3  | None  | :fox_face: [Well, That Escalated Quickly - Privesc 03](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws) <br> :lock: [s3cur3.it IAMVulnerable - Part 2](https://s3cur3.it/home/practicing-aws-security-with-iamvulnerable-part-2) |
| Glue-PassExistingRoleToNewGlueDevEndpoint | privesc18  | None  | :fox_face: [Well, That Escalated Quickly - Privesc 18](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws)  |
| Lambda-PassExistingRoleToNewLambdaThenInvoke | privesc15  |  None | :fox_face: [Well, That Escalated Quickly - Privesc 15](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws)   |
| Lambda-PassRoleToNewLambdaThenTrigger | privesc16  |  None | :fox_face: [Well, That Escalated Quickly - Privesc 16](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws)  |
| SageMaker-CreateNotebookPassRole |  privesc-sageNotebook | None  | :rhinoceros: [AWS IAM Privilege Escalation - Method 2](https://rhinosecuritylabs.com/aws/aws-privilege-escalation-methods-mitigation-part-2/)  |
| SageMaker-CreateTrainingJobPassRole | privesc-sageTraining  |  None  |   |
| SageMaker-CreateProcessingJobPassRole |  privesc-sageProcessing | None   | |
| **Category: Permissions on Policies** |    |   |
| IAM-AddUserToGroup | privesc13  |  None  |:fox_face: [Well, That Escalated Quickly - Privesc 13](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws)   |
| IAM-AttachGroupPolicy| privesc8  | None   | :fox_face: [Well, That Escalated Quickly - Privesc 08](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws)  |
| IAM-AttachRolePolicy| privesc9  | None   | :fox_face: [Well, That Escalated Quickly - Privesc 09](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws)  |
| IAM-AttachUserPolicy| privesc7  | None   | :fox_face:  [Well, That Escalated Quickly - Privesc 07](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws)  |
| IAM-CreateNewPolicyVersion| privesc1  |  None | :fox_face: [Well, That Escalated Quickly - Privesc 01](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws) <br> :lock: [s3cur3.it IAMVulnerable - Part 1](https://s3cur3.it/home/practicing-aws-security-with-iamvulnerable) |
| IAM-PutGroupPolicy | privesc11  | None  | :fox_face: [Well, That Escalated Quickly - Privesc 11](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws)  |
| IAM-PutRolePolicy | privesc12  | None | :fox_face:  [Well, That Escalated Quickly - Privesc 12](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws) |
| IAM-PutUserPolicy | privesc10  | None   | :fox_face: [Well, That Escalated Quickly - Privesc 10](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws)  |
| IAM-SetExistingDefaultPolicyVersion | privesc2  | None  |  :fox_face: [Well, That Escalated Quickly - Privesc 02](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws) <br> :lock: [s3cur3.it IAMVulnerable - Part 2](https://s3cur3.it/home/practicing-aws-security-with-iamvulnerable-part-2)|
| **Category: Privilege Escalation using AWS Services**|    |   |   |
| EC2InstanceConnect-SendSSHPublicKey | privesc-instanceConnect  |  EC2  | 🔑 [AWS IAM privilege escalation paths](https://pswalia2u.medium.com/aws-iam-privilege-escalation-paths-cba36be1aa9e) |
| CloudFormation-UpdateStack | privesc-cfUpdateStack | CloudFormation | 🔑 [AWS IAM privilege escalation paths](https://pswalia2u.medium.com/aws-iam-privilege-escalation-paths-cba36be1aa9e) |
| Glue-UpdateExistingGlueDevEndpoint| privesc19  |  Glue | :fox_face: [Well, That Escalated Quickly - Privesc 19](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws)  |
| Lambda-EditExistingLambdaFunctionWithRole| privesc17  |  Lambda  | :fox_face: [Well, That Escalated Quickly - Privesc 17](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws) <br> :lock: [s3cur3.it IAMVulnerable - Part 4](https://s3cur3.it/home/practicing-aws-security-with-iamvulnerable-part-4)  |
| SageMakerCreatePresignedNotebookURL | privesc-sageUpdateURL | Sagemaker | :rhinoceros: [AWS IAM Privilege Escalation - Method 3](https://rhinosecuritylabs.com/aws/aws-privilege-escalation-methods-mitigation-part-2/) |
| SSM-SendCommand| privesc-ssm-command  |  EC2  | 🔑 [AWS IAM privilege escalation paths](https://pswalia2u.medium.com/aws-iam-privilege-escalation-paths-cba36be1aa9e) |
| SSM-StartSession | privesc-ssm-session  |  EC2  | 🔑 [AWS IAM privilege escalation paths](https://pswalia2u.medium.com/aws-iam-privilege-escalation-paths-cba36be1aa9e) |
| STS-AssumeRole | privesc-assumerole  | None   | 🔑 [AWS IAM privilege escalation paths](https://pswalia2u.medium.com/aws-iam-privilege-escalation-paths-cba36be1aa9e) |
| **Category: Updating an AssumeRole Policy** |   |   |   |
| IAM-UpdatingAssumeRolePolicy |  privesc14 | None  | :fox_face: [Well, That Escalated Quickly - Privesc 14](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws)   |



# Other Use Cases

#### Default - No `terraform.tfvars` configured
* Deploy using your default AWS profile (Default)
* All created roles are assumable by the principal used to run Terraform (specified in your default profile)

#### Use a profile other than the default to run Terraform
* Copy `terraform.tfvars.example` to `terraform.tvvars`
* Uncomment the line `#aws_local_profile = "profile_name"` and enter the profile name you'd like to use
* If you are using a non-default profile, and still want to use the `aws_credentails_file_example` file, you can use this command to generate an AWS credentials file that works with your non-default profile name (Thanks @scriptingislife)
   * Remember to replace `nondefaultuser` with the profile name you are using): 
   * `tail -n +7 aws_credentials_file_example | sed -e "s/111111111111/$(aws sts get-caller-identity | grep Account | awk -F\" '{print $4}')/g;s/default/nondefaultuser/g" >> ~/.aws/credentials`
 

#### Use an ARN other than the caller as the principal that can assume the newly created roles

* Copy `terraform.tfvars.example` to `terraform.tvvars`
* Uncomment the line `#aws_assume_role_arn = "arn:aws:iam::112233445566:user/you"` and enter the ARN you'd like to use

Once created, each of the privesc roles will be assumable by the principal (ARN) you specified.

#### Create the resource in account X, but use an ARN from account Y as the principal that can assume the newly created roles

If you have configured AWS CLI profiles that assume roles into other accounts, you will want to specify the profile name AND manually specify the ARN you'd like to use to assume into the different roles.

In the example below, the resources will be created in the account that is tied to `"prod-cross-org-access-role"`, but each role that Terraform creates can be accessed by `"arn:aws:iam::112233445566:user/you"`, which belongs to another account.

```
aws_local_profile = "prod-cross-org-access-role"
aws_assume_role_arn = "arn:aws:iam::112233445566:user/you"
```

# FAQ

### How does IAM Vulnerable compare to [CloudGoat](https://github.com/RhinoSecurityLabs/cloudgoat/), [Terragoat](https://github.com/bridgecrewio/terragoat), and [SadCloud](https://github.com/nccgroup/sadcloud)?

All of these tools use Terraform to deploy intentionally vulnerable infrastructure to AWS. However, **IAM Vulnerable's focus is IAM privilege escalation**, whereas the other tools either don't cover IAM privesc or only cover some scenarios.  

* [CloudGoat](https://github.com/RhinoSecurityLabs/cloudgoat/) deploys eight unique scenarios, some of which cover IAM privesc paths, while others focus on other areas like secrets in EC2 metadata.
* [Terragoat](https://github.com/bridgecrewio/terragoat) and [SadCloud](https://github.com/nccgroup/sadcloud) both focus on the many ways you can misconfigure your cloud accounts, but do not cover IAM privesc paths. In fact, you can almost think of IAM vulnerable as a missing puzzle piece when applied along side Terragoat or SadCloud. The intentionally vulnerable configurations complement each other.

### How does IAM Vulnerable compare to [Cloudsplaining](https://github.com/salesforce/cloudsplaining/), [AWSPX](https://github.com/FSecureLABS/awspx), [Principal Mapper](https://github.com/nccgroup/PMapper), [Pacu](https://github.com/RhinoSecurityLabs/pacu), [Cloudmapper](https://github.com/duo-labs/cloudmapper), or [ScouteSuite](https://github.com/nccgroup/ScoutSuite)?

All of these tools help identify existing misconfigurations in your AWS environment. Some, like Pacu, also help you exploit misconfigurations. In contrast, IAM Vulnerable **creates** intentionally vulnerable infrastructure. If you really want to learn how to use tools like Principal Mapper (PMapper), AWSPX, Pacu, and Cloudsplaining, IAM Vulnerable is for you.


### I've never used Terraform and I'm afraid of it. Help!?

I was also afraid of Terraform and projects that would create resources in my account before I knew how Terraform worked. Here are some things that might ease your anxiety:
   * By using an AWS account for this single purpose, you can rest assured that this repository won't negatively impact anything else you care about. Even if you deploy IAM Vulnerable to a separate account in an AWS organization, you can rest assured that the other accounts in the org will be outside the blast radius of this playground account.
   * The `terraform plan` command is a dry run. It shows you exactly what will be deployed if you run `terraform apply` before you actually run it.
   * Rest assured knowing that you can `terraform destroy` anything you `terraform apply` for a clean slate.
   * If your concern is cost, check out [Infracost](https://www.infracost.io/docs/). You download this binary, register for a free API key, and execute it within a Terraform directory like `iam-vulnerable`. This tool runs `terraform plan` and calculates the monthly cost associated with the plan as it is currently configured. This is the tool I used to populate the [module cost estimates table above](#non-free-resource-modules).

### Can I run this tool and another tool like [CloudGoat](https://github.com/RhinoSecurityLabs/cloudgoat/), [Terragoat](https://github.com/bridgecrewio/terragoat), or [SadCloud](https://github.com/nccgroup/sadcloud) in the same AWS account?

Yes. Each tool will keep its Terraform state separately, but all resources will be created, updated, and deleted in the same account, and they can coexist.

# Prior work and good references

* https://github.com/RhinoSecurityLabs/AWS-IAM-Privilege-Escalation
* https://rhinosecuritylabs.com/aws/aws-privilege-escalation-methods-mitigation/
* https://rhinosecuritylabs.com/aws/aws-privilege-escalation-methods-mitigation-part-2/
* https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws
* https://ermetic.com/whats-new/blog/aws/auditing-passrole-a-problematic-privilege-escalation-permission/
