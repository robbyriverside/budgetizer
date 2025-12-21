# Budgetizer Abstraction Layer

This document defines the core abstractions for the Budgetizer application, centered around the concept of **Cash Flow**.

## 1. Core Concept: Cash Flow
Everything in the system is a **Cash Flow**. A Cash Flow represents a container of financial activity over time.

### 1.1. The Goal
The primary goal of any Cash Flow is to maintain a **Positive Balance** (or meet a target).
- **Buffer**: The specific amount of money remaining at the end of a cycle.
- **Alert Condition**: When the predicted Buffer falls below a safe threshold (or goes negative).

### 1.2. Cycles
Time is not linear or strictly monthly. It is cyclic.
- **Cycle**: A period of validity for a Cash Flow.
- **Cycle Start**: Triggered by the *End Event* of the previous cycle.
- **Cycle End Event**: A specific transaction or date that marks the closure of the current period (e.g., "Mortgage Payment" for Checking, "Statement Date" for Credit Cards).

### 1.3. Hierarchy
Cash Flows are organized hierarchically.
1.  **Root Cash Flow (Checking)**: The master flow. All actual money enters and leaves here.
2.  **Child Cash Flows**:
    - **Credit Cards** (Expense Flows): Accumulate debt to be paid by the Root.
    - **Savings** (Asset Flows): "Pay Yourself First" allocations for investments and unexpected expenses.

---

## 2. Transactions
A **Transaction** is the atomic unit of change within a Cash Flow.

### 2.1. Attributes
- **Amount**: Positive (Income) or Negative (Expense).
- **Date**: When it occurred (or is predicted to occur).
- **Description**: What it is.
- **Vendor**: Derived from the **first tag** in the `tags` list. The vendor tag is immutable.
- **Tags**: Attributes assigned by AI. The first tag is always the Vendor.
- **Related Transaction**: A link to a corresponding transaction in another Cash Flow (e.g., a credit card payment expense in Checking links to a payment received income in the Credit Card).

### 2.2. Dimensions
Every transaction exists on three key dimensions:
1.  **Variability**:
    - **Fixed**: Same amount every node (e.g., Rent, Netflix).
    - **Variable**: Fluctuates (e.g., Groceries, Utilities). *Managed via Tag Budgets*.
2.  **Planning**:
    - **Planned**: Known in advance.
    - **Unexpected**: Ad-hoc events (e.g., Car repair).
3.  **Flow Type**:
    - **Income**: Money In.
    - **Expense**: Money Out.

Also represented as tags on the transaction.

---

## 3. Tagging Model
The system uses an **AI-first** approach to classification.

### 3.1. Vendor vs. Tags
- **Vendor Tag**: The **first tag** in the list is always the Vendor. It cannot be removed.
- **Tags**: Subsequent tags describe products or categories (e.g., "Groceries", "Home Goods").
- **Control**: User can remove any tag *except* the first one.

### 3.2. Tag Budgets
Budgeting is done on the **Tag**:
- **Limit**: The maximum amount to spend on a Tag.
- **Frequency**: The cycle for that limit (Weekly, Monthly).
- **Variable Expenses** are constrained by the sum of budgets for their assigned tags.

## 3. Cash Flow Types

### 3.1. Checking Account (The Root)
- **Role**: The Hub.
- **Cycle Trigger**: Major recurring expense (e.g., Mortgage).
- **Buffer**: Must remain positive.
- **Interactions**:
    - Pays Credit Cards (Previous cycle's total).
    - Sends excess buffer to Savings.
    - Pulls from Savings if buffer is low.

### 3.2. Credit Card (Expense Aggregator)
- **Role**: Delays payment of expenses to the next Root Cycle.
- **Cycle Trigger**: Statement Date.
- **Buffer**: Effectively Zero (Target is to pay off in full).
- **Sub-Types**:
    - **General**: Daily variable spending (Groceries, Gas).
    - **Subscription**: Fixed recurring monthly charges.
    - **Emergency/Project**: Large unexpected or planned one-off projects.
- **Constraint**: The total of `Cycle N` becomes a *Fixed Payment Transaction* in the Checking Account's future cycle.

### 3.3. Savings (Buckets)
- **Role**: "Pay Yourself First" mechanism. Handles unexpected expenses and investments.
- **Cycle**: Often aligns with Checking transfers.
- **Structure**: Composed of "Buckets" (Budgets) for specific purposes (e.g., "Emergency Fund", "New Car").
- **Flow**:
    - **In**: From Checking (Priority allocation or End-of-cycle overflow).
    - **Out**: To Checking (To cover a deficit or pay for a specific goal).

---

## 4. Prediction & Logic

### 4.1. The Prediction Engine
The core value proposition is **predicting the End-of-Cycle Buffer**.
`Predicted Buffer = Current Balance + (Planned Income) - (Planned Expenses) - (Expected Variable Expenses)`

- **Variable Expense Prediction**: Uses the *Sum of Tag Budgets* or historical average to estimate remaining spend for the cycle.
- **Credit Card Lag**: Spending *now* on a Credit Card does not reduce the Checking Buffer *now*, but reduces the *Next Cycle's* Checking Buffer.

### 4.2. Alerts
- **Overspending**: When `Current Tag Spend > Tag Limit`.
- **Low Buffer**: When `Predicted Buffer < Safety Threshold`.
- **Action**: These alerts trigger a recommendation (e.g., "Transfer $500 from Savings").
