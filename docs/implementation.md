# Implementation Notes

## 1. Transaction Ingestion & Matching

### 1.1. Data Source Integration
- **Aggregator Service**: Integrate with a banking data provider (e.g., Plaid, Yodlee, or simple CSV import for MVP) to fetch transactions.
- **Cache/Store**: Raw transactions from the provider are stored in a "Staging" area before being committed to a Cycle.

### 1.2. The Matching Engine
The core logic for processing incoming transactions.

#### **Step 1: Initialization State & Workflow**
All fetched transactions enter a rigorous state machine:

1.  **Incoming Fetch**: New list of transactions arrives from the provider.
2.  **Matching (Initialization Check)**:
    -   **Initialized Transactions**: Existing transactions in the database that have been processed/saved.
    -   **Lazy AI Matching**: System attempts to match transaction to existing Vendor/Tag rules (Regex).
    -   **Match Found**: The incoming transaction is linked to the identified Vendor and its Tags are applied. (Status: Synced).
    -   **No Match**: The transaction is marked as **Uninitialized** and flagged for AI evaluation.
    -   **Conflict**: If multiple new transactions map to the same initialized transaction (rare, but possible with duplicates), flag for manual review.
3.  **The Uninitialized Queue (UI Split View)**:
    -   **Mock Behavior**: For V1 dev, the Mock Bank Service will *always* append 2-3 new random transactions on every sync to force this state.
    -   **UI Presentation**: A dedicated "New Transactions" pane appears at the top of the list.
    -   **Blocking Condition**: The syncing process is considered **Incomplete** as long as this pane is visible.
4.  **User Resolution**:
    -   **Option A (Fix)**: User manually sets properties (Category, Fixed/Variable, Limit) -> Becomes **Initialized** -> Moves to Main List.
    -   **Option B (Manual Match)**: User manually links the uninitialized item to an existing (orphan) Initialized transaction -> Becomes **Initialized**.

#### **Step 2: Intelligent Pattern Matching (AI Tagging)**
If no exact or regex match is found:
1.  **AI Evaluation**: The system sends the transaction description to the AI agent.
2.  **Vendor Identification**: AI identifies the business/vendor (e.g., "Target").
3.  **Tag Assignment**: AI assigns comprehensive tags based on the vendor's business (e.g., "clothes", "home goods", "food").
4.  **Learning**: The system creates a new `MatchRule` (regex) linking this description pattern to the identified Vendor and its Tags for future "Lazy AI" matching.

#### **Step 3: Validation Logic (New vs Fixed vs Variable)**
Once matched or categorized, specific logic applies:

1.  **Fixed Transactions**:
    - **Validation**: Check `Amount` (must be exact) and `Date` (allow variance, e.g., +/- 3 days).
    - **Outcome**: If matches, status = `Verified`. If amount differs, status = `Review Needed` (Did the bill go up?).

2.  **Variable Transactions**:
    - **Requirement**: Must have **Tags** which may be linked to Budgets.
    - **Calculation**: `Remaining Budget = Tag Limit - Current Transaction Amount`.
    - **Outcome**: Updates the running total for that Tag's limit in the current cycle.

- **Pattern Registry**:
    - A database of `MatchRules` associated with Vendors.
    - **Rule Structure**:
        - `Pattern`: Regex string (e.g., `^Netflix.*$`).
        - `VendorId`: The identified Business.
        - `Confidence`: Score threshold.

- **Auto-Learning Workflow**:
    1.  **New Transaction** arrives (e.g., "MCDONALDS 123").
    2.  **No Match** found in `MatchRules`.
    3.  **AI Action**: AI identifies "McDonalds" and tags ["Fast Food", "Dining"].
    4.  **System Action**:
        - Generates a proposed Regex: `^MCDONALDS.*`.
        - Saves this new `MatchRule` linked to the McDonalds Vendor entity.
    5.  **Future Transaction** (e.g., "MCDONALDS 456") arrives.
    6.  **Match**: `MatchRule` finds it. Automatically assigns "McDonalds" and tags ["Fast Food", "Dining"].

### 1.3. User Intervention (The "New vs Match" Decision)
When a transaction is imported that doesn't perfectly align:

- **Scenario**: Statement description changes (e.g., "COMCAST CABLE" -> "XFINITY").
- **UI**:
    - Presents the "Orphaned" incoming transaction.
    - Shows "Likely Matches" (similar amount, same day of month).
- **Resolution**:
    - If User selects "Match to 'Comcast Cable'":
    - If User selects "Match to 'Comcast Cable'":
    - **System Update**: Updates the `MatchRule` for 'Comcast Cable' to include the new pattern (OR logic).

### 1.4. Budget Calculation Engine
- **Cashflow Status**: derived from the sum of all components in the cycle.
- **Formula**:
    `Total Budget = Sum(Fixed Transactions) + Sum(Variable Limits)`
- **Cycle Health**:
    - `Fixed Variance`: `Actual Fixed - Expected Fixed` (Should be 0).
    - `Variable Usage`: `Sum(Actual Variable) / Sum(Variable Limits)`.
- **Over-Budget Check**:
    - Calculated per Cashflow.
    - If `Projected Cycle Spend > Available Income`, flag as **Over Budget**.

## 2. Technical Components

### Database Schema Extensions
```typescript
interface MatchRule {
  id: string;
  pattern: string; // Regex
  vendorId: string; // Link to Vendor entity (which holds the tags)
  lastUsed: Date;
  frequency: number;
}
```

### API Service
- `POST /api/sync`: Triggers fetch from bank.
- `GET /api/reconciliation`: Returns list of { imported, unmatched, suggested }.
- `POST /api/resolve`: User confirms match; System updates Regex.
