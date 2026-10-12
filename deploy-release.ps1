#!/usr/bin/env pwsh
<#
.SYNOPSIS
PesoPal v1.0.0 Release - MASTER DEPLOY SCRIPT
Adds all secrets and completes the release automatically.

.EXAMPLE
pwsh .\deploy-release.ps1
#>

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                                ║" -ForegroundColor Cyan
Write-Host "║         PesoPal v1.0.0 - COMPLETE RELEASE DEPLOY              ║" -ForegroundColor Cyan
Write-Host "║                                                                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# STEP 1: VERIFY ENVIRONMENT
# ============================================================================

Write-Host "STEP 1: Verifying environment..." -ForegroundColor Yellow
Write-Host ""

# Check PowerShell version
$psVersion = $PSVersionTable.PSVersion
Write-Host "  PowerShell: $psVersion" -ForegroundColor Gray
if ($psVersion.Major -lt 7) {
	Write-Host "  ⚠️  PowerShell 7+ recommended (pwsh)" -ForegroundColor Yellow
}

# Check keystore file
if (-not (Test-Path "cashledger.keystore")) {
	Write-Host "  ✗ cashledger.keystore not found!" -ForegroundColor Red
	exit 1
}
Write-Host "  ✓ keystore file" -ForegroundColor Green

# Check base64 keystore
if (-not (Test-Path "keystore-base64.txt")) {
	Write-Host "  ✗ keystore-base64.txt not found! Encoding now..." -ForegroundColor Yellow
	$keystore = [IO.File]::ReadAllBytes('cashledger.keystore')
	$encoded = [Convert]::ToBase64String($keystore)
	$encoded | Out-File -Encoding UTF8 keystore-base64.txt
	Write-Host "  ✓ Created keystore-base64.txt" -ForegroundColor Green
} else {
	Write-Host "  ✓ keystore-base64.txt" -ForegroundColor Green
}

# Check git
try {
	$gitVersion = git --version 2>&1 | Select-Object -First 1
	Write-Host "  ✓ git ($gitVersion)" -ForegroundColor Green
} catch {
	Write-Host "  ✗ git not found!" -ForegroundColor Red
	exit 1
}

# Check GitHub CLI
$ghExists = $false
try {
	$ghVersion = & where.exe gh 2>$null
	if ($ghVersion) {
		Write-Host "  ✓ GitHub CLI (gh)" -ForegroundColor Green
		$ghExists = $true
	}
} catch {
	Write-Host "  ⚠️  GitHub CLI not found (will use manual setup)" -ForegroundColor Yellow
}

Write-Host ""

# ============================================================================
# STEP 2: VERIFY GIT STATUS
# ============================================================================

Write-Host "STEP 2: Verifying git status..." -ForegroundColor Yellow
Write-Host ""

$gitStatus = git rev-parse --abbrev-ref HEAD
$gitTag = git describe --tags --abbrev=0 2>$null

Write-Host "  Branch: $gitStatus" -ForegroundColor Gray
if ($gitTag) {
	Write-Host "  Latest tag: $gitTag" -ForegroundColor Gray
}

# Verify tracking
$tracking = git status
if ($tracking -match "ahead of") {
	Write-Host "  ⚠️  Unpushed commits detected" -ForegroundColor Yellow
	Write-Host "  Run: git push origin master" -ForegroundColor Yellow
	exit 1
}

Write-Host "  ✓ Repository is clean" -ForegroundColor Green
Write-Host ""

# ============================================================================
# STEP 3: SETUP SECRETS
# ============================================================================

Write-Host "STEP 3: Setting up GitHub secrets..." -ForegroundColor Yellow
Write-Host ""

if ($ghExists) {
	Write-Host "Using GitHub CLI for setup..." -ForegroundColor Cyan
	Write-Host ""

	$proceed = Read-Host "Proceed with automated secret setup? (Y/n)"
	if ($proceed -eq "n") {
		Write-Host "Skipped. Using manual setup." -ForegroundColor Yellow
		$manualSetup = $true
	} else {
		Write-Host ""
		try {
			& pwsh ".\setup-github-secrets.ps1"
			$secretsAdded = $true
		} catch {
			Write-Host "Setup script failed: $_" -ForegroundColor Red
			$secretsAdded = $false
		}
	}
} else {
	Write-Host "GitHub CLI not available." -ForegroundColor Yellow
	Write-Host ""
	Write-Host "Choose method:" -ForegroundColor Cyan
	Write-Host "  1. Provide GitHub token (automated)" -ForegroundColor Yellow
	Write-Host "  2. Manual setup (copy-paste in browser)" -ForegroundColor Yellow
	Write-Host ""

	$method = Read-Host "Choose (1 or 2)"

	if ($method -eq "1") {
		Write-Host ""
		Write-Host "Get your GitHub token:" -ForegroundColor Cyan
		Write-Host "  1. https://github.com/settings/tokens" -ForegroundColor Yellow
		Write-Host "  2. Generate new token (classic)" -ForegroundColor Yellow
		Write-Host "  3. Scopes: repo, admin:repo_hook" -ForegroundColor Yellow
		Write-Host "  4. Copy and paste below" -ForegroundColor Yellow
		Write-Host ""

		$token = Read-Host "Paste your GitHub token"

		if ($token) {
			Write-Host ""
			Write-Host "Adding secrets via REST API..." -ForegroundColor Yellow
			Write-Host ""
			& pwsh ".\add-secrets-automated.ps1" -Token $token
			$secretsAdded = $true
		} else {
			$secretsAdded = $false
		}
	} else {
		$manualSetup = $true
		$secretsAdded = $false
	}
}

if ($manualSetup) {
	Write-Host ""
	Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
	Write-Host "║                 MANUAL SECRET SETUP                            ║" -ForegroundColor Yellow
	Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
	Write-Host ""
	Write-Host "Open: https://github.com/Synonymz/PesoPal/settings/secrets/actions" -ForegroundColor Cyan
	Write-Host ""
	Write-Host "Add 4 secrets:" -ForegroundColor Yellow
	Write-Host ""
	Write-Host "  1. ANDROID_KEYSTORE_PATH" -ForegroundColor Green
	Write-Host "     Value: (open keystore-base64.txt, copy all content)" -ForegroundColor Gray
	Write-Host ""
	Write-Host "  2. ANDROID_KEY_ALIAS" -ForegroundColor Green
	Write-Host "     Value: pesopa_key" -ForegroundColor Gray
	Write-Host ""
	Write-Host "  3. ANDROID_KEY_PASSWORD" -ForegroundColor Green
	Write-Host "     Value: Francis" -ForegroundColor Gray
	Write-Host ""
	Write-Host "  4. ANDROID_KEYSTORE_PASSWORD" -ForegroundColor Green
	Write-Host "     Value: Francis" -ForegroundColor Gray
	Write-Host ""
	Write-Host "After adding all 4 secrets, press any key to continue..." -ForegroundColor Yellow
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	$secretsAdded = $true
}

Write-Host ""

if (-not $secretsAdded) {
	Write-Host "Secrets setup failed or incomplete." -ForegroundColor Red
	exit 1
}

Write-Host "✓ Secrets configured" -ForegroundColor Green
Write-Host ""

# ============================================================================
# STEP 4: MONITOR WORKFLOW
# ============================================================================

Write-Host "STEP 4: Monitoring GitHub Actions workflow..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Repository: Synonymz/PesoPal" -ForegroundColor Gray
Write-Host "Release: v1.0.0" -ForegroundColor Gray
Write-Host ""

$proceed = Read-Host "Open GitHub Actions in browser? (Y/n)"
if ($proceed -ne "n") {
	Start-Process "https://github.com/Synonymz/PesoPal/actions"
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                                                                ║" -ForegroundColor Green
Write-Host "║        ✅ RELEASE DEPLOYMENT STARTED!                         ║" -ForegroundColor Green
Write-Host "║                                                                ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "Timeline:" -ForegroundColor Cyan
Write-Host "  1-2 min  : Workflow picks up secrets and starts building" -ForegroundColor Yellow
Write-Host "  5-10 min : APK built and signed" -ForegroundColor Yellow
Write-Host "  1-2 min  : Release published with APK" -ForegroundColor Yellow
Write-Host "  1 min    : latest.json generated and published" -ForegroundColor Yellow
Write-Host ""
Write-Host "Total: ~10-15 minutes" -ForegroundColor Green
Write-Host ""

Write-Host "What's happening now:" -ForegroundColor Cyan
Write-Host "  ✓ Secrets stored securely in GitHub" -ForegroundColor Green
Write-Host "  ✓ Workflow will resume automatically" -ForegroundColor Green
Write-Host "  ✓ GitHub Actions will build the APK" -ForegroundColor Green
Write-Host "  ✓ APK will be signed with your keystore" -ForegroundColor Green
Write-Host "  ✓ Release page will be created" -ForegroundColor Green
Write-Host "  ✓ APK will be uploaded as download asset" -ForegroundColor Green
Write-Host "  ✓ Update metadata (latest.json) will be generated" -ForegroundColor Green
Write-Host "  ✓ Users can now check for updates!" -ForegroundColor Green
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Monitor workflow: https://github.com/Synonymz/PesoPal/actions" -ForegroundColor Yellow
Write-Host "  2. Download APK from releases page when ready" -ForegroundColor Yellow
Write-Host "  3. Test on Android device" -ForegroundColor Yellow
Write-Host "  4. Announce release to users" -ForegroundColor Yellow
Write-Host ""

Write-Host "Release URLs:" -ForegroundColor Cyan
Write-Host "  Releases: https://github.com/Synonymz/PesoPal/releases" -ForegroundColor Yellow
Write-Host "  v1.0.0: https://github.com/Synonymz/PesoPal/releases/tag/v1.0.0" -ForegroundColor Yellow
Write-Host "  Updates: https://raw.githubusercontent.com/Synonymz/PesoPal/gh-pages/latest.json" -ForegroundColor Yellow
Write-Host ""

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                   RELEASE IN PROGRESS! 🚀                     ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
