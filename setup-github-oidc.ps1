# GitHub OIDC Setup Script for ZavaStorefront
# This script creates a service principal with federated credentials for GitHub Actions

# Configuration
$SUBSCRIPTION_ID = "b7b6dce1-bd42-4a42-8999-57b145d6e140"
$RESOURCE_GROUP = "rg-dev"
$GITHUB_ORG = "microsoft"
$GITHUB_REPO = "TechWorkshop-L300-GitHub-Copilot-and-platform"
$APP_NAME = "github-oidc-zavastore"
$LOCATION = "westus2"

Write-Host "🔧 Setting up GitHub OIDC authentication for Azure deployment..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Subscription: $SUBSCRIPTION_ID"
Write-Host "Resource Group: $RESOURCE_GROUP"
Write-Host "GitHub Repository: $GITHUB_ORG/$GITHUB_REPO"
Write-Host ""

# Set the subscription context
Write-Host "📋 Setting subscription context..." -ForegroundColor Yellow
az account set --subscription $SUBSCRIPTION_ID

# Create the Service Principal
Write-Host "🔐 Creating Service Principal..." -ForegroundColor Yellow
$spOutput = az ad sp create-for-rbac `
  --name $APP_NAME `
  --role contributor `
  --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" `
  --years 1 `
  --query "{appId: appId, displayName: displayName, tenantId: tenant}" `
  --output json | ConvertFrom-Json

$APP_ID = $spOutput.appId
$TENANT_ID = $spOutput.tenantId

Write-Host "✅ Service Principal created" -ForegroundColor Green
Write-Host "   App ID: $APP_ID"
Write-Host "   Tenant ID: $TENANT_ID"
Write-Host ""

# Create federated credential for main branch
Write-Host "🔗 Creating federated credential for main branch..." -ForegroundColor Yellow
$mainCredential = @{
    name = "$APP_NAME-main"
    issuer = "https://token.actions.githubusercontent.com"
    subject = "repo:$GITHUB_ORG/$($GITHUB_REPO):ref:refs/heads/main"
    audiences = @("api://AzureADTokenExchange")
    description = "Deploy from main branch"
} | ConvertTo-Json -Compress

az ad app federated-credential create --id $APP_ID --parameters $mainCredential

Write-Host "✅ Federated credential created for main branch" -ForegroundColor Green
Write-Host ""

# Create federated credential for pull requests
Write-Host "🔗 Creating federated credential for pull requests..." -ForegroundColor Yellow
$prCredential = @{
    name = "$APP_NAME-pr"
    issuer = "https://token.actions.githubusercontent.com"
    subject = "repo:$GITHUB_ORG/$($GITHUB_REPO):pull_request"
    audiences = @("api://AzureADTokenExchange")
    description = "Deploy from pull requests"
} | ConvertTo-Json -Compress

az ad app federated-credential create --id $APP_ID --parameters $prCredential

Write-Host "✅ Federated credential created for pull requests" -ForegroundColor Green
Write-Host ""

# Verify role assignment
Write-Host "🔍 Verifying role assignment..." -ForegroundColor Yellow
az role assignment list `
  --assignee $APP_ID `
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" `
  --query "[].{Role:roleDefinitionName, Scope:scope}" `
  --output table

Write-Host ""
Write-Host "✨ Setup complete! Configure these values in GitHub:" -ForegroundColor Green
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "GitHub Repository Secrets (none needed for OIDC!)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "GitHub Repository Variables:" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "AZURE_CLIENT_ID: $APP_ID" -ForegroundColor White
Write-Host "AZURE_TENANT_ID: $TENANT_ID" -ForegroundColor White
Write-Host "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID" -ForegroundColor White
Write-Host "AZURE_RESOURCE_GROUP: $RESOURCE_GROUP" -ForegroundColor White
Write-Host "AZURE_CONTAINER_REGISTRY: cramubkqos56puq" -ForegroundColor White
Write-Host "AZURE_CONTAINER_APP_NAME: src" -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "🎯 Next steps:" -ForegroundColor Yellow
Write-Host "1. Go to: https://github.com/$GITHUB_ORG/$GITHUB_REPO/settings/variables/actions"
Write-Host "2. Add the variables listed above"
Write-Host "3. Your workflow is already configured for OIDC (see deploy.yml)"
Write-Host "4. Push to main branch to trigger deployment"
Write-Host ""
