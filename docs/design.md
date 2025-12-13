# Budgetizer System Design

## 1. Core Architecture: The Cashflow Model
The system is built entirely on the concept of **Cashflows**.
-   **Definition**: A container of financial activity (Money In, Money Out).
-   **Immutability Constraint**: Automated Cashflows (linked to Bank) generally **NEVER** allow manual transaction entry. Reality is the source of truth.
-   **Structure**: Hierarchical. A Cashflow can contain transactions that are themselves links to Child Cashflows.

## 2. Cashflow Types

### 2.1. Automated Cashflows (The Backbone)
-   **Source**: 1:1 Map to a Bank Account / Credit Card API.
-   **Checking (Root)**: The primary hub.
    -   *Buffer*: Goal is to keep this positive.
    -   *Cycles*: Triggered by the "Mortgage/Rent" transaction.
-   **Credit Cards (Child)**:
    -   *Cycle*: Triggered by Statement End Date.
    -   *Interaction*: The "Payment" transaction in Checking acts as the parent pointer to this Cashflow's cycle.

### 2.2. Manual Cashflows (The Dynamic Edge)
-   **Source**: Created by the user to track "Black Hole" or "Composite" spending.
-   **Use Case**:
    -   **Cash Wallet**: User creates a Manual Cashflow linked to a specific "ATM Withdrawal" transaction in Checking.
    -   **Detailed Breakdown**: The user adds manual entries (Lunch, Taxi) to this cashflow to account for the $100 withdrawal.
-   **No Split Transactions**: We do not split a single line item. We attach a Manual Cashflow to it if detailed breakdown is needed.

### 2.3. Savings (Pay Yourself First)
-   **Role**: Priority destination for funds, not just a waste bin for overflow.
-   **Buckets**: Sub-allocations within Savings for specific goals (Investments, Emergency Fund).

## 3. Data Flow & Workflows

### 3.1. Initialization (Onboarding)
1.  **Connect**: User authorizes Bank API.
2.  **Ingest**: System pulls recent history.
3.  **Construct**: System creates the Automated Cashflow entities.
4.  **Calibrate**:
    -   User identifies the "Cycle Trigger" (e.g., Mortgage).
    -   System back-calculates previous cycles to establish a matching history.

### 3.2. Routine Sync & Match
1.  **Fetch**: 
    -   *Trigger*: Manual "Pull Transactions" button (or scheduled background job).
    -   Robot pulls new transactions from Bank API.
2.  **Match**:
    -   *Exact*: Amount + Date match.
    -   *Lazy AI*: Regex on description (if established by AI).
    -   *New*: AI evaluates description to identify business and assign tags.
3.  **Validate**:
    -   *Fixed*: Check Date/Amount variance.
    -   *Variable*: Deduct from Tag Limit.

### 3.3. Over-Budget Investigation
1.  **Trigger**: "Checking Account Predicted Buffer < 0".
2.  **Drill Down**: System highlights the generic "Credit Card Payment" that is higher than expected.
3.  **Trace**: User clicks the Payment -> Jumps to that Credit Card's Cashflow Cycle.
4.  **Identify**: System sorts that cycle by "Variance from Category Limit" (e.g., Dining Out is $200 over limit).

## 4. Domain Logic

### 4.1. Budgeting = Limits
We do not budget "Money". We measure **Limits**.
-   **Fixed Items**: Limit = Expected Amount.
-   **Variable Items**: Limit = User defined cap on a Tag.
-   **Mad Money (Discretionary)**: Special Variable Category where variance (Under/Over limit) is tracked cumulatively across cycles.
-   **Health Check**: `Sum(Transactions) vs Sum(Limits)`.

### 4.2. Prediction
-   Use history to project the *remainder* of the current cycle.
-   *Formula*: `Current Balance + Pending Income - (Remaining Fixed Bills + Remaining Variable Budgets)`.

## 5. Security & Technical Considerations
-   **Auth**: Strong user authentication required (OAuth/JWT).
-   **Encryption**: Banking credentials must never be stored raw (rely on Provider tokens).
-   **Privacy**: Financial data should be encrypted at rest.

## 6. Open Issues & Future Considerations
1.  **Debt Principal Tracking**: Tracking the reducing principal of mortgages/loans. **Decision**: Future Enhancement (Phase 2).
