# Firebase Migration Script - IMPORT Phase
# This script imports all data to the NEW Firebase project
# Run this script in PowerShell AFTER running the export script

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Firebase Migration - IMPORT to NEW Project" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Prompt for new project ID
Write-Host "Enter your NEW Firebase Project ID:" -ForegroundColor Yellow
$NEW_PROJECT_ID = Read-Host

if ([string]::IsNullOrWhiteSpace($NEW_PROJECT_ID)) {
    Write-Host "✗ Project ID cannot be empty!" -ForegroundColor Red
    exit 1
}

Write-Host "`nUsing NEW Project ID: $NEW_PROJECT_ID" -ForegroundColor Green

# Find the most recent backup directory
Write-Host "`nLooking for backup directory..." -ForegroundColor Yellow
$backupDirs = Get-ChildItem -Directory | Where-Object { $_.Name -like "firebase-backup-*" } | Sort-Object Name -Descending
if ($backupDirs.Count -eq 0) {
    Write-Host "✗ No backup directory found!" -ForegroundColor Red
    Write-Host "Please run the export script first: .\firebase-migrate-export.ps1" -ForegroundColor Yellow
    exit 1
}

$BACKUP_DIR = $backupDirs[0].Name
Write-Host "✓ Found backup: $BACKUP_DIR" -ForegroundColor Green

# Confirm before proceeding
Write-Host "`nWARNING: This will import data to $NEW_PROJECT_ID" -ForegroundColor Red
Write-Host "Make sure you have:" -ForegroundColor Yellow
Write-Host "  1. Created the new Firebase project" -ForegroundColor White
Write-Host "  2. Enabled Authentication, Realtime Database, Firestore, and Storage" -ForegroundColor White
Write-Host "  3. Configured the same authentication methods as old project" -ForegroundColor White
Write-Host "`nProceed with import? (Y/N): " -ForegroundColor Yellow -NoNewline
$confirm = Read-Host

if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Import cancelled." -ForegroundColor Yellow
    exit 0
}

# Step 1: Set new project
Write-Host "`n[1/5] Setting Firebase project to NEW project..." -ForegroundColor Green
firebase use $NEW_PROJECT_ID

# Step 2: Import Authentication Users
Write-Host "`n[2/5] Importing Authentication users..." -ForegroundColor Green
$authBackupPath = "$BACKUP_DIR\auth-users-backup.json"
if (Test-Path $authBackupPath) {
    try {
        firebase auth:import $authBackupPath --hash-algo=SCRYPT --project $NEW_PROJECT_ID
        Write-Host "✓ Authentication users imported successfully!" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to import auth users. Error: $_" -ForegroundColor Red
        Write-Host "You may need to import manually or check hash algorithm" -ForegroundColor Yellow
    }
} else {
    Write-Host "⊘ No auth backup found, skipping..." -ForegroundColor Yellow
}

# Step 3: Import Realtime Database
Write-Host "`n[3/5] Importing Realtime Database..." -ForegroundColor Green
$dbBackupPath = "$BACKUP_DIR\realtime-database-backup.json"
if (Test-Path $dbBackupPath) {
    Write-Host "WARNING: This will overwrite the entire database!" -ForegroundColor Red
    Write-Host "Continue? (Y/N): " -NoNewline -ForegroundColor Yellow
    $confirmDB = Read-Host
    if ($confirmDB -eq "Y" -or $confirmDB -eq "y") {
        try {
            firebase database:set / $dbBackupPath --project $NEW_PROJECT_ID --confirm
            Write-Host "✓ Realtime Database imported successfully!" -ForegroundColor Green
        } catch {
            Write-Host "✗ Failed to import Realtime Database. Error: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "⊘ Skipped Realtime Database import" -ForegroundColor Yellow
    }
} else {
    Write-Host "⊘ No database backup found, skipping..." -ForegroundColor Yellow
}

# Step 4: Import Firestore
Write-Host "`n[4/5] Importing Firestore..." -ForegroundColor Green
$firestoreBackupPath = "$BACKUP_DIR\firestore-backup"
if (Test-Path $firestoreBackupPath) {
    try {
        # Upload to new project's storage
        Write-Host "Uploading Firestore backup to Cloud Storage..." -ForegroundColor Yellow
        gsutil -m cp -r $firestoreBackupPath "gs://$NEW_PROJECT_ID.firebasestorage.app/"
        # Import from storage
        Write-Host "Importing Firestore from Cloud Storage..." -ForegroundColor Yellow
        gcloud config set project $NEW_PROJECT_ID
        gcloud firestore import "gs://$NEW_PROJECT_ID.firebasestorage.app/firestore-backup"
        Write-Host "✓ Firestore imported successfully!" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to import Firestore. Error: $_" -ForegroundColor Red
        Write-Host "Make sure gcloud is installed and configured" -ForegroundColor Yellow
    }
} else {
    Write-Host "⊘ No Firestore backup found, skipping..." -ForegroundColor Yellow
}

# Step 5: Import Storage Files
Write-Host "`n[5/5] Importing Storage files..." -ForegroundColor Green
$storageBackupPath = "$BACKUP_DIR\storage-backup"
if (Test-Path $storageBackupPath) {
    try {
        gsutil -m cp -r "$storageBackupPath/*" "gs://$NEW_PROJECT_ID.firebasestorage.app/"
        Write-Host "✓ Storage files imported successfully!" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to import Storage files. Error: $_" -ForegroundColor Red
    }
} else {
    Write-Host "⊘ No storage backup found, skipping..." -ForegroundColor Yellow
}

# Summary
Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "  IMPORT COMPLETE!" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Update Flutter app configuration:" -ForegroundColor White
Write-Host "   flutterfire configure --project=$NEW_PROJECT_ID" -ForegroundColor Gray
Write-Host "`n2. Clean and rebuild the app:" -ForegroundColor White
Write-Host "   flutter clean" -ForegroundColor Gray
Write-Host "   flutter pub get" -ForegroundColor Gray
Write-Host "   flutter run -d windows" -ForegroundColor Gray
Write-Host "`n3. Test all Firebase features in the app" -ForegroundColor White
Write-Host "   - Authentication (login/register)" -ForegroundColor Gray
Write-Host "   - Realtime Database (rides data)" -ForegroundColor Gray
Write-Host "   - Firestore (user profiles)" -ForegroundColor Gray
Write-Host "   - Storage (file uploads)" -ForegroundColor Gray

Write-Host "`n4. Run the app update script:" -ForegroundColor White
Write-Host "   .\firebase-update-app.ps1" -ForegroundColor Gray

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
