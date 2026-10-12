#!/usr/bin/env pwsh
<#
.SYNOPSIS
Configure GitHub Secrets for PesoPal v1.0.0 Release

.DESCRIPTION
This script sets up all required GitHub repository secrets for the CI/CD pipeline.
Requires GitHub CLI (gh) to be installed and authenticated.

.EXAMPLE
pwsh .\setup-github-secrets.ps1
#>

param(
	[string]$Repository = "Synonymz/PesoPal",
	[switch]$DryRun = $false
)

# Display banner
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   GitHub Secrets Setup for PesoPal v1.0.0  ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if gh CLI is installed
Write-Host "Checking GitHub CLI installation..." -ForegroundColor Yellow
try {
	$ghVersion = gh --version
	Write-Host "✓ GitHub CLI found: $ghVersion" -ForegroundColor Green
} catch {
	Write-Host "✗ GitHub CLI not installed!" -ForegroundColor Red
	Write-Host "  Install from: https://cli.github.com/" -ForegroundColor Yellow
	Write-Host ""
	Write-Host "  For now, copy values manually to:" -ForegroundColor Yellow
	Write-Host "  https://github.com/$Repository/settings/secrets/actions" -ForegroundColor Cyan
	exit 1
}

Write-Host ""
Write-Host "Repository: $Repository" -ForegroundColor Cyan
Write-Host ""

# Verify authentication
Write-Host "Verifying GitHub authentication..." -ForegroundColor Yellow
try {
	$user = gh auth status 2>&1 | Select-String "Logged in to"
	Write-Host "✓ $user" -ForegroundColor Green
} catch {
	Write-Host "✗ Not authenticated with GitHub CLI" -ForegroundColor Red
	Write-Host "  Run: gh auth login" -ForegroundColor Yellow
	exit 1
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

# Define secrets
$secrets = @{
	"ANDROID_KEYSTORE_PATH" = @{
		Value = "keystore-base64.txt"  # Will read from file
		Description = "Base64-encoded Android keystore file"
	}
	"ANDROID_KEY_ALIAS" = @{
		Value = "pesopa_key"
		Description = "Keystore key alias"
	}
	"ANDROID_KEY_PASSWORD" = @{
		Value = "Francis"
		Description = "Private key password"
	}
	"ANDROID_KEYSTORE_PASSWORD" = @{
		Value = "Francis"
		Description = "Keystore password"
	}
}

# Read base64 encoded keystore
Write-Host ""
Write-Host "Reading keystore file..." -ForegroundColor Yellow
$keystoreFile = "keystore-base64.txt"

if (Test-Path $keystoreFile) {
	$keystoreBase64 = Get-Content $keystoreFile -Raw
	$secrets["ANDROID_KEYSTORE_PATH"].Value = $keystoreBase64
	Write-Host "✓ Keystore base64 content loaded ($(($keystoreBase64.Length / 1024).ToString('F2')) KB)" -ForegroundColor Green
} else {
	Write-Host "✗ keystore-base64.txt not found!" -ForegroundColor Red
	Write-Host "  Create it by running:" -ForegroundColor Yellow
	Write-Host '  $keystore = [IO.File]::ReadAllBytes("cashledger.keystore")' -ForegroundColor Gray
	Write-Host '  $encoded = [Convert]::ToBase64String($keystore)' -ForegroundColor Gray
	Write-Host '  $encoded | Out-File keystore-base64.txt' -ForegroundColor Gray
	exit 1
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "Secrets to configure:" -ForegroundColor Cyan
Write-Host ""

$secretCount = 0
foreach ($secretName in $secrets.Keys) {
	$secretCount++
	$description = $secrets[$secretName].Description
	$value = $secrets[$secretName].Value

	if ($secretName -eq "ANDROID_KEYSTORE_PATH") {
		Write-Host "  $secretCount. $secretName" -ForegroundColor Green
		Write-Host "     Description: $description" -ForegroundColor Gray
		Write-Host "     Value: (base64 content - $(($value.Length / 1024).ToString('F2')) KB)" -ForegroundColor Gray
	} else {
		Write-Host "  $secretCount. $secretName" -ForegroundColor Green
		Write-Host "     Description: $description" -ForegroundColor Gray
		Write-Host "     Value: $value" -ForegroundColor Gray
	}
	Write-Host ""
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
	Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
	Write-Host ""
	Write-Host "To apply these secrets, remove -DryRun flag:" -ForegroundColor Yellow
	Write-Host "  pwsh .\setup-github-secrets.ps1" -ForegroundColor Cyan
} else {
	Write-Host "Adding secrets to GitHub repository..." -ForegroundColor Yellow
	Write-Host ""

	$successCount = 0
	$failureCount = 0

	foreach ($secretName in $secrets.Keys) {
		$description = $secrets[$secretName].Description
		$value = $secrets[$secretName].Value

		try {
			Write-Host "  ⏳ Setting $secretName..." -ForegroundColor Yellow -NoNewline

			# Use echo to pass value to gh CLI
			if ($secretName -eq "ANDROID_KEYSTORE_PATH") {
				# For large base64 values
				echo $value | gh secret set $secretName -R $Repository
			} else {
				# For regular values
				gh secret set $secretName --body $value -R $Repository
			}

			Write-Host " ✓" -ForegroundColor Green
			$successCount++
		} catch {
			Write-Host " ✗" -ForegroundColor Red
			Write-Host "    Error: $_" -ForegroundColor Red
			$failureCount++
		}
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
		Write-Host "║   ✓ ALL SECRETS CONFIGURED SUCCESSFULLY!   ║" -ForegroundColor Green
		Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Green
		Write-Host ""
		Write-Host "Next steps:" -ForegroundColor Cyan
		Write-Host "  1. Go to: https://github.com/$Repository/actions" -ForegroundColor Yellow
		Write-Host "  2. Watch the v1.0.0 workflow run" -ForegroundColor Yellow
		Write-Host "  3. Wait for APK build to complete (5-10 minutes)" -ForegroundColor Yellow
		Write-Host "  4. Download APK from releases page" -ForegroundColor Yellow
		Write-Host "  5. Test on Android device" -ForegroundColor Yellow
	} else {
		Write-Host "Some secrets failed to configure." -ForegroundColor Red
		Write-Host "Please add them manually:" -ForegroundColor Yellow
		Write-Host "  https://github.com/$Repository/settings/secrets/actions" -ForegroundColor Cyan
	}
}

Write-Host ""
