# Firebase Setup Complete Guide

## Step 1: Enable Email/Password Authentication

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Click **Authentication** in the left sidebar
4. Go to **Sign-in method** tab
5. Click **Email/Password**
6. Toggle **Enable** (the switch should be blue)
7. Click **Save**

---

## Step 2: Get Firebase Credentials

1. In Firebase Console, go to **Project Settings** (gear icon, top left)
2. Click **Your apps** section
3. Look for your Android/iOS app - if not there, add it:
   - Click **Add app**
   - Select **Android** or **iOS**
   - For Android: Get `google-services.json`
   - For iOS: Get `GoogleService-Info.plist`

### For Web (if testing in web):
1. Click the **Web** icon `</>`
2. Register app with name "StudyMate AI Web"
3. Copy the `firebaseConfig` object shown

### For Android specifically:
1. Go to Project Settings → Apps → Android app
2. Download `google-services.json`
3. Place it in: `android/app/google-services.json`

### Update firebase_options.dart with Android Credentials:

Replace placeholders in `lib/firebase_options.dart` with these values from Google Cloud Console:

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your Firebase project
3. APIs & Services → Credentials
4. Look for "API Key" (not OAuth client)
5. Also find your Project ID

The values you need:
- **apiKey**: Your API Key from Google Cloud
- **appId**: Find in Firebase Console → Project Settings → Apps → App ID
- **messagingSenderId**: In Firebase Console → Project Settings → Cloud Messaging tab
- **projectId**: Your Firebase project ID
- **storageBucket**: `{projectId}.appspot.com`
- **authDomain**: `{projectId}.firebaseapp.com`

Update `lib/firebase_options.dart` - for **Android**:
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ACTUAL_API_KEY_HERE',
  appId: 'YOUR_ACTUAL_APP_ID_HERE',
  messagingSenderId: 'YOUR_ACTUAL_MESSAGING_SENDER_ID_HERE',
  projectId: 'YOUR_ACTUAL_PROJECT_ID_HERE',
  storageBucket: 'YOUR_PROJECT_ID_HERE.appspot.com',
);
```

---

## Step 3: Set Up Firestore Security Rules

1. In Firebase Console, go to **Firestore Database**
2. Click **Rules** tab
3. Replace all existing rules with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own data
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Specific rules for collections
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
    }
    
    match /feedback/{document=**} {
      allow create: if request.auth != null;
      allow read: if request.auth != null;
    }
    
    match /notes/{document=**} {
      allow create, read: if request.auth != null;
      allow write: if request.auth.uid == resource.data.userId;
    }
  }
}
```

4. Click **Publish**

---

## Step 4: Enable Cloud Storage

1. In Firebase Console, go to **Storage**
2. Click **Get Started**
3. Choose location (default is fine)
4. For security rules, use:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

5. Click **Done**

---

## Step 5: Verify Configuration

After updating `firebase_options.dart`, test by running:

```bash
cd c:\Users\Ayesha\OneDrive\Desktop\StudyMateAi\studymate_ai
flutter clean
flutter pub get
flutter run
```

---

## Troubleshooting

### "Signup failed" with no error code
- Check Firebase is initialized with real credentials (not placeholders)
- Verify Email/Password provider is enabled

### "Permission denied" error
- Make sure Firestore rules are updated (Step 3)
- Make sure user is authenticated before Firestore operations

### "Network error"
- Check internet connection
- Verify Firebase project is accessible

### "Invalid API Key"
- Get the correct API key from Google Cloud Console
- Make sure it's not restricted to specific services

---

## Files to Update

- ✅ `lib/firebase_options.dart` - Add real Firebase credentials
- ✅ `android/app/google-services.json` - Place downloaded file here
- ✅ Firebase Console - Enable Auth, set Firestore rules, enable Storage

Once these are done, the signup/login should work!
