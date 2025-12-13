# Implementation Plan

I want to incrementally implement the system.  

# Version 1

Start with the foundation of the automated cashflow pulling transactions from the bank and matching them to the cashflow.

**Decision**: Use **Plaid** as the banking backend.
-   **Mock/Dev**: Use Plaid `Sandbox` environment to simulate accounts.
-   **Live**: Use Plaid `Development` tier (Free < 100 items) for real connections.

**Tech Stack Decisions**:
-   **Database**: `sqflite` (with `sqflite_common_ffi` for macOS) - Standard SQL for relational/cycle data.
-   **Security**: `flutter_secure_storage` - For storing Plaid Tokens and Client Secrets.
-   **State**: `Riverpod` - Modern, safe state management.
-   **Plaid Integration**: Use `plaid_flutter` (or webview workaround if macOS support is flaky).

So in the first version there no hierarchy of cashflows.  Just a single cashflow that is linked to bank account with checking, savings, and credit card.  I need to test them on my specific bank accounts to see if they work.

**Core Feature**: Implement the **Cycle Engine**. Even without hierarchy, the Checkings Account must respect the "Cycle Trigger" (e.g., Mortgage Payment) to group transactions correctly.

**UI Implementation**: Build the complete **Dashboard & Interaction Model** defined in `docs/ui_v1.md`.
-   Single Window, Right Sidebar (Navigation/Calc).
-   Cycle Progress Visuals.
-   Transaction List with Multi-select.  

## Version 2

Second version allows me to budget a single cashflow transaction.   And implement all the features of a transaction: see abstraction.md section 2.2.

**Core Feature**: **Prediction Engine**. Calculate the "Projected End-of-Cycle Buffer" based on the new Limits and Fixed/Variable definitions.

## Version 3

Third version allows me to budget a hierarchy of cashflows.  Where I can double-click a transaction with a sub-cashflow and open the new cashflow to budget it.  

**Core Feature**: **Manual Cashflows** (Cash Wallet) & **Savings Buckets**. Implement the ability to attach a manual cashflow to a "Cash Withdrawal" transaction to handle the "No Split Transaction" logic. Implement "Pay Yourself First" logic for Savings.  

## Version 4

Fourth version provides alerts and reports.


