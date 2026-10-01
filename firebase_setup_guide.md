# Firebase Backend Integration Guide

This guide covers the database structure, security rules, and necessary manual steps to fully integrate Firebase into the MP Citizen Engagement App.

## 1. Firestore Database Schema

### `users` collection
- **Document ID**: Unique User ID (`uid` from Firebase Auth)
- **Fields**:
  - `uid` (string)
  - `name` (string)
  - `phone` (string)
  - `area` (string)
  - `ward` (string)
  - `village` (string)
  - `role` (string) - `citizen`, `volunteer`, or `admin`
  - `points` (number)
  - `createdAt` (timestamp)

### `appointments` collection
- **Document ID**: Auto-generated
- **Fields**:
  - `userId` (string)
  - `date` (timestamp)
  - `timeSlot` (string)
  - `status` (string) - `pending`, `approved`, `rejected`
  - `reason` (string)
  - `createdAt` (timestamp)

### `complaints` collection
- **Document ID**: Auto-generated
- **Fields**:
  - `userId` (string)
  - `category` (string)
  - `description` (string)
  - `imageUrl` (string, nullable)
  - `status` (string) - `pending`, `in-progress`, `resolved`
  - `resolutionNotes` (string, nullable)
  - `createdAt` (timestamp)

### `projects` collection
- **Document ID**: Auto-generated
- **Fields**:
  - `title` (string)
  - `description` (string)
  - `beforeImage` (string, nullable)
  - `afterImage` (string, nullable)
  - `budget` (number)
  - `timeline` (string)
  - `location` (geopoint)
  - `status` (string) - `planned`, `ongoing`, `completed`
  - `createdAt` (timestamp)

### `events`, `news`, `surveys` collections
Follow the Dart models implemented in the codebase (`lib/models/`).

---

## 2. Firebase Security Rules

To ensure data privacy and correct access permissions, configure your Firestore Security Rules as follows:

Go to **Firebase Console** -> **Firestore Database** -> **Rules** and paste the following:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Check if the user is authenticated
    function isAuth() {
      return request.auth != null;
    }
    
    // Check if the user is an admin by querying the users collection
    function isAdmin() {
      return isAuth() && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // Users Collection: users can read/write their own data. Admins can read all.
    match /users/{userId} {
      allow read: if isAuth() && (request.auth.uid == userId || isAdmin());
      allow write: if isAuth() && (request.auth.uid == userId || isAdmin());
    }

    // Appointments & Complaints: users can read/write their own. Admins can manage all.
    match /appointments/{docId} {
      allow create: if isAuth();
      allow read: if isAuth() && (resource.data.userId == request.auth.uid || isAdmin());
      allow update, delete: if isAdmin(); // only admin modifies status
    }

    match /complaints/{docId} {
      allow create: if isAuth();
      allow read: if isAuth() && (resource.data.userId == request.auth.uid || isAdmin());
      allow update, delete: if isAdmin(); 
    }

    // Public Data (Projects, News, Events): anyone auth'd can read. Only admins can write.
    match /projects/{docId} {
      allow read: if isAuth();
      allow write: if isAdmin();
    }
    
    match /news/{docId} {
      allow read: if isAuth();
      allow write: if isAdmin();
    }
    
    match /events/{docId} {
      allow read: if isAuth();
      allow update: if isAuth(); // users can rsvp (update participants array)
      allow create, delete: if isAdmin();
    }
    
    match /surveys/{docId} {
      allow read: if isAuth();
      allow update: if isAuth(); // users can vote
      allow create, delete: if isAdmin();
    }
  }
}
```

## 3. Storage Rules

Go to **Firebase Console** -> **Storage** -> **Rules**:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /complaints/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null; // Users can upload complaint images
    }
    match /projects/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

## 4. Setting up FCM (Firebase Cloud Messaging)

1. Connect the app inside the Firebase Console.
2. If `firebase_messaging` is included (already in `pubspec.yaml`), add the setup code to your `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission();
  // ... run app
}
```

## 5. Google Sign In & OTP Setup

- **Phone OTP**: Ensure "Phone" is selected and enabled under *Authentication > Sign-in method*. Add SHA-1 and SHA-256 keys to your Firebase Android app settings.
- **Google Sign-In**: Enable "Google" under *Sign-in method*. You will need the Web Client ID config in `google_sign_in` package if applicable.
