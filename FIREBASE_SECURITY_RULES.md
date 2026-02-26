# Firebase Security Rules Setup Guide

## 🔒 Configure Firebase Security Rules

Your app is built successfully but needs security rules configured in Firebase Console.

---

## 📋 Step-by-Step Instructions

### 1. **Realtime Database Rules**

1. Go to: https://console.firebase.google.com/project/driver-app-9ede9/database
2. Click on **"Rules"** tab
3. Replace with this:

```json
{
  "rules": {
    ".read": "now < 1763269200000",
    ".write": "now < 1763269200000"
  }
}
```

4. Click **"Publish"**

---

### 2. **Firestore Database Rules**

1. Go to: https://console.firebase.google.com/project/driver-app-9ede9/firestore
2. Click on **"Rules"** tab
3. Replace with this (for testing):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

4. Click **"Publish"**

**For Production** (use this after testing):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Drivers collection
    match /drivers/{driverId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Riders collection
    match /riders/{riderId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Rides collection
    match /rides/{rideId} {
      allow read, write: if request.auth != null;
    }
    
    // GPS tracking
    match /gps_tracking/{trackingId} {
      allow read, write: if request.auth != null;
    }
    
    // Ride history
    match /ride_history/{historyId} {
      allow read, write: if request.auth != null;
    }
    
    // Notifications
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null;
    }
    
    // Support tickets
    match /support_tickets/{ticketId} {
      allow read, write: if request.auth != null;
    }
    
    // Earnings
    match /earnings/{earningId} {
      allow read, write: if request.auth != null;
    }
    
    // Settings
    match /settings/{userId} {
      allow read, write: if request.auth != null;
    }
    
    // Manual rides
    match /manual_rides/{rideId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

### 3. **Firebase Storage Rules**

1. Go to: https://console.firebase.google.com/project/driver-app-9ede9/storage
2. Click on **"Rules"** tab
3. Replace with this:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true;
    }
  }
}
```

4. Click **"Publish"**

**For Production** (use this after testing):

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile pictures - drivers
    match /profile_pictures/drivers/{driverId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Profile pictures - riders
    match /profile_pictures/riders/{riderId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Ride documents
    match /ride_documents/{rideId}/{fileName} {
      allow read, write: if request.auth != null;
    }
    
    // Company files
    match /company_files/{fileName} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Chat attachments
    match /chat_attachments/{chatId}/{messageId}/{fileName} {
      allow read, write: if request.auth != null;
    }
    
    // Support attachments
    match /support_attachments/{ticketId}/{fileName} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## ✅ After Setting Rules

1. Go back to your running test app
2. Click **"Create Sample Data"** button
3. Check the console for success messages
4. Verify in Firebase Console:
   - Firestore Database should show collections with sample data
   - Storage will show folders when files are uploaded

---

## 🔗 Quick Links

- **Realtime Database Rules**: https://console.firebase.google.com/project/driver-app-9ede9/database/rules
- **Firestore Rules**: https://console.firebase.google.com/project/driver-app-9ede9/firestore/rules
- **Storage Rules**: https://console.firebase.google.com/project/driver-app-9ede9/storage/rules

---

## ⚠️ Important Notes

### Test Mode Rules (Current)
- ✅ Allow all read/write operations
- ✅ Good for testing and development
- ❌ **NOT secure for production**
- ⏰ Set expiration date for safety

### Production Rules (After Testing)
- ✅ Require authentication
- ✅ Secure data access
- ✅ User-specific permissions
- ✅ Ready for production use

**Remember to switch to production rules before deploying your app!**

---

## 🚀 Next Steps

1. ✅ Set Realtime Database rules
2. ✅ Set Firestore rules
3. ✅ Set Storage rules
4. ✅ Click "Publish" for each
5. ✅ Run test app and create sample data
6. ✅ Verify data in Firebase Console

**After rules are set, your organized Firebase data structure will work perfectly!** 🎉
