#!/usr/bin/env pwsh
<#
.SYNOPSIS
PesoPal v1.0.0 - Secrets Setup (Automated)

This script handles GitHub authentication and adds all 4 secrets.
#>

Write-Host ""
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   PesoPal v1.0.0 - Secrets Setup           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Option 1: Try GitHub CLI first
$ghExists = $null
try {
	$ghExists = & where.exe gh 2>$null
} catch {
	$ghExists = $null
}

if ($ghExists) {
	Write-Host "✓ GitHub CLI found!" -ForegroundColor Green
	Write-Host ""
	Write-Host "Running automated setup..." -ForegroundColor Yellow
	Write-Host ""

	# Use the automatic setup script
	& pwsh .\setup-github-secrets.ps1
	exit 0
}

# Option 2: Use REST API (requires token)
Write-Host "GitHub CLI not found. Using REST API method." -ForegroundColor Yellow
Write-Host ""
Write-Host "You have 2 options:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Generate GitHub token and use automated API script" -ForegroundColor Yellow
Write-Host "  2. Add secrets manually via GitHub web UI (fastest for 1-time setup)" -ForegroundColor Yellow
Write-Host ""

$choice = Read-Host "Choose (1 or 2, or press Enter for manual setup)"

if ($choice -eq "1") {
	Write-Host ""
	Write-Host "Getting token..." -ForegroundColor Yellow
	$Token = Read-Host "Paste your GitHub Personal Access Token"

	if ([string]::IsNullOrEmpty($Token)) {
		Write-Host "No token provided." -ForegroundColor Red
		exit 1
	}

	Write-Host ""
	Write-Host "Adding secrets via REST API..." -ForegroundColor Yellow
	& pwsh .\add-secrets-via-api.ps1 -Token $Token
} else {
	Write-Host ""
	Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Yellow
	Write-Host "║        MANUAL SETUP (2 minutes)            ║" -ForegroundColor Yellow
	Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Yellow
	Write-Host ""
	Write-Host "1. Open: https://github.com/Synonymz/PesoPal/settings/secrets/actions" -ForegroundColor Cyan
	Write-Host ""
	Write-Host "2. Add 4 secrets:" -ForegroundColor Cyan
	Write-Host ""
	Write-Host "   Secret 1:" -ForegroundColor Green
	Write-Host "   Name:  ANDROID_KEYSTORE_PATH" -ForegroundColor Gray
	Write-Host "   Value: (open keystore-base64.txt and copy entire content)" -ForegroundColor Gray
	Write-Host ""
	Write-Host "   Secret 2:" -ForegroundColor Green
	Write-Host "   Name:  ANDROID_KEY_ALIAS" -ForegroundColor Gray
	Write-Host "   Value: pesopa_key" -ForegroundColor Gray
	Write-Host ""
	Write-Host "   Secret 3:" -ForegroundColor Green
	Write-Host "   Name:  ANDROID_KEY_PASSWORD" -ForegroundColor Gray
	Write-Host "   Value: Francis" -ForegroundColor Gray
	Write-Host ""
	Write-Host "   Secret 4:" -ForegroundColor Green
	Write-Host "   Name:  ANDROID_KEYSTORE_PASSWORD" -ForegroundColor Gray
	Write-Host "   Value: Francis" -ForegroundColor Gray
	Write-Host ""
	Write-Host "3. After adding all 4 secrets:" -ForegroundColor Cyan
	Write-Host "  - Workflow automatically resumes" -ForegroundColor Yellow
	Write-Host "  - APK builds in ~10 minutes" -ForegroundColor Yellow
	Write-Host "  - Monitor: https://github.com/Synonymz/PesoPal/actions" -ForegroundColor Yellow
	Write-Host ""
	Write-Host "Press any key when done..." -ForegroundColor Yellow
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	Write-Host ""
	Write-Host "✓ Secrets added! Workflow should start building now." -ForegroundColor Green
}

Write-Host ""
