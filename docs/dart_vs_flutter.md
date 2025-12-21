# Dart vs. Flutter Implementation

You asked why the current `budgetizer` package and specifically the `BankService` cannot be run as a pure Dart application and requires the Flutter engine. This document outlines the specific blockers and architectural reasons.

## 1. Native SDK Dependencies (Plaid)
The primary blocker for a "pure Dart" implementation of the *entire* flow is the **Plaid Link** integration.

-   **The Problem**: The `plaid_flutter` package is a wrapper around the **Plaid iOS SDK** and **Plaid Android SDK**. It relies on `MethodChannels` to communicate with the native operating system to launch the secure, embedded web view (Plaid Link flow) where authentication happens.
-   **Why strict Dart fails**: A pure Dart process (like `dart bin/main.dart`) runs in a standalone VM with no access to iOS/Android rendering surfaces or native APIs. It cannot open the Plaid SDK UI.

## 2. Flutter Services (Assets & Configuration)
The current implementation of `BankService` and `MockBankService` relies on Flutter-specific mechanisms for data loading.

-   **`rootBundle`**: The `MockBankService` uses `rootBundle.loadString()` to read the local JSON mock data. `rootBundle` is part of `package:flutter/services.dart` and requires a running Flutter engine to access assets packaged with the app.
-   **`flutter_dotenv`**: The configuration is loaded using `flutter_dotenv`, which also relies on `rootBundle` to read the `.env` file from the build assets.
-   **Result**: Running this code in a standard Dart environment throws `NotInitializedError` or missing binding errors because the Flutter services binding hasn't been initialized.

## 3. Dependency Injection (Riverpod)
We are currently using `flutter_riverpod`.
-   While `riverpod` exists as a pure Dart package, `flutter_riverpod` adds widget-layer bindings (`ProviderScope`, `ConsumerWidget`). Mixing these into the business logic layer (even via imports) makes the code dependent on the Flutter SDK.

## Path to a Pure Dart Library
To achieve your goal of having a core "Budgetization" library that works in pure Dart (e.g., for a CLI tool or server-side component), we would need to refactor the architecture:

1.  **Split the Architecture**:
    -   `budgetizer_core` (Dart Only): Models (`BankTransaction`), API Clients (HTTP calls to Plaid), and Business Logic.
    -   `budgetizer_flutter` (Flutter): UI Components, Plaid Link invocation, and Asset Loading bridges.
2.  **Abstract Interfaces**:
    -   Define a `ConfigurationService` interface.
        -   *Flutter impl*: Uses `flutter_dotenv`.
        -   *Dart impl*: Uses `dart:io` `Platform.environment` or `dotenv` (pure Dart package).
    -   Define a `FileService` interface.
        -   *Flutter impl*: Uses `rootBundle`.
        -   *Dart impl*: Uses `dart:io` `File`.
3.  **Isolate Plaid Link**:
    -   The `PlaidLink.open()` call must remain strictly in the Flutter UI layer, not in the `BankService`. The Service should only handle the API calls (Token Exchange, Fetch Transactions) which *can* be pure Dart (using `package:http`).

### Summary
The current codebase is a **Flutter App**, not a **Dart Library**. To support pure Dart apps, we must decouple the core logic from `flutter/services.dart` and native plugins like `plaid_flutter`.
