param(
	[Parameter(Mandatory=$true)]
	[string]$Tag,
	[Parameter(Mandatory=$true)]
	[string]$AssetPath,
	[string]$Repo = "Synonymz/PesoPal",
	[string]$Branch = "gh-pages",
	[switch]$Push,
	[switch]$UploadRelease
)

function Write-Log($msg) { Write-Host "[generate-latest] $msg" }

if (-not (Test-Path $AssetPath)) { Write-Error "Asset file not found: $AssetPath"; exit 2 }

# compute sha256
$hash = Get-FileHash -Path $AssetPath -Algorithm SHA256 | Select-Object -ExpandProperty Hash
$hash = $hash.ToLowerInvariant()

# build filename
$fileName = Split-Path -Path $AssetPath -Leaf

# build release download URL
$apkUrl = "https://github.com/$Repo/releases/download/$Tag/$fileName"

$versionCode = [int](Get-Date -UFormat %s)
$versionName = $Tag

$obj = @{ versionCode = $versionCode; versionName = $versionName; apkUrl = $apkUrl; sha256 = $hash }
$json = $obj | ConvertTo-Json -Depth 5

$tmp = [IO.Path]::GetTempFileName()
Set-Content -Path $tmp -Value $json -Encoding UTF8

Write-Log "Generated latest.json content:`n$json"

if ($Push)
{
	Write-Log "Preparing to push latest.json to gh-pages branch of $Repo"
	$repoUrl = "https://github.com/$Repo.git"
	$work = Join-Path -Path (Get-Location) -ChildPath "gh-pages-work"
	if (Test-Path $work) { Remove-Item $work -Recurse -Force }
	git clone --branch $Branch $repoUrl $work
	if ($LASTEXITCODE -ne 0) { Write-Error "git clone failed"; exit 3 }
	Copy-Item -Path $tmp -Destination (Join-Path $work "latest.json") -Force
	Push-Location $work
	git add latest.json
	git commit -m "Update latest.json for $Tag"
	git push origin $Branch
	if ($LASTEXITCODE -ne 0) { Write-Error "git push failed"; Pop-Location; exit 4 }
	Pop-Location
	Write-Log "Pushed latest.json to $Repo $Branch"
}
else
{
	Write-Log "latest.json written to: $tmp"
}

if ($UploadRelease)
{
	Write-Log "Uploading asset to GitHub release for tag $Tag"
	$token = $env:GITHUB_TOKEN
	if ([string]::IsNullOrEmpty($token)) { Write-Error "GITHUB_TOKEN not set in environment"; exit 5 }

	$apiBase = "https://api.github.com/repos/$Repo"
	# find release by tag
	$release = Invoke-RestMethod -Headers @{ Authorization = "token $token"; Accept = 'application/vnd.github.v3+json' } -Uri "$apiBase/releases/tags/$Tag" -Method Get
	if ($null -eq $release) { Write-Error "Release for tag $Tag not found"; exit 6 }

	$uploadUrl = $release.upload_url -replace "\{.*\}", ""

	# Prepare query name parameter
	$uploadUrlWithName = "$uploadUrl?name=$fileName"

	Write-Log "Uploading $fileName to $uploadUrlWithName"
	$bytes = [System.IO.File]::ReadAllBytes($AssetPath)
	$uri = [System.Uri]::EscapeUriString($uploadUrlWithName)
	$resp = Invoke-RestMethod -Headers @{ Authorization = "token $token"; Accept = 'application/vnd.github.v3+json' } -Uri $uri -Method Post -ContentType "application/octet-stream" -Body $bytes
	if ($null -eq $resp) { Write-Error "Upload failed"; exit 7 }
	Write-Log "Upload succeeded"
}
