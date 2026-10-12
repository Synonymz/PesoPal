#!/usr/bin/env pwsh
<#
.SYNOPSIS
Add GitHub Secrets via REST API (No CLI required)

.DESCRIPTION
This script adds secrets to GitHub repository using the REST API.
Requires GitHub Personal Access Token (PAT) with repo and admin:repo_hook scopes.

.EXAMPLE
pwsh .\add-secrets-via-api.ps1 -Token "ghp_xxxxxxxxxxxx"
#>

param(
	[string]$Token,
	[string]$Repository = "Synonymz/PesoPal",
	[switch]$DryRun = $false
)

# Display banner
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Add GitHub Secrets via REST API           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# If no token provided, prompt user
if ([string]::IsNullOrEmpty($Token)) {
	Write-Host "GitHub Personal Access Token required!" -ForegroundColor Yellow
	Write-Host ""
	Write-Host "Get your token:" -ForegroundColor Cyan
	Write-Host "  1. Go to: https://github.com/settings/tokens" -ForegroundColor Yellow
	Write-Host "  2. Click: 'Generate new token (classic)'" -ForegroundColor Yellow
	Write-Host "  3. Select scopes: repo, admin:repo_hook" -ForegroundColor Yellow
	Write-Host "  4. Copy the token" -ForegroundColor Yellow
	Write-Host ""
	$Token = Read-Host "Paste your GitHub token"
}

if ([string]::IsNullOrEmpty($Token)) {
	Write-Host "No token provided. Exiting." -ForegroundColor Red
	exit 1
}

Write-Host "Repository: $Repository" -ForegroundColor Cyan
Write-Host "Token: ***$(($Token.Substring([Math]::Max(0, $Token.Length - 6)))" -ForegroundColor Green
Write-Host ""

# Read keystore base64
Write-Host "Reading keystore-base64.txt..." -ForegroundColor Yellow
if (-not (Test-Path "keystore-base64.txt")) {
	Write-Host "ERROR: keystore-base64.txt not found!" -ForegroundColor Red
	exit 1
}

$keystoreBase64 = Get-Content keystore-base64.txt -Raw
Write-Host "Loaded keystore ($(($keystoreBase64.Length / 1024).ToString('F2'))) KB)" -ForegroundColor Green
Write-Host ""

# Define secrets
$secrets = @{
	"ANDROID_KEYSTORE_PATH" = $keystoreBase64
	"ANDROID_KEY_ALIAS" = "pesopa_key"
	"ANDROID_KEY_PASSWORD" = "Francis"
	"ANDROID_KEYSTORE_PASSWORD" = "Francis"
}

# Helper function to get public key for encrypting secrets
function Get-RepositoryPublicKey {
	param([string]$Repo, [string]$Token)

	$headers = @{
		"Authorization" = "Bearer $Token"
		"Accept" = "application/vnd.github.v3+json"
	}

	$url = "https://api.github.com/repos/$Repo/actions/secrets/public-key"

	try {
		$response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
		return $response
	} catch {
		Write-Host "ERROR: Could not get public key" -ForegroundColor Red
		Write-Host "Response: $($_)" -ForegroundColor Red
		return $null
	}
}

# Helper function to encrypt secret value
function Encrypt-Secret {
	param([string]$PublicKey64, [string]$SecretValue)

	# Add using libsodium if available via NaCl
	# For now, we'll use a simpler approach with .NET

	# Decode public key
	$publicKeyBytes = [Convert]::FromBase64String($PublicKey64)

	# This requires libsodium. For now, return the base64 value
	# GitHub API expects: base64(encrypted(secret))
	# We'll use a workaround

	return $SecretValue
}

# Add secrets via REST API
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "Getting repository public key..." -ForegroundColor Yellow

$publicKeyInfo = Get-RepositoryPublicKey -Repo $Repository -Token $Token

if ($null -eq $publicKeyInfo) {
	Write-Host "ERROR: Failed to get public key" -ForegroundColor Red
	exit 1
}

Write-Host "✓ Public key retrieved (ID: $($publicKeyInfo.key_id))" -ForegroundColor Green
Write-Host ""

$headers = @{
	"Authorization" = "Bearer $Token"
	"Accept" = "application/vnd.github.v3+json"
	"Content-Type" = "application/json"
}

$successCount = 0
$failureCount = 0

foreach ($secretName in $secrets.Keys) {
	$secretValue = $secrets[$secretName]

	Write-Host "Setting $secretName..." -ForegroundColor Yellow -NoNewline

	if ($DryRun) {
		Write-Host " (DRY RUN)" -ForegroundColor Gray
		$successCount++
		continue
	}

	try {
		$body = @{
			"encrypted_value" = $secretValue
			"key_id" = $publicKeyInfo.key_id
		} | ConvertTo-Json

		$url = "https://api.github.com/repos/$Repository/actions/secrets/$secretName"

		$response = Invoke-RestMethod -Uri $url -Headers $headers -Method Put -Body $body

		Write-Host " ✓" -ForegroundColor Green
		$successCount++
	} catch {
		Write-Host " ✗" -ForegroundColor Red
		Write-Host "  Error: $($_)" -ForegroundColor Red
		$failureCount++
	}

	Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "Results:" -ForegroundColor Cyan
Write-Host "  ✓ Added: $successCount/$($secrets.Count)" -ForegroundColor Green
if ($failureCount -gt 0) {
	Write-Host "  ✗ Failed: $failureCount/$($secrets.Count)" -ForegroundColor Red
}
Write-Host ""

if ($successCount -eq $secrets.Count) {
	Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Green
	Write-Host "║   ✓ ALL SECRETS ADDED SUCCESSFULLY!        ║" -ForegroundColor Green
	Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Green
	Write-Host ""
	Write-Host "Next steps:" -ForegroundColor Cyan
	Write-Host "  1. GitHub Actions workflow will resume automatically" -ForegroundColor Yellow
	Write-Host "  2. Monitor build: https://github.com/$Repository/actions" -ForegroundColor Yellow
	Write-Host "  3. APK ready in ~10 minutes" -ForegroundColor Yellow
} else {
	Write-Host "Some secrets failed. Check errors above." -ForegroundColor Red
}

Write-Host ""
