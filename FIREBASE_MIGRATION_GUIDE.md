# Firebase Migration Guide
## Complete Guide to Migrate Firebase Project

### Prerequisites
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Install Google Cloud SDK: https://cloud.google.com/sdk/docs/install
3. Login to both Firebase accounts

---

## PHASE 1: Export Data from OLD Project (driver-app-6f975)

### Step 1.1: Login to OLD Firebase Project
```bash
# Login to Firebase
firebase login

# Select the old project
firebase use driver-app-6f975
```

### Step 1.2: Export Authentication Users
```bash
# Export all users to JSON
firebase auth:export auth-users-backup.json --format=JSON --project driver-app-6f975

# This will create auth-users-backup.json with all user data including:
# - UIDs, emails, password hashes
# - Phone numbers, display names
# - Custom claims, metadata
```

### Step 1.3: Export Realtime Database
```bash
# Method 1: Using Firebase CLI
firebase database:get / --project driver-app-6f975 > realtime-database-backup.json

# Method 2: Using curl (if you have admin SDK token)
curl "https://driver-app-6f975-default-rtdb.firebaseio.com/.json?auth=YOUR_SECRET" > realtime-database-backup.json
```

**OR manually via Console:**
1. Go to: https://console.firebase.google.com/project/driver-app-6f975/database
2. Click ⋮ (three dots) → Export JSON
3. Save as `realtime-database-backup.json`

### Step 1.4: Export Firestore Data
```bash
# Using gcloud (more reliable)
gcloud config set project driver-app-6f975

# Export to Cloud Storage bucket
gcloud firestore export gs://driver-app-6f975.firebasestorage.app/firestore-backup

# Download the exported data
gsutil -m cp -r gs://driver-app-6f975.firebasestorage.app/firestore-backup ./firestore-backup
```

### Step 1.5: Export Storage Files
```bash
# Download all files from Firebase Storage
gsutil -m cp -r gs://driver-app-6f975.firebasestorage.app ./storage-backup

# This preserves folder structure and all files
```

### Step 1.6: Export Security Rules
```bash
# Realtime Database Rules
firebase database:get --project driver-app-6f975 --pretty --export-rules > database-rules.json

# Firestore Rules
firebase firestore:rules --project driver-app-6f975 > firestore.rules

# Storage Rules
firebase storage:rules --project driver-app-6f975 > storage.rules
```

---

## PHASE 2: Create and Setup NEW Firebase Project

### Step 2.1: Create New Firebase Project
1. Go to: https://console.firebase.google.com/
2. Click "Add project"
3. Enter project name (e.g., `driver-app-new`)
4. Enable Google Analytics (optional)
5. Create project

### Step 2.2: Enable Required Services in New Project
1. **Enable Authentication:**
   - Go to Authentication → Get Started
   - Enable Sign-in methods: Email/Password, Phone

2. **Enable Realtime Database:**
   - Go to Realtime Database → Create Database
   - Choose location (same as old project for consistency)
   - Start in **locked mode** (we'll import rules later)

3. **Enable Firestore:**
   - Go to Firestore Database → Create Database
   - Choose location
   - Start in **production mode**

4. **Enable Storage:**
   - Go to Storage → Get Started
   - Choose location
   - Set up

### Step 2.3: Switch to New Project
```bash
# Add the new project
firebase use --add

# Select the new project (e.g., driver-app-new)
# Give it an alias like "production"
```

---

## PHASE 3: Import Data to NEW Project

### Step 3.1: Import Authentication Users
```bash
# Import users to new project
firebase auth:import auth-users-backup.json --project YOUR-NEW-PROJECT-ID --hash-algo=SCRYPT

# If users have passwords, Firebase will preserve the hashes
# Users can login with same credentials
```

### Step 3.2: Import Realtime Database
```bash
# Import data using Firebase CLI
firebase database:set / realtime-database-backup.json --project YOUR-NEW-PROJECT-ID --confirm

# This will overwrite the entire database with backed up data
```

**OR use REST API:**
```bash
# Get your database secret from Firebase Console → Project Settings → Service Accounts
curl -X PUT -d @realtime-database-backup.json \
  "https://YOUR-NEW-PROJECT-ID-default-rtdb.firebaseio.com/.json?auth=YOUR_NEW_SECRET"
```

### Step 3.3: Import Firestore Data
```bash
# Upload backup to new project's storage
gsutil -m cp -r ./firestore-backup gs://YOUR-NEW-PROJECT-ID.firebasestorage.app/

# Import from Cloud Storage
gcloud config set project YOUR-NEW-PROJECT-ID
gcloud firestore import gs://YOUR-NEW-PROJECT-ID.firebasestorage.app/firestore-backup
```

### Step 3.4: Import Storage Files
```bash
# Upload all files to new Storage bucket
gsutil -m cp -r ./storage-backup/* gs://YOUR-NEW-PROJECT-ID.firebasestorage.app/

# Preserve metadata and permissions
```

### Step 3.5: Import Security Rules
```bash
# Deploy Realtime Database rules
firebase deploy --only database --project YOUR-NEW-PROJECT-ID

# Deploy Firestore rules
firebase deploy --only firestore:rules --project YOUR-NEW-PROJECT-ID

# Deploy Storage rules
firebase deploy --only storage --project YOUR-NEW-PROJECT-ID
```

---

## PHASE 4: Update Flutter App Configuration

### Step 4.1: Install FlutterFire CLI
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Make sure it's in your PATH
```

### Step 4.2: Configure New Firebase Project in Flutter App
```bash
# Navigate to your project directory
cd c:\Users\achir\driver_app

# Remove old Firebase configuration
flutterfire configure --project=YOUR-NEW-PROJECT-ID

# This will:
# 1. Update lib/firebase_options.dart with new credentials
# 2. Download new google-services.json for Android
# 3. Download new GoogleService-Info.plist for iOS
# 4. Update all platform-specific configs
```

**The command will prompt you to:**
- Select platforms (Android, iOS, Web, Windows, macOS)
- It will automatically update all configuration files

### Step 4.3: Verify Updated Files
The following files will be automatically updated:
- ✅ `lib/firebase_options.dart` - All API keys and project IDs
- ✅ `android/app/google-services.json` - Android config
- ✅ `ios/Runner/GoogleService-Info.plist` - iOS config (if exists)

---

## PHASE 5: Testing and Validation

### Step 5.1: Clean and Rebuild
```powershell
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Build and run
flutter run -d windows
```

### Step 5.2: Test All Firebase Features
1. **Authentication:**
   - Test login with existing user credentials
   - Test new user registration
   - Test phone auth

2. **Realtime Database:**
   - Verify rides data is accessible
   - Test creating new ride
   - Test updating ride status

3. **Firestore:**
   - Verify user profiles load
   - Test document reads/writes

4. **Storage:**
   - Test file uploads
   - Verify existing files are accessible

---

## PHASE 6: Cleanup (After Successful Migration)

### Step 6.1: Keep Old Project Temporarily
- Keep the old Firebase project active for 1-2 weeks
- Monitor for any issues
- Some users might still be on old app version

### Step 6.2: Update App in Production
1. Update app version in `pubspec.yaml`
2. Build release versions
3. Deploy to Play Store / App Store
4. Force update old app versions (optional)

### Step 6.3: Deactivate Old Project (After Everyone Migrates)
1. Download final backup
2. Disable all services in old project
3. Delete old project (optional)

---

## Quick Reference Commands

### Export Everything (One Script)
```bash
# Set old project
firebase use driver-app-6f975

# Export all data
firebase auth:export auth-backup.json --format=JSON
firebase database:get / > db-backup.json
gcloud firestore export gs://driver-app-6f975.firebasestorage.app/firestore-backup
gsutil -m cp -r gs://driver-app-6f975.firebasestorage.app ./storage-backup
```

### Import Everything (One Script)
```bash
# Set new project
firebase use YOUR-NEW-PROJECT-ID

# Import all data
firebase auth:import auth-backup.json --hash-algo=SCRYPT
firebase database:set / db-backup.json --confirm
gcloud firestore import gs://YOUR-NEW-PROJECT-ID.firebasestorage.app/firestore-backup
gsutil -m cp -r ./storage-backup/* gs://YOUR-NEW-PROJECT-ID.firebasestorage.app/
```

### Update Flutter App
```bash
flutterfire configure --project=YOUR-NEW-PROJECT-ID
flutter clean
flutter pub get
flutter run
```

---

## Troubleshooting

### Issue: Auth import fails
**Solution:** Make sure you include `--hash-algo=SCRYPT` for password preservation

### Issue: Firestore import permission denied
**Solution:** 
```bash
gcloud auth login
gcloud config set project YOUR-NEW-PROJECT-ID
```

### Issue: Storage files not accessible
**Solution:** Check storage rules and make them match the old project

### Issue: App can't connect to new Firebase
**Solution:** 
1. Verify `google-services.json` is updated
2. Run `flutter clean`
3. Rebuild app completely
4. Check if Firebase SDK versions match in `pubspec.yaml`

---

## Need Help?
If you encounter any issues during migration, check:
1. Firebase Console → Project Settings → Service Accounts
2. Verify all services are enabled in new project
3. Check security rules are properly deployed
4. Ensure app package name matches in Firebase console

