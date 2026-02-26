# Firebase Migration - Quick Start Checklist

## 📋 Complete Migration Checklist

### Phase 1: Preparation ✓
- [ ] Install Firebase CLI: `npm install -g firebase-tools`
- [ ] Install Google Cloud SDK: https://cloud.google.com/sdk/docs/install
- [ ] Login to OLD Firebase account: `firebase login`
- [ ] Create NEW Firebase project in Firebase Console
- [ ] Note down NEW project ID: ________________

### Phase 2: Export Data from OLD Project ✓
- [ ] Run export script: `.\firebase-migrate-export.ps1`
  - [ ] Authentication users exported
  - [ ] Realtime Database exported
  - [ ] Firestore data exported
  - [ ] Storage files exported
- [ ] Verify backup folder created with all data
- [ ] Backup folder location: ________________

### Phase 3: Setup NEW Firebase Project ✓
- [ ] Go to Firebase Console → NEW project
- [ ] Enable Authentication
  - [ ] Enable Email/Password sign-in
  - [ ] Enable Phone sign-in (if used)
  - [ ] Enable other sign-in methods as needed
- [ ] Enable Realtime Database
  - [ ] Create database in same region as old project
  - [ ] Start in locked mode (rules will be imported)
- [ ] Enable Firestore
  - [ ] Create database in same region
  - [ ] Start in production mode
- [ ] Enable Storage
  - [ ] Create bucket in same region

### Phase 4: Import Data to NEW Project ✓
- [ ] Run import script: `.\firebase-migrate-import.ps1`
  - [ ] Enter NEW project ID when prompted
  - [ ] Authentication users imported
  - [ ] Realtime Database imported
  - [ ] Firestore data imported
  - [ ] Storage files imported
- [ ] Verify data in Firebase Console
  - [ ] Check Authentication → Users tab
  - [ ] Check Realtime Database → Data tab
  - [ ] Check Firestore → Data tab
  - [ ] Check Storage → Files tab

### Phase 5: Update Flutter App ✓
- [ ] Run app update script: `.\firebase-update-app.ps1`
  - [ ] Enter NEW project ID when prompted
  - [ ] Configuration files updated
  - [ ] App cleaned and rebuilt
- [ ] Verify updated files:
  - [ ] `lib\firebase_options.dart` contains new project ID
  - [ ] `android\app\google-services.json` updated
  - [ ] Backup created in case of rollback

### Phase 6: Testing ✓
- [ ] Build and run app: `flutter run -d windows`
- [ ] Test Authentication:
  - [ ] Login with existing user
  - [ ] Register new user
  - [ ] Password reset
  - [ ] Phone authentication (if used)
- [ ] Test Realtime Database:
  - [ ] View existing rides
  - [ ] Create new ride
  - [ ] Update ride status
  - [ ] Delete ride
- [ ] Test Firestore:
  - [ ] Load user profile
  - [ ] Update profile data
- [ ] Test Storage:
  - [ ] Upload file
  - [ ] Download existing file

### Phase 7: Deployment ✓
- [ ] Update version in `pubspec.yaml`
- [ ] Build release versions:
  - [ ] Android: `flutter build apk --release`
  - [ ] iOS: `flutter build ios --release`
  - [ ] Windows: `flutter build windows --release`
- [ ] Deploy to stores:
  - [ ] Google Play Store (Android)
  - [ ] Apple App Store (iOS)
  - [ ] Microsoft Store (Windows)
- [ ] Monitor for issues

### Phase 8: Cleanup (After 1-2 Weeks) ✓
- [ ] Verify all users migrated to new project
- [ ] Export final backup from OLD project
- [ ] Disable services in OLD project:
  - [ ] Disable Authentication
  - [ ] Set Database rules to deny all
  - [ ] Set Storage rules to deny all
- [ ] Keep OLD project for 30 more days before deletion
- [ ] Delete OLD project (optional)

---

## 🚀 Quick Start Commands

### One-Line Export (Alternative to script)
```powershell
firebase use driver-app-6f975; firebase auth:export auth-backup.json --format=JSON; firebase database:get / > db-backup.json
```

### One-Line Import (Alternative to script)
```powershell
firebase use YOUR-NEW-PROJECT-ID; firebase auth:import auth-backup.json --hash-algo=SCRYPT; firebase database:set / db-backup.json --confirm
```

### Update Flutter App
```powershell
flutterfire configure --project=YOUR-NEW-PROJECT-ID; flutter clean; flutter pub get
```

### Build and Test
```powershell
flutter run -d windows
```

---

## ⚠️ Important Notes

### Security Rules
After import, verify security rules are properly set:
1. Realtime Database: Firebase Console → Database → Rules
2. Firestore: Firebase Console → Firestore → Rules
3. Storage: Firebase Console → Storage → Rules

### Package Name
Ensure your app package name matches in Firebase:
- Android: `com.ttd.driverapp`
- iOS: `com.ttd.driverapp`

### API Keys
New project will have different API keys. These are automatically updated by `flutterfire configure`.

### Testing Users
After migration, existing users can login with same credentials because password hashes are preserved.

### Data Validation
Before deactivating old project, verify:
- User count matches (old vs new)
- Ride count matches
- All data is accessible in new project

---

## 🆘 Troubleshooting

### Issue: "Firebase CLI not found"
**Solution:** Install with `npm install -g firebase-tools`

### Issue: "gcloud not found"
**Solution:** Install from https://cloud.google.com/sdk/docs/install

### Issue: "FlutterFire CLI not found"
**Solution:** 
```powershell
dart pub global activate flutterfire_cli
# Add to PATH: %USERPROFILE%\AppData\Local\Pub\Cache\bin
```

### Issue: "Permission denied" during import
**Solution:**
```powershell
gcloud auth login
gcloud config set project YOUR-NEW-PROJECT-ID
```

### Issue: App can't connect to new Firebase
**Solution:**
1. Verify `google-services.json` is updated
2. Run `flutter clean`
3. Delete `build` folder manually
4. Rebuild: `flutter pub get` then `flutter run`

### Issue: Auth import fails
**Solution:** Make sure to use `--hash-algo=SCRYPT` parameter

### Issue: Data not visible after import
**Solution:** Check security rules - they may be too restrictive

---

## 📞 Support

If you encounter issues:
1. Check Firebase Console → Project Settings → Service Accounts
2. Verify all services are enabled
3. Check Firebase Status: https://status.firebase.google.com/
4. Review migration logs in PowerShell output

---

## ✅ Success Criteria

Migration is successful when:
- ✅ All users can login with existing credentials
- ✅ All rides data is visible in app
- ✅ New rides can be created and updated
- ✅ User profiles load correctly
- ✅ No errors in Firebase Console → Usage & Billing
- ✅ App functions exactly as before migration

---

**Created:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Old Project:** driver-app-6f975
**New Project:** [YOUR-NEW-PROJECT-ID]
