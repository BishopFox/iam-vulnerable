#!/bin/bash

# IAM Vulnerable Cleanup Script (Bash Version)
#
# This script cleans up all resources created by the iam-vulnerable Terraform project.
# It's designed for cases where the Terraform state is lost and 'terraform destroy' cannot be used.
#
# Usage:
#     ./cleanup_iam_vulnerable.sh [--profile PROFILE_NAME] [--dry-run] [--yes]
#
# Requirements:
#     - AWS CLI v2 (configured with appropriate credentials)
#     - jq (for JSON parsing)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
AWS_PROFILE=""
DRY_RUN=false
SKIP_CONFIRMATION=false
ACCOUNT_ID=""
TOTAL_RESOURCES=0

# Resource arrays
declare -a USERS=()
declare -a ROLES=()
declare -a GROUPS=()
declare -a POLICIES=()
declare -a ACCESS_KEYS=()
declare -a INSTANCE_PROFILES=()
declare -a LAMBDA_FUNCTIONS=()
declare -a CLOUDFORMATION_STACKS=()
declare -a GLUE_DEV_ENDPOINTS=()
declare -a SAGEMAKER_NOTEBOOKS=()

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --profile PROFILE    AWS profile to use"
    echo "  --dry-run           Show what would be deleted without actually deleting"
    echo "  --yes               Skip confirmation prompt"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --profile my-aws-profile --dry-run"
    echo "  $0 --yes"
}

# Function to check dependencies
check_dependencies() {
    if ! command -v aws &> /dev/null; then
        print_color "$RED" "❌ Error: AWS CLI not found. Please install AWS CLI v2."
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        print_color "$RED" "❌ Error: jq not found. Please install jq for JSON parsing."
        exit 1
    fi
}

# Function to set AWS CLI options
set_aws_options() {
    if [[ -n "$AWS_PROFILE" ]]; then
        AWS_OPTS="--profile $AWS_PROFILE"
    else
        AWS_OPTS=""
    fi
}

# Function to get account information
get_account_info() {
    print_color "$BLUE" "🔍 Getting AWS account information..."
    
    local identity
    if ! identity=$(aws sts get-caller-identity $AWS_OPTS 2>/dev/null); then
        print_color "$RED" "❌ Error: Unable to get AWS account information. Please check your credentials."
        exit 1
    fi
    
    ACCOUNT_ID=$(echo "$identity" | jq -r '.Account')
    local user_id=$(echo "$identity" | jq -r '.UserId')
    local arn=$(echo "$identity" | jq -r '.Arn')
    
    print_color "$CYAN" "🏢 AWS Account: $ACCOUNT_ID"
    print_color "$CYAN" "👤 Current Identity: $arn"
}

# Function to check if a name matches IAM vulnerable patterns
matches_iam_vulnerable_pattern() {
    local name=$1
    local patterns=("privesc" "fn1-" "fn2-" "fn3-" "fn4-" "fp1-" "fp2-" "fp3-" "fp4-" "fp5-" "Ryan")
    
    for pattern in "${patterns[@]}"; do
        if [[ "$name" == "$pattern"* ]]; then
            return 0
        fi
    done
    return 1
}

# Function to find IAM users
find_iam_users() {
    print_color "$BLUE" "🔍 Scanning for IAM users..."
    
    local users_json
    if users_json=$(aws iam list-users $AWS_OPTS --output json 2>/dev/null); then
        while IFS= read -r user; do
            local user_name=$(echo "$user" | jq -r '.UserName')
            if matches_iam_vulnerable_pattern "$user_name"; then
                USERS+=("$user_name")
                ((TOTAL_RESOURCES++))
                
                # Find access keys for this user
                local keys_json
                if keys_json=$(aws iam list-access-keys $AWS_OPTS --user-name "$user_name" --output json 2>/dev/null); then
                    while IFS= read -r key; do
                        local access_key_id=$(echo "$key" | jq -r '.AccessKeyId')
                        local status=$(echo "$key" | jq -r '.Status')
                        ACCESS_KEYS+=("$access_key_id:$user_name:$status")
                        ((TOTAL_RESOURCES++))
                    done < <(echo "$keys_json" | jq -c '.AccessKeyMetadata[]?')
                fi
            fi
        done < <(echo "$users_json" | jq -c '.Users[]?')
    else
        print_color "$YELLOW" "⚠️  Warning: Could not list IAM users"
    fi
}

# Function to find IAM roles
find_iam_roles() {
    print_color "$BLUE" "🔍 Scanning for IAM roles..."
    
    local roles_json
    if roles_json=$(aws iam list-roles $AWS_OPTS --output json 2>/dev/null); then
        while IFS= read -r role; do
            local role_name=$(echo "$role" | jq -r '.RoleName')
            if matches_iam_vulnerable_pattern "$role_name"; then
                ROLES+=("$role_name")
                ((TOTAL_RESOURCES++))
            fi
        done < <(echo "$roles_json" | jq -c '.Roles[]?')
    else
        print_color "$YELLOW" "⚠️  Warning: Could not list IAM roles"
    fi
}

# Function to find IAM groups
find_iam_groups() {
    print_color "$BLUE" "🔍 Scanning for IAM groups..."
    
    local groups_json
    if groups_json=$(aws iam list-groups $AWS_OPTS --output json 2>/dev/null); then
        while IFS= read -r group; do
            local group_name=$(echo "$group" | jq -r '.GroupName')
            if matches_iam_vulnerable_pattern "$group_name"; then
                GROUPS+=("$group_name")
                ((TOTAL_RESOURCES++))
            fi
        done < <(echo "$groups_json" | jq -c '.Groups[]?')
    else
        print_color "$YELLOW" "⚠️  Warning: Could not list IAM groups"
    fi
}

# Function to find IAM policies
find_iam_policies() {
    print_color "$BLUE" "🔍 Scanning for IAM policies..."
    
    local policies_json
    if policies_json=$(aws iam list-policies $AWS_OPTS --scope Local --output json 2>/dev/null); then
        while IFS= read -r policy; do
            local policy_name=$(echo "$policy" | jq -r '.PolicyName')
            local policy_arn=$(echo "$policy" | jq -r '.Arn')
            if matches_iam_vulnerable_pattern "$policy_name"; then
                POLICIES+=("$policy_name:$policy_arn")
                ((TOTAL_RESOURCES++))
            fi
        done < <(echo "$policies_json" | jq -c '.Policies[]?')
    else
        print_color "$YELLOW" "⚠️  Warning: Could not list IAM policies"
    fi
}

# Function to find instance profiles
find_instance_profiles() {
    print_color "$BLUE" "🔍 Scanning for instance profiles..."
    
    local profiles_json
    if profiles_json=$(aws iam list-instance-profiles $AWS_OPTS --output json 2>/dev/null); then
        while IFS= read -r profile; do
            local profile_name=$(echo "$profile" | jq -r '.InstanceProfileName')
            if matches_iam_vulnerable_pattern "$profile_name"; then
                INSTANCE_PROFILES+=("$profile_name")
                ((TOTAL_RESOURCES++))
            fi
        done < <(echo "$profiles_json" | jq -c '.InstanceProfiles[]?')
    else
        print_color "$YELLOW" "⚠️  Warning: Could not list instance profiles"
    fi
}

# Function to find Lambda functions
find_lambda_functions() {
    print_color "$BLUE" "🔍 Scanning for Lambda functions..."
    
    local functions_json
    if functions_json=$(aws lambda list-functions $AWS_OPTS --output json 2>/dev/null); then
        while IFS= read -r function; do
            local function_name=$(echo "$function" | jq -r '.FunctionName')
            if [[ "$function_name" == "test_lambda" ]] || matches_iam_vulnerable_pattern "$function_name"; then
                LAMBDA_FUNCTIONS+=("$function_name")
                ((TOTAL_RESOURCES++))
            fi
        done < <(echo "$functions_json" | jq -c '.Functions[]?')
    else
        print_color "$YELLOW" "⚠️  Warning: Could not list Lambda functions"
    fi
}

# Function to find CloudFormation stacks
find_cloudformation_stacks() {
    print_color "$BLUE" "🔍 Scanning for CloudFormation stacks..."
    
    local stacks_json
    if stacks_json=$(aws cloudformation list-stacks $AWS_OPTS --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE UPDATE_ROLLBACK_COMPLETE --output json 2>/dev/null); then
        while IFS= read -r stack; do
            local stack_name=$(echo "$stack" | jq -r '.StackName')
            if [[ "$stack_name" == "privesc-cloudformationStack" ]] || matches_iam_vulnerable_pattern "$stack_name"; then
                CLOUDFORMATION_STACKS+=("$stack_name")
                ((TOTAL_RESOURCES++))
            fi
        done < <(echo "$stacks_json" | jq -c '.StackSummaries[]?')
    else
        print_color "$YELLOW" "⚠️  Warning: Could not list CloudFormation stacks"
    fi
}

# Function to find Glue dev endpoints
find_glue_dev_endpoints() {
    print_color "$BLUE" "🔍 Scanning for Glue dev endpoints..."
    
    local endpoints_json
    if endpoints_json=$(aws glue get-dev-endpoints $AWS_OPTS --output json 2>/dev/null); then
        while IFS= read -r endpoint; do
            local endpoint_name=$(echo "$endpoint" | jq -r '.EndpointName')
            if [[ "$endpoint_name" == "privesc-glue-devendpoint" ]] || matches_iam_vulnerable_pattern "$endpoint_name"; then
                GLUE_DEV_ENDPOINTS+=("$endpoint_name")
                ((TOTAL_RESOURCES++))
            fi
        done < <(echo "$endpoints_json" | jq -c '.DevEndpoints[]?')
    else
        print_color "$YELLOW" "⚠️  Warning: Could not list Glue dev endpoints"
    fi
}

# Function to find SageMaker notebook instances
find_sagemaker_notebooks() {
    print_color "$BLUE" "🔍 Scanning for SageMaker notebook instances..."
    
    local notebooks_json
    if notebooks_json=$(aws sagemaker list-notebook-instances $AWS_OPTS --output json 2>/dev/null); then
        while IFS= read -r notebook; do
            local notebook_name=$(echo "$notebook" | jq -r '.NotebookInstanceName')
            if [[ "$notebook_name" == "privesc-sagemakerNotebook" ]] || matches_iam_vulnerable_pattern "$notebook_name"; then
                local status=$(echo "$notebook" | jq -r '.NotebookInstanceStatus')
                SAGEMAKER_NOTEBOOKS+=("$notebook_name:$status")
                ((TOTAL_RESOURCES++))
            fi
        done < <(echo "$notebooks_json" | jq -c '.NotebookInstances[]?')
    else
        print_color "$YELLOW" "⚠️  Warning: Could not list SageMaker notebook instances"
    fi
}

# Function to display all found resources
display_resources() {
    echo ""
    print_color "$CYAN" "$(printf '=%.0s' {1..60})"
    print_color "$CYAN" "📋 IAM VULNERABLE RESOURCES FOUND"
    print_color "$CYAN" "$(printf '=%.0s' {1..60})"
    
    if [[ ${#ACCESS_KEYS[@]} -gt 0 ]]; then
        echo ""
        print_color "$BLUE" "🔸 ACCESS KEYS (${#ACCESS_KEYS[@]}):"
        for key in "${ACCESS_KEYS[@]}"; do
            IFS=':' read -r access_key_id user_name status <<< "$key"
            echo "   • $access_key_id (User: $user_name, Status: $status)"
        done
    fi
    
    if [[ ${#USERS[@]} -gt 0 ]]; then
        echo ""
        print_color "$BLUE" "🔸 USERS (${#USERS[@]}):"
        for user in "${USERS[@]}"; do
            echo "   • $user"
        done
    fi
    
    if [[ ${#GROUPS[@]} -gt 0 ]]; then
        echo ""
        print_color "$BLUE" "🔸 GROUPS (${#GROUPS[@]}):"
        for group in "${GROUPS[@]}"; do
            echo "   • $group"
        done
    fi
    
    if [[ ${#ROLES[@]} -gt 0 ]]; then
        echo ""
        print_color "$BLUE" "🔸 ROLES (${#ROLES[@]}):"
        for role in "${ROLES[@]}"; do
            echo "   • $role"
        done
    fi
    
    if [[ ${#POLICIES[@]} -gt 0 ]]; then
        echo ""
        print_color "$BLUE" "🔸 POLICIES (${#POLICIES[@]}):"
        for policy in "${POLICIES[@]}"; do
            IFS=':' read -r policy_name policy_arn <<< "$policy"
            echo "   • $policy_name (ARN: $policy_arn)"
        done
    fi
    
    if [[ ${#INSTANCE_PROFILES[@]} -gt 0 ]]; then
        echo ""
        print_color "$BLUE" "🔸 INSTANCE PROFILES (${#INSTANCE_PROFILES[@]}):"
        for profile in "${INSTANCE_PROFILES[@]}"; do
            echo "   • $profile"
        done
    fi
    
    if [[ ${#LAMBDA_FUNCTIONS[@]} -gt 0 ]]; then
        echo ""
        print_color "$BLUE" "🔸 LAMBDA FUNCTIONS (${#LAMBDA_FUNCTIONS[@]}):"
        for function in "${LAMBDA_FUNCTIONS[@]}"; do
            echo "   • $function"
        done
    fi
    
    if [[ ${#CLOUDFORMATION_STACKS[@]} -gt 0 ]]; then
        echo ""
        print_color "$BLUE" "🔸 CLOUDFORMATION STACKS (${#CLOUDFORMATION_STACKS[@]}):"
        for stack in "${CLOUDFORMATION_STACKS[@]}"; do
            echo "   • $stack"
        done
    fi
    
    if [[ ${#GLUE_DEV_ENDPOINTS[@]} -gt 0 ]]; then
        echo ""
        print_color "$BLUE" "🔸 GLUE DEV ENDPOINTS (${#GLUE_DEV_ENDPOINTS[@]}):"
        for endpoint in "${GLUE_DEV_ENDPOINTS[@]}"; do
            echo "   • $endpoint"
        done
    fi
    
    if [[ ${#SAGEMAKER_NOTEBOOKS[@]} -gt 0 ]]; then
        echo ""
        print_color "$BLUE" "🔸 SAGEMAKER NOTEBOOKS (${#SAGEMAKER_NOTEBOOKS[@]}):"
        for notebook in "${SAGEMAKER_NOTEBOOKS[@]}"; do
            IFS=':' read -r notebook_name status <<< "$notebook"
            echo "   • $notebook_name (Status: $status)"
        done
    fi
    
    echo ""
    print_color "$CYAN" "📊 TOTAL RESOURCES: $TOTAL_RESOURCES"
}

# Function to delete access keys
delete_access_keys() {
    if [[ ${#ACCESS_KEYS[@]} -eq 0 ]]; then
        return
    fi
    
    echo ""
    print_color "$BLUE" "🔸 Deleting access keys..."
    
    for key in "${ACCESS_KEYS[@]}"; do
        IFS=':' read -r access_key_id user_name status <<< "$key"
        
        if [[ "$DRY_RUN" == true ]]; then
            echo "   [DRY RUN] Would delete access key: $access_key_id (User: $user_name)"
        else
            if aws iam delete-access-key $AWS_OPTS --user-name "$user_name" --access-key-id "$access_key_id" 2>/dev/null; then
                print_color "$GREEN" "   ✅ Deleted access key: $access_key_id (User: $user_name)"
            else
                print_color "$RED" "   ❌ Failed to delete access key: $access_key_id"
            fi
        fi
    done
}

# Function to delete users
delete_users() {
    if [[ ${#USERS[@]} -eq 0 ]]; then
        return
    fi
    
    echo ""
    print_color "$BLUE" "🔸 Deleting users..."
    
    for user in "${USERS[@]}"; do
        if [[ "$DRY_RUN" == true ]]; then
            echo "   [DRY RUN] Would delete user: $user"
            continue
        fi
        
        # Detach user policies
        local attached_policies
        if attached_policies=$(aws iam list-attached-user-policies $AWS_OPTS --user-name "$user" --output json 2>/dev/null); then
            while IFS= read -r policy; do
                local policy_arn=$(echo "$policy" | jq -r '.PolicyArn')
                local policy_name=$(echo "$policy" | jq -r '.PolicyName')
                if aws iam detach-user-policy $AWS_OPTS --user-name "$user" --policy-arn "$policy_arn" 2>/dev/null; then
                    echo "   🔗 Detached policy $policy_name from user $user"
                fi
            done < <(echo "$attached_policies" | jq -c '.AttachedPolicies[]?')
        fi
        
        # Delete inline user policies
        local inline_policies
        if inline_policies=$(aws iam list-user-policies $AWS_OPTS --user-name "$user" --output json 2>/dev/null); then
            while IFS= read -r policy_name; do
                if aws iam delete-user-policy $AWS_OPTS --user-name "$user" --policy-name "$policy_name" 2>/dev/null; then
                    echo "   🔗 Deleted inline policy $policy_name from user $user"
                fi
            done < <(echo "$inline_policies" | jq -r '.PolicyNames[]?')
        fi
        
        # Remove user from groups
        local groups
        if groups=$(aws iam get-groups-for-user $AWS_OPTS --user-name "$user" --output json 2>/dev/null); then
            while IFS= read -r group; do
                local group_name=$(echo "$group" | jq -r '.GroupName')
                if aws iam remove-user-from-group $AWS_OPTS --user-name "$user" --group-name "$group_name" 2>/dev/null; then
                    echo "   👥 Removed user $user from group $group_name"
                fi
            done < <(echo "$groups" | jq -c '.Groups[]?')
        fi
        
        # Delete login profile if exists
        if aws iam delete-login-profile $AWS_OPTS --user-name "$user" 2>/dev/null; then
            echo "   🔑 Deleted login profile for user $user"
        fi
        
        # Delete the user
        if aws iam delete-user $AWS_OPTS --user-name "$user" 2>/dev/null; then
            print_color "$GREEN" "   ✅ Deleted user: $user"
        else
            print_color "$RED" "   ❌ Failed to delete user: $user"
        fi
    done
}

# Function to delete groups
delete_groups() {
    if [[ ${#GROUPS[@]} -eq 0 ]]; then
        return
    fi
    
    echo ""
    print_color "$BLUE" "🔸 Deleting groups..."
    
    for group in "${GROUPS[@]}"; do
        if [[ "$DRY_RUN" == true ]]; then
            echo "   [DRY RUN] Would delete group: $group"
            continue
        fi
        
        # Detach group policies
        local attached_policies
        if attached_policies=$(aws iam list-attached-group-policies $AWS_OPTS --group-name "$group" --output json 2>/dev/null); then
            while IFS= read -r policy; do
                local policy_arn=$(echo "$policy" | jq -r '.PolicyArn')
                local policy_name=$(echo "$policy" | jq -r '.PolicyName')
                if aws iam detach-group-policy $AWS_OPTS --group-name "$group" --policy-arn "$policy_arn" 2>/dev/null; then
                    echo "   🔗 Detached policy $policy_name from group $group"
                fi
            done < <(echo "$attached_policies" | jq -c '.AttachedPolicies[]?')
        fi
        
        # Delete inline group policies
        local inline_policies
        if inline_policies=$(aws iam list-group-policies $AWS_OPTS --group-name "$group" --output json 2>/dev/null); then
            while IFS= read -r policy_name; do
                if aws iam delete-group-policy $AWS_OPTS --group-name "$group" --policy-name "$policy_name" 2>/dev/null; then
                    echo "   🔗 Deleted inline policy $policy_name from group $group"
                fi
            done < <(echo "$inline_policies" | jq -r '.PolicyNames[]?')
        fi
        
        # Delete the group
        if aws iam delete-group $AWS_OPTS --group-name "$group" 2>/dev/null; then
            print_color "$GREEN" "   ✅ Deleted group: $group"
        else
            print_color "$RED" "   ❌ Failed to delete group: $group"
        fi
    done
}

# Function to delete roles
delete_roles() {
    if [[ ${#ROLES[@]} -eq 0 ]]; then
        return
    fi
    
    echo ""
    print_color "$BLUE" "🔸 Deleting roles..."
    
    for role in "${ROLES[@]}"; do
        if [[ "$DRY_RUN" == true ]]; then
            echo "   [DRY RUN] Would delete role: $role"
            continue
        fi
        
        # Detach role policies
        local attached_policies
        if attached_policies=$(aws iam list-attached-role-policies $AWS_OPTS --role-name "$role" --output json 2>/dev/null); then
            while IFS= read -r policy; do
                local policy_arn=$(echo "$policy" | jq -r '.PolicyArn')
                local policy_name=$(echo "$policy" | jq -r '.PolicyName')
                if aws iam detach-role-policy $AWS_OPTS --role-name "$role" --policy-arn "$policy_arn" 2>/dev/null; then
                    echo "   🔗 Detached policy $policy_name from role $role"
                fi
            done < <(echo "$attached_policies" | jq -c '.AttachedPolicies[]?')
        fi
        
        # Delete inline role policies
        local inline_policies
        if inline_policies=$(aws iam list-role-policies $AWS_OPTS --role-name "$role" --output json 2>/dev/null); then
            while IFS= read -r policy_name; do
                if aws iam delete-role-policy $AWS_OPTS --role-name "$role" --policy-name "$policy_name" 2>/dev/null; then
                    echo "   🔗 Deleted inline policy $policy_name from role $role"
                fi
            done < <(echo "$inline_policies" | jq -r '.PolicyNames[]?')
        fi
        
        # Delete the role
        if aws iam delete-role $AWS_OPTS --role-name "$role" 2>/dev/null; then
            print_color "$GREEN" "   ✅ Deleted role: $role"
        else
            print_color "$RED" "   ❌ Failed to delete role: $role"
        fi
    done
}

# Function to delete policies
delete_policies() {
    if [[ ${#POLICIES[@]} -eq 0 ]]; then
        return
    fi
    
    echo ""
    print_color "$BLUE" "🔸 Deleting policies..."
    
    for policy in "${POLICIES[@]}"; do
        IFS=':' read -r policy_name policy_arn <<< "$policy"
        
        if [[ "$DRY_RUN" == true ]]; then
            echo "   [DRY RUN] Would delete policy: $policy_name"
            continue
        fi
        
        # Delete all policy versions except the default
        local versions
        if versions=$(aws iam list-policy-versions $AWS_OPTS --policy-arn "$policy_arn" --output json 2>/dev/null); then
            while IFS= read -r version; do
                local version_id=$(echo "$version" | jq -r '.VersionId')
                local is_default=$(echo "$version" | jq -r '.IsDefaultVersion')
                if [[ "$is_default" != "true" ]]; then
                    if aws iam delete-policy-version $AWS_OPTS --policy-arn "$policy_arn" --version-id "$version_id" 2>/dev/null; then
                        echo "   📄 Deleted policy version $version_id for $policy_name"
                    fi
                fi
            done < <(echo "$versions" | jq -c '.Versions[]?')
        fi
        
        # Delete the policy
        if aws iam delete-policy $AWS_OPTS --policy-arn "$policy_arn" 2>/dev/null; then
            print_color "$GREEN" "   ✅ Deleted policy: $policy_name"
        else
            print_color "$RED" "   ❌ Failed to delete policy: $policy_name"
        fi
    done
}

# Function to delete instance profiles
delete_instance_profiles() {
    if [[ ${#INSTANCE_PROFILES[@]} -eq 0 ]]; then
        return
    fi
    
    echo ""
    print_color "$BLUE" "🔸 Deleting instance profiles..."
    
    for profile in "${INSTANCE_PROFILES[@]}"; do
        if [[ "$DRY_RUN" == true ]]; then
            echo "   [DRY RUN] Would delete instance profile: $profile"
            continue
        fi
        
        # Remove roles from instance profile
        local profile_info
        if profile_info=$(aws iam get-instance-profile $AWS_OPTS --instance-profile-name "$profile" --output json 2>/dev/null); then
            while IFS= read -r role; do
                local role_name=$(echo "$role" | jq -r '.RoleName')
                if aws iam remove-role-from-instance-profile $AWS_OPTS --instance-profile-name "$profile" --role-name "$role_name" 2>/dev/null; then
                    echo "   🔗 Removed role $role_name from instance profile $profile"
                fi
            done < <(echo "$profile_info" | jq -c '.InstanceProfile.Roles[]?')
        fi
        
        # Delete the instance profile
        if aws iam delete-instance-profile $AWS_OPTS --instance-profile-name "$profile" 2>/dev/null; then
            print_color "$GREEN" "   ✅ Deleted instance profile: $profile"
        else
            print_color "$RED" "   ❌ Failed to delete instance profile: $profile"
        fi
    done
}

# Function to delete Lambda functions
delete_lambda_functions() {
    if [[ ${#LAMBDA_FUNCTIONS[@]} -eq 0 ]]; then
        return
    fi
    
    echo ""
    print_color "$BLUE" "🔸 Deleting Lambda functions..."
    
    for function in "${LAMBDA_FUNCTIONS[@]}"; do
        if [[ "$DRY_RUN" == true ]]; then
            echo "   [DRY RUN] Would delete Lambda function: $function"
        else
            if aws lambda delete-function $AWS_OPTS --function-name "$function" 2>/dev/null; then
                print_color "$GREEN" "   ✅ Deleted Lambda function: $function"
            else
                print_color "$RED" "   ❌ Failed to delete Lambda function: $function"
            fi
        fi
    done
}

# Function to delete CloudFormation stacks
delete_cloudformation_stacks() {
    if [[ ${#CLOUDFORMATION_STACKS[@]} -eq 0 ]]; then
        return
    fi
    
    echo ""
    print_color "$BLUE" "🔸 Deleting CloudFormation stacks..."
    
    for stack in "${CLOUDFORMATION_STACKS[@]}"; do
        if [[ "$DRY_RUN" == true ]]; then
            echo "   [DRY RUN] Would delete CloudFormation stack: $stack"
        else
            if aws cloudformation delete-stack $AWS_OPTS --stack-name "$stack" 2>/dev/null; then
                print_color "$GREEN" "   ✅ Initiated deletion of CloudFormation stack: $stack"
                print_color "$YELLOW" "   ⏳ Note: Stack deletion may take several minutes to complete"
            else
                print_color "$RED" "   ❌ Failed to delete CloudFormation stack: $stack"
            fi
        fi
    done
}

# Function to delete Glue dev endpoints
delete_glue_dev_endpoints() {
    if [[ ${#GLUE_DEV_ENDPOINTS[@]} -eq 0 ]]; then
        return
    fi
    
    echo ""
    print_color "$BLUE" "🔸 Deleting Glue dev endpoints..."
    
    for endpoint in "${GLUE_DEV_ENDPOINTS[@]}"; do
        if [[ "$DRY_RUN" == true ]]; then
            echo "   [DRY RUN] Would delete Glue dev endpoint: $endpoint"
        else
            if aws glue delete-dev-endpoint $AWS_OPTS --endpoint-name "$endpoint" 2>/dev/null; then
                print_color "$GREEN" "   ✅ Deleted Glue dev endpoint: $endpoint"
            else
                print_color "$RED" "   ❌ Failed to delete Glue dev endpoint: $endpoint"
            fi
        fi
    done
}

# Function to delete SageMaker notebook instances
delete_sagemaker_notebooks() {
    if [[ ${#SAGEMAKER_NOTEBOOKS[@]} -eq 0 ]]; then
        return
    fi
    
    echo ""
    print_color "$BLUE" "🔸 Deleting SageMaker notebook instances..."
    
    for notebook in "${SAGEMAKER_NOTEBOOKS[@]}"; do
        IFS=':' read -r notebook_name status <<< "$notebook"
        
        if [[ "$DRY_RUN" == true ]]; then
            echo "   [DRY RUN] Would delete SageMaker notebook: $notebook_name"
            continue
        fi
        
        # Stop the notebook if it's running
        if [[ "$status" == "InService" ]]; then
            if aws sagemaker stop-notebook-instance $AWS_OPTS --notebook-instance-name "$notebook_name" 2>/dev/null; then
                print_color "$YELLOW" "   ⏸️  Stopping SageMaker notebook: $notebook_name"
                print_color "$YELLOW" "   ⏳ Note: Notebook must be stopped before deletion"
            fi
        elif [[ "$status" == "Stopped" ]]; then
            if aws sagemaker delete-notebook-instance $AWS_OPTS --notebook-instance-name "$notebook_name" 2>/dev/null; then
                print_color "$GREEN" "   ✅ Deleted SageMaker notebook: $notebook_name"
            else
                print_color "$RED" "   ❌ Failed to delete SageMaker notebook: $notebook_name"
            fi
        else
            print_color "$YELLOW" "   ⏳ SageMaker notebook $notebook_name is in $status state"
        fi
    done
}

# Function to delete all resources
delete_resources() {
    if [[ "$DRY_RUN" == true ]]; then
        print_color "$BLUE" "\n🔍 DRY RUN MODE - No resources will be deleted"
        return
    fi
    
    print_color "$BLUE" "\n🗑️  Starting resource deletion..."
    
    # Deletion order is important to avoid dependency conflicts
    delete_access_keys
    delete_sagemaker_notebooks
    delete_glue_dev_endpoints
    delete_lambda_functions
    delete_cloudformation_stacks
    delete_instance_profiles
    delete_users
    delete_groups
    delete_roles
    delete_policies
}

# Function to find all resources
find_all_resources() {
    find_iam_users
    find_iam_roles
    find_iam_groups
    find_iam_policies
    find_instance_profiles
    find_lambda_functions
    find_cloudformation_stacks
    find_glue_dev_endpoints
    find_sagemaker_notebooks
}

# Main function
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --profile)
                AWS_PROFILE="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --yes)
                SKIP_CONFIRMATION=true
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                print_color "$RED" "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    print_color "$CYAN" "🧹 IAM Vulnerable Cleanup Script"
    print_color "$CYAN" "$(printf '=%.0s' {1..40})"
    
    # Check dependencies
    check_dependencies
    
    # Set AWS options
    set_aws_options
    
    # Get account information
    get_account_info
    
    # Find all resources
    find_all_resources
    
    # Display resources
    display_resources
    
    if [[ $TOTAL_RESOURCES -eq 0 ]]; then
        print_color "$GREEN" "\n✅ No IAM Vulnerable resources found!"
        exit 0
    fi
    
    # Confirmation
    if [[ "$SKIP_CONFIRMATION" == false ]] && [[ "$DRY_RUN" == false ]]; then
        echo ""
        print_color "$YELLOW" "⚠️  WARNING: This will delete $TOTAL_RESOURCES resources!"
        print_color "$YELLOW" "This action cannot be undone."
        echo ""
        read -p "Do you want to continue? (type 'yes' to confirm): " response
        if [[ "$response" != "yes" ]]; then
            print_color "$RED" "❌ Operation cancelled."
            exit 0
        fi
    fi
    
    # Delete resources
    delete_resources
    
    # Final message
    if [[ "$DRY_RUN" == true ]]; then
        print_color "$BLUE" "\n🔍 DRY RUN COMPLETE: Found $TOTAL_RESOURCES resources that would be deleted"
    else
        print_color "$GREEN" "\n✅ CLEANUP COMPLETE: Processed $TOTAL_RESOURCES resources"
        print_color "$YELLOW" "Note: Some resources (like CloudFormation stacks) may take additional time to fully delete."
    fi
}

# Run main function
main "$@"
