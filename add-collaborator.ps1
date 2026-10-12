# Add GitHub Collaborator Script

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Add GitHub Collaborator - Admin Access" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "This script will add irumasama28-art as Admin" -ForegroundColor Yellow
Write-Host ""

# Get GitHub token
Write-Host "You need a GitHub Personal Access Token with 'admin:org_hook' and 'repo' scopes" -ForegroundColor Yellow
Write-Host ""
Write-Host "Get token from: https://github.com/settings/tokens" -ForegroundColor Cyan
Write-Host ""

$token = Read-Host "Paste your GitHub Personal Access Token"

if ([string]::IsNullOrEmpty($token)) {
	Write-Host "No token provided. Exiting." -ForegroundColor Red
	exit 1
}

Write-Host ""
Write-Host "Testing authentication..." -ForegroundColor Yellow

$headers = @{
	"Authorization" = "Bearer $token"
	"Accept" = "application/vnd.github.v3+json"
	"Content-Type" = "application/json"
}

try {
	$userTest = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers
	Write-Host "Authenticated as: $($userTest.login)" -ForegroundColor Green
} catch {
	Write-Host "Authentication failed!" -ForegroundColor Red
	Write-Host "Error: $($_)" -ForegroundColor Red
	exit 1
}

Write-Host ""
Write-Host "Adding irumasama28-art as Admin..." -ForegroundColor Yellow
Write-Host ""

$body = @{
	permission = "admin"
} | ConvertTo-Json

try {
	$response = Invoke-RestMethod `
		-Uri "https://api.github.com/repos/Synonymz/PesoPal/collaborators/irumasama28-art" `
		-Headers $headers `
		-Method Put `
		-Body $body

	Write-Host "SUCCESS! Invitation sent!" -ForegroundColor Green
	Write-Host ""
	Write-Host "Details:" -ForegroundColor Cyan
	Write-Host "  Username: irumasama28-art" -ForegroundColor Gray
	Write-Host "  Permission: Admin" -ForegroundColor Gray
	Write-Host "  Status: Awaiting acceptance" -ForegroundColor Gray
	Write-Host ""
	Write-Host "Next steps:" -ForegroundColor Yellow
	Write-Host "  1. irumasama28-art will receive an email invitation" -ForegroundColor Gray
	Write-Host "  2. They need to accept the invitation" -ForegroundColor Gray
	Write-Host "  3. Once accepted, they'll have full admin access" -ForegroundColor Gray

} catch {
	Write-Host "FAILED to add collaborator!" -ForegroundColor Red
	Write-Host "Error: $_" -ForegroundColor Red
	exit 1
}

Write-Host ""
