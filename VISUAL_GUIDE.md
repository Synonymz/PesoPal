# Update Flow - Visual Quick Reference

## 🔄 The Complete Update Cycle

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  PHASE 1: STARTUP CHECK (Automatic, runs in background)   ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

  User opens PesoPal v1.0.0
		 ↓
  LoadingPage shows animated splash
  (3-5 seconds parallel: animation + database init)
		 ↓
  App fully loads with AppShell
		 ↓
  BACKGROUND: MauiProgram.cs runs:

  ┌─────────────────────────────────────────┐
  │ Task.Run(async () => {                  │
  │   var info = await updater              │
  │     .CheckForUpdateAsync(               │
  │       "https://raw.githubusercontent.. │
  │        /Synonymz/PesoPal/gh-pages/     │
  │        latest.json"                     │
  │     );                                  │
  │   state.SetLatest(info);                │
  │ })                                      │
  └─────────────────────────────────────────┘
		 ↓
  HTTP GET https://raw.githubusercontent.com/Synonymz/PesoPal/gh-pages/latest.json
		 ↓
  ┌─────────────────────────────────────────────────────────┐
  │ Response:                                               │
  │ {                                                       │
  │   "versionCode": 1700000000,    ← Latest version       │
  │   "versionName": "v1.2.3",                             │
  │   "apkUrl": "https://github.../app.apk",              │
  │   "sha256": "abc123def456..."                          │
  │ }                                                       │
  └─────────────────────────────────────────────────────────┘
		 ↓
  UpdateService.CheckForUpdateAsync() compares:

  ┌─────────────────────────────────────────┐
  │ Current versionCode: 1600000000         │
  │ Latest versionCode:  1700000000         │
  │                                         │
  │ 1700000000 > 1600000000?                │
  │            YES! ✓                       │
  └─────────────────────────────────────────┘
		 ↓
  UpdateState.SetLatest(new UpdateInfo(...))
		 ↓
  StateChanged event raises
		 ↓
  SettingsPage.OnUpdateStateChanged() runs
		 ↓
  Badge appears: "CHECK FOR UPDATES [UPDATE ✨]"

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  PHASE 2: USER INITIATES DOWNLOAD (Manual action)         ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

  User sees badge → taps "Check for updates" row
		 ↓
  Dialog shows: "Version 1.2.3 Available"
  User taps: [Download & Install]
		 ↓
  SettingsPage.CheckForUpdateAsync() called
		 ↓
  UpdateService.StartUpdateAsync(UpdateInfo info)
		 ↓
  ┌─────────────────────────────────────────────────┐
  │ _cts = new CancellationTokenSource();           │
  │ fileName = "cashledger-update-1700000000.apk"   │
  │ dest = /sdcard/Android/data/                    │
  │        com.pesopal.app/files/Download/          │
  │        cashledger-update-1700000000.apk         │
  └─────────────────────────────────────────────────┘
		 ↓
  HTTP GET info.ApkUrl (resumable, with progress)
		 ↓
  ┌─────────────────────────────────────────────────┐
  │ Download Progress Loop:                         │
  │ ▓░░░░░░ (10%)  → SetProgress(10)               │
  │ ▓▓▓▓░░░ (45%)  → SetProgress(45)               │
  │ ▓▓▓▓▓▓░ (85%)  → SetProgress(85)               │
  │ ▓▓▓▓▓▓▓ (100%) → Download complete            │
  │                                                │
  │ Can cancel anytime:                            │
  │ _cts.Cancel() → Stop download               │
  │              → Delete partial APK            │
  │              → Return to Settings            │
  └─────────────────────────────────────────────────┘
		 ↓
  Download complete, file at:
  /sdcard/Android/data/com.pesopal.app/files/Download/
				  cashledger-update-1700000000.apk

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  PHASE 3: VERIFICATION (Automatic, before install)        ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

  if (info.Sha256 != null) {
		 ↓
	SHA256.ComputeHash(downloaded_apk)
		 ↓
	┌────────────────────────────────┐
	│ Downloaded file:               │
	│ HASH = abc123def456...         │
	│                                │
	│ Expected from latest.json:     │
	│ HASH = abc123def456...         │
	│                                │
	│ Match? → YES ✓ Continue      │
	│ Match? → NO ✗ Delete, Error   │
	└────────────────────────────────┘
  }
		 ↓
  if (hash mismatch) {
	Toast.MakeText("Integrity check failed")
	File.Delete(apk_path)
	return  // STOP - do not install
  }
		 ↓
  Hash verified ✓

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  PHASE 4: INSTALLATION PROMPT (System action)             ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

  FileProvider.GetUriForFile(
	context,
	"com.pesopal.app.fileprovider",
	apk_file
  )
  → Returns: content://com.pesopal.app.fileprovider/...

  (Note: NOT file:// URI - Android 7+ requires content://)
		 ↓
  Intent intent = new Intent(Intent.ActionInstallPackage);
  intent.SetData(apkUri);
  intent.AddFlags(ActivityFlags.GrantReadUriPermission);
  context.StartActivity(intent);
		 ↓
  ┌──────────────────────────────────────────┐
  │  [ANDROID SYSTEM INSTALLER DIALOG]       │
  │                                          │
  │  Install PesoPal?                        │
  │                                          │
  │  This will update PesoPal                │
  │  from 1.0.0 to 1.2.3                    │
  │                                          │
  │  App data will be preserved ✓            │
  │                                          │
  │  [Cancel]            [Install]           │
  │                         ↓                │
  │                    [User taps]           │
  └──────────────────────────────────────────┘
		 ↓
  ⚠️  CRITICAL CHECK:

  ┌─────────────────────────────────────────┐
  │ Does new APK have SAME signing cert?    │
  │                                         │
  │ Old: signed with pesopa.keystore        │
  │ New: signed with pesopa.keystore        │
  │                                         │
  │ YES → Continue (upgrade)                │
  │ NO → FAIL: "App not installed"          │
  └─────────────────────────────────────────┘

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  PHASE 5: UNINSTALL + INSTALL (Android handles)           ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

  Android runs:

  ┌─────────────────────────────────────┐
  │ Step 1: Uninstall PesoPal v1.0.0    │
  │         (Remove APK, keep data)     │
  │         ✓ Completed                 │
  │                                     │
  │ Step 2: Install PesoPal v1.2.3      │
  │         (Install new APK)           │
  │         ✓ Completed                 │
  │                                     │
  │ Step 3: Link data                   │
  │         (Relink SQLite database,    │
  │          SharedPreferences, etc.)   │
  │         ✓ Completed                 │
  │                                     │
  │ Installation Complete!              │
  │ ┌─────────────────────────────────┐ │
  │ │ [Open App]     [Done]            │ │
  │ └─────────────────────────────────┘ │
  └─────────────────────────────────────┘
		 ↓
  User taps: [Open App]

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  PHASE 6: APP LAUNCHES WITH NEW VERSION                   ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

  PesoPal v1.2.3 starts
		 ↓
  ┌─────────────────────────────┐
  │  [Loading v1.2.3...]        │
  │                             │
  │    [animated splash]        │
  │                             │
  │  ⏱️  ~3-5 seconds          │
  └─────────────────────────────┘
		 ↓
  LoadingPage animation runs
  LedgerDatabase.InitializeAsync() runs (parallel)
		 ↓
  Both complete
		 ↓
  App switches to AppShell
		 ↓
  ┌──────────────────────────────────────┐
  │  Home Tab (v1.2.3 with old data)    │
  │                                      │
  │  📊 [NEW] Dashboard Widget            │
  │                                      │
  │  Total: 50,000 PHP  ✓ (from old DB) │
  │  Latest Transactions:                │
  │  • 2024-01-15  +1,000 PHP            │
  │  • 2024-01-14  -500 PHP              │
  │  • ... all old data preserved! ✅   │
  │                                      │
  │  ✨ New features available           │
  │  ✨ All old data intact              │
  │  ✨ No setup needed                  │
  └──────────────────────────────────────┘
		 ↓
  User checks Settings:

  ┌──────────────────────────────────────┐
  │  Settings Tab                        │
  │                                      │
  │  ✓ About                             │
  │  🔄 Check for updates                │  ← Badge GONE
  │                                      │
  │  Version: 1.2.3  ✓                   │
  └──────────────────────────────────────┘
		 ↓
  ✅ UPDATE COMPLETE!

```

---

## ⏱️ Timeline

```
T=0:00    User taps "Check for updates"
		  └─ Settings: "Downloading Update..."

T=0:05    Download starts
		  └─ Progress: ▓░░ (10%)

T=0:15    Download progressing
		  └─ Progress: ▓▓▓▓░ (45%)

T=0:25    Download near complete
		  └─ Progress: ▓▓▓▓▓▓░ (80%)

T=0:30    Download 100% complete
		  └─ "Verifying integrity..."

T=0:35    SHA-256 verified ✓
		  └─ "Launching installer..."

T=0:40    System installer appears
		  └─ User sees: "Install v1.2.3?"

T=0:45    User taps [Install]
		  └─ Uninstall old version...

T=0:50    Old version uninstalled
		  └─ Install new version...

T=0:55    New version installed
		  └─ [Open App]

T=1:00    User taps [Open App]
		  └─ v1.2.3 launches

T=1:05    LoadingPage animation
		  └─ Database init in background

T=1:10    Animation + DB complete
		  └─ App switches to AppShell

T=1:15    ✅ UserFull app loaded with new version!
		  └─ Timeline: ~1 minute 15 seconds total
```

---

## 🎛️ Control Flow Diagram

```
┌──────────────────────────────────────────────────────────┐
│                      MauiProgram                         │
│                      .CreateMauiApp()                    │
└──────────┬───────────────────────────────────────────────┘
		   │
		   ├─→ Batteries_V2.Init() [SQLite native]
		   │
		   ├─→ builder.Services.AddSingleton<LedgerDatabase>()
		   │
		   ├─→ builder.Services.AddSingleton<UpdateState>()
		   │
		   ├─→ #if ANDROID
		   │   builder.Services.AddSingleton<IUpdateService, UpdateService>()
		   │
		   ├─→ app = builder.Build()
		   │
		   └─→ #if ANDROID
			   _ = Task.Run(async () =>
			   {
				   var state = Services.GetService<UpdateState>();
				   var updater = Services.GetService<IUpdateService>();

				   if (updater != null && state != null)
				   {
					   var info = await updater.CheckForUpdateAsync(
						   "https://raw.githubusercontent.com/Synonymz/PesoPal/gh-pages/latest.json"
					   );
					   state.SetLatest(info);  // Badge appears in Settings
				   }
			   });

┌──────────────────────────────────────────────────────────┐
│                   App.xaml.cs                            │
│            CreateWindow(IActivationState?)               │
└──────────┬───────────────────────────────────────────────┘
		   │
		   └─→ return new Window(new LoadingPage());

┌──────────────────────────────────────────────────────────┐
│                  LoadingPage.cs                          │
│             PlayIntroAsync() starts immediately          │
└──────────┬───────────────────────────────────────────────┘
		   │
		   ├─→ Logo FadeTo + ScaleTo (600ms)
		   │
		   ├─→ Start breathing pulse (background Task)
		   │
		   ├─→ Typewriter effect for "PesoPal" (1.2s)
		   │   • Blinking cursor animation
		   │
		   ├─→ Fade in subtitle + spinner (400ms)
		   │
		   └─→ Return (animation complete)

┌──────────────────────────────────────────────────────────┐
│                  App.xaml.cs (parallel)                  │
│            InitializeAppAsync(LedgerDatabase)            │
└──────────┬───────────────────────────────────────────────┘
		   │
		   ├─→ Get LoadingPage from window
		   │
		   ├─→ introTask = loading?.PlayIntroAsync()
		   │
		   ├─→ dbTask = database.InitializeAsync()
		   │
		   ├─→ await Task.WhenAll(introTask, dbTask)
		   │   • Waits for BOTH to complete
		   │   • One of them takes longer
		   │
		   ├─→ await loading?.StopAndFadeOutAsync()
		   │   • Cancel breathing animation
		   │   • Fade page to 0 opacity
		   │
		   ├─→ CancelAnimations(loading)
		   │
		   ├─→ Application.Current.Windows[0].Page = new AppShell()
		   │
		   └─→ Success ✓

┌──────────────────────────────────────────────────────────┐
│                  SettingsPage.cs                         │
│            OnAppearing() / OnUpdateStateChanged()        │
└──────────┬───────────────────────────────────────────────┘
		   │
		   ├─→ _state.Latest != null?
		   │   ├─ YES → Show badge [UPDATE ✨]
		   │   └─ NO → Show normal row
		   │
		   ├─→ User taps row
		   │   └─→ CheckForUpdateAsync()
		   │       ├─→ updater.CheckForUpdateAsync(url)
		   │       │   └─→ UpdateState.Latest populated
		   │       │
		   │       └─→ If update available:
		   │           updater.StartUpdateAsync(info)
		   │           ├─→ Download with progress
		   │           ├─→ SHA-256 verify
		   │           └─→ Launch installer
		   │
		   └─→ _state.StateChanged event
			   ├─→ Show/hide progress overlay
			   ├─→ Update progress bar %
			   ├─→ Show result toast on complete

┌──────────────────────────────────────────────────────────┐
│              UpdateService.cs (Android)                  │
│            CheckForUpdateAsync(metadataUrl)              │
└──────────┬───────────────────────────────────────────────┘
		   │
		   ├─→ HTTP GET metadataUrl
		   │
		   ├─→ Parse JSON
		   │   {
		   │     "versionCode": 1700000000,
		   │     "versionName": "v1.2.3",
		   │     "apkUrl": "https://...",
		   │     "sha256": "abc123..."
		   │   }
		   │
		   ├─→ GetPackageInfo() → currentVersionCode
		   │
		   ├─→ if (remoteVersionCode > currentVersionCode)
		   │   ├─ YES → return UpdateInfo(...)
		   │   │        state.SetLatest() → badge shown
		   │   └─ NO → return null (no update)
		   │
		   └─→ Always catch exceptions silently

┌──────────────────────────────────────────────────────────┐
│              UpdateService.cs (Android)                  │
│             StartUpdateAsync(UpdateInfo info)            │
└──────────┬───────────────────────────────────────────────┘
		   │
		   ├─→ Create dest = /sdcard/.../Download/apk
		   │
		   ├─→ HTTP GET info.ApkUrl (resumable)
		   │
		   ├─→ While reading:
		   │   └─→ SetProgress((bytes_read / total) * 100)
		   │       └─→ UI progress bar updates
		   │
		   ├─→ Download complete
		   │
		   ├─→ if (info.Sha256 != null)
		   │   ├─→ Compute SHA256
		   │   ├─→ if (match) continue
		   │   └─→ if (mismatch) delete + error
		   │
		   ├─→ FileProvider.GetUriForFile()
		   │   └─→ Returns content:// URI
		   │
		   ├─→ Intent intent = ACTION_INSTALL_PACKAGE
		   │
		   ├─→ intent.SetData(uri)
		   │
		   ├─→ context.StartActivity(intent)
		   │   └─→ System installer launches
		   │
		   └─→ NotifyResult("Update downloaded", true)

└─→ Android System Installer ⟷ User ⟷ Install/Cancel
	└─→ If Install: uninstall old + install new
		└─→ v1.2.3 launches
			└─→ App.xaml.cs → LoadingPage → AppShell
				└─→ ✅ All data intact!
```

---

## 📌 Key Checkpoints

```
✓ LoadingPage compiles and animates
  └─ No Span.ForegroundColor errors
  └─ Source="pesopal_logo.svg" resolves correctly

✓ MauiProgram registers UpdateState & UpdateService
  └─ DI container populated
  └─ Background check Task.Run started

✓ UpdateService.CheckForUpdateAsync works
  └─ HTTP GET latest.json succeeds
  └─ JSON parsing succeeds
  └─ Version comparison logic correct

✓ SettingsPage shows badge when update available
  └─ StateChanged event fires
  └─ UI refreshes

✓ FileProvider configured correctly
  └─ AndroidManifest.xml declared
  └─ provider_paths.xml references external-files-path

✓ GitHub Actions workflow triggered on tag push
  └─ Builds & signs APK
  └─ Creates release
  └─ Runs generate-latest.ps1
  └─ Pushes latest.json to gh-pages

✓ latest.json accessible & valid
  └─ Format correct
  └─ SHA-256 matches APK
  └─ URL parseable
```

---

**This is the complete update system! 🎉**
