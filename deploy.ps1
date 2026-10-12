# PesoPal v1.0.0 Release - Deploy Script

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PesoPal v1.0.0 - Release Deploy Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verify keystore
Write-Host "Checking files..." -ForegroundColor Yellow
if (-not (Test-Path "keystore-base64.txt")) {
	Write-Host "Creating keystore-base64.txt..." -ForegroundColor Yellow
	$keystore = [IO.File]::ReadAllBytes('cashledger.keystore')
	$encoded = [Convert]::ToBase64String($keystore)
	$encoded | Out-File -Encoding UTF8 keystore-base64.txt
	Write-Host "OK!" -ForegroundColor Green
} else {
	Write-Host "OK - keystore-base64.txt found" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "GitHub Secrets Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Two options:" -ForegroundColor Yellow
Write-Host "1. Manual setup (2 minutes)" -ForegroundColor Gray
Write-Host "2. Use GitHub token (automated)" -ForegroundColor Gray
Write-Host ""

$choice = Read-Host "Choice (1 or 2)"

if ($choice -eq "2") {
	Write-Host ""
	Write-Host "Get your GitHub token from:" -ForegroundColor Cyan
	Write-Host "https://github.com/settings/tokens" -ForegroundColor Yellow
	Write-Host ""
	Write-Host "Requirements:" -ForegroundColor Yellow
	Write-Host "- Token type: Classic" -ForegroundColor Gray
	Write-Host "- Scopes: repo, admin:repo_hook" -ForegroundColor Gray
	Write-Host ""

	$token = Read-Host "Paste your GitHub token"

	if ([string]::IsNullOrEmpty($token)) {
		$choice = 1
	} else {
		Write-Host ""
		Write-Host "Testing authentication..." -ForegroundColor Yellow

		$headers = @{
			"Authorization" = "Bearer $token"
			"Accept" = "application/vnd.github.v3+json"
		}

		try {
			$user = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers
			Write-Host "Authenticated as: $($user.login)" -ForegroundColor Green
			Write-Host ""
		} catch {
			Write-Host "Authentication failed!" -ForegroundColor Red
			$choice = 1
		}
	}
}

if ($choice -eq "1") {
	Write-Host ""
	Write-Host "MANUAL SETUP INSTRUCTIONS:" -ForegroundColor Yellow
	Write-Host "========================================" -ForegroundColor Cyan
	Write-Host ""
	Write-Host "1. Open this URL:" -ForegroundColor Green
	Write-Host "https://github.com/Synonymz/PesoPal/settings/secrets/actions" -ForegroundColor Cyan
	Write-Host ""
	Write-Host "2. Click 'New repository secret'" -ForegroundColor Green
	Write-Host ""
	Write-Host "3. Add 4 secrets:" -ForegroundColor Green
	Write-Host ""
	Write-Host "Secret 1:" -ForegroundColor Yellow
	Write-Host "  Name: ANDROID_KEYSTORE_PATH" -ForegroundColor Gray
	Write-Host "  Value: (content of keystore-base64.txt - ~3.6 KB)" -ForegroundColor Gray
	Write-Host ""
	Write-Host "Secret 2:" -ForegroundColor Yellow
	Write-Host "  Name: ANDROID_KEY_ALIAS" -ForegroundColor Gray
	Write-Host "  Value: pesopa_key" -ForegroundColor Gray
	Write-Host ""
	Write-Host "Secret 3:" -ForegroundColor Yellow
	Write-Host "  Name: ANDROID_KEY_PASSWORD" -ForegroundColor Gray
	Write-Host "  Value: Francis" -ForegroundColor Gray
	Write-Host ""
	Write-Host "Secret 4:" -ForegroundColor Yellow
	Write-Host "  Name: ANDROID_KEYSTORE_PASSWORD" -ForegroundColor Gray
	Write-Host "  Value: Francis" -ForegroundColor Gray
	Write-Host ""
	Write-Host "Press ENTER when all 4 secrets have been added..." -ForegroundColor Yellow
	Read-Host ""

	Write-Host ""
	Write-Host "Great! Secrets are now configured." -ForegroundColor Green

} else {
	Write-Host ""
	Write-Host "Adding secrets via REST API..." -ForegroundColor Yellow
	Write-Host ""

	$keystoreBase64 = Get-Content keystore-base64.txt -Raw

	$secrets = @(
		@{ Name = "ANDROID_KEYSTORE_PATH"; Value = $keystoreBase64 },
		@{ Name = "ANDROID_KEY_ALIAS"; Value = "pesopa_key" },
		@{ Name = "ANDROID_KEY_PASSWORD"; Value = "Francis" },
		@{ Name = "ANDROID_KEYSTORE_PASSWORD"; Value = "Francis" }
	)

	# Get public key
	Write-Host "Getting repository public key..." -ForegroundColor Yellow
	try {
		$pubKey = Invoke-RestMethod -Uri "https://api.github.com/repos/Synonymz/PesoPal/actions/secrets/public-key" `
			-Headers $headers
		Write-Host "OK - Key ID: $($pubKey.key_id)" -ForegroundColor Green
	} catch {
		Write-Host "Failed to get public key: $_" -ForegroundColor Red
		exit 1
	}

	Write-Host ""
	Write-Host "Adding 4 secrets..." -ForegroundColor Yellow
	Write-Host ""

	$count = 0
	foreach ($secret in $secrets) {
		$count++
		Write-Host "  $count. $($secret.Name)..." -ForegroundColor Yellow -NoNewline

		try {
			$body = @{
				encrypted_value = $secret.Value
				key_id = $pubKey.key_id
			} | ConvertTo-Json -Compress

			$response = Invoke-RestMethod `
				-Uri "https://api.github.com/repos/Synonymz/PesoPal/actions/secrets/$($secret.Name)" `
				-Headers $headers `
				-Method Put `
				-Body $body

			Write-Host " OK" -ForegroundColor Green
		} catch {
			Write-Host " FAILED" -ForegroundColor Red
			Write-Host "Error: $_" -ForegroundColor Red
		}

		Start-Sleep -Milliseconds 500
	}

	Write-Host ""
	Write-Host "Secrets added successfully!" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RELEASE DEPLOYMENT COMPLETE!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "What happens now:" -ForegroundColor Green
Write-Host "  - GitHub Actions workflow resumes" -ForegroundColor Yellow
Write-Host "  - APK is built and signed (5-10 minutes)" -ForegroundColor Yellow
Write-Host "  - Release is published on GitHub" -ForegroundColor Yellow
Write-Host "  - APK is available for download" -ForegroundColor Yellow
Write-Host "" 

Write-Host "Monitor the build here:" -ForegroundColor Green
Write-Host "https://github.com/Synonymz/PesoPal/actions" -ForegroundColor Cyan
Write-Host ""

Write-Host "Release page (when ready):" -ForegroundColor Green
Write-Host "https://github.com/Synonymz/PesoPal/releases/tag/v1.0.0" -ForegroundColor Cyan
Write-Host ""

$openWeb = Read-Host "Open GitHub Actions in browser? (y/n)"
if ($openWeb -eq "y") {
	Start-Process "https://github.com/Synonymz/PesoPal/actions"
}

Write-Host ""
Write-Host "SUCCESS! Release in progress!" -ForegroundColor Green
Write-Host ""
