#!/bin/bash

# GitHub OIDC Setup Script for ZavaStorefront
# This script creates a service principal with federated credentials for GitHub Actions

set -e

# Configuration
SUBSCRIPTION_ID="b7b6dce1-bd42-4a42-8999-57b145d6e140"
RESOURCE_GROUP="rg-dev"
GITHUB_ORG="microsoft"
GITHUB_REPO="TechWorkshop-L300-GitHub-Copilot-and-platform"
APP_NAME="github-oidc-zavastore"
LOCATION="westus2"

echo "🔧 Setting up GitHub OIDC authentication for Azure deployment..."
echo ""
echo "Subscription: $SUBSCRIPTION_ID"
echo "Resource Group: $RESOURCE_GROUP"
echo "GitHub Repository: $GITHUB_ORG/$GITHUB_REPO"
echo ""

# Set the subscription context
echo "📋 Setting subscription context..."
az account set --subscription "$SUBSCRIPTION_ID"

# Create the Service Principal
echo "🔐 Creating Service Principal..."
SP_OUTPUT=$(az ad sp create-for-rbac \
  --name "$APP_NAME" \
  --role contributor \
  --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" \
  --query "{appId: appId, displayName: displayName, tenantId: tenant}" \
  --output json)

APP_ID=$(echo $SP_OUTPUT | jq -r '.appId')
TENANT_ID=$(echo $SP_OUTPUT | jq -r '.tenantId')

echo "✅ Service Principal created"
echo "   App ID: $APP_ID"
echo "   Tenant ID: $TENANT_ID"
echo ""

# Create federated credential for main branch
echo "🔗 Creating federated credential for main branch..."
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters "{
    \"name\": \"$APP_NAME-main\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$GITHUB_ORG/$GITHUB_REPO:ref:refs/heads/main\",
    \"audiences\": [\"api://AzureADTokenExchange\"],
    \"description\": \"Deploy from main branch\"
  }"

echo "✅ Federated credential created for main branch"
echo ""

# Create federated credential for pull requests
echo "🔗 Creating federated credential for pull requests..."
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters "{
    \"name\": \"$APP_NAME-pr\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$GITHUB_ORG/$GITHUB_REPO:pull_request\",
    \"audiences\": [\"api://AzureADTokenExchange\"],
    \"description\": \"Deploy from pull requests\"
  }"

echo "✅ Federated credential created for pull requests"
echo ""

# Verify role assignment
echo "🔍 Verifying role assignment..."
az role assignment list \
  --assignee "$APP_ID" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" \
  --query "[].{Role:roleDefinitionName, Scope:scope}" \
  --output table

echo ""
echo "✨ Setup complete! Configure these values in GitHub:"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "GitHub Repository Secrets (none needed for OIDC!)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "GitHub Repository Variables:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "AZURE_CLIENT_ID: $APP_ID"
echo "AZURE_TENANT_ID: $TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo "AZURE_RESOURCE_GROUP: $RESOURCE_GROUP"
echo "AZURE_CONTAINER_REGISTRY: cramubkqos56puq"
echo "AZURE_CONTAINER_APP_NAME: src"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 Next steps:"
echo "1. Go to: https://github.com/$GITHUB_ORG/$GITHUB_REPO/settings/variables/actions"
echo "2. Add the variables listed above"
echo "3. Update your workflow to use OIDC (see deploy.yml)"
echo "4. Push to main branch to trigger deployment"
echo ""
