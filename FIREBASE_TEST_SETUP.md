# Firebase Test Project Setup Guide

## Part 1: Create a Firebase Project (Free)

1. **Go to [Firebase Console](https://console.firebase.google.com)**
2. **Click "Create a project" or "Add project"**
3. **Enter project name**: `StudyMateAI` (or any name)
4. **Accept terms** and click **Continue**
5. **Google Analytics**: You can disable it for testing, click **Continue**
6. **Click "Create project"** - Wait 1-2 minutes for setup to complete

---

## Part 2: Enable Email/Password Authentication

1. From Firebase Console, click your project
2. In left sidebar, click **Authentication**
3. Click **Get Started** or **Sign-in method**
4. Find **Email/Password**
5. Click the **Email/Password** option
6. **Toggle the switch to ON** (it should turn blue)
7. Click **Save**

✅ **Done!** Authentication is now enabled.

---

## Part 3: Create Android App in Firebase

1. In Firebase Console, click **Project Settings** (⚙️ gear icon, top left)
2. Click **Your apps** tab
3. Click **Add app** → Select **Android**
4. Fill in:
   - **Android package name**: `com.studymate.ai`
   - **App nickname**: `StudyMateAI Android` (optional)
5. Click **Register app**
6. **Important**: Download `google-services.json`
   - Click **Download google-services.json**
   - **Save it to**: `c:\Users\Ayesha\OneDrive\Desktop\StudyMateAi\studymate_ai\android\app\google-services.json`

---

## Part 4: Copy Your Credentials

### Method 1: From Firebase Console (Easiest)

1. In Firebase Console, click **Project Settings** (⚙️ gear icon)
2. Click **Your apps** → Click your Android app
3. You should see this section - **Copy these values**:

```
API KEY: AIzaSy...
APP ID: 1:123...
MESSAGING SENDER ID: 123...
PROJECT ID: studymateai-xxxxx
STORAGE BUCKET: studymateai-xxxxx.appspot.com
```

### Method 2: From the Downloaded google-services.json

1. Open `android/app/google-services.json` in VS Code
2. Find this section and copy the values:

```json
{
  "project_info": {
    "project_number": "COPY_MESSAGING_SENDER_ID",
    "project_id": "COPY_PROJECT_ID",
    "storage_bucket": "COPY_STORAGE_BUCKET"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "COPY_APP_ID"
      },
      "api_key": [
        {
          "current_key": "COPY_API_KEY"
        }
      ]
    }
  ]
}
```

---

## Part 5: Update firebase_options.dart

Once you have your credentials, update `lib/firebase_options.dart`:

**Replace** this section:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',
  appId: 'YOUR_ANDROID_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_STORAGE_BUCKET',
);
```

**With** your actual values (example):

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyB2J4XZ...',           // From google-services.json or Firebase Console
  appId: '1:123456789:android:abc...',  // From google-services.json
  messagingSenderId: '123456789',       // From google-services.json (project_number)
  projectId: 'studymateai-abc123',      // From Firebase Console
  storageBucket: 'studymateai-abc123.appspot.com', // From Firebase Console
);
```

---

## Part 6: Set Up Firestore

1. In Firebase Console, click **Firestore Database** (or **Cloud Firestore**)
2. Click **Create database**
3. Choose region (default is fine)
4. **Security rules**: Select **Start in test mode** (for now)
5. Click **Create**
6. Click **Rules** tab
7. **Replace all text** with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow all operations for now (test mode)
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

8. Click **Publish**

---

## Part 7: Set Up Cloud Storage

1. In Firebase Console, click **Storage**
2. Click **Get Started**
3. Choose location and click **Next**
4. For rules, replace with:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true;
    }
  }
}
```

5. Click **Done**

---

## Part 8: Test It Out

1. **Run the app**:
   ```bash
   cd c:\Users\Ayesha\OneDrive\Desktop\StudyMateAi\studymate_ai
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Try signing up**:
   - Email: `test@example.com`
   - Password: `Test@123456` (must be 6+ chars)

3. **If it works**: You should see "Account created successfully!"

---

## Part 9: Find Your Values (Visual Guide)

### In Firebase Console → Project Settings → Your Apps:

```
┌─ Your apps
│  ├─ Android (click this)
│  │  ├─ Android package name: com.studymate.ai
│  │  └─ [Shows:]
│  │     ├─ API KEY
│  │     ├─ APP ID
│  │     └─ Other options
│  └─ Download google-services.json (button)
```

### In google-services.json file:

```json
{
  "project_info": {
    "project_number": "✓ COPY THIS (messagingSenderId)",
    "project_id": "✓ COPY THIS (projectId)",
    "storage_bucket": "✓ COPY THIS"
  },
  "client": [{
    "client_info": {
      "mobilesdk_app_id": "✓ COPY THIS (appId)"
    },
    "api_key": [{
      "current_key": "✓ COPY THIS (apiKey)"
    }]
  }]
}
```

---

## Troubleshooting

### "No Firebase project"
- Make sure you created a project at console.firebase.google.com

### Still seeing "Signup failed"
- Check your credentials are NOT the placeholder values
- Make sure google-services.json is in `android/app/`
- Try `flutter clean` then `flutter run`

### "Permission denied"
- You're in test mode, rules should allow all
- If not, update Firestore rules as shown above

---

## Quick Summary

✅ Create Firebase project
✅ Enable Email/Password Auth
✅ Create Android app
✅ Download google-services.json → Save to android/app/
✅ Copy credentials to firebase_options.dart
✅ Set up Firestore (test mode)
✅ Set up Cloud Storage (test mode)
✅ Run app and test signup

Once done, come back and tell me if signup works!
