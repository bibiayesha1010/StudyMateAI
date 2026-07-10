# Create Firebase Project - Step-by-Step

## Step 1: Go to Firebase Console

1. Open your browser and go to: **https://console.firebase.google.com**
2. If you're not logged in, sign in with your Google account
   - If you don't have one, create a free Google account at https://accounts.google.com

---

## Step 2: Create a New Project

### On the Firebase Console home page:

```
┌─────────────────────────────────┐
│  Firebase                       │
│  Get started by creating a new  │
│  project                        │
│                                 │
│  [+ Create a project]  ← CLICK  │
└─────────────────────────────────┘
```

---

## Step 3: Project Setup

### Screen 1 - Project Name
```
Project name: StudyMateAI
               ↓ (Type this)
```
- **Click in the text box**
- **Type**: `StudyMateAI`
- **Click "Continue"**

### Screen 2 - Google Analytics
```
Enable Google Analytics for this project?
○ Yes (default)
● No  ← SELECT THIS (for testing)
```
- **Click "No" option**
- **Click "Create project"**

### Wait 1-2 minutes
Firebase will create your project. You'll see a loading screen, then a success message.

**Click "Continue"** when done.

---

## Step 4: Add Android App to Firebase

### You should now be on the Firebase Console

```
┌──────────────────────────────────┐
│  Get started by adding Firebase  │
│  to your app                     │
│                                  │
│  [Android icon]  ← CLICK THIS   │
│  [iOS icon]                      │
│  [Web icon]                      │
└──────────────────────────────────┘
```

- **Click the Android icon** (looks like the Android logo)

### Register Android App

Fill in the form:

```
Android package name: com.studymate.ai
                      ↓ (Copy/paste this exactly)

App nickname (optional): StudyMateAI Android
                         ↓ (Optional, type anything)

SHA-1 certificate fingerprint: (Leave empty for now)
```

**Click "Register app"**

---

## Step 5: Download google-services.json

You should see a blue button:

```
[↓ Download google-services.json]
```

- **Click this button**
- A file `google-services.json` will download
- **Open File Explorer**
- **Navigate to**: `C:\Users\Ayesha\OneDrive\Desktop\StudyMateAi\studymate_ai\android\app\`
- **Paste the file there**

Check that the file is at: `studymate_ai\android\app\google-services.json`

---

## Step 6: Get Your Credentials

**Keep the Firebase Console open** and look for this information. There should be a section showing:

### Method A: From Firebase Console (Look for a box with):

```
┌─────────────────────────────────┐
│ Android Configuration           │
│                                 │
│ API Key:                        │
│ AIzaSyB2J4XZ_xxxxx... ← COPY   │
│                                 │
│ App ID:                         │
│ 1:123456789:android:abc... ← COPY
│                                 │
│ Sender ID:                      │
│ 123456789 ← COPY                │
│                                 │
│ Project ID:                     │
│ studymateai-abc123 ← COPY       │
└─────────────────────────────────┘
```

If you don't see this, click "Next" a few times in the setup wizard.

### Method B: From google-services.json file

1. **Right-click** the `google-services.json` file you just saved
2. **Open with** → **Visual Studio Code** (or any text editor)
3. **Look for these sections** and copy the values:

```json
{
  "project_info": {
    "project_number": "123456789",  ← COPY AS messagingSenderId
    "project_id": "studymateai-abc123",  ← COPY AS projectId
    "storage_bucket": "studymateai-abc123.appspot.com"  ← COPY
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789:android:abc..."  ← COPY AS appId
      },
      "api_key": [
        {
          "current_key": "AIzaSyB2J4XZ..."  ← COPY AS apiKey
        }
      ]
    }
  ]
}
```

---

## Step 7: Your Credentials (Fill These In)

### Copy YOUR values here:

```
apiKey: ___________________________________

appId: ____________________________________

messagingSenderId: _________________________

projectId: _________________________________

storageBucket: ______________________________
```

---

## Step 8: Update firebase_options.dart

**Open in VS Code**: `lib/firebase_options.dart`

**Find lines 33-39** and replace:

```dart
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );
```

**With YOUR actual values**:

```dart
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB2J4XZ...',  ← PASTE YOUR API KEY
    appId: '1:123456789:android:abc...',  ← PASTE YOUR APP ID
    messagingSenderId: '123456789',  ← PASTE YOUR SENDER ID
    projectId: 'studymateai-abc123',  ← PASTE YOUR PROJECT ID
    storageBucket: 'studymateai-abc123.appspot.com',  ← PASTE YOUR BUCKET
  );
```

**Save the file** (Ctrl+S)

---

## Step 9: Back in Firebase Console - Enable Authentication

1. In the Firebase Console, click **Authentication** (left sidebar)
2. Click **Get Started** or **Sign-in method**
3. Find **Email/Password**
4. **Click the Email/Password option**
5. **Toggle ON** (switch should turn blue)
6. **Click Save**

---

## Step 10: Set Up Firestore Database

1. Click **Firestore Database** (left sidebar)
2. Click **Create database**
3. Choose your region (default is fine)
4. Select **Start in test mode**
5. Click **Create**
6. Click **Rules** tab
7. Replace all text with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

8. Click **Publish**

---

## Step 11: Set Up Cloud Storage

1. Click **Storage** (left sidebar)
2. Click **Get Started**
3. Choose location and click **Next**
4. Replace rules with:

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

## Step 12: Test Your App

1. **Open terminal** in VS Code
2. **Run**:
   ```bash
   cd c:\Users\Ayesha\OneDrive\Desktop\StudyMateAi\studymate_ai
   flutter clean
   flutter pub get
   flutter run
   ```

3. **Try to sign up** with:
   - Email: `test@example.com`
   - Password: `Test@123456`

4. **Check the console** for messages like:
   - ✅ `Firebase initialized successfully` = Good!
   - ❌ Error message = Check your credentials

---

## Troubleshooting

### "Still seeing placeholder values"
- Make sure you're editing `lib/firebase_options.dart`
- Make sure you replaced ALL 5 placeholder lines
- Save the file (Ctrl+S)

### "Firebase initialized successfully" but signup still fails
- Check that Email/Password auth is enabled
- Check that Firestore rules are published
- Check your internet connection

### Can't find credentials
- Open `android/app/google-services.json` in any text editor
- Search for `project_number`, `project_id`, `api_key`
- Copy the values shown in Step 6

---

## Quick Checklist

✅ Created Firebase project  
✅ Downloaded google-services.json to android/app/  
✅ Copied 5 credentials from Firebase Console or JSON file  
✅ Updated firebase_options.dart with real values  
✅ Enabled Email/Password authentication  
✅ Created Firestore database (test mode)  
✅ Created Cloud Storage (test mode)  
✅ Saved firebase_options.dart  
✅ Ran `flutter clean && flutter pub get && flutter run`  

**Once all done, test signup!**
