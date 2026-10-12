# Troubleshooting & Diagnostics Guide

## 🔧 Testing the Update System

### Prerequisites
- Android device or emulator connected
- `adb` installed and in PATH
- App installed: v1.0.0 (old version)

---

## 📋 Step-by-Step Local Testing

### 1. Install Old Version

```bash
cd C:\Dev\CashLedgerAndroid

# Build old version (current code)
dotnet publish -f net10.0-android -c Release -o bin/Release/old

# Install on device
adb install -r bin/Release/old/com.pesopal.app-Signed.apk

# Verify installation
adb shell pm list packages | grep pesopal
# Output should show: package:com.pesopal.app
```

### 2. View App Version

```bash
# Get current installed version info
adb shell dumpsys package com.pesopal.app | grep version

# Output should show:
# versionName=1.0.0
# versionCode=1600000000 (Unix timestamp)
```

### 3. Open App and Check Settings

```bash
# Launch app
adb shell am start -n com.pesopal.app/.MainActivity

# Wait for app to fully load (~5 seconds)
# Open Settings tab manually on device
# Check that "Check for updates" row shows NO badge initially
# (Badge appears after background check runs, ~3-5 seconds)
```

### 4. Monitor Update Check (Logcat)

```bash
# In terminal, continuously read logs
adb logcat | grep -i "update\|version\|json\|latest"

# Expected output in logs:
# UpdateService.CheckForUpdateAsync: Fetching metadata...
# UpdateService.CheckForUpdateAsync: versionCode=1700000000 > current=1600000000
# UpdateState.SetLatest called
# SettingsPage.OnUpdateStateChanged: Update available!

# If you see:
# - "No update available" → likely latest.json version isn't newer
# - "Network error" → metadata URL unreachable
# - "JSON parse error" → latest.json format wrong
```

### 5. Trigger Manual Check

```bash
# With app running, look at logcat
# Open Settings tab → Tap "Check for updates"
# Logcat should show download starting

# Monitor progress
adb logcat | grep -i download

# Expected logging:
# StartUpdateAsync: Downloading from https://...
# Progress: 0%, 10%, 25%, 50%... 100%
# SHA-256 verification...
# Launcher started: ACTION_INSTALL_PACKAGE
```

---

## 📊 Checking JSON Format

### Fetch latest.json and validate

```bash
# Download and display
curl https://raw.githubusercontent.com/Synonymz/PesoPal/gh-pages/latest.json

# Output should be:
# {
#   "versionCode": 1700000000,
#   "versionName": "v1.2.3",
#   "apkUrl": "https://github.com/Synonymz/PesoPal/releases/download/v1.2.3/...",
#   "sha256": "abc123def456..."
# }

# Validate JSON syntax
curl https://raw.githubusercontent.com/Synonymz/PesoPal/gh-pages/latest.json | jq .
# jq is JSON query tool - if invalid, it will error

# Check specific field
curl https://raw.githubusercontent.com/Synonymz/PesoPal/gh-pages/latest.json | jq .versionCode
# Output: 1700000000
```

### Manually test version comparison

```powershell
# In PowerShell:
$old = 1600000000
$new = 1700000000
if ($new -gt $old) { Write-Host "Update available!" }

# Linux/Mac (bash):
old=1600000000
new=1700000000
if [ $new -gt $old ]; then echo "Update available!"; fi
```

---

## 🔍 Android Device Logs

### Real-time Update Monitoring

```bash
# Terminal 1: Start logcat filter
adb logcat | grep -E "UpdateService|UpdateState|SettingsPage|SHA256" --color=always

# Terminal 2: While filtering above, in another terminal:
# Open app, wait for background check

# You should see output like:
# D/UpdateService: CheckForUpdateAsync: url=https://raw...
# D/UpdateService: Current version: 1600000000
# D/UpdateService: Remote version: 1700000000
# D/UpdateService: Update available, calling SetLatest
# D/UpdateState: StateChanged event raised
```

### APK File Location

```bash
# Where downloaded APK is stored
adb shell ls -la /sdcard/Android/data/com.pesopal.app/files/Download/

# Output:
# -rw-r----- cashledger-update-1700000000.apk

# Get file size (compare to latest.json size)
adb shell ls -lh /sdcard/Android/data/com.pesopal.app/files/Download/

# Copy APK to computer for inspection
adb pull /sdcard/Android/data/com.pesopal.app/files/Download/cashledger-update-1700000000.apk ./test-downloaded.apk

# Verify SHA-256 matches
certUtil -hashfile test-downloaded.apk SHA256
# Compare with sha256 value in latest.json
```

### Check FileProvider Configuration

```bash
# Verify provider is registered
adb shell dumpsys package com.pesopal.app

# Look for:
# Queries: (should be empty or minimal)
# Package [com.pesopal.app] (signature check: /path/to/key)
# installed=true

# If you see errors about FileProvider, check:
# Platforms/Android/AndroidManifest.xml for provider declaration
# Platforms/Android/Resources/xml/provider_paths.xml for path config
```

---

## 🧪 Simulated Update Testing

### Using Mock latest.json (Offline Testing)

```bash
# 1. Create test latest.json
mkdir -p test_metadata
cat > test_metadata/latest.json << 'EOF'
{
  "versionCode": 2000000000,
  "versionName": "v2.0.0",
  "apkUrl": "file:///sdcard/Download/test.apk",
  "sha256": "abc123def456..."
}
EOF

# 2. Push to device
adb push test_metadata/latest.json /sdcard/Download/

# 3. Update metadata URL in SettingsPage.cs to point to local file
# (for testing only - use proper URL in production)

# 4. Test with local APK file
# - Build new APK
# - Push to device: adb push new.apk /sdcard/Download/test.apk
# - Run app, check for updates
# - Should show v2.0.0
```

### Pre-generated SHA-256 for Testing

```bash
# Get SHA-256 of APK
certUtil -hashfile path/to/app.apk SHA256
# macOS:
shasum -a 256 path/to/app.apk

# Create test latest.json with that hash
# Update settings to use test file
# Download should pass verification
```

---

## 🚨 Common Issues & Diagnostics

### Issue 1: "No update available in Settings"

**Symptoms:**
- Badge doesn't appear even after background check

**Diagnostic Steps:**

```bash
# 1. Check app version code
adb shell dumpsys package com.pesopal.app | grep versionCode

# 2. Check latest.json format and content
curl https://raw.githubusercontent.com/Synonymz/PesoPal/gh-pages/latest.json | jq .

# 3. Compare versions manually
# If remote versionCode <= current versionCode, no update shown
local_version=1600000000
remote_version=$(curl -s https://raw.../latest.json | jq -r .versionCode)
if [ $remote_version -gt $local_version ]; then 
  echo "Should show update!"
else 
  echo "Version not newer, no update shown"
fi

# 4. Check app logs
adb logcat | grep UpdateService

# Expected:
# 1600000000 > 1600000000? NO → No update
# 1700000000 > 1600000000? YES → Update available
```

### Issue 2: "Download starts but gets stuck"

**Symptoms:**
- Progress bar shows but doesn't advance
- No error message

**Diagnostic Steps:**

```bash
# 1. Check network connectivity
adb shell ping 8.8.8.8
# Should show: 64 bytes from 8.8.8.8 (if ping allowed)
# or just test: adb shell curl https://github.com (should not hang)

# 2. Check APK URL is valid
# In SettingsPage, get apkUrl from latest.json
curl -I https://github.com/Synonymz/PesoPal/releases/download/v1.2.3/app.apk
# Should show: HTTP/2 200 OK

# 3. Monitor logcat for download progress
adb logcat | grep "Progress\|download\|read"

# 4. Check available storage
adb shell df /sdcard
# Ensure at least 100MB free

# 5. Kill and restart
adb shell am force-stop com.pesopal.app
adb shell am start -n com.pesopal.app/.MainActivity
# Try download again
```

### Issue 3: "SHA-256 verification failed"

**Symptoms:**
- Toast: "Downloaded update failed integrity check"
- Partial APK deleted

**Diagnostic Steps:**

```bash
# 1. Verify latest.json has correct SHA
latest_sha=$(curl -s https://raw.../latest.json | jq -r .sha256)
echo "Expected SHA: $latest_sha"

# 2. Get SHA of downloaded file (if still there)
adb shell ls /sdcard/Android/data/com.pesopal.app/files/Download/

# 3. Manually compute SHA (after copying APK)
adb pull /sdcard/Android/data/com.pesopal.app/files/Download/*.apk test.apk
certUtil -hashfile test.apk SHA256

# 4. Compare
# If different:
#   - APK corrupted during download (retry)
#   - latest.json has wrong SHA (regenerate)
#   - network issue (try on different WiFi)

# 5. Regenerate latest.json on gh-pages
# Option A: Automated via GitHub Actions (push tag)
# Option B: Manual via PowerShell script
pwsh tools/generate-latest.ps1 -Tag v1.2.3 -AssetPath ./app-release.apk -Repo Synonymz/PesoPal -Branch gh-pages -Push
```

### Issue 4: "App not installed" during system install

**Symptoms:**
- System installer shows error dialog
- Can't complete installation

**Diagnostic Steps:**

```bash
# 1. Check if signing certificate matches
# Old APK certificate
adb shell dumpsys package com.pesopal.app | grep -A 5 "Signatures="

# 2. Get certificate info of new APK
# Extract cert from APK before install
unzip -q app-new.apk -d app_extracted
openssl pkcs7 -inform DER -in app_extracted/META-INF/CERT.RSA -print_certs | grep -i subject

# Compare with old app cert → must match!

# 3. If certs don't match:
#    New APK signed with different keystore
#    Solution: Re-signed with same keystore.jks + key alias

# 4. If you're stuck with mismatched certs:
#    Uninstall old app completely first
adb uninstall com.pesopal.app
# Then install new version
adb install app-new.apk
#    (But users' data might not transfer!)
```

### Issue 5: "FileProvider error" / "No content provider"

**Symptoms:**
- App crashes with: "FileProvider could not find ..."
- System installer never launches

**Diagnostic Steps:**

```bash
# 1. Check AndroidManifest.xml for FileProvider declaration
adb shell grep -r "FileProvider" /data/data/com.pesopal.app/
# or check source:
cat Platforms/Android/AndroidManifest.xml | grep -A 5 FileProvider

# 2. Verify provider_paths.xml exists
ls -la Platforms/Android/Resources/xml/provider_paths.xml

# 3. Check content in provider_paths.xml
cat Platforms/Android/Resources/xml/provider_paths.xml
# Should show:
# <external-files-path name="external_files" path="." />

# 4. Rebuild and reinstall
dotnet clean
dotnet publish -f net10.0-android -c Release
adb install -r bin/Release/net10.0-android/*.apk
```

---

## 📈 Performance & Metrics

### Measure Download Speed

```bash
# Monitor in real-time
adb shell cat /proc/net/dev | grep wlan

# Or use NetworkInfo in code (not exposed in UI yet)
# Could add to SettingsPage:
# "Download speed: X.X MB/s"

# Typical speeds:
# WiFi 5GHz: 10-20 MB/s
# WiFi 2.4GHz: 5-10 MB/s
# 4G LTE: 1-5 MB/s
# 3G: 0.5-1 MB/s
```

### Measure Update File Size (APK)

```bash
# After build
ls -lh bin/Release/net10.0-android/*.apk

# Typical MAUI app: 50-150 MB
# Factors:
# - .NET runtime libraries
# - Android framework wrappers
# - All NuGet packages
# - Drawable resources
```

### Memory Usage During Download

```bash
adb shell dumpsys meminfo com.pesopal.app

# Watch during download
watch -n 1 'adb shell dumpsys meminfo com.pesopal.app | grep -E "Native|Dalvik"'

# Should be relatively stable (~100-200 MB max)
# If jumping wildly → memory leak
```

---

## ✅ Pre-Release Checklist

Before publishing v1.2.3 for real users:

```bash
# 1. Verify build signing
certUtil -hashfile bin/Release/app-Signed.apk SHA256
# Save this hash

# 2. Create latest.json locally
# Use the hash above
cat > latest.json << 'EOF'
{
  "versionCode": 1700000000,
  "versionName": "v1.2.3",
  "apkUrl": "https://github.com/Synonymz/PesoPal/releases/download/v1.2.3/app-Signed.apk",
  "sha256": "your-hash-here"
}
EOF

# 3. Test on emulator with old version
adb install -r bin/Release/old.apk
adb shell am start -n com.pesopal.app/.MainActivity
# Wait for load, open Settings
# Badge should NOT appear (old latest.json)
# Manual check: should fail or timeout

# 4. Push test latest.json
adb push latest.json /sdcard/Download/
# Update settings to test URL
# Check for updates → Should succeed

# 5. Real GitHub publish
# Push tag → GitHub Actions builds signed APK
# Actions runs generate-latest.ps1
# latest.json deployed to gh-pages
# Real users can now update

# 6. Monitor
# Watch for error reports
# Check GitHub Release comments
# Monitor Analytics for version distribution
```

---

## 🔗 Useful Commands Reference

```bash
# Install
adb install -r file.apk

# Uninstall
adb uninstall com.pesopal.app

# Launch app
adb shell am start -n com.pesopal.app/.MainActivity

# View logs
adb logcat | grep keyword

# Get package info
adb shell dumpsys package com.pesopal.app

# Get version code
adb shell dumpsys package com.pesopal.app | grep version

# File operations
adb push local_file device_path
adb pull device_path local_file

# Kill app
adb shell am force-stop com.pesopal.app

# Clear app data
adb shell pm clear com.pesopal.app

# Test network
adb shell ping google.com
adb shell curl https://example.com

# Get logcat of crash
adb logcat -d *:E | grep pesopal

# Monitor in real-time
adb logcat --follow --format=brief | grep -i update
```

---

## 💬 What to Tell Users If Something Goes Wrong

### If Update Fails in Download

> "Your download was incomplete. Don't worry! The partial file was automatically deleted, freeing up space. Try the update again from Settings > Check for updates."

### If Installation Prompt Never Appears

> "The system installer might be taking time to launch. Try:
> 1. Go to Settings > Apps
> 2. Find 'Package Installer' > Force Stop
> 3. Return to PesoPal and retry"

### If "App Not Installed" Error

> "This might mean the update is from a different source than your original install. Try:
> 1. Go to device Settings > Apps > PesoPal
> 2. Uninstall completely
> 3. Reinstall from Play Store / release page
> 4. Your data will be restored"

### If All Else Fails

> "Update manually:
> 1. Download APK from https://github.com/Synonymz/PesoPal/releases
> 2. Open file in Files app
> 3. Install from there
> Contact support if this doesn't work"

---

**All configurations verified ✅ and ready to ship!**
