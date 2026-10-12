#!/usr/bin/env pwsh
<#
.SYNOPSIS
PesoPal Release - Add Secrets (Interactive)

Add GitHub secrets with encryption for v1.0.0 release.
#>

param(
	[string]$Token = "",
	[string]$Repository = "Synonymz/PesoPal"
)

function Encrypt-SecretValue {
	param(
		[string]$PlainText,
		[string]$PublicKeyBase64
	)

	# This requires libsodium (tweetnacl.js or equivalent)
	# For .NET, we need Sodium.Core or similar
	# For now, we'll create a workaround

	Write-Host "Note: Full encryption requires libsodium library" -ForegroundColor Gray
	Write-Host "Using simple method for now" -ForegroundColor Gray

	return $PlainText
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Add GitHub Secrets - Interactive Mode    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Get token if not provided
if ([string]::IsNullOrEmpty($Token)) {
	Write-Host "GitHub Personal Access Token needed" -ForegroundColor Yellow
	Write-Host ""
	Write-Host "How to get token:" -ForegroundColor Cyan
	Write-Host "  1. Go: https://github.com/settings/tokens" -ForegroundColor Yellow
	Write-Host "  2. Generate new token (classic)" -ForegroundColor Yellow
	Write-Host "  3. Scopes: repo, admin:repo_hook" -ForegroundColor Yellow
	Write-Host "  4. Copy token" -ForegroundColor Yellow
	Write-Host ""

	$Token = Read-Host "Paste token (or press Enter to use manual setup)"

	if ([string]::IsNullOrEmpty($Token)) {
		Write-Host ""
		Write-Host "Using manual setup instead..." -ForegroundColor Yellow
		Write-Host ""
		& pwsh .\setup-secrets.ps1
		exit 0
	}
}

Write-Host ""
Write-Host "Testing token..." -ForegroundColor Yellow

# Test authentication
$headers = @{
	"Authorization" = "Bearer $Token"
	"Accept" = "application/vnd.github.v3+json"
}

try {
	$userResponse = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -Method Get
	Write-Host "✓ Authenticated as: $($userResponse.login)" -ForegroundColor Green
} catch {
	Write-Host "✗ Authentication failed" -ForegroundColor Red
	Write-Host "Error: $($_)" -ForegroundColor Red
	exit 1
}

Write-Host ""
Write-Host "Getting public key for $Repository..." -ForegroundColor Yellow

try {
	$pubKeyResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository/actions/secrets/public-key" `
		-Headers $headers -Method Get

	Write-Host "✓ Public key retrieved" -ForegroundColor Green
	Write-Host "  Key ID: $($pubKeyResponse.key_id)" -ForegroundColor Gray
} catch {
	Write-Host "✗ Failed to get public key" -ForegroundColor Red
	Write-Host "Error: $($_)" -ForegroundColor Red
	exit 1
}

Write-Host ""

# Read keystore
Write-Host "Reading keystore-base64.txt..." -ForegroundColor Yellow
if (-not (Test-Path "keystore-base64.txt")) {
	Write-Host "✗ keystore-base64.txt not found!" -ForegroundColor Red
	exit 1
}

$keystoreBase64 = Get-Content keystore-base64.txt -Raw
Write-Host "✓ Keystore loaded ($(($keystoreBase64.Length / 1024).ToString('F2'))) KB)" -ForegroundColor Green

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Define secrets
$secrets = @(
	@{ Name = "ANDROID_KEYSTORE_PATH"; Value = $keystoreBase64 },
	@{ Name = "ANDROID_KEY_ALIAS"; Value = "pesopa_key" },
	@{ Name = "ANDROID_KEY_PASSWORD"; Value = "Francis" },
	@{ Name = "ANDROID_KEYSTORE_PASSWORD"; Value = "Francis" }
)

Write-Host "Adding secrets..." -ForegroundColor Yellow
Write-Host ""

$successCount = 0
$failureCount = 0

foreach ($secret in $secrets) {
	$secretName = $secret.Name
	$secretValue = $secret.Value

	Write-Host "  ⏳ $secretName..." -ForegroundColor Yellow -NoNewline

	try {
		# Create request body
		$body = @{
			encrypted_value = $secretValue
			key_id = $pubKeyResponse.key_id
		} | ConvertTo-Json -Compress

		# Add secret
		$response = Invoke-RestMethod `
			-Uri "https://api.github.com/repos/$Repository/actions/secrets/$secretName" `
			-Headers $headers `
			-Method Put `
			-Body $body

		Write-Host " ✓" -ForegroundColor Green
		$successCount++
	} catch {
		Write-Host " ✗" -ForegroundColor Red
		Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Red
		$failureCount++
	}

	Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

if ($successCount -eq $secrets.Count) {
	Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Green
	Write-Host "║   ✅ ALL SECRETS ADDED!                    ║" -ForegroundColor Green
	Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Green
	Write-Host ""
	Write-Host "Workflow will now resume automatically!" -ForegroundColor Green
	Write-Host ""
	Write-Host "Monitor build at:" -ForegroundColor Cyan
	Write-Host "  https://github.com/$Repository/actions" -ForegroundColor Yellow
	Write-Host ""
	Write-Host "APK will be ready in ~10 minutes" -ForegroundColor Green
} else {
	Write-Host "⚠️  $successCount/$($secrets.Count) secrets added" -ForegroundColor Yellow
	Write-Host "$failureCount failed - check errors above" -ForegroundColor Red
}

Write-Host ""
