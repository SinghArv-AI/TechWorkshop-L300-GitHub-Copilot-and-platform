# GitHub Actions Deployment Setup with OIDC

## Prerequisites

- Azure subscription with deployed infrastructure (Container Registry and Container App)
- GitHub repository with appropriate permissions
- Azure CLI installed locally

## Why OIDC?

OpenID Connect (OIDC) provides **passwordless authentication** for GitHub Actions, eliminating the need to store and rotate long-lived Azure credentials. This is more secure and follows Microsoft's recommended best practices.

## Configuration Steps

### 1. Run the OIDC Setup Script

Choose the script for your platform and run it from the repository root:

**PowerShell (Windows):**
```powershell
.\setup-github-oidc.ps1
```

**Bash (Linux/macOS):**
```bash
chmod +x setup-github-oidc.sh
./setup-github-oidc.sh
```

This script will:
- ✅ Create a service principal with contributor access to your resource group
- ✅ Configure federated credentials for GitHub OIDC (main branch and pull requests)
- ✅ Assign necessary permissions
- ✅ Display the values you need to configure in GitHub

### 2. Configure GitHub Variables

The script output will show you exactly what values to add. Navigate to:

**GitHub Repository → Settings → Secrets and variables → Actions → Variables**

Add these variables (values provided by the script):

| Name | Description | Your Value |
|------|-------------|------------|
| `AZURE_CLIENT_ID` | Service principal application ID | *(from script output)* |
| `AZURE_TENANT_ID` | Azure AD tenant ID | *(from script output)* |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID | `b7b6dce1-bd42-4a42-8999-57b145d6e140` |
| `AZURE_RESOURCE_GROUP` | Resource group name | `rg-dev` |
| `AZURE_CONTAINER_REGISTRY` | ACR name (without .azurecr.io) | `cramubkqos56puq` |
| `AZURE_CONTAINER_APP_NAME` | Container App name | `src` |

**Note:** With OIDC, you don't need any secrets! All authentication is handled via federated identity.

**Note:** With OIDC, you don't need any secrets! All authentication is handled via federated identity.

### 3. Trigger Deployment

The workflow triggers automatically on:
- Push to `main` branch (any changes in `src/` directory)
- Pull requests to any branch
- Manual trigger via GitHub Actions UI

To manually trigger:
- GitHub → **Actions** → **Build and Deploy** → **Run workflow**

## How It Works

1. **GitHub Actions** requests an OIDC token from GitHub's identity provider
2. Azure validates the token against the federated credential configuration
3. If valid, Azure issues a short-lived access token (no secrets involved!)
4. The workflow uses this token to authenticate Azure CLI commands

## Security Benefits

✅ **No long-lived credentials** stored in GitHub  
✅ **No secret rotation required**  
✅ **Audit trail** of all authentication attempts  
✅ **Scoped access** limited to specific resource group  
✅ **Short-lived tokens** that expire automatically

## Infrastructure Details

Based on your deployed infrastructure:

- **Container Registry**: `cramubkqos56puq`
- **Container App**: `src`
- **Resource Group**: `rg-dev`
- **Subscription ID**: `b7b6dce1-bd42-4a42-8999-57b145d6e140`
- **Location**: `westus2`

## Verify Deployment

After successful deployment, access your application at:
https://src.bluedune-a37f3a2c.westus2.azurecontainerapps.io/
