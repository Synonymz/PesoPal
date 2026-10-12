<#
PrepareIcon.ps1
Usage: .\Tools\PrepareIcon.ps1 -Source "C:\Users\you\Downloads\10.png"

This script copies your source image into the project as the app icon and splash (loading.png)
and, if ImageMagick (magick) is installed, produces common Android densities and a Play Store
512x512 PNG. If ImageMagick is not present it will only copy the source file.
#>
param(
	[Parameter(Mandatory=$true)]
	[string]$Source
)

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$projectRoot = Resolve-Path "$root\.."
$projectRoot = $projectRoot.Path

$appIconDir = Join-Path $projectRoot "Resources\AppIcon"
$splashDir = Join-Path $projectRoot "Resources\Splash"

if (!(Test-Path $Source)) {
	Write-Error "Source file not found: $Source"
	exit 1
}

# Ensure directories
New-Item -ItemType Directory -Path $appIconDir -Force | Out-Null
New-Item -ItemType Directory -Path $splashDir -Force | Out-Null

$destApp = Join-Path $appIconDir "loading.png"
$destSplash = Join-Path $splashDir "loading.png"

Copy-Item -Path $Source -Destination $destApp -Force
Copy-Item -Path $Source -Destination $destSplash -Force

Write-Host "Copied source to: $destApp and $destSplash"

# If ImageMagick is available, generate density variants
$magick = Get-Command magick -ErrorAction SilentlyContinue
if ($null -ne $magick) {
	Write-Host "ImageMagick found. Generating resized icons..."
	$sizes = @(
		@{Name='ldpi'; Size=36},
		@{Name='mdpi'; Size=48},
		@{Name='hdpi'; Size=72},
		@{Name='xhdpi'; Size=96},
		@{Name='xxhdpi'; Size=144},
		@{Name='xxxhdpi'; Size=192}
	)
	foreach ($s in $sizes) {
		$out = Join-Path $appIconDir "icon_$($s.Name).png"
		magick convert "$destApp" -resize ${s.Size}x${s.Size} "$out"
		Write-Host "Wrote $out"
	}

	# Play Store 512x512
	$play = Join-Path $projectRoot "PlayStoreIcon"
	New-Item -ItemType Directory -Path $play -Force | Out-Null
	$playOut = Join-Path $play "icon_512.png"
	magick convert "$destApp" -resize 512x512 "$playOut"
	Write-Host "Wrote Play Store icon: $playOut"
} else {
	Write-Warning "ImageMagick (magick) not found in PATH. Skipping automated resizing. Install ImageMagick or run your own image tool to produce required densities."
}

Write-Host "PrepareIcon finished. Rebuild the project in Visual Studio to let Resizetizer generate platform assets."
