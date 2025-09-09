# IAM Vulnerable Cleanup Scripts

This directory contains two cleanup scripts designed to remove all resources created by the iam-vulnerable Terraform project. These scripts are particularly useful when the Terraform state is lost and `terraform destroy` cannot be used.

## Scripts Available

### 1. Python Version (`cleanup_iam_vulnerable.py`)
- **Requirements**: Python 3.6+, boto3 library
- **Installation**: `pip install boto3`
- **Features**: Rich output formatting, detailed error handling, comprehensive resource detection

### 2. Bash Version (`cleanup_iam_vulnerable.sh`)
- **Requirements**: AWS CLI v2, jq
- **Installation**: 
  - AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html
  - jq: `brew install jq` (macOS) or `apt-get install jq` (Ubuntu)
- **Features**: Lightweight, no Python dependencies, colorized output

## Usage

Both scripts support the same command-line options:

```bash
# Python version
./cleanup_iam_vulnerable.py [--profile PROFILE_NAME] [--dry-run] [--yes]

# Bash version
./cleanup_iam_vulnerable.sh [--profile PROFILE_NAME] [--dry-run] [--yes]
```

### Options

- `--profile PROFILE_NAME`: Use a specific AWS profile (default: uses default profile or environment variables)
- `--dry-run`: Show what would be deleted without actually deleting anything
- `--yes`: Skip the confirmation prompt and proceed with deletion

### Examples

```bash
# Dry run to see what would be deleted
./cleanup_iam_vulnerable.py --dry-run

# Use a specific AWS profile
./cleanup_iam_vulnerable.py --profile my-aws-profile

# Skip confirmation and delete everything
./cleanup_iam_vulnerable.py --yes

# Combine options
./cleanup_iam_vulnerable.sh --profile staging --dry-run
```

## Resources Cleaned Up

The scripts will identify and delete the following types of resources created by iam-vulnerable:

### IAM Resources
- **Users**: All users with names starting with `privesc`, `fn1-`, `fn2-`, `fn3-`, `fn4-`, `fp1-`, `fp2-`, `fp3-`, `fp4-`, `fp5-`, or named `Ryan`
- **Roles**: All roles matching the same naming patterns
- **Groups**: All groups matching the same naming patterns  
- **Policies**: All customer-managed policies matching the same naming patterns
- **Access Keys**: All access keys belonging to the identified users
- **Instance Profiles**: All instance profiles matching the naming patterns

### Other AWS Resources
- **Lambda Functions**: Functions named `test_lambda` or matching the naming patterns
- **CloudFormation Stacks**: Stacks named `privesc-cloudformationStack` or matching patterns
- **Glue Dev Endpoints**: Endpoints named `privesc-glue-devendpoint` or matching patterns
- **SageMaker Notebooks**: Notebooks named `privesc-sagemakerNotebook` or matching patterns

## Deletion Order

The scripts delete resources in a specific order to avoid dependency conflicts:

1. Access Keys
2. SageMaker Notebook Instances (stopped first if running)
3. Glue Development Endpoints
4. Lambda Functions
5. CloudFormation Stacks (deletion initiated, may take time to complete)
6. Instance Profiles (roles removed first)
7. IAM Users (policies detached, groups removed, login profiles deleted)
8. IAM Groups (policies detached)
9. IAM Roles (policies detached)
10. IAM Policies (non-default versions deleted first)

## Safety Features

- **Confirmation Prompt**: By default, scripts show all resources to be deleted and require explicit confirmation
- **Dry Run Mode**: Use `--dry-run` to see what would be deleted without making any changes
- **Error Handling**: Scripts continue processing even if individual resource deletions fail
- **Detailed Logging**: Clear output showing what's being deleted and any errors encountered

## AWS Credentials

The scripts use standard AWS credential resolution:

1. Command line profile (`--profile` option)
2. Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, etc.)
3. AWS credentials file (`~/.aws/credentials`)
4. IAM roles (if running on EC2)

## Important Notes

- **Irreversible**: Resource deletion cannot be undone
- **CloudFormation**: Stack deletions are initiated but may take several minutes to complete
- **SageMaker**: Notebook instances must be stopped before deletion (script handles this automatically)
- **Permissions**: Ensure your AWS credentials have sufficient permissions to delete all resource types

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure your AWS credentials have the necessary IAM permissions
2. **Resource Not Found**: Some resources may have already been deleted or may not exist
3. **Dependency Conflicts**: The scripts handle most dependency issues automatically, but some resources may need manual intervention

### Getting Help

Run either script with `--help` to see usage information:

```bash
./cleanup_iam_vulnerable.py --help
./cleanup_iam_vulnerable.sh --help
```

## Security Considerations

- These scripts have broad permissions to delete AWS resources
- Always run with `--dry-run` first to verify what will be deleted
- Use specific AWS profiles to limit scope to the intended account
- Review the resource list carefully before confirming deletion
