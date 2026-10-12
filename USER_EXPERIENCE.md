# User Experience - Update Flow

## 👤 A Typical User's Perspective

### Scenario: User installed PesoPal v1.0.0 two weeks ago. You just released v1.2.3 with new features.

---

## 📱 Timeline of Events

### **Day 1: User Opens App (unchanged features)**

```
┌─────────────────────────────────────┐
│  [Open PesoPal]                     │
│                                     │
│  "Loading PesoPal..."               │
│                                     │
│    [blue background]                │
│    [logo fades in + breathes]       │
│    P e s o P a l [cursor blinking] │
│    CASH LEDGER                      │
│    [spinner rotating]               │
│                                     │
│  ⏱️  Takes ~3-5 seconds             │
└─────────────────────────────────────┘
		 ↓
	[fade out]
		 ↓
┌─────────────────────────────────────┐
│  Home Tab                           │
│  ├─ Total: 50,000 PHP              │
│  ├─ [Cash In]  [Cash Out]          │
│  │                                 │
│  └─ Recent Transactions             │
│     2024-01-15  +1,000 PHP          │
│     2024-01-14  -500 PHP            │
└─────────────────────────────────────┘
		 ↓
	⏰ BACKGROUND: UpdateService checks
	   https://raw.githubusercontent.com/Synonymz/PesoPal/gh-pages/latest.json

	   Compares: latest versionCode (1700000000) vs current (1600000000)

	   Result: UPDATE AVAILABLE ✨
```

---

### **Same Time: Settings Tab Shows Update Available**

```
┌─────────────────────────────────────┐
│  Settings Tab 🔧                    │
│                                     │
│  ✓ About                            │
│  🔄 Check for updates  [UPDATE ✨]  │  ← Badge appears!
│                                     │
│  [Footer text]                      │
│  Version: 1.0.0                     │
│  Building cash ledger better...     │
└─────────────────────────────────────┘

🔔 User thinks: "Hmm, there's an update available. 
   Let me check what's new."
```

---

### **User Taps "Check for updates" Row**

```
┌─────────────────────────────────────┐
│  Settings Tab                       │
│                                     │
│  ✓ About                            │
│  🔄 Check for updates  [UPDATE ✨]  │
│       ↓ [User taps]                 │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Version 1.2.3 Available          ││
│  │                                  ││
│  │ What's New:                      ││
│  │ • New Dashboard Widget           ││
│  │ • Faster Transactions            ││
│  │ • Bug Fixes                      ││
│  │                                  ││
│  │ [Download & Install]             ││
│  │ [Later]                          ││
│  └─────────────────────────────────┘│
│                                     │
└─────────────────────────────────────┘

🤔 User thinks: "Nice! Dashboard widget sounds good. 
   Let me update."

   (Taps "Download & Install")
```

---

### **Download in Progress**

```
┌─────────────────────────────────────┐
│  Settings Tab                       │
│                                     │
│  ✓ About                            │
│  🔄 Downloading Update...           │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Downloading v1.2.3              ││
│  │                                  ││
│  │ ▓▓▓▓▓░░░░░░░░░░░░░░░ 32%        ││
│  │ [Speed: 2.5 MB/s]                ││
│  │ [8.2 / 25.6 MB]                  ││
│  │                                  ││
│  │ [Cancel]                         ││
│  └─────────────────────────────────┘│
│                                     │
│  Background: DL writes to           │
│  /sdcard/Android/data/              │
│   com.pesopal.app/files/Download/   │
│   cashledger-update-1700000000.apk  │
│                                     │
└─────────────────────────────────────┘

📊 User sees live download progress
   Can cancel anytime (file freed)
```

---

### **Download Complete - Verification**

```
┌─────────────────────────────────────┐
│  Settings Tab                       │
│                                     │
│  ✓ About                            │
│  🔄 Verifying Update...             │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Verifying integrity...          ││
│  │                                  ││
│  │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ 100%       ││
│  │ [SHA-256 Check: PASS ✓]         ││
│  │                                  ││
│  │ Launching installer...           ││
│  └─────────────────────────────────┘│
│                                     │
│  Background: Computes SHA256 hash   │
│  of downloaded APK, compares with   │
│  value from latest.json             │
│  ✓ Match → Continue                │
│  ✗ Mismatch → Delete file, error   │
│                                     │
└─────────────────────────────────────┘

✅ All checks pass
   System installer about to launch...
```

---

### **Android System Installer Prompt**

```
┌─────────────────────────────────────────┐
│  Install PesoPal?                       │
│                                         │
│  This will update PesoPal               │
│  from version 1.0.0 to 1.2.3            │
│                                         │
│  ⚠️  App data will be preserved         │
│                                         │
│  Permissions:                           │
│  • Files and media                      │
│  • Installation capability              │
│                                         │
│  [More info]    [Cancel] [Install]      │
│                                    ▲▲▲  │
│                              User taps  │
└─────────────────────────────────────────┘

🎯 This is ANDROID'S screen, not our app

   Key points shown:
   - Version upgrade 1.0.0 → 1.2.3
   - App data PRESERVED (user still has all transactions)
   - Permissions (same as before)
```

---

### **Installation in Progress**

```
┌──────────────────────────────────┐
│  Installing PesoPal...           │
│                                  │
│  ▓▓▓▓▓▓░░░░░░░░░░░░░░░ 65%      │
│                                  │
│  Step 1: Uninstall v1.0.0 ... ✓ │
│  Step 2: Install v1.2.3 ... ↻   │
│  Step 3: Ready              ... ⏳ │
└──────────────────────────────────┘

⚡ On the phone:
   1. Old version APK removed
   2. New version APK installed
   3. App database files preserved
   4. SharedPreferences preserved
```

---

### **Installation Complete - App Relaunches**

```
┌─────────────────────────────────────┐
│  Installation Complete              │
│                                     │
│  [Open App]   [Done]                │
│        ↓                            │
│    [User taps "Open App"]           │
└─────────────────────────────────────┘
		↓
┌─────────────────────────────────────┐
│  [Loading v1.2.3...]                │
│                                     │
│    [blue background]                │
│    [logo fades in + breathes]       │
│    P e s o P a l [cursor]          │
│    CASH LEDGER                      │
│    [spinner]                        │
│                                     │
│  ⏱️  ~3-5 seconds                   │
└─────────────────────────────────────┘
		↓
	[fade out]
		↓
┌─────────────────────────────────────┐
│  Home Tab  ← NEW VERSION 1.2.3      │
│                                     │
│  📊 [NEW] Dashboard Widget          │
│  ├─ Total: 50,000 PHP ✓ (preserved)│
│  ├─ [Cash In]  [Cash Out]          │
│  │                                 │
│  └─ Recent Transactions             │
│     2024-01-15  +1,000 PHP          │
│     2024-01-14  -500 PHP            │
│     ... all data still here! ✅     │
└─────────────────────────────────────┘

✨ User sees:
   1. New Dashboard Widget
   2. All transactions intact
   3. No data loss
   4. Faster app (promised feature)
```

---

### **User Checks Settings**

```
┌─────────────────────────────────────┐
│  Settings Tab 🔧                    │
│                                     │
│  ✓ About                            │
│  🔄 Check for updates               │  ← Badge GONE
│                                     │
│  [Footer text]                      │
│  Version: 1.2.3 ← Updated!          │
│  Building cash ledger better...     │
└─────────────────────────────────────┘

🎉 User thinks: "Perfect! 
   It kept all my data, and now I have 
   the new dashboard. Love it!"
```

---

## 🎬 Alternate Scenario: User Clicks "Later" on Update

```
┌─────────────────────────────────────┐
│  Settings Tab                       │
│                                     │
│  ✓ About                            │
│  🔄 Check for updates  [UPDATE ✨]  │  ← Badge STAYS
│                                     │
│  [Update available dialog]          │
│  • New Dashboard Widget             │
│  • [Download & Install]             │
│  • [Later]                          │
│        ↓ [Tap "Later"]              │
│                                     │
│  Dialog closes                      │
│  Badge remains, notification stays  │
└─────────────────────────────────────┘

⏳ What happens:
   - User goes back to using app normally
   - Next time they open Settings, badge still shows
   - Next restart: UpdateState checks again (same version available)
   - User can update whenever they want
   - Update NOT forced (optional, user-initiated)
```

---

## 🚫 Alternate Scenario: User Cancels During Download

```
┌─────────────────────────────────────┐
│  Downloading Update...              │
│                                     │
│  ▓▓▓▓▓░░░░░░░░░░░░░░░ 32%          │
│  [Speed: 2.5 MB/s]                  │
│  [8.2 / 25.6 MB]                    │
│                                     │
│  [Cancel]                           │
│      ↓ [Tap "Cancel"]               │
│                                     │
│  ⏹️  Download stopped               │
│  🗑️  Temp file deleted              │
│  📢 "Update cancelled"               │
└─────────────────────────────────────┘

What happens:
   - Partial APK in Downloads folder deleted
   - No wasted space
   - App continues running normally
   - Battery saved (no burning CPU)
   - Can retry update anytime from Settings
```

---

## 🔄 Scenario: Automatic Check on Next App Open (After Cancellation)

```
Day 3: User opens PesoPal again

1. LoadingPage shows (animated splash)
2. MauiProgram.cs starts background check
3. Fetches latest.json again
4. Same v1.2.3 still available
5. UpdateState.Latest updated
6. Settings tab badge appears again

User can tap "Check for updates" anytime
```

---

## 📊 Under the Hood - What's Actually Happening

### Connection Sequence

```
User Device                        GitHub
	 │                              │
	 │─────────────────────────────→│
	 │   HTTP GET latest.json       │
	 │                              │
	 │←─────────────────────────────│
	 │   JSON: v1.2.3 available     │
	 │   apkUrl, sha256, versionCode│
	 │                              │
	 ├─ Compare versionCode (1700000000 > 1600000000? YES)
	 ├─ UpdateState.SetLatest() called
	 ├─ SettingsPage.OnUpdateStateChanged() fires
	 ├─ UI badge appears ✨
	 │
	 │ [User taps "Check for updates"]
	 │
	 │─────────────────────────────→│
	 │   HTTP GET APK (resume-able) │
	 │   Content-Length: 25.6 MB    │
	 │                              │
	 │←─ 5MB ─|                     │
	 │  [progress bar updates]      │
	 │                              │
	 │←─ 10MB ─|                    │
	 │  [progress bar updates]      │
	 │                              │
	 │←─ 25.6MB ─| (complete)       │
	 │                              │
	 ├─ SHA256.ComputeHash(downloaded_apk)
	 ├─ Compare: hash vs latest.json sha256
	 │  ✓ MATCH
	 │
	 ├─ FileProvider.GetUriForFile()
	 ├─ Intent.SetData(content:// URI)
	 ├─ Context.StartActivity(installer intent)
	 │
	 │
	 └─ [Android System Installer takes over]
		└─ Prompts user: "Install?"
		   └─ Uninstalls old version
		   └─ Installs new version
		   └─ Relaunches app
		   └─ App reads from same database
		   └─ User sees v1.2.3 with old data intact
```

---

## 🔐 Security Checkpoints

```
Download Flow with Security

APK File                    Verification
	↓                           ↓
┌─────────────────────────────────────┐
│ 1. HTTPS (encrypted in transit)    │ ✅
│                                     │
│ 2. SHA-256 from latest.json         │ ✅
│    Downloaded APK hash compared     │
│    If mismatch → DELETE & ERROR     │
│                                     │
│ 3. Same Signing Certificate         │ ✅
│    Old APK cert must match new APK  │
│    Android enforces this            │
│    If different → Installation fails│
│                                     │
│ 4. FileProvider (Android 7+)        │ ✅
│    content:// URI instead of file://│
│    Only app-specific Downloads      │
│    folder accessible                │
│                                     │
│ 5. User Approval                    │ ✅
│    System installer shows version   │
│    User can review / cancel anytime │
│                                     │
└─────────────────────────────────────┘

Result: Tampered APK cannot be installed
		Corrupted APK rejected by hash
		Only authorized updates work
```

---

## 📱 What User Data Is Preserved?

```
After Update: v1.0.0 → v1.2.3

✅ PRESERVED ON UPGRADE:
   ├─ All transactions in SQLite DB
   ├─ App settings (store name, fees)
   ├─ Backup files (if stored in scoped storage)
   ├─ User preferences
   └─ All app data

❌ NOT AFFECTED:
   ├─ Other apps on phone
   ├─ System settings
   ├─ Photos, videos, documents
   └─ Phone storage

📍 WHERE DATA STORED:
   /data/data/com.pesopal.app/
   ├─ databases/cashledger.db3 (SQLite)
   ├─ shared_prefs/... (Android preferences)
   └─ files/... (app-specific files)

   This directory is NOT touched during update
   Old app uninstalled first (data still there)
   New app installed to same directory
   Android automatically links data back
   Result: User sees all their data!
```

---

## 💡 Pro Tips for Users

### Before Updating
- ✅ Ensure WiFi connected (25+ MB download)
- ✅ Battery > 20%
- ✅ Space available: ~50 MB free

### During Updating
- ✅ Don't force-close app during update
- ✅ Can see progress bar percentage
- ✅ Can cancel anytime (file cleaned up)

### After Updating
- ✅ All data preserved
- ✅ No setup needed
- ✅ Use app normally
- ✅ Check "About" to see new version number

### If Something Goes Wrong
```
Issue: "App not installed" error
Solution: 
  1. Wait 5 minutes (sometimes retry works)
  2. Go to Settings > Apps > Show System > 
	 Delete "PesoPal (old version if multiple)"
  3. Retry update
  4. Contact support if still fails

Issue: Update slow
Solution:
  1. Check WiFi connection speed
  2. Try again later (server might be busy)
  3. Download overnight

Issue: After update, "No data"
Solution: VERY RARE - database might corrupt
  1. Reinstall app
  2. Restore from backup (if you have one)
  3. Contact support with screenshot
```

---

## ✅ Update Success Checklist (From User Perspective)

User should see this ✓ each step:

- [ ] ✓ App loads with new version number
- [ ] ✓ All transactions still visible
- [ ] ✓ Store name still correct
- [ ] ✓ Fee settings intact
- [ ] ✓ New features work (Dashboard Widget)
- [ ] ✓ App performance same or better
- [ ] ✓ Can still do Cash In / Cash Out
- [ ] ✓ History tab shows old transactions
- [ ] ✓ Settings show v1.2.3

If any of these ✗, something went wrong - contact support.

---

**That's the complete user journey! 🎉**

From checking for updates to using new features—all their data intact.
