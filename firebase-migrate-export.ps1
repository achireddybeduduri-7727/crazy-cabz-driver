# Firebase Migration Script - EXPORT Phase
# This script exports all data from the OLD Firebase project
# Run this script in PowerShell

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Firebase Migration - EXPORT from OLD Project" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$OLD_PROJECT_ID = "driver-app-6f975"
$BACKUP_DIR = "firebase-backup-$(Get-Date -Format 'yyyy-MM-dd-HHmmss')"

# Create backup directory
Write-Host "Creating backup directory: $BACKUP_DIR" -ForegroundColor Yellow
New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null

# Step 1: Check if Firebase CLI is installed
Write-Host "`n[1/6] Checking Firebase CLI installation..." -ForegroundColor Green
try {
    $firebaseVersion = firebase --version
    Write-Host "✓ Firebase CLI found: $firebaseVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Firebase CLI not found!" -ForegroundColor Red
    Write-Host "Please install: npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}

# Step 2: Login to Firebase
Write-Host "`n[2/6] Logging in to Firebase..." -ForegroundColor Green
Write-Host "Please login with your OLD Firebase account" -ForegroundColor Yellow
firebase login

# Step 3: Set project
Write-Host "`n[3/6] Setting Firebase project..." -ForegroundColor Green
firebase use $OLD_PROJECT_ID

# Step 4: Export Authentication Users
Write-Host "`n[4/6] Exporting Authentication users..." -ForegroundColor Green
$authBackupPath = "$BACKUP_DIR\auth-users-backup.json"
try {
    firebase auth:export $authBackupPath --format=JSON --project $OLD_PROJECT_ID
    Write-Host "✓ Authentication users exported to: $authBackupPath" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to export auth users. Error: $_" -ForegroundColor Red
    Write-Host "You can export manually from Firebase Console" -ForegroundColor Yellow
}

# Step 5: Export Realtime Database
Write-Host "`n[5/6] Exporting Realtime Database..." -ForegroundColor Green
$dbBackupPath = "$BACKUP_DIR\realtime-database-backup.json"
try {
    $dbData = firebase database:get / --project $OLD_PROJECT_ID
    $dbData | Out-File -FilePath $dbBackupPath -Encoding UTF8
    Write-Host "✓ Realtime Database exported to: $dbBackupPath" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to export Realtime Database. Error: $_" -ForegroundColor Red
    Write-Host "You can export manually from Firebase Console → Database → Export JSON" -ForegroundColor Yellow
}

# Step 6: Export Firestore (requires gcloud)
Write-Host "`n[6/6] Exporting Firestore..." -ForegroundColor Green
Write-Host "Checking for gcloud CLI..." -ForegroundColor Yellow
try {
    $gcloudVersion = gcloud --version
    Write-Host "✓ gcloud CLI found" -ForegroundColor Green
    
    # Set project
    gcloud config set project $OLD_PROJECT_ID
    
    # Export Firestore
    Write-Host "Exporting Firestore to Cloud Storage..." -ForegroundColor Yellow
    $firestoreBackupPath = "gs://$OLD_PROJECT_ID.firebasestorage.app/firestore-backup-export"
    gcloud firestore export $firestoreBackupPath
    
    # Download the export
    Write-Host "Downloading Firestore backup..." -ForegroundColor Yellow
    gsutil -m cp -r $firestoreBackupPath "$BACKUP_DIR\firestore-backup"
    Write-Host "✓ Firestore exported to: $BACKUP_DIR\firestore-backup" -ForegroundColor Green
} catch {
    Write-Host "✗ gcloud CLI not found or Firestore export failed" -ForegroundColor Red
    Write-Host "Install gcloud: https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
    Write-Host "Or export manually from Cloud Console" -ForegroundColor Yellow
}

# Step 7: Export Storage Files
Write-Host "`n[7/6] Exporting Storage files..." -ForegroundColor Green
try {
    $storageBackupPath = "$BACKUP_DIR\storage-backup"
    gsutil -m cp -r "gs://$OLD_PROJECT_ID.firebasestorage.app" $storageBackupPath
    Write-Host "✓ Storage files exported to: $storageBackupPath" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to export Storage files. Error: $_" -ForegroundColor Red
    Write-Host "You may not have storage files or gsutil is not configured" -ForegroundColor Yellow
}

# Summary
Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "  EXPORT COMPLETE!" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "`nBackup location: $BACKUP_DIR" -ForegroundColor Green
Write-Host "`nExported files:" -ForegroundColor Yellow
Get-ChildItem -Path $BACKUP_DIR -Recurse | Select-Object FullName

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Create a new Firebase project in Firebase Console" -ForegroundColor White
Write-Host "2. Note down the new project ID" -ForegroundColor White
Write-Host "3. Run the IMPORT script: .\firebase-migrate-import.ps1" -ForegroundColor White

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
