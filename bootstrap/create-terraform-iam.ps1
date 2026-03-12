param (
    [string]$ProjectName = "portfolio",
    [string]$UserName    = "terraform-deployer"
)

$PolicyName = "$UserName-policy"
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "[1/4] Creating IAM user: $UserName" -ForegroundColor Cyan
aws iam create-user --user-name $UserName | Out-Null
Write-Host "  OK: user created"

$Policy = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VPCManagement",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpc","ec2:DeleteVpc","ec2:DescribeVpcs",
        "ec2:ModifyVpcAttribute","ec2:DescribeVpcAttribute",
        "ec2:CreateSubnet","ec2:DeleteSubnet","ec2:DescribeSubnets",
        "ec2:ModifySubnetAttribute",
        "ec2:CreateInternetGateway","ec2:DeleteInternetGateway",
        "ec2:AttachInternetGateway","ec2:DetachInternetGateway",
        "ec2:DescribeInternetGateways",
        "ec2:CreateRouteTable","ec2:DeleteRouteTable",
        "ec2:AssociateRouteTable","ec2:DisassociateRouteTable",
        "ec2:DescribeRouteTables","ec2:ReplaceRouteTableAssociation",
        "ec2:CreateRoute","ec2:DeleteRoute",
        "ec2:CreateSecurityGroup","ec2:DeleteSecurityGroup",
        "ec2:DescribeSecurityGroups","ec2:DescribeSecurityGroupRules",
        "ec2:AuthorizeSecurityGroupIngress","ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress","ec2:RevokeSecurityGroupEgress",
        "ec2:ModifySecurityGroupRules",
        "ec2:DescribeAvailabilityZones","ec2:DescribeAccountAttributes",
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateTags","ec2:DeleteTags","ec2:DescribeTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "S3Management",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket","s3:DeleteBucket",
        "s3:GetBucketLocation","s3:ListBucket","s3:ListAllMyBuckets",
        "s3:GetBucketVersioning","s3:PutBucketVersioning",
        "s3:GetBucketPublicAccessBlock","s3:PutBucketPublicAccessBlock",
        "s3:GetBucketPolicy","s3:PutBucketPolicy","s3:DeleteBucketPolicy",
        "s3:GetEncryptionConfiguration","s3:PutEncryptionConfiguration",
        "s3:GetLifecycleConfiguration","s3:PutLifecycleConfiguration",
        "s3:GetBucketTagging","s3:PutBucketTagging",
        "s3:GetBucketAcl","s3:PutBucketAcl",
        "s3:GetBucketCORS","s3:PutBucketCORS",
        "s3:PutObject","s3:GetObject","s3:DeleteObject",
        "s3:GetBucketObjectLockConfiguration"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudFrontManagement",
      "Effect": "Allow",
      "Action": [
        "cloudfront:CreateDistribution","cloudfront:UpdateDistribution",
        "cloudfront:DeleteDistribution","cloudfront:GetDistribution",
        "cloudfront:GetDistributionConfig","cloudfront:ListDistributions",
        "cloudfront:CreateInvalidation","cloudfront:GetInvalidation",
        "cloudfront:CreateOriginAccessControl",
        "cloudfront:UpdateOriginAccessControl",
        "cloudfront:DeleteOriginAccessControl",
        "cloudfront:GetOriginAccessControl",
        "cloudfront:ListOriginAccessControls",
        "cloudfront:GetCachePolicy","cloudfront:ListCachePolicies",
        "cloudfront:GetOriginRequestPolicy","cloudfront:ListOriginRequestPolicies",
        "cloudfront:TagResource","cloudfront:UntagResource",
        "cloudfront:ListTagsForResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "WAFManagement",
      "Effect": "Allow",
      "Action": [
        "wafv2:CreateWebACL","wafv2:UpdateWebACL","wafv2:DeleteWebACL",
        "wafv2:GetWebACL","wafv2:ListWebACLs",
        "wafv2:AssociateWebACL","wafv2:DisassociateWebACL",
        "wafv2:GetWebACLForResource",
        "wafv2:ListTagsForResource","wafv2:TagResource","wafv2:UntagResource",
        "wafv2:CheckCapacity",
        "wafv2:ListManagedRuleSets","wafv2:DescribeManagedRuleGroup"
      ],
      "Resource": "*"
    },
    {
      "Sid": "LambdaManagement",
      "Effect": "Allow",
      "Action": [
        "lambda:CreateFunction","lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration","lambda:DeleteFunction",
        "lambda:GetFunction","lambda:GetFunctionConfiguration",
        "lambda:GetFunctionCodeSigningConfig","lambda:ListFunctions",
        "lambda:CreateFunctionUrlConfig","lambda:UpdateFunctionUrlConfig",
        "lambda:DeleteFunctionUrlConfig","lambda:GetFunctionUrlConfig",
        "lambda:AddPermission","lambda:RemovePermission","lambda:GetPolicy",
        "lambda:TagResource","lambda:UntagResource","lambda:ListTags",
        "lambda:PublishVersion","lambda:GetFunctionEventInvokeConfig"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMForCICDUser",
      "Effect": "Allow",
      "Action": [
        "iam:CreateUser","iam:DeleteUser","iam:GetUser",
        "iam:CreateAccessKey","iam:DeleteAccessKey","iam:ListAccessKeys",
        "iam:PutUserPolicy","iam:DeleteUserPolicy","iam:GetUserPolicy",
        "iam:ListUserPolicies",
        "iam:AttachUserPolicy","iam:DetachUserPolicy","iam:ListAttachedUserPolicies",
        "iam:TagUser","iam:UntagUser","iam:ListUserTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMForLambdaRole",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole","iam:DeleteRole","iam:GetRole",
        "iam:UpdateRole","iam:UpdateAssumeRolePolicy",
        "iam:PutRolePolicy","iam:DeleteRolePolicy","iam:GetRolePolicy",
        "iam:AttachRolePolicy","iam:DetachRolePolicy",
        "iam:ListRolePolicies","iam:ListAttachedRolePolicies",
        "iam:TagRole","iam:UntagRole","iam:ListRoleTags",
        "iam:PassRole"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchLogs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup","logs:DeleteLogGroup",
        "logs:PutRetentionPolicy","logs:DeleteRetentionPolicy",
        "logs:DescribeLogGroups",
        "logs:ListTagsLogGroup","logs:TagLogGroup","logs:UntagLogGroup",
        "logs:ListTagsForResource","logs:TagResource","logs:UntagResource"
      ],
      "Resource": "*"
    }
  ]
}
"@

$TempFile = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".json"
[System.IO.File]::WriteAllText($TempFile, $Policy, [System.Text.Encoding]::UTF8)

Write-Host "[2/4] Attaching inline policy: $PolicyName" -ForegroundColor Cyan
aws iam put-user-policy `
    --user-name $UserName `
    --policy-name $PolicyName `
    --policy-document "file://$TempFile"
Write-Host "  OK: policy attached"

Remove-Item $TempFile -Force

Write-Host "[3/4] Creating Access Key" -ForegroundColor Cyan
$KeyOutput = aws iam create-access-key --user-name $UserName | ConvertFrom-Json
$AccessKeyId     = $KeyOutput.AccessKey.AccessKeyId
$SecretAccessKey = $KeyOutput.AccessKey.SecretAccessKey
Write-Host "  OK: access key created"

Write-Host "[4/4] Saving credentials to bootstrap\terraform.env.ps1" -ForegroundColor Cyan
$EnvPath = Join-Path $PSScriptRoot "terraform.env.ps1"
$EnvLines = @(
    "# Terraform IAM credentials -- DO NOT COMMIT THIS FILE",
    "# Load into shell: . .\bootstrap\terraform.env.ps1",
    "",
    "`$env:AWS_ACCESS_KEY_ID     = `"$AccessKeyId`"",
    "`$env:AWS_SECRET_ACCESS_KEY = `"$SecretAccessKey`"",
    "`$env:AWS_DEFAULT_REGION    = `"ap-southeast-1`""
)
[System.IO.File]::WriteAllLines($EnvPath, $EnvLines, [System.Text.Encoding]::UTF8)
Write-Host "  Saved: bootstrap\terraform.env.ps1"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  DONE! IAM user '$UserName' created." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Yellow
Write-Host "  1. Load credentials:  . .\bootstrap\terraform.env.ps1"
Write-Host "  2. Verify identity:   aws sts get-caller-identity"
Write-Host "  3. Deploy infra:      cd terraform ; terraform init ; terraform apply"
Write-Host ""
Write-Host "  Access Key ID: $AccessKeyId" -ForegroundColor Gray