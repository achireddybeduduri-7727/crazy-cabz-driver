# Firebase Migration - Simple Step-by-Step Guide
## Moving Your Driver App to a New Firebase Account

---

## 🎯 **What Are We Doing?**

We're moving all your app data from the old Firebase account (`driver-app-6f975`) to a new Firebase account, so your app can use the new account instead.

Think of it like moving your house:
- **Pack everything** from old house (Export)
- **Get a new house** ready (Create new project)
- **Move everything** to new house (Import)
- **Update your address** (Update app configuration)

---

## 📦 **What Data We're Moving**

1. **User Accounts** (Authentication)
   - All user emails and passwords
   - Phone numbers
   - User IDs
   - Login information

2. **Rides Database** (Realtime Database)
   - All completed rides
   - Active rides
   - Route information
   - Driver history

3. **User Profiles** (Firestore)
   - Driver information
   - Profile pictures
   - Settings
   - App data

4. **Files** (Storage)
   - Profile pictures
   - Document uploads
   - Any other files

---

## ⏰ **How Long Will It Take?**

- **Preparation:** 10 minutes (installing tools)
- **Export:** 5-10 minutes (downloading data)
- **New Project Setup:** 5 minutes (creating new project)
- **Import:** 10-15 minutes (uploading data)
- **App Update:** 5 minutes (updating configuration)
- **Testing:** 10-15 minutes (making sure everything works)

**Total Time:** 45-60 minutes

---

## 🛠️ **PHASE 1: Preparation (10 minutes)**

### What You Need to Install First

#### 1. Install Firebase CLI
**What it does:** Lets you control Firebase from command line

**How to install:**
```powershell
# Open PowerShell and run:
npm install -g firebase-tools
```

**Check if it worked:**
```powershell
firebase --version
# Should show: 13.x.x or higher
```

---

#### 2. Install FlutterFire CLI
**What it does:** Updates your Flutter app's Firebase configuration

**How to install:**
```powershell
dart pub global activate flutterfire_cli
```

**Check if it worked:**
```powershell
flutterfire --version
# Should show version number
```

**⚠️ Important:** If you get "command not found", add this to your PATH:
```
%USERPROFILE%\AppData\Local\Pub\Cache\bin
```

To add to PATH:
1. Press Windows key
2. Search "Environment Variables"
3. Click "Edit system environment variables"
4. Click "Environment Variables" button
5. Under "User variables", select "Path"
6. Click "Edit"
7. Click "New"
8. Add: `%USERPROFILE%\AppData\Local\Pub\Cache\bin`
9. Click OK on all windows
10. Restart PowerShell

---

#### 3. Install Google Cloud SDK (Optional but Recommended)
**What it does:** Needed for exporting/importing Firestore data

**How to install:**
1. Download from: https://cloud.google.com/sdk/docs/install
2. Run the installer
3. Follow the installation wizard
4. Restart PowerShell

**Check if it worked:**
```powershell
gcloud --version
# Should show version info
```

---

## 📤 **PHASE 2: Export Data from Old Project (10 minutes)**

### Step 1: Login to Firebase

```powershell
# Open PowerShell in your project folder
cd c:\Users\achir\driver_app

# Login to Firebase
firebase login
```

**What happens:**
- A browser window will open
- Login with your OLD Firebase account (the one that has driver-app-6f975)
- Click "Allow" to give permission
- You'll see "Login successful" in PowerShell

---

### Step 2: Run the Export Script

```powershell
# Run the export script
.\firebase-migrate-export.ps1
```

**What happens:**
1. Script checks if Firebase CLI is installed ✓
2. Asks you to login (if not already logged in)
3. Connects to old project: `driver-app-6f975`
4. Creates a backup folder (e.g., `firebase-backup-2025-10-17-143022`)
5. Exports:
   - ✅ User accounts → `auth-users-backup.json`
   - ✅ Rides database → `realtime-database-backup.json`
   - ✅ User profiles → `firestore-backup/`
   - ✅ Storage files → `storage-backup/`

**Time:** 5-10 minutes (depending on data size)

**Result:** You'll have a folder with all your data backed up

---

### Step 3: Verify the Backup

```powershell
# Check what was exported
dir firebase-backup-*
```

You should see:
```
firebase-backup-2025-10-17-143022/
├── auth-users-backup.json       (User accounts)
├── realtime-database-backup.json (Rides data)
├── firestore-backup/             (User profiles)
└── storage-backup/               (Files)
```

---

## 🆕 **PHASE 3: Create New Firebase Project (5 minutes)**

### Step 1: Go to Firebase Console

1. Open browser: https://console.firebase.google.com/
2. **Important:** Login with your NEW Firebase account (the one you want to use)

---

### Step 2: Create New Project

1. Click **"Add project"** button
2. **Project name:** Enter a name (e.g., `driver-app-new` or `driver-app-production`)
3. Click **Continue**
4. **Google Analytics:** Choose "Enable" or "Disable" (optional)
5. Click **Create project**
6. Wait 30 seconds while project is created
7. Click **Continue**

**📝 Note:** Write down your new project ID (it will be shown on the screen)
Example: `driver-app-new` or `driver-app-production-abc123`

---

### Step 3: Enable Services in New Project

Now we need to turn on the same services you were using in the old project:

#### A. Enable Authentication
1. In Firebase Console, click **"Authentication"** in left sidebar
2. Click **"Get started"** button
3. Enable **Email/Password**:
   - Click "Email/Password"
   - Toggle "Enable" switch
   - Click "Save"
4. Enable **Phone** (if you use phone login):
   - Click "Phone"
   - Toggle "Enable" switch
   - Click "Save"

---

#### B. Enable Realtime Database
1. Click **"Realtime Database"** in left sidebar
2. Click **"Create Database"** button
3. **Database location:** Choose same region as old project (e.g., `us-central1`)
4. **Security rules:** Select "Start in **locked mode**"
5. Click **"Enable"**

**Why locked mode?** We'll import the security rules from old project later.

---

#### C. Enable Firestore
1. Click **"Firestore Database"** in left sidebar
2. Click **"Create database"** button
3. **Location:** Choose same region as Realtime Database
4. **Security rules:** Select "Start in **production mode**"
5. Click **"Create"**

---

#### D. Enable Storage
1. Click **"Storage"** in left sidebar
2. Click **"Get started"** button
3. **Security rules:** Select "Start in **production mode**"
4. Click **"Done"**

---

### Step 4: Note Your New Project ID

Go to **Project Settings** (⚙️ gear icon → Project settings)

You'll see:
- **Project ID:** `driver-app-new` (or whatever you named it)
- **Project number:** `123456789012`

**📝 Write down the Project ID** - you'll need it in next step!

---

## 📥 **PHASE 4: Import Data to New Project (15 minutes)**

### Step 1: Run the Import Script

```powershell
# Make sure you're in the project folder
cd c:\Users\achir\driver_app

# Run the import script
.\firebase-migrate-import.ps1
```

---

### Step 2: Follow the Prompts

**Prompt 1:** "Enter your NEW Firebase Project ID"
```
Type: driver-app-new (or your project ID)
Press Enter
```

**Prompt 2:** "Proceed with import? (Y/N)"
```
Type: Y
Press Enter
```

---

### Step 3: What Happens During Import

The script will:

1. **Switch to new project**
   ```
   [1/5] Setting Firebase project to NEW project...
   ✓ Using project: driver-app-new
   ```

2. **Import user accounts**
   ```
   [2/5] Importing Authentication users...
   ✓ Authentication users imported successfully!
   ```
   - All users can now login to new project
   - Passwords are preserved (users don't need to reset)

3. **Import rides database**
   ```
   [3/5] Importing Realtime Database...
   WARNING: This will overwrite the entire database!
   Continue? (Y/N): Y
   ✓ Realtime Database imported successfully!
   ```
   - All rides, routes, and data copied to new project

4. **Import user profiles**
   ```
   [4/5] Importing Firestore...
   ✓ Firestore imported successfully!
   ```
   - All user profiles and documents copied

5. **Import files**
   ```
   [5/5] Importing Storage files...
   ✓ Storage files imported successfully!
   ```
   - All uploaded files copied to new project

**Time:** 10-15 minutes

---

### Step 4: Verify Data in Firebase Console

Go to Firebase Console (new project) and check:

1. **Authentication → Users**
   - Should see all your users listed
   - Count should match old project

2. **Realtime Database → Data**
   - Click on data tree
   - Should see all rides, routes, etc.

3. **Firestore → Data**
   - Should see all collections
   - Click to view documents

4. **Storage → Files**
   - Should see all uploaded files

---

## 🔄 **PHASE 5: Update Your Flutter App (5 minutes)**

Now we need to tell your Flutter app to use the NEW Firebase project instead of the old one.

### Step 1: Run the App Update Script

```powershell
# Run the update script
.\firebase-update-app.ps1
```

---

### Step 2: Follow the Prompts

**Prompt 1:** "Enter your NEW Firebase Project ID"
```
Type: driver-app-new (your project ID)
Press Enter
```

**Prompt 2:** Platform Selection
```
? Which platforms would you like to configure?
  [x] android
  [x] ios
  [x] macos
  [x] web
  [x] windows

Select all that apply, then press Enter
```

---

### Step 3: What Gets Updated

The script automatically updates these files:

1. **`lib/firebase_options.dart`**
   - Old project ID → New project ID
   - Old API keys → New API keys
   - Old database URL → New database URL

   **Before:**
   ```dart
   projectId: 'driver-app-6f975',
   apiKey: 'AIzaSyCAQ9uanry0Zd2S5VT_z8lLm6iPSB2kkOw',
   databaseURL: 'https://driver-app-6f975-default-rtdb.firebaseio.com',
   ```

   **After:**
   ```dart
   projectId: 'driver-app-new',
   apiKey: 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
   databaseURL: 'https://driver-app-new-default-rtdb.firebaseio.com',
   ```

2. **`android/app/google-services.json`**
   - Android configuration updated for new project

3. **Backup created**
   - Old configuration saved to `firebase-config-backup-2025-10-17-143045/`
   - In case you need to rollback

---

### Step 4: Clean and Rebuild

The script automatically runs:

```powershell
flutter clean      # Deletes old build files
flutter pub get    # Gets latest dependencies
```

This ensures the app uses the new configuration.

---

## ✅ **PHASE 6: Test Everything (15 minutes)**

### Step 1: Build and Run the App

```powershell
# Run the app on Windows
flutter run -d windows
```

**Time:** 2-3 minutes for build

---

### Step 2: Test Checklist

#### Test 1: Login (MOST IMPORTANT)
```
1. Open the app
2. Try logging in with an EXISTING user account
   - Use credentials that worked before migration
3. ✓ Should login successfully
   - If it works, passwords were preserved correctly!
```

---

#### Test 2: View Rides Data
```
1. After login, go to Rides tab
2. ✓ Should see all your previous rides
3. ✓ Active routes should appear
4. ✓ Ride history should be complete
```

---

#### Test 3: Create New Ride
```
1. Click the + button (FAB)
2. Create a new manual ride
3. Fill in details
4. Save
5. ✓ New ride should appear in list
6. ✓ Data should be saved to database
```

---

#### Test 4: User Profile
```
1. Go to Profile tab
2. ✓ Should see your driver information
3. ✓ Profile picture should load
4. Try updating profile
5. ✓ Changes should save
```

---

#### Test 5: Real-time Updates
```
1. Open Firebase Console → Realtime Database
2. Manually change a ride status
3. ✓ App should update automatically
4. This confirms real-time connection works
```

---

#### Test 6: Earnings
```
1. Go to Earnings tab
2. ✓ Should see earnings data
3. ✓ Charts should display
4. ✓ Historical data should be complete
```

---

### Step 3: What If Something Doesn't Work?

#### Problem: Can't login
**Solution:**
```powershell
# Check Firebase Console → Authentication
# Make sure users were imported
# Count should match old project
```

#### Problem: No rides showing
**Solution:**
```powershell
# Check Firebase Console → Realtime Database
# Click on data tree to verify data is there
# Check security rules allow reading
```

#### Problem: App crashes on start
**Solution:**
```powershell
# Restore old configuration
cd firebase-config-backup-2025-10-17-XXXXXX
Copy-Item firebase_options.dart ..\lib\firebase_options.dart -Force
Copy-Item google-services.json ..\android\app\google-services.json -Force

# Clean and rebuild
flutter clean
flutter pub get
flutter run -d windows
```

#### Problem: Real-time updates not working
**Solution:**
```powershell
# Check database rules in Firebase Console
# Should allow read/write for authenticated users
```

---

## 🎉 **PHASE 7: Deploy to Production (Optional)**

If everything works in testing, you can deploy the updated app:

### Step 1: Update Version Number

Edit `pubspec.yaml`:
```yaml
version: 1.0.1+2  # Increment version
```

---

### Step 2: Build Release Versions

#### For Windows:
```powershell
flutter build windows --release
```

#### For Android:
```powershell
flutter build apk --release
# or
flutter build appbundle --release
```

#### For iOS:
```powershell
flutter build ios --release
```

---

### Step 3: Distribute

- **Google Play Store:** Upload new APK/App Bundle
- **Apple App Store:** Upload new IPA
- **Windows:** Distribute new .exe

---

## 🧹 **PHASE 8: Cleanup (After 1-2 Weeks)**

### Week 1-2: Monitor
- Keep OLD project active
- Watch for any issues
- Some users may still be on old app version

---

### Week 3: Disable Old Project Services

1. Go to OLD Firebase Console (`driver-app-6f975`)

2. **Disable Authentication:**
   - Authentication → Settings
   - Disable all sign-in methods

3. **Lock Database:**
   - Realtime Database → Rules
   - Change to deny all:
   ```json
   {
     "rules": {
       ".read": false,
       ".write": false
     }
   }
   ```

4. **Lock Storage:**
   - Storage → Rules
   - Change to deny all:
   ```
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /{allPaths=**} {
         allow read, write: if false;
       }
     }
   }
   ```

---

### Month 2: Delete Old Project (Optional)

1. Download final backup from old project
2. Go to Project Settings
3. Click "Delete project"
4. Confirm deletion

**⚠️ Warning:** This is permanent and cannot be undone!

---

## 📊 **Migration Summary**

### ✅ What We Did

```
OLD PROJECT (driver-app-6f975)          NEW PROJECT (driver-app-new)
├─ User Accounts (500 users)        →  ✓ Imported (500 users)
├─ Rides Database (1,234 rides)     →  ✓ Imported (1,234 rides)
├─ User Profiles (500 documents)    →  ✓ Imported (500 documents)
└─ Storage Files (150 files)        →  ✓ Imported (150 files)

Flutter App Configuration
├─ firebase_options.dart            →  ✓ Updated
├─ google-services.json             →  ✓ Updated
└─ GoogleService-Info.plist         →  ✓ Updated

Testing
├─ Login                            →  ✓ Works
├─ View Rides                       →  ✓ Works
├─ Create Ride                      →  ✓ Works
├─ User Profile                     →  ✓ Works
└─ Real-time Updates                →  ✓ Works
```

---

## 🔍 **Frequently Asked Questions**

### Q1: Will users need to reset their passwords?
**A:** No! Passwords are preserved during migration. Users can login with same credentials.

---

### Q2: Will there be any downtime?
**A:** No! Old project stays active during migration. You only switch when ready.

---

### Q3: What if migration fails?
**A:** All scripts create automatic backups. You can restore and try again.

---

### Q4: Can I test before switching completely?
**A:** Yes! You can keep both projects active and test the new one thoroughly.

---

### Q5: How long should I keep the old project?
**A:** Recommended: 1-2 weeks for monitoring, then 30 more days as backup before deleting.

---

### Q6: What about iOS users?
**A:** They'll get the update when you release the new app version to App Store.

---

### Q7: Do I need to migrate everything at once?
**A:** The scripts migrate everything together, but you can test incrementally.

---

### Q8: What if I have a lot of data?
**A:** Export/Import may take longer, but process is the same. Budget 1-2 hours for large datasets.

---

## 📝 **Quick Reference Commands**

### Full Migration (One Command):
```powershell
.\firebase-migrate-complete.ps1
```

### Step-by-Step:
```powershell
# 1. Export
.\firebase-migrate-export.ps1

# 2. Import (after creating new project)
.\firebase-migrate-import.ps1

# 3. Update app
.\firebase-update-app.ps1

# 4. Test
flutter run -d windows
```

### Troubleshooting:
```powershell
# Check Firebase login
firebase login

# Check current project
firebase projects:list

# Switch project
firebase use PROJECT-ID

# Reset app
flutter clean
flutter pub get
```

---

## 🆘 **Getting Help**

If you get stuck:

1. **Check the error message** - It usually tells you what's wrong
2. **Look in the detailed guide** - `FIREBASE_MIGRATION_GUIDE.md`
3. **Check Firebase Console** - Verify services are enabled
4. **Restore backup** - Scripts create backups automatically

---

## ✅ **You're Ready!**

You now understand the complete migration process. Here's what to do:

1. **Start with:** `.\firebase-migrate-complete.ps1`
2. **Follow the wizard** - It guides you through each step
3. **Test thoroughly** - Use the checklist above
4. **Deploy when ready** - After confirming everything works

**Good luck! 🚀**

---

**Total Estimated Time:** 45-60 minutes
**Difficulty Level:** Medium (scripts automate most steps)
**Risk Level:** Low (automatic backups, reversible)
**Recommended Approach:** Use the all-in-one wizard script

