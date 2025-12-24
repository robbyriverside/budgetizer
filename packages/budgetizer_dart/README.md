# Budgetizer Dart

A pure Dart library for the Budgetizer core budgeting logic. This project provides the data models, financial services, and logic needed to build budgeting applications, separated from any specific UI framework.

## Features

- **Pure Dart**: Core logic is independent of Flutter, enabling CLI and server-side usage.
- **Financial Models**: Robust definitions for Transactions, Cashflows, Cycles, and Tags.
- **Tag Engine**: Intelligent transaction tagging with regex support and efficient lookup.
- **Plaid Integration**: Custom pure Dart wrapper (`plaid_dart`) for interacting with the Plaid API.
- **Database Abstraction**: `DatabaseService` using `sqflite_common_ffi` for compatibility across platforms (Mobile, Desktop, CLI).

## Project Structure

- `lib/`: Core library code.
- `packages/`: Modularized internal packages.
  - `plaid_dart/`: Pure Dart client for Plaid API.
- `example/`: Example scripts and applications.
  - `budget_simulation.dart`: CLI simulation of budget logic.
  - `plaid_cli_test.dart`: CLI tool to test Plaid integration.
  - `flutter_example/`: Minimal Flutter app demonstrating library usage.

## Setup

1.  **Prerequisites**: Ensure you have the [Dart SDK](https://dart.dev/get-dart) installed (version >=3.2.0 <4.0.0).

2.  **Install Dependencies**:
    ```bash
    dart pub get
    ```

3.  **Local Environment**:
    For examples that require API keys (like Plaid), you may need to set environment variables.
    ```bash
    export PLAID_CLIENT_ID="your_client_id"
    export PLAID_SECRET="your_secret"
    ```

## Running Examples

### Budget Simulation
Runs a simulation of budget logic, including transaction tagging and budget period calculations.

```bash
dart example/budget_simulation.dart
```

### Plaid CLI Test
Tests the Plaid integration by creating link tokens and fetching transactions (CLI only).

```bash
# Requires PLAID_CLIENT_ID and PLAID_SECRET to be set
dart example/plaid_cli_test.dart
```

## Packages

### Plaid Dart
Located in `packages/plaid_dart`, this internal package provides a lightweight, pure Dart interface to Plaid's API, tailored for this project's needs.
