# Complete Firebase Migration - All-in-One Script
# This script guides you through the entire migration process
# Run this in PowerShell as Administrator

param(
    [Parameter(Mandatory=$false)]
    [string]$NewProjectId = ""
)

$ErrorActionPreference = "Continue"

function Write-Title {
    param([string]$Text)
    Write-Host "`n$('=' * 60)" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "$('=' * 60)" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Text)
    Write-Host "`n$Text" -ForegroundColor Green
}

function Write-Success {
    param([string]$Text)
    Write-Host "✓ $Text" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Text)
    Write-Host "⚠ $Text" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Text)
    Write-Host "✗ $Text" -ForegroundColor Red
}

Write-Title "Firebase Migration Wizard"

Write-Host "`nThis wizard will guide you through the complete migration process:" -ForegroundColor White
Write-Host "  1. Export data from old Firebase project" -ForegroundColor Gray
Write-Host "  2. Help you create a new Firebase project" -ForegroundColor Gray
Write-Host "  3. Import data to new project" -ForegroundColor Gray
Write-Host "  4. Update Flutter app configuration" -ForegroundColor Gray
Write-Host "  5. Test the migration" -ForegroundColor Gray

Write-Host "`nBefore starting, make sure you have:" -ForegroundColor Yellow
Write-Host "  - Firebase CLI installed (npm install -g firebase-tools)" -ForegroundColor White
Write-Host "  - Google Cloud SDK installed (for Firestore)" -ForegroundColor White
Write-Host "  - Access to old Firebase account (driver-app-6f975)" -ForegroundColor White
Write-Host "  - Created a new Firebase project (or will create one)" -ForegroundColor White

Write-Host "`nContinue? (Y/N): " -ForegroundColor Yellow -NoNewline
$continue = Read-Host

if ($continue -ne "Y" -and $continue -ne "y") {
    Write-Host "Migration cancelled." -ForegroundColor Yellow
    exit 0
}

# Configuration
$OLD_PROJECT_ID = "driver-app-6f975"
$TIMESTAMP = Get-Date -Format "yyyy-MM-dd-HHmmss"
$BACKUP_DIR = "firebase-backup-$TIMESTAMP"

# ============================================================================
# PHASE 1: PREREQUISITES CHECK
# ============================================================================

Write-Title "Phase 1: Prerequisites Check"

# Check Firebase CLI
Write-Step "Checking Firebase CLI..."
try {
    $firebaseVersion = firebase --version 2>&1
    Write-Success "Firebase CLI installed: $firebaseVersion"
} catch {
    Write-Error-Custom "Firebase CLI not found!"
    Write-Host "Install with: npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}

# Check gcloud (optional but recommended)
Write-Step "Checking Google Cloud SDK..."
try {
    $gcloudVersion = gcloud --version 2>&1 | Select-Object -First 1
    Write-Success "gcloud SDK installed: $gcloudVersion"
    $hasGcloud = $true
} catch {
    Write-Warning "gcloud SDK not found (optional, but needed for Firestore)"
    Write-Host "Download: https://cloud.google.com/sdk/docs/install" -ForegroundColor Gray
    $hasGcloud = $false
}

# Check Dart (for FlutterFire CLI)
Write-Step "Checking Dart SDK..."
try {
    $dartVersion = dart --version 2>&1
    Write-Success "Dart SDK installed"
} catch {
    Write-Error-Custom "Dart SDK not found! Flutter should include Dart."
    exit 1
}

# ============================================================================
# PHASE 2: EXPORT DATA FROM OLD PROJECT
# ============================================================================

Write-Title "Phase 2: Export Data from Old Project"

# Login to Firebase
Write-Step "Logging in to Firebase..."
Write-Host "Please login with your OLD Firebase account credentials" -ForegroundColor Yellow
firebase login --no-localhost

# Set old project
Write-Step "Setting old Firebase project..."
firebase use $OLD_PROJECT_ID
Write-Success "Using project: $OLD_PROJECT_ID"

# Create backup directory
Write-Step "Creating backup directory..."
New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
Write-Success "Backup directory created: $BACKUP_DIR"

# Export Authentication
Write-Step "Exporting Authentication users..."
$authBackupPath = "$BACKUP_DIR\auth-users.json"
try {
    firebase auth:export $authBackupPath --format=JSON --project $OLD_PROJECT_ID 2>&1 | Out-Null
    if (Test-Path $authBackupPath) {
        $authCount = (Get-Content $authBackupPath | ConvertFrom-Json).users.Count
        Write-Success "Exported $authCount users"
    } else {
        Write-Warning "No authentication users found or export failed"
    }
} catch {
    Write-Warning "Auth export failed - may have no users or permission issue"
}

# Export Realtime Database
Write-Step "Exporting Realtime Database..."
$dbBackupPath = "$BACKUP_DIR\database.json"
try {
    $dbData = firebase database:get / --project $OLD_PROJECT_ID 2>&1
    $dbData | Out-File -FilePath $dbBackupPath -Encoding UTF8
    if (Test-Path $dbBackupPath) {
        $dbSize = (Get-Item $dbBackupPath).Length / 1KB
        Write-Success "Exported database (${dbSize}KB)"
    }
} catch {
    Write-Warning "Database export failed"
}

# Export Firestore (if gcloud available)
if ($hasGcloud) {
    Write-Step "Exporting Firestore..."
    try {
        gcloud config set project $OLD_PROJECT_ID 2>&1 | Out-Null
        $firestoreBucket = "gs://$OLD_PROJECT_ID.firebasestorage.app/firestore-export-$TIMESTAMP"
        gcloud firestore export $firestoreBucket 2>&1 | Out-Null
        
        # Download
        $firestoreLocalPath = "$BACKUP_DIR\firestore"
        gsutil -m cp -r $firestoreBucket $firestoreLocalPath 2>&1 | Out-Null
        Write-Success "Exported Firestore data"
    } catch {
        Write-Warning "Firestore export failed - may be empty or permission issue"
    }
} else {
    Write-Warning "Skipping Firestore export (gcloud not installed)"
}

# Export Storage
Write-Step "Exporting Storage files..."
try {
    $storagePath = "$BACKUP_DIR\storage"
    gsutil -m cp -r "gs://$OLD_PROJECT_ID.firebasestorage.app" $storagePath 2>&1 | Out-Null
    if (Test-Path $storagePath) {
        Write-Success "Exported Storage files"
    }
} catch {
    Write-Warning "Storage export failed - may be empty"
}

Write-Success "Export phase complete!"
Write-Host "`nBackup saved to: $BACKUP_DIR" -ForegroundColor Cyan

# ============================================================================
# PHASE 3: NEW PROJECT SETUP
# ============================================================================

Write-Title "Phase 3: New Project Setup"

if ([string]::IsNullOrWhiteSpace($NewProjectId)) {
    Write-Host "`nDo you have a NEW Firebase project created? (Y/N): " -ForegroundColor Yellow -NoNewline
    $hasNewProject = Read-Host
    
    if ($hasNewProject -ne "Y" -and $hasNewProject -ne "y") {
        Write-Host "`nPlease create a new Firebase project:" -ForegroundColor Yellow
        Write-Host "  1. Go to: https://console.firebase.google.com/" -ForegroundColor White
        Write-Host "  2. Click 'Add project'" -ForegroundColor White
        Write-Host "  3. Enter project name (e.g., 'driver-app-new')" -ForegroundColor White
        Write-Host "  4. Enable Google Analytics (optional)" -ForegroundColor White
        Write-Host "  5. Create project" -ForegroundColor White
        Write-Host "`nAfter creating, enable these services:" -ForegroundColor Yellow
        Write-Host "  - Authentication (Email/Password, Phone)" -ForegroundColor White
        Write-Host "  - Realtime Database" -ForegroundColor White
        Write-Host "  - Firestore Database" -ForegroundColor White
        Write-Host "  - Storage" -ForegroundColor White
        Write-Host "`nPress Enter when done..." -NoNewline
        Read-Host
    }
    
    Write-Host "`nEnter your NEW Firebase Project ID: " -ForegroundColor Yellow -NoNewline
    $NewProjectId = Read-Host
}

if ([string]::IsNullOrWhiteSpace($NewProjectId)) {
    Write-Error-Custom "Project ID cannot be empty!"
    exit 1
}

Write-Success "New project: $NewProjectId"

# ============================================================================
# PHASE 4: IMPORT DATA TO NEW PROJECT
# ============================================================================

Write-Title "Phase 4: Import Data to New Project"

Write-Host "`nWARNING: This will import data to $NewProjectId" -ForegroundColor Red
Write-Host "Make sure all services are enabled in the new project!" -ForegroundColor Yellow
Write-Host "`nContinue with import? (Y/N): " -ForegroundColor Yellow -NoNewline
$confirmImport = Read-Host

if ($confirmImport -ne "Y" -and $confirmImport -ne "y") {
    Write-Host "Import cancelled. You can run the import later." -ForegroundColor Yellow
    exit 0
}

# Set new project
Write-Step "Switching to new project..."
firebase use $NewProjectId
Write-Success "Using project: $NewProjectId"

# Import Authentication
if (Test-Path $authBackupPath) {
    Write-Step "Importing Authentication users..."
    try {
        firebase auth:import $authBackupPath --hash-algo=SCRYPT --project $NewProjectId 2>&1 | Out-Null
        Write-Success "Authentication users imported"
    } catch {
        Write-Warning "Auth import failed - check console for details"
    }
}

# Import Realtime Database
if (Test-Path $dbBackupPath) {
    Write-Step "Importing Realtime Database..."
    Write-Warning "This will overwrite the entire database!"
    try {
        firebase database:set / $dbBackupPath --project $NewProjectId --confirm 2>&1 | Out-Null
        Write-Success "Realtime Database imported"
    } catch {
        Write-Warning "Database import failed"
    }
}

# Import Firestore
$firestoreLocalPath = "$BACKUP_DIR\firestore"
if ((Test-Path $firestoreLocalPath) -and $hasGcloud) {
    Write-Step "Importing Firestore..."
    try {
        # Upload to new storage
        $newFirestoreBucket = "gs://$NewProjectId.firebasestorage.app/firestore-import"
        gsutil -m cp -r $firestoreLocalPath $newFirestoreBucket 2>&1 | Out-Null
        
        # Import
        gcloud config set project $NewProjectId 2>&1 | Out-Null
        gcloud firestore import $newFirestoreBucket 2>&1 | Out-Null
        Write-Success "Firestore imported"
    } catch {
        Write-Warning "Firestore import failed"
    }
}

# Import Storage
$storagePath = "$BACKUP_DIR\storage"
if (Test-Path $storagePath) {
    Write-Step "Importing Storage files..."
    try {
        gsutil -m cp -r "$storagePath/*" "gs://$NewProjectId.firebasestorage.app/" 2>&1 | Out-Null
        Write-Success "Storage files imported"
    } catch {
        Write-Warning "Storage import failed"
    }
}

Write-Success "Import phase complete!"

# ============================================================================
# PHASE 5: UPDATE FLUTTER APP
# ============================================================================

Write-Title "Phase 5: Update Flutter App Configuration"

# Check FlutterFire CLI
Write-Step "Checking FlutterFire CLI..."
try {
    $flutterfireVersion = flutterfire --version 2>&1
    Write-Success "FlutterFire CLI installed"
} catch {
    Write-Warning "FlutterFire CLI not found. Installing..."
    dart pub global activate flutterfire_cli
    Write-Success "FlutterFire CLI installed"
}

# Backup current config
Write-Step "Backing up current Firebase configuration..."
$configBackupDir = "firebase-config-backup-$TIMESTAMP"
New-Item -ItemType Directory -Path $configBackupDir -Force | Out-Null

if (Test-Path "lib\firebase_options.dart") {
    Copy-Item "lib\firebase_options.dart" "$configBackupDir\" -Force
}
if (Test-Path "android\app\google-services.json") {
    Copy-Item "android\app\google-services.json" "$configBackupDir\" -Force
}
Write-Success "Backup saved to: $configBackupDir"

# Configure new project
Write-Step "Configuring new Firebase project in Flutter app..."
Write-Host "Select ALL platforms when prompted (Android, iOS, Web, Windows, macOS)" -ForegroundColor Yellow

try {
    flutterfire configure --project=$NewProjectId
    Write-Success "Firebase configuration updated!"
} catch {
    Write-Error-Custom "Configuration failed!"
    Write-Host "Restore backup if needed from: $configBackupDir" -ForegroundColor Yellow
    exit 1
}

# Clean and rebuild
Write-Step "Cleaning project..."
flutter clean | Out-Null
Write-Success "Project cleaned"

Write-Step "Getting dependencies..."
flutter pub get | Out-Null
Write-Success "Dependencies updated"

# ============================================================================
# PHASE 6: SUMMARY
# ============================================================================

Write-Title "Migration Complete!"

Write-Host "`n📊 Summary:" -ForegroundColor Cyan
Write-Host "  Old Project: $OLD_PROJECT_ID" -ForegroundColor Gray
Write-Host "  New Project: $NewProjectId" -ForegroundColor Green
Write-Host "  Backup Location: $BACKUP_DIR" -ForegroundColor Gray
Write-Host "  Config Backup: $configBackupDir" -ForegroundColor Gray

Write-Host "`n✅ Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Test the app:" -ForegroundColor White
Write-Host "     flutter run -d windows" -ForegroundColor Gray

Write-Host "`n  2. Verify all features work:" -ForegroundColor White
Write-Host "     - Login with existing user" -ForegroundColor Gray
Write-Host "     - View rides data" -ForegroundColor Gray
Write-Host "     - Create new ride" -ForegroundColor Gray
Write-Host "     - Check user profile" -ForegroundColor Gray

Write-Host "`n  3. If everything works:" -ForegroundColor White
Write-Host "     - Build release version" -ForegroundColor Gray
Write-Host "     - Deploy to production" -ForegroundColor Gray
Write-Host "     - Monitor for issues" -ForegroundColor Gray

Write-Host "`n  4. After 1-2 weeks:" -ForegroundColor White
Write-Host "     - Disable old project services" -ForegroundColor Gray
Write-Host "     - Keep old project for 30 days" -ForegroundColor Gray
Write-Host "     - Delete old project (optional)" -ForegroundColor Gray

Write-Host "`n📝 Documentation:" -ForegroundColor Cyan
Write-Host "  - Full guide: FIREBASE_MIGRATION_GUIDE.md" -ForegroundColor Gray
Write-Host "  - Checklist: MIGRATION_CHECKLIST.md" -ForegroundColor Gray

Write-Host "`nRun the app now? (Y/N): " -ForegroundColor Yellow -NoNewline
$runNow = Read-Host

if ($runNow -eq "Y" -or $runNow -eq "y") {
    Write-Host "`nStarting app..." -ForegroundColor Green
    flutter run -d windows
} else {
    Write-Host "`nYou can run the app later with: flutter run -d windows" -ForegroundColor Yellow
}

Write-Host "`n🎉 Migration wizard complete!" -ForegroundColor Green
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
