#!/usr/bin/env python3
"""
IAM Vulnerable Cleanup Script (Python Version)

This script cleans up all resources created by the iam-vulnerable Terraform project.
It's designed for cases where the Terraform state is lost and 'terraform destroy' cannot be used.

Usage:
    python3 cleanup_iam_vulnerable.py [--profile PROFILE_NAME] [--dry-run] [--yes]

Requirements:
    - boto3 (pip install boto3)
    - AWS credentials configured (via profile, environment variables, or IAM role)
"""

import boto3
import sys
import argparse
import json
from botocore.exceptions import ClientError, NoCredentialsError
from typing import List, Dict, Any

class IAMVulnerableCleanup:
    def __init__(self, profile_name: str = None, dry_run: bool = False):
        """Initialize the cleanup script with AWS session."""
        try:
            if profile_name:
                self.session = boto3.Session(profile_name=profile_name)
            else:
                self.session = boto3.Session()
            
            self.iam = self.session.client('iam')
            self.lambda_client = self.session.client('lambda')
            self.cloudformation = self.session.client('cloudformation')
            self.glue = self.session.client('glue')
            self.sagemaker = self.session.client('sagemaker')
            self.sts = self.session.client('sts')
            
            self.dry_run = dry_run
            self.account_id = None
            
        except NoCredentialsError:
            print("❌ Error: AWS credentials not found. Please configure your credentials.")
            sys.exit(1)
        except Exception as e:
            print(f"❌ Error initializing AWS session: {e}")
            sys.exit(1)

    def get_account_info(self) -> Dict[str, str]:
        """Get AWS account information."""
        try:
            identity = self.sts.get_caller_identity()
            self.account_id = identity['Account']
            return {
                'account_id': identity['Account'],
                'user_id': identity['UserId'],
                'arn': identity['Arn']
            }
        except ClientError as e:
            print(f"❌ Error getting account information: {e}")
            sys.exit(1)

    def find_iam_vulnerable_resources(self) -> Dict[str, List[Dict[str, Any]]]:
        """Find all IAM resources created by iam-vulnerable."""
        resources = {
            'users': [],
            'roles': [],
            'groups': [],
            'policies': [],
            'access_keys': [],
            'instance_profiles': [],
            'lambda_functions': [],
            'cloudformation_stacks': [],
            'glue_dev_endpoints': [],
            'sagemaker_notebooks': []
        }

        # Define prefixes and patterns used by iam-vulnerable
        iam_prefixes = [
            'privesc', 'fn1-', 'fn2-', 'fn3-', 'fn4-', 'fp1-', 'fp2-', 'fp3-', 'fp4-', 'fp5-',
            'Ryan'  # Special admin user
        ]

        print("🔍 Scanning for IAM Vulnerable resources...")

        # Find IAM Users
        try:
            paginator = self.iam.get_paginator('list_users')
            for page in paginator.paginate():
                for user in page['Users']:
                    user_name = user['UserName']
                    if any(user_name.startswith(prefix) for prefix in iam_prefixes):
                        resources['users'].append(user)
                        
                        # Find access keys for this user
                        try:
                            keys_response = self.iam.list_access_keys(UserName=user_name)
                            for key in keys_response['AccessKeyMetadata']:
                                resources['access_keys'].append({
                                    'AccessKeyId': key['AccessKeyId'],
                                    'UserName': user_name,
                                    'Status': key['Status']
                                })
                        except ClientError:
                            pass
        except ClientError as e:
            print(f"⚠️  Warning: Could not list users: {e}")

        # Find IAM Roles
        try:
            paginator = self.iam.get_paginator('list_roles')
            for page in paginator.paginate():
                for role in page['Roles']:
                    role_name = role['RoleName']
                    if any(role_name.startswith(prefix) for prefix in iam_prefixes):
                        resources['roles'].append(role)
        except ClientError as e:
            print(f"⚠️  Warning: Could not list roles: {e}")

        # Find IAM Groups
        try:
            paginator = self.iam.get_paginator('list_groups')
            for page in paginator.paginate():
                for group in page['Groups']:
                    group_name = group['GroupName']
                    if any(group_name.startswith(prefix) for prefix in iam_prefixes):
                        resources['groups'].append(group)
        except ClientError as e:
            print(f"⚠️  Warning: Could not list groups: {e}")

        # Find IAM Policies
        try:
            paginator = self.iam.get_paginator('list_policies')
            for page in paginator.paginate(Scope='Local'):  # Only customer-managed policies
                for policy in page['Policies']:
                    policy_name = policy['PolicyName']
                    if any(policy_name.startswith(prefix) for prefix in iam_prefixes):
                        resources['policies'].append(policy)
        except ClientError as e:
            print(f"⚠️  Warning: Could not list policies: {e}")

        # Find Instance Profiles
        try:
            paginator = self.iam.get_paginator('list_instance_profiles')
            for page in paginator.paginate():
                for profile in page['InstanceProfiles']:
                    profile_name = profile['InstanceProfileName']
                    if any(profile_name.startswith(prefix) for prefix in iam_prefixes):
                        resources['instance_profiles'].append(profile)
        except ClientError as e:
            print(f"⚠️  Warning: Could not list instance profiles: {e}")

        # Find Lambda Functions
        try:
            paginator = self.lambda_client.get_paginator('list_functions')
            for page in paginator.paginate():
                for function in page['Functions']:
                    function_name = function['FunctionName']
                    if function_name == 'test_lambda' or any(function_name.startswith(prefix) for prefix in iam_prefixes):
                        resources['lambda_functions'].append(function)
        except ClientError as e:
            print(f"⚠️  Warning: Could not list Lambda functions: {e}")

        # Find CloudFormation Stacks
        try:
            paginator = self.cloudformation.get_paginator('list_stacks')
            for page in paginator.paginate(StackStatusFilter=['CREATE_COMPLETE', 'UPDATE_COMPLETE', 'UPDATE_ROLLBACK_COMPLETE']):
                for stack in page['StackSummaries']:
                    stack_name = stack['StackName']
                    if stack_name == 'privesc-cloudformationStack' or any(stack_name.startswith(prefix) for prefix in iam_prefixes):
                        resources['cloudformation_stacks'].append(stack)
        except ClientError as e:
            print(f"⚠️  Warning: Could not list CloudFormation stacks: {e}")

        # Find Glue Dev Endpoints
        try:
            response = self.glue.get_dev_endpoints()
            for endpoint in response['DevEndpoints']:
                endpoint_name = endpoint['EndpointName']
                if endpoint_name == 'privesc-glue-devendpoint' or any(endpoint_name.startswith(prefix) for prefix in iam_prefixes):
                    resources['glue_dev_endpoints'].append(endpoint)
        except ClientError as e:
            print(f"⚠️  Warning: Could not list Glue dev endpoints: {e}")

        # Find SageMaker Notebook Instances
        try:
            paginator = self.sagemaker.get_paginator('list_notebook_instances')
            for page in paginator.paginate():
                for notebook in page['NotebookInstances']:
                    notebook_name = notebook['NotebookInstanceName']
                    if notebook_name == 'privesc-sagemakerNotebook' or any(notebook_name.startswith(prefix) for prefix in iam_prefixes):
                        resources['sagemaker_notebooks'].append(notebook)
        except ClientError as e:
            print(f"⚠️  Warning: Could not list SageMaker notebooks: {e}")

        return resources

    def display_resources(self, resources: Dict[str, List[Dict[str, Any]]]) -> int:
        """Display all found resources and return total count."""
        total_count = 0
        
        print("\n" + "="*60)
        print("📋 IAM VULNERABLE RESOURCES FOUND")
        print("="*60)

        for resource_type, items in resources.items():
            if items:
                count = len(items)
                total_count += count
                print(f"\n🔸 {resource_type.upper().replace('_', ' ')} ({count}):")
                
                for item in items:
                    if resource_type == 'users':
                        print(f"   • {item['UserName']} (Created: {item['CreateDate'].strftime('%Y-%m-%d %H:%M:%S')})")
                    elif resource_type == 'roles':
                        print(f"   • {item['RoleName']} (Created: {item['CreateDate'].strftime('%Y-%m-%d %H:%M:%S')})")
                    elif resource_type == 'groups':
                        print(f"   • {item['GroupName']} (Created: {item['CreateDate'].strftime('%Y-%m-%d %H:%M:%S')})")
                    elif resource_type == 'policies':
                        print(f"   • {item['PolicyName']} (ARN: {item['Arn']})")
                    elif resource_type == 'access_keys':
                        print(f"   • {item['AccessKeyId']} (User: {item['UserName']}, Status: {item['Status']})")
                    elif resource_type == 'instance_profiles':
                        print(f"   • {item['InstanceProfileName']} (Created: {item['CreateDate'].strftime('%Y-%m-%d %H:%M:%S')})")
                    elif resource_type == 'lambda_functions':
                        print(f"   • {item['FunctionName']} (Runtime: {item['Runtime']})")
                    elif resource_type == 'cloudformation_stacks':
                        print(f"   • {item['StackName']} (Status: {item['StackStatus']})")
                    elif resource_type == 'glue_dev_endpoints':
                        print(f"   • {item['EndpointName']} (Status: {item.get('Status', 'Unknown')})")
                    elif resource_type == 'sagemaker_notebooks':
                        print(f"   • {item['NotebookInstanceName']} (Status: {item['NotebookInstanceStatus']})")

        print(f"\n📊 TOTAL RESOURCES: {total_count}")
        return total_count

    def delete_resources(self, resources: Dict[str, List[Dict[str, Any]]]) -> None:
        """Delete all found resources in the correct order."""
        if self.dry_run:
            print("\n🔍 DRY RUN MODE - No resources will be deleted")
            return

        print("\n🗑️  Starting resource deletion...")
        
        # Deletion order is important to avoid dependency conflicts
        deletion_order = [
            ('access_keys', self._delete_access_keys),
            ('sagemaker_notebooks', self._delete_sagemaker_notebooks),
            ('glue_dev_endpoints', self._delete_glue_dev_endpoints),
            ('lambda_functions', self._delete_lambda_functions),
            ('cloudformation_stacks', self._delete_cloudformation_stacks),
            ('instance_profiles', self._delete_instance_profiles),
            ('users', self._delete_users),
            ('groups', self._delete_groups),
            ('roles', self._delete_roles),
            ('policies', self._delete_policies)
        ]

        for resource_type, delete_func in deletion_order:
            if resources[resource_type]:
                print(f"\n🔸 Deleting {resource_type.replace('_', ' ')}...")
                delete_func(resources[resource_type])

    def _delete_access_keys(self, access_keys: List[Dict[str, Any]]) -> None:
        """Delete IAM access keys."""
        for key in access_keys:
            try:
                self.iam.delete_access_key(
                    UserName=key['UserName'],
                    AccessKeyId=key['AccessKeyId']
                )
                print(f"   ✅ Deleted access key: {key['AccessKeyId']} (User: {key['UserName']})")
            except ClientError as e:
                print(f"   ❌ Failed to delete access key {key['AccessKeyId']}: {e}")

    def _delete_users(self, users: List[Dict[str, Any]]) -> None:
        """Delete IAM users and their attached policies."""
        for user in users:
            user_name = user['UserName']
            try:
                # Detach user policies
                try:
                    attached_policies = self.iam.list_attached_user_policies(UserName=user_name)
                    for policy in attached_policies['AttachedPolicies']:
                        self.iam.detach_user_policy(UserName=user_name, PolicyArn=policy['PolicyArn'])
                        print(f"   🔗 Detached policy {policy['PolicyName']} from user {user_name}")
                except ClientError:
                    pass

                # Delete inline user policies
                try:
                    inline_policies = self.iam.list_user_policies(UserName=user_name)
                    for policy_name in inline_policies['PolicyNames']:
                        self.iam.delete_user_policy(UserName=user_name, PolicyName=policy_name)
                        print(f"   🔗 Deleted inline policy {policy_name} from user {user_name}")
                except ClientError:
                    pass

                # Remove user from groups
                try:
                    groups = self.iam.list_groups_for_user(UserName=user_name)
                    for group in groups['Groups']:
                        self.iam.remove_user_from_group(UserName=user_name, GroupName=group['GroupName'])
                        print(f"   👥 Removed user {user_name} from group {group['GroupName']}")
                except ClientError:
                    pass

                # Delete login profile if exists
                try:
                    self.iam.delete_login_profile(UserName=user_name)
                    print(f"   🔑 Deleted login profile for user {user_name}")
                except ClientError:
                    pass

                # Delete the user
                self.iam.delete_user(UserName=user_name)
                print(f"   ✅ Deleted user: {user_name}")
            except ClientError as e:
                print(f"   ❌ Failed to delete user {user_name}: {e}")

    def _delete_groups(self, groups: List[Dict[str, Any]]) -> None:
        """Delete IAM groups and their attached policies."""
        for group in groups:
            group_name = group['GroupName']
            try:
                # Detach group policies
                try:
                    attached_policies = self.iam.list_attached_group_policies(GroupName=group_name)
                    for policy in attached_policies['AttachedPolicies']:
                        self.iam.detach_group_policy(GroupName=group_name, PolicyArn=policy['PolicyArn'])
                        print(f"   🔗 Detached policy {policy['PolicyName']} from group {group_name}")
                except ClientError:
                    pass

                # Delete inline group policies
                try:
                    inline_policies = self.iam.list_group_policies(GroupName=group_name)
                    for policy_name in inline_policies['PolicyNames']:
                        self.iam.delete_group_policy(GroupName=group_name, PolicyName=policy_name)
                        print(f"   🔗 Deleted inline policy {policy_name} from group {group_name}")
                except ClientError:
                    pass

                # Delete the group
                self.iam.delete_group(GroupName=group_name)
                print(f"   ✅ Deleted group: {group_name}")
            except ClientError as e:
                print(f"   ❌ Failed to delete group {group_name}: {e}")

    def _delete_roles(self, roles: List[Dict[str, Any]]) -> None:
        """Delete IAM roles and their attached policies."""
        for role in roles:
            role_name = role['RoleName']
            try:
                # Detach role policies
                try:
                    attached_policies = self.iam.list_attached_role_policies(RoleName=role_name)
                    for policy in attached_policies['AttachedPolicies']:
                        self.iam.detach_role_policy(RoleName=role_name, PolicyArn=policy['PolicyArn'])
                        print(f"   🔗 Detached policy {policy['PolicyName']} from role {role_name}")
                except ClientError:
                    pass

                # Delete inline role policies
                try:
                    inline_policies = self.iam.list_role_policies(RoleName=role_name)
                    for policy_name in inline_policies['PolicyNames']:
                        self.iam.delete_role_policy(RoleName=role_name, PolicyName=policy_name)
                        print(f"   🔗 Deleted inline policy {policy_name} from role {role_name}")
                except ClientError:
                    pass

                # Delete the role
                self.iam.delete_role(RoleName=role_name)
                print(f"   ✅ Deleted role: {role_name}")
            except ClientError as e:
                print(f"   ❌ Failed to delete role {role_name}: {e}")

    def _delete_policies(self, policies: List[Dict[str, Any]]) -> None:
        """Delete IAM policies."""
        for policy in policies:
            try:
                # Delete all policy versions except the default
                versions = self.iam.list_policy_versions(PolicyArn=policy['Arn'])
                for version in versions['Versions']:
                    if not version['IsDefaultVersion']:
                        self.iam.delete_policy_version(
                            PolicyArn=policy['Arn'],
                            VersionId=version['VersionId']
                        )
                        print(f"   📄 Deleted policy version {version['VersionId']} for {policy['PolicyName']}")

                # Delete the policy
                self.iam.delete_policy(PolicyArn=policy['Arn'])
                print(f"   ✅ Deleted policy: {policy['PolicyName']}")
            except ClientError as e:
                print(f"   ❌ Failed to delete policy {policy['PolicyName']}: {e}")

    def _delete_instance_profiles(self, profiles: List[Dict[str, Any]]) -> None:
        """Delete IAM instance profiles."""
        for profile in profiles:
            profile_name = profile['InstanceProfileName']
            try:
                # Remove roles from instance profile
                for role in profile['Roles']:
                    self.iam.remove_role_from_instance_profile(
                        InstanceProfileName=profile_name,
                        RoleName=role['RoleName']
                    )
                    print(f"   🔗 Removed role {role['RoleName']} from instance profile {profile_name}")

                # Delete the instance profile
                self.iam.delete_instance_profile(InstanceProfileName=profile_name)
                print(f"   ✅ Deleted instance profile: {profile_name}")
            except ClientError as e:
                print(f"   ❌ Failed to delete instance profile {profile_name}: {e}")

    def _delete_lambda_functions(self, functions: List[Dict[str, Any]]) -> None:
        """Delete Lambda functions."""
        for function in functions:
            try:
                self.lambda_client.delete_function(FunctionName=function['FunctionName'])
                print(f"   ✅ Deleted Lambda function: {function['FunctionName']}")
            except ClientError as e:
                print(f"   ❌ Failed to delete Lambda function {function['FunctionName']}: {e}")

    def _delete_cloudformation_stacks(self, stacks: List[Dict[str, Any]]) -> None:
        """Delete CloudFormation stacks."""
        for stack in stacks:
            try:
                self.cloudformation.delete_stack(StackName=stack['StackName'])
                print(f"   ✅ Initiated deletion of CloudFormation stack: {stack['StackName']}")
                print(f"   ⏳ Note: Stack deletion may take several minutes to complete")
            except ClientError as e:
                print(f"   ❌ Failed to delete CloudFormation stack {stack['StackName']}: {e}")

    def _delete_glue_dev_endpoints(self, endpoints: List[Dict[str, Any]]) -> None:
        """Delete Glue development endpoints."""
        for endpoint in endpoints:
            try:
                self.glue.delete_dev_endpoint(EndpointName=endpoint['EndpointName'])
                print(f"   ✅ Deleted Glue dev endpoint: {endpoint['EndpointName']}")
            except ClientError as e:
                print(f"   ❌ Failed to delete Glue dev endpoint {endpoint['EndpointName']}: {e}")

    def _delete_sagemaker_notebooks(self, notebooks: List[Dict[str, Any]]) -> None:
        """Delete SageMaker notebook instances."""
        for notebook in notebooks:
            try:
                # Stop the notebook if it's running
                if notebook['NotebookInstanceStatus'] == 'InService':
                    self.sagemaker.stop_notebook_instance(NotebookInstanceName=notebook['NotebookInstanceName'])
                    print(f"   ⏸️  Stopping SageMaker notebook: {notebook['NotebookInstanceName']}")
                    print(f"   ⏳ Note: Notebook must be stopped before deletion")
                
                # If already stopped, delete it
                elif notebook['NotebookInstanceStatus'] == 'Stopped':
                    self.sagemaker.delete_notebook_instance(NotebookInstanceName=notebook['NotebookInstanceName'])
                    print(f"   ✅ Deleted SageMaker notebook: {notebook['NotebookInstanceName']}")
                else:
                    print(f"   ⏳ SageMaker notebook {notebook['NotebookInstanceName']} is in {notebook['NotebookInstanceStatus']} state")
            except ClientError as e:
                print(f"   ❌ Failed to delete SageMaker notebook {notebook['NotebookInstanceName']}: {e}")

def main():
    parser = argparse.ArgumentParser(description='Clean up IAM Vulnerable resources')
    parser.add_argument('--profile', help='AWS profile to use')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be deleted without actually deleting')
    parser.add_argument('--yes', action='store_true', help='Skip confirmation prompt')
    
    args = parser.parse_args()

    print("🧹 IAM Vulnerable Cleanup Script")
    print("=" * 40)

    # Initialize cleanup
    cleanup = IAMVulnerableCleanup(profile_name=args.profile, dry_run=args.dry_run)
    
    # Get account information
    account_info = cleanup.get_account_info()
    print(f"🏢 AWS Account: {account_info['account_id']}")
    print(f"👤 Current Identity: {account_info['arn']}")
    
    # Find resources
    resources = cleanup.find_iam_vulnerable_resources()
    total_count = cleanup.display_resources(resources)
    
    if total_count == 0:
        print("\n✅ No IAM Vulnerable resources found!")
        return

    # Confirmation
    if not args.yes and not args.dry_run:
        print(f"\n⚠️  WARNING: This will delete {total_count} resources!")
        print("This action cannot be undone.")
        response = input("\nDo you want to continue? (type 'yes' to confirm): ")
        if response.lower() != 'yes':
            print("❌ Operation cancelled.")
            return

    # Delete resources
    cleanup.delete_resources(resources)
    
    if args.dry_run:
        print(f"\n🔍 DRY RUN COMPLETE: Found {total_count} resources that would be deleted")
    else:
        print(f"\n✅ CLEANUP COMPLETE: Processed {total_count} resources")
        print("Note: Some resources (like CloudFormation stacks) may take additional time to fully delete.")

if __name__ == '__main__':
    main()
