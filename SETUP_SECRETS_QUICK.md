# 🎯 SETUP SECRETS - ONE CLICK START

## ⚡ Quick Start (30 seconds)

### Option A: Automated (GitHub CLI)

```powershell
pwsh .\setup-github-secrets.ps1
```

**That's it!** The script handles everything.

---

### Option B: Manual (No CLI needed)

1. Open: https://github.com/Synonymz/PesoPal/settings/secrets/actions

2. Click: **"New repository secret"**

3. Add these 4 secrets:

```
ANDROID_KEYSTORE_PATH
├─ Copy entire content of: keystore-base64.txt
└─ Paste value

ANDROID_KEY_ALIAS
├─ Value: pesopa_key
└─ Click "Add secret"

ANDROID_KEY_PASSWORD
├─ Value: Francis
└─ Click "Add secret"

ANDROID_KEYSTORE_PASSWORD
├─ Value: Francis
└─ Click "Add secret"
```

---

## ✅ AFTER SETUP

Nothing else needed! 

**GitHub Actions automatically:**
- Builds APK
- Signs with keystore
- Creates Release
- Uploads APK
- Publishes latest.json

**Check progress:** https://github.com/Synonymz/PesoPal/actions

---

## 📦 FILES PROVIDED

| File | Purpose |
|------|---------|
| `setup-github-secrets.ps1` | Automated setup script |
| `keystore-base64.txt` | Encoded keystore (for manual setup) |
| `GITHUB_SECRETS_CONFIG.md` | Detailed configuration guide |

---

**Choose your path above and execute! 🚀**
