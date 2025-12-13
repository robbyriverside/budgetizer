# Gap Analysis: Missing Features

Based on the review of `instructions.md`, `cashflow.md`, `abstraction.md`, `transactions.md`, and `implementation.md`, the following common budgeting features are currently undefined or under-specified:

## 1. Split Transactions
**Gap**: Real-world transactions often cover multiple categories (e.g., a "Costco" run containing Groceries, Clothing, and Household Goods).
- **Current State**: `Category` is 1:1 with `Transaction`.
- **Requirement**: Need logic to split a single Imported Transaction into multiple sub-transactions or allocation records.

## 2. Onboarding & Initial Setup
**Gap**: How does the user get started?
- **Current State**: Assumes Cashflows and Cycles exist.
- **Requirement**:
    - Workflow for "Day 1": Setting initial bank balances.
    - Defining the first triggers (e.g., "When was your last Mortgage payment?").
    - Import Wizard for historical data to train the "Brain".

## 3. Reconciliation Workflow
**Gap**: Ensuring the system matches reality.
- **Current State**: Mention of "Synced" status.
- **Requirement**: A formal "Reconcile" mode where users verify the System Balance matches the Bank Balance at a specific point in time (e.g., matching the Statement Ending Balance).

## 4. Manual Transactions (Cash)
**Gap**: Handling cash or untracked spending.
- **Current State**: `transactions.md` says "I don't ever want to enter a transaction manually," but allows for "Cash" type.
- **Requirement**: If I pull $100 Cash from ATM (Transfer), tracking where that goes requires manual entry if granularity is desired, or it's just a black hole "Cash Expense". Clarification needed.

## 5. Reporting & Traceability
**Gap**: Long-term views.
- **Current State**: Focus is heavily on "Current Cycle" and "Predicted Cycle".
- **Requirement**:
    - Trend Reports (e.g., "Grocery spending over last 12 cycles").
    - Year-end tax reporting.

## 6. Debt Management (Liabilities)
**Gap**: Tracking the balance of long-term debt.
- **Current State**: Mortgage is a "Trigger Transaction".
- **Requirement**: Do we track the *Principal* of the Mortgage/Car Loan reducing over time? Or is it just a cashflow expense?

## 7. Authentication & Security
**Gap**: System access.
- **Requirement**: Login/Auth requirements, especially given financial data is involved.
