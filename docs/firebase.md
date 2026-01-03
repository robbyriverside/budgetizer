# Firebase Integration

This document outlines the Firebase features used by the web version of Budgetizer, how to test them using mocks, and how to set up your Firebase account.

## Used Features

The web application (`apps/web`) currently utilizes the following Firebase services:

### 1. Cloud Firestore
Used as the backend storage repository (replacing SQLite which is used on Desktop).
- **Implementation**: `apps/web/lib/services/firebase_service.dart`
- **Collections**:
  - `cashflow_cycles`: Stores budget cycles/cashflow data.
  - `reports`: Stores generated reports.
  - `settings`: Stores application settings (key-value pairs).

### 2. Firebase Core
- **Usage**: Initializes the Firebase app in `main.dart`.
- **Note**: Currently, `main.dart` attempts to initialize default options which requires `flutterfire configure` to be run.

> [!NOTE]
> **Firebase Authentication** is NOT currently implemented or used in the code. The app likely relies on open security rules or temporary access for development.

## Testing with Firebase Mocks

To test components that rely on Firebase without connecting to a live backend, we use the `fake_cloud_firestore` package. This allows you to instantiate a fake instance of Firestore that behaves like the real one but runs entirely in memory.

### 1. Add Dependencies
First, ensure you have the mock library in your `dev_dependencies` in `apps/web/pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  fake_cloud_firestore: ^3.0.0
```

### 2. Writing Tests
Here is an example of how to test the `FirebaseService` using a mock instance:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:budgetizer_web/services/firebase_service.dart'; // Adjust import path
import 'package:budgetizer_dart/budgetizer_dart.dart';

void main() {
  test('saves and retrieves a cycle', () async {
    // 1. Setup the fake instance
    final instance = FakeFirebaseFirestore();
    
    // 2. Inject it into your service
    // Note: You might need to refactor FirebaseService to accept an instance 
    // in its constructor rather than calling .instance directly.
    final service = FirebaseService(firestore: instance);
    
    // 3. Perform operations
    final cycle = Cashflow(id: '1', ...); 
    await service.saveCycle('cycle_1', cycle, 'type', 'cashflow_id');
    
    // 4. Verify results using the service or checking the fake instance
    final result = await service.getCycle('cycle_1');
    expect(result, isNotNull);
    
    // Verify direct storage
    final snapshot = await instance.collection('cashflow_cycles').doc('cycle_1').get();
    expect(snapshot.exists, true);
  });
}
```

> [!TIP]
> **Refactoring for Testability**: The current `FirebaseService` accesses `FirebaseFirestore.instance` directly. To test it effectively, modify the class to accept an optional `FirebaseFirestore` instance in the constructor:
> ```dart
> class FirebaseService implements StorageRepository {
>   final FirebaseFirestore _firestore;
>   
>   FirebaseService({FirebaseFirestore? firestore}) 
>     : _firestore = firestore ?? FirebaseFirestore.instance;
>   ...
> }
> ```

## Firebase Setup Guide

Follow these steps to set up a Firebase account and project for Budgetizer.

### 1. Create a Firebase Account
1.  Go to the [Firebase Console](https://console.firebase.google.com/).
2.  Sign in with your Google account.
3.  Click **Create a project**.

### 2. Create a Project
1.  Enter a project name (e.g., `budgetizer-web`).
2.  (Optional) Disable Google Analytics for this project if it's just for testing.
3.  Click **Create project**.

### 3. Enable Cloud Firestore
1.  In the left sidebar, navigate to **Build > Firestore Database**.
2.  Click **Create database**.
3.  Choose a **Location** (e.g., `nam5 (us-central)`).
4.  **Security Rules**: Start in **Test mode** (allows anyone to read/write for 30 days).
    *   *Warning*: For production, you must configure strict rules, especially since Auth is not integrated yet.
5.  Click **Enable**.

### 4. Register the Web App
1.  Go to **Project settings** (gear icon) > **General**.
2.  Under "Your apps", click the **Web (</>)** icon.
3.  Enter an App nickname (e.g., `Budgetizer Web`).
4.  (Optional) Check "Also set up Firebase Hosting" if you plan to host it there.
5.  Click **Register app**.

### 5. Configure the Codebase
You need to generate the `firebase_options.dart` file so the app knows how to connect to your project.

1.  **Install the Firebase CLI**:
    ```bash
    npm install -g firebase-tools
    firebase login
    ```
2.  **Install FlutterFire CLI**:
    ```bash
    dart pub global activate flutterfire_cli
    ```
3.  **Run Configuration**:
    Run this command from the root of your workspace (or `apps/web`):
    ```bash
    cd apps/web
    flutterfire configure
    ```
    *   Select your new project (`budgetizer-web`).
    *   Select `web` as the platform.
    *   This will generate `lib/firebase_options.dart`.

4.  **Update imports**:
    Uncomment the imports and initialization code in `apps/web/lib/main.dart`:
    ```dart
    import 'firebase_options.dart'; 
    
    // ... inside main()
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    ```

You are now ready to run `flutter run -d chrome`!
