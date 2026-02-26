# Firebase App Update Script
# This script updates the Flutter app to use the NEW Firebase project
# Run this script AFTER importing data to the new project

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Update Flutter App - NEW Firebase Project" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Prompt for new project ID
Write-Host "Enter your NEW Firebase Project ID:" -ForegroundColor Yellow
$NEW_PROJECT_ID = Read-Host

if ([string]::IsNullOrWhiteSpace($NEW_PROJECT_ID)) {
    Write-Host "✗ Project ID cannot be empty!" -ForegroundColor Red
    exit 1
}

Write-Host "`nUpdating app to use: $NEW_PROJECT_ID" -ForegroundColor Green

# Step 1: Check if FlutterFire CLI is installed
Write-Host "`n[1/5] Checking FlutterFire CLI installation..." -ForegroundColor Green
try {
    $flutterfireVersion = flutterfire --version
    Write-Host "✓ FlutterFire CLI found: $flutterfireVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠ FlutterFire CLI not found. Installing..." -ForegroundColor Yellow
    try {
        dart pub global activate flutterfire_cli
        Write-Host "✓ FlutterFire CLI installed successfully!" -ForegroundColor Green
        
        # Add to PATH if needed
        Write-Host "`nIMPORTANT: Add Dart global packages to PATH:" -ForegroundColor Yellow
        Write-Host "  %USERPROFILE%\AppData\Local\Pub\Cache\bin" -ForegroundColor Gray
        Write-Host "Then restart PowerShell and run this script again." -ForegroundColor Yellow
        exit 0
    } catch {
        Write-Host "✗ Failed to install FlutterFire CLI. Error: $_" -ForegroundColor Red
        Write-Host "Please install manually: dart pub global activate flutterfire_cli" -ForegroundColor Yellow
        exit 1
    }
}

# Step 2: Backup current configuration
Write-Host "`n[2/5] Backing up current Firebase configuration..." -ForegroundColor Green
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
$backupDir = "firebase-config-backup-$timestamp"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

if (Test-Path "lib\firebase_options.dart") {
    Copy-Item "lib\firebase_options.dart" "$backupDir\firebase_options.dart"
    Write-Host "✓ Backed up firebase_options.dart" -ForegroundColor Green
}

if (Test-Path "android\app\google-services.json") {
    Copy-Item "android\app\google-services.json" "$backupDir\google-services.json"
    Write-Host "✓ Backed up google-services.json" -ForegroundColor Green
}

if (Test-Path "ios\Runner\GoogleService-Info.plist") {
    Copy-Item "ios\Runner\GoogleService-Info.plist" "$backupDir\GoogleService-Info.plist"
    Write-Host "✓ Backed up GoogleService-Info.plist" -ForegroundColor Green
}

Write-Host "Backup saved to: $backupDir" -ForegroundColor Green

# Step 3: Configure new Firebase project
Write-Host "`n[3/5] Configuring new Firebase project..." -ForegroundColor Green
Write-Host "This will update all Firebase configuration files." -ForegroundColor Yellow
Write-Host "`nPlease select the platforms when prompted:" -ForegroundColor Yellow
Write-Host "  - Android: Yes" -ForegroundColor White
Write-Host "  - iOS: Yes (if you have iOS setup)" -ForegroundColor White
Write-Host "  - Web: Yes" -ForegroundColor White
Write-Host "  - Windows: Yes" -ForegroundColor White
Write-Host "  - macOS: Yes (if you have macOS setup)" -ForegroundColor White
Write-Host ""

try {
    flutterfire configure --project=$NEW_PROJECT_ID
    Write-Host "✓ Firebase configuration updated successfully!" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to configure Firebase. Error: $_" -ForegroundColor Red
    Write-Host "`nRestoring backup..." -ForegroundColor Yellow
    if (Test-Path "$backupDir\firebase_options.dart") {
        Copy-Item "$backupDir\firebase_options.dart" "lib\firebase_options.dart" -Force
    }
    if (Test-Path "$backupDir\google-services.json") {
        Copy-Item "$backupDir\google-services.json" "android\app\google-services.json" -Force
    }
    Write-Host "✓ Backup restored" -ForegroundColor Green
    exit 1
}

# Step 4: Verify updated files
Write-Host "`n[4/5] Verifying updated files..." -ForegroundColor Green

$updatedFiles = @()

if (Test-Path "lib\firebase_options.dart") {
    $content = Get-Content "lib\firebase_options.dart" -Raw
    if ($content -match $NEW_PROJECT_ID) {
        Write-Host "✓ lib\firebase_options.dart - Updated" -ForegroundColor Green
        $updatedFiles += "lib\firebase_options.dart"
    } else {
        Write-Host "⚠ lib\firebase_options.dart - May not be updated" -ForegroundColor Yellow
    }
}

if (Test-Path "android\app\google-services.json") {
    $content = Get-Content "android\app\google-services.json" -Raw
    if ($content -match $NEW_PROJECT_ID) {
        Write-Host "✓ android\app\google-services.json - Updated" -ForegroundColor Green
        $updatedFiles += "android\app\google-services.json"
    } else {
        Write-Host "⚠ android\app\google-services.json - May not be updated" -ForegroundColor Yellow
    }
}

if (Test-Path "ios\Runner\GoogleService-Info.plist") {
    $updatedFiles += "ios\Runner\GoogleService-Info.plist"
    Write-Host "✓ ios\Runner\GoogleService-Info.plist - Updated" -ForegroundColor Green
}

# Step 5: Clean and rebuild
Write-Host "`n[5/5] Cleaning and rebuilding project..." -ForegroundColor Green

Write-Host "`nRunning flutter clean..." -ForegroundColor Yellow
flutter clean

Write-Host "`nGetting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "✓ Project cleaned and dependencies updated!" -ForegroundColor Green

# Summary
Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "  FIREBASE APP UPDATE COMPLETE!" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Write-Host "`nUpdated Files:" -ForegroundColor Yellow
foreach ($file in $updatedFiles) {
    Write-Host "  ✓ $file" -ForegroundColor Green
}

Write-Host "`nConfiguration Backup:" -ForegroundColor Yellow
Write-Host "  📁 $backupDir" -ForegroundColor Gray

Write-Host "`nNew Firebase Project:" -ForegroundColor Yellow
Write-Host "  🔥 $NEW_PROJECT_ID" -ForegroundColor Cyan

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Build and run the app:" -ForegroundColor White
Write-Host "   flutter run -d windows" -ForegroundColor Gray

Write-Host "`n2. Test all Firebase features:" -ForegroundColor White
Write-Host "   ✓ Authentication - Try logging in with existing credentials" -ForegroundColor Gray
Write-Host "   ✓ Realtime Database - Check if rides data loads" -ForegroundColor Gray
Write-Host "   ✓ Firestore - Verify user profiles" -ForegroundColor Gray
Write-Host "   ✓ Storage - Test file uploads" -ForegroundColor Gray

Write-Host "`n3. If everything works:" -ForegroundColor White
Write-Host "   - Build release versions for production" -ForegroundColor Gray
Write-Host "   - Update app in stores with new version" -ForegroundColor Gray
Write-Host "   - Monitor old project for 1-2 weeks before deactivating" -ForegroundColor Gray

Write-Host "`n4. If issues occur:" -ForegroundColor White
Write-Host "   - Check Firebase Console for service status" -ForegroundColor Gray
Write-Host "   - Verify security rules are deployed" -ForegroundColor Gray
Write-Host "   - Restore backup from: $backupDir" -ForegroundColor Gray

Write-Host "`nReady to test? (Y/N): " -ForegroundColor Yellow -NoNewline
$runNow = Read-Host

if ($runNow -eq "Y" -or $runNow -eq "y") {
    Write-Host "`nStarting app on Windows..." -ForegroundColor Green
    flutter run -d windows
} else {
    Write-Host "`nYou can run the app later with: flutter run -d windows" -ForegroundColor Yellow
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
