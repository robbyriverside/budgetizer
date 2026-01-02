# Budgetizer

**Budgetizer** is a powerful, locally-focused personal finance application built with Flutter Desktop. It helps you aggregate transactions from various sources, automatically tag them, and customize your budgeting and reporting flows.

## Key Features

- **Multi-Source Import**: Fetch transactions from **Plaid**, import **CSV** files, or parse **PDF** bank statements using AI (Gemini).
- **Auto-Tagging**: Robust, rule-based tagging engine configurable via `db_tags.json`.
- **Flexible Reporting**: Create, save, and manage custom budget reports. Support for weekly, monthly, and annual tracking.
- **Mock Data Mode**: Built-in mock data generator for testing and demonstration.
- **Local-First Storage**: All data is securely stored locally in a SQLite database.

## Project Structure

This project is organized as a monorepo:

- **`apps/desktop`**: The main Flutter Desktop application UI and feature logic.
- **`packages/budgetizer_dart`**: A pure Dart package containing the core business logic, data models, and services (BankService, DatabaseService, etc.).

## Key Files & Artifacts

The application produces and relies on several key files:

### 1. `budgetizer.db`
This is the primary SQLite database where all your application data is stored. It is created automatically on first run.
- **Location**: Typically in your OS-specific application data directory (e.g., `~/Library/Containers/...` on macOS).
- **Contents**:
  - `cashflow_cycles`: Stores all your transaction data organized by account and time period.
  - `reports`: Stores your saved report definitions and budgets.
  - `settings`: Persists application state like the last viewed report.

### 2. `apps/desktop/assets/data/db_tags.json`
This JSON file acts as the brain of the auto-tagging system. It defines regex rules that map transaction descriptions to vendors and tags.
- **Format**:
  ```json
  [
    {
      "vendor": "Amazon",
      "regex": "(?i)amzn|amazon",
      "tags": ["Shopping", "Online"],
      "account_tag": "Shopping" // Optional primary tag
    }
  ]
  ```

### 3. `.env`
This file contains your private API keys and configuration secrets. **It is not checked into version control.**
- **Required Keys**:
  - `PLAID_CLIENT_ID`, `PLAID_SECRET`: For banking integration.
  - `GEMINI_API_KEY`: For AI features (PDF parsing, smart tagging).
- **Setup**: Copy `.env.example` to `.env` and fill in your keys.

## Getting Started

1.  **Prerequisites**: Ensure you have the [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.
2.  **Dependencies**:
    ```bash
    cd apps/desktop
    flutter pub get
    ```
3.  **Run**:
    ```bash
    flutter run -d macos
    ```
    *(Or `windows` / `linux` depending on your host OS)*

## Advanced Usage

- **Mock Mode**: On the Loading Screen, you can choose "Mock Data" to generate a realistic set of test transactions without needing API keys.
- **Database Management**: The database schema is managed via `DatabaseService`. Migrations are handled automatically on app startup.
