# 🔥 Firebase Migration Toolkit

Complete toolkit to migrate your Flutter app from one Firebase project to another.

## 📁 Files Included

1. **FIREBASE_MIGRATION_GUIDE.md** - Comprehensive step-by-step migration guide
2. **MIGRATION_CHECKLIST.md** - Checklist to track migration progress
3. **firebase-migrate-export.ps1** - Export data from old project
4. **firebase-migrate-import.ps1** - Import data to new project
5. **firebase-update-app.ps1** - Update Flutter app configuration
6. **firebase-migrate-complete.ps1** - All-in-one automated migration wizard

## 🚀 Quick Start

### Option 1: Automated (Recommended)
Run the complete migration wizard:
```powershell
.\firebase-migrate-complete.ps1
```
This single script will:
- Export all data from old project
- Guide you through new project setup
- Import all data to new project
- Update Flutter app configuration
- Clean and rebuild the app

### Option 2: Step-by-Step
If you prefer more control, run scripts individually:

1. **Export data:**
   ```powershell
   .\firebase-migrate-export.ps1
   ```

2. **Create new Firebase project** in console (https://console.firebase.google.com/)
   - Enable Authentication
   - Enable Realtime Database
   - Enable Firestore
   - Enable Storage

3. **Import data:**
   ```powershell
   .\firebase-migrate-import.ps1
   ```

4. **Update app:**
   ```powershell
   .\firebase-update-app.ps1
   ```

### Option 3: Manual
Follow the detailed instructions in `FIREBASE_MIGRATION_GUIDE.md`

## 📋 Prerequisites

Before starting, install these tools:

### Required:
- **Firebase CLI**
  ```powershell
  npm install -g firebase-tools
  ```

- **FlutterFire CLI**
  ```powershell
  dart pub global activate flutterfire_cli
  ```

### Optional (but recommended for Firestore):
- **Google Cloud SDK**
  Download from: https://cloud.google.com/sdk/docs/install

## ⚙️ What Gets Migrated

✅ **Authentication Users**
- All user accounts with emails, UIDs
- Password hashes (users keep same passwords)
- Phone numbers, display names
- Custom claims and metadata

✅ **Realtime Database**
- Complete database structure
- All rides, routes, and data
- Preserves data hierarchy

✅ **Firestore**
- All collections and documents
- User profiles and app data
- Indexes and composite indexes

✅ **Storage**
- All uploaded files
- Folder structure preserved
- File metadata

✅ **Security Rules**
- Realtime Database rules
- Firestore rules
- Storage rules

## 🎯 Migration Steps Overview

```
OLD PROJECT                    NEW PROJECT
(driver-app-6f975)         →  (your-new-project)
     │
     ├─ Export Data
     │   ├─ Auth users     →  Backup folder
     │   ├─ Database       →  Backup folder
     │   ├─ Firestore      →  Backup folder
     │   └─ Storage        →  Backup folder
     │
     ├─ Create New Project
     │   ├─ Enable services
     │   └─ Configure
     │
     ├─ Import Data
     │   ├─ Auth users     →  New project
     │   ├─ Database       →  New project
     │   ├─ Firestore      →  New project
     │   └─ Storage        →  New project
     │
     └─ Update App
         ├─ firebase_options.dart
         ├─ google-services.json
         └─ GoogleService-Info.plist
```

## 📝 Current Project Details

**Old Project:**
- Project ID: `driver-app-6f975`
- Package: `com.ttd.driverapp`
- Database: `https://driver-app-6f975-default-rtdb.firebaseio.com`
- Storage: `driver-app-6f975.firebasestorage.app`

**Services Used:**
- ✅ Firebase Authentication (Email/Password, Phone)
- ✅ Realtime Database (Ride history, active routes)
- ✅ Firestore (User profiles, app data)
- ✅ Storage (File uploads)

## 🔍 Testing After Migration

After migration, test all features:

### Authentication
```
✓ Login with existing credentials
✓ Register new user
✓ Password reset
✓ Phone authentication
```

### Realtime Database
```
✓ View existing rides
✓ Create new ride
✓ Update ride status
✓ Real-time updates working
```

### Firestore
```
✓ Load user profile
✓ Update profile data
✓ Query collections
```

### Storage
```
✓ Upload new file
✓ Download existing file
✓ File URLs working
```

## 🛠️ Troubleshooting

### Scripts Won't Run
```powershell
# Enable script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Firebase CLI Not Found
```powershell
npm install -g firebase-tools
firebase login
```

### FlutterFire CLI Not Found
```powershell
dart pub global activate flutterfire_cli
# Add to PATH: %USERPROFILE%\AppData\Local\Pub\Cache\bin
```

### Permission Denied
```powershell
gcloud auth login
gcloud config set project YOUR-PROJECT-ID
```

### App Won't Build After Migration
```powershell
flutter clean
rd /s /q build  # Delete build folder
flutter pub get
flutter run -d windows
```

## 📊 Success Criteria

Migration is successful when:
- ✅ All users can login with existing credentials
- ✅ All rides/data visible in app
- ✅ New data can be created
- ✅ Real-time updates work
- ✅ No errors in Firebase Console
- ✅ App functions exactly as before

## ⚠️ Important Notes

1. **Backup Everything**
   - Scripts create automatic backups
   - Keep backups for at least 30 days
   - Test before deleting old project

2. **Password Preservation**
   - User passwords are preserved
   - No need for users to reset passwords
   - Same login credentials work

3. **Gradual Migration**
   - Keep old project active for 1-2 weeks
   - Monitor for issues
   - Some users may still be on old app version

4. **Security Rules**
   - Verify rules are deployed to new project
   - Test access permissions
   - Check Firebase Console → Rules tab

5. **API Keys**
   - New project has different API keys
   - `flutterfire configure` updates them automatically
   - No manual editing needed

## 📞 Need Help?

If you encounter issues:
1. Check `FIREBASE_MIGRATION_GUIDE.md` for detailed steps
2. Review `MIGRATION_CHECKLIST.md` for tracking
3. Check Firebase Console for service status
4. Verify all services are enabled in new project

## 📅 Timeline

Recommended migration timeline:

```
Day 1: Export and Setup
├─ Run export script
├─ Create new project
└─ Enable all services

Day 2: Import and Test
├─ Run import script
├─ Update app config
└─ Test all features

Week 1-2: Monitor
├─ Deploy to production
├─ Monitor for issues
└─ Keep old project active

Week 3-4: Cleanup
├─ Verify all users migrated
├─ Disable old project services
└─ Keep backup for 30 days

Month 2: Complete
└─ Delete old project (optional)
```

## 🎉 Ready to Migrate?

1. Read `MIGRATION_CHECKLIST.md`
2. Run `.\firebase-migrate-complete.ps1`
3. Follow the wizard prompts
4. Test thoroughly
5. Deploy to production

**Estimated Time:** 30-60 minutes (depending on data size)

---

**Last Updated:** October 17, 2025
**Old Project:** driver-app-6f975
**Target:** New Firebase Project
