# Data Model & API

This document defines the core data structures and the flow of data through the Budgetizer system. It acts as the internal API specification for how applications should ingest, process, and store financial data.

## 1. Configuring Data Sources

The primary source of truth for financial data is the bank feed. We use **Plaid** as the primary provider, leveraging the `plaid_flutter` SDK.

### Plaid Integration
- **Environment**: Users start in the **Development** or **Sandbox** environment (free tier).
- **Authentication Flow**:
    1.  **Link Token**: The app requests a `link_token` from the backend (or direct Plaid call in serverless setups).
    2.  **Plaid Link**: The UI presents the Plaid Link widget using the token.
    3.  **Public Token**: On success, Plaid returns a `public_token`.
    4.  **Access Token**: The app exchanges the `public_token` for a permanent `access_token`.
    5.  **Storage**: The `access_token` is securely stored (never logging it) and used for all subsequent data fetches.

### Data Source Abstraction
While Plaid is the default, the system uses a `BankService` abstraction to allow for other sources (e.g., CSV import, other aggregators). A `DataSource` configuration object holds the credentials and status of each connection.

### Credentials

I have a client_id and a sandbox_secret for Plaid. I need to store these in the environment variables.  So the app can pick them up from the environment.

---

## 2. Loading Transaction Data

Transactions are the atomic units of the system. They are fetched from the `DataSource` and normalized into our internal `BankTransaction` schema.

### Schema: `BankTransaction`
| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `String` | Unique ID (from Plaid `transaction_id`). |
| `date` | `DateTime` | Date of the transaction (YYYY-MM-DD). |
| `description` | `String` | Raw description from the bank. |
| `vendorName` | `String` | Cleaned vendor name (e.g., "Target"). |
| `amount` | `double` | Transaction value (Negative = Expense, Positive = Income). |
| `tags` | `List<String>` | List of applied tags. First tag is usually the Vendor. |
| `isInitialized` | `bool` | `false` = Needs Review (New), `true` = Reviewed. |
| `cashflowId` | `String` | ID of the parent Cashflow (e.g., "checking_1"). |

### Loading Process
1.  **Fetch**: `BankService.fetchTransactions(cashflowId)` calls the provider.
2.  **Mapping**:
    -   Plaid `name` -> `description`.
    -   Plaid `category` (list) -> `tags`.
    -   Plaid `amount` -> `amount` (Ensure sign consistency).
3.  **Deduplication**: Transactions are matched by `id`. Existing transactions are updated, not duplicated.

---

## 3. Cashflows and Cashflow Series

The Budgetizer logic is built on **Cashflows**, not just simple accounts. A Cashflow is a container for money entering and leaving over time.

### Hierarchy
-   **Checking Account (Root)**: The central hub. All income enters here; bills and credit card payments leave from here.
-   **Credit Cards (Child)**: Treated as sub-cashflows. They accumulate negative balance (debt) which is settled by a "Transfer" transaction from checking.
-   **Savings (Child)**: A destination for surplus funds or specific goals.

### Lifecycle & Concepts
-   **Cycle**: A defined time period (e.g., Monthly, Paycheck-to-Paycheck).
    -   *Trigger*: A cycle often starts/ends on a key transaction (e.g., Mortgage Payment).
-   **Buffer**: The "Safe to Spend" balance remaining in the Checking cashflow for the current cycle.
    -   *Calculation*: `Current Balance` + `Pending Income` - `Planned Expenses`.
-   **Series**: A repeating pattern of transactions (e.g., "Rent" every 1st of the month). The system identifies these to predict future cashflow.

---

## 4. Tagging Transactions

Tagging is the core organization mechanism. It is automated ("Smart Tagging") to reduce user toil.

### Smart Tagging Workflow
1.  **Regex Match**: content is checked against known patterns in `db_tags.json`.
    -   *Example*: `r'TARGET'` matches "Target".
2.  **Lazy AI Analysis**: If no regex match is found:
    -   The description is sent to an AI service (`analyzeTransaction`).
    -   AI determines the Vendor and suitable Tags (e.g., "Grocery", "Home Goods").
    -   System generates a new regex for future matches.
3.  **Reference Previous Cycle**: When a new transaction arrives, the system looks back at the previous cycle. If "Netflix" was tagged "Subscription" last month, it applies the same tag.

### Rules
-   **Immutability**: Users **remove** tags that don't apply, they rarely need to add them.
    -   *Example*: Target automatically gets `[Target, Groceries, Clothing]`. If you only bought food, you remove `Clothing`.
-   **Vendor as Tag**: The Vendor Name (e.g., "Chevron") is itself a tag, allowing strict reporting on specific merchants.

---

## 5. Budgeting Tags

Budgets are constraints applied to Tags, not arbitrary buckets.

### Model
Budget logic is embedded in the `Tag` definition:
-   `budgetLimit` (`double`): The max spending allowed.
-   `frequency` (`int`): The period for the limit in **days**.
    -   `0`: Monthly (Calendar Month).
    -   `7`: Weekly (Rolling or Fixed 7 days).
    -   `365`: Yearly.

### Validation Logic
-   **Aggregation**: To check a budget, query all transactions with `Tag X` within the current cycle/frequency window.
-   **Variance**: `Sum(Transaction Amounts)` - `budgetLimit`.
-   **Alerts**: If Variance > 0, the tag is "Over Budget".

---

## 6. Tag Storage and Indexing

### Persistence
-   **Initial Store**: `assets/data/db_tags.json`. This acts as the seed database.
-   **Runtime**: Tags are loaded into memory (`BankService._tags`).
-   **User Edits**: When a user updates a budget or tag rule, it must be persisted to local storage (or a user-specific cloud database) to survive restarts.

### Indexing for Performance
To efficiently report on "How much did I spend on Dining?", we cannot iterate `AllTransactions` every time.
-   **Inverted Index**: The system maintains a cached map: `Map<String, List<String>> tagToTransactionIds`.
    -   *Key*: Tag Name (e.g., "Dining").
    -   *Value*: List of Transaction IDs.
-   **Lazy Loading**: This index is built once upon data load and updated incrementally when a transaction is modified.
-   **O(1) Lookup**: Fetching all "Dining" transactions becomes a direct dictionary lookup, enabling instant UI updates.



