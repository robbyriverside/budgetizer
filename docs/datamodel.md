# Data Model & API

This document defines the core data structures and the flow of data through the Budgetizer system. It acts as the internal API specification for how applications should ingest, process, and store financial data.

Everything below should be written in pure dart.  We are creating the library plaid_dart and everything related to our base datamodel features should be pure dart.

## 1. Configuring Data Sources

The primary source of truth for financial data is the bank feed. We use **Plaid** as the primary provider, leveraging the `plaid_flutter` SDK.

### Plaid Integration
- **Hybrid Architecture**:
    -   **UI (Flutter)**: Uses `plaid_flutter` to launch the **Link** widget and obtain a `public_token`.
    -   **API (Pure Dart)**: Uses `plaid_dart` package (custom) to exchange tokens and fetch transactions. This allows API logic to run headless (CLI/Server).
- **Environment**: Users start in the **Development** or **Sandbox** environment (free tier).
- **Authentication Flow**:
    1.  **Link Token**: The app requests a `link_token` via `PlaidClient` (Dart).
    2.  **Plaid Link**: The UI presents the Plaid Link widget using the token (`plaid_flutter`).
    3.  **Public Token**: On success, Plaid returns a `public_token`.
    4.  **Access Token**: The app exchanges the `public_token` for a permanent `access_token` via `PlaidClient`.
    5.  **Storage**: The `access_token` is securely stored and used for daily syncs.

### Data Source Abstraction
While Plaid is the default, the system uses a `BankService` abstraction to allow for other sources (e.g., CSV import, other aggregators). A `DataSource` configuration object holds the credentials and status of each connection.

### Credentials

I have a client_id and a sandbox_secret for Plaid. I need to store these in the environment variables.  So the app can pick them up from the environment.

PLAID_CLIENT_ID=your_client_id_here
PLAID_SECRET=your_sandbox_secret_here
PLAID_ENV=sandbox

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

### Unknown Transactions & AI Resolution
Transactions that do not match an existing Regex rule are initially marked as **Unknown** (`isInitialized: false`). These require resolution before they can be included in the budget.

#### Resolution Workflow
1.  **Detection**: The `TagEngine` fails to match a `regex` in `db_tags.json`.
2.  **AI Analysis**: The system delegates the description to an **AI Service**.
    *   The AI performs a web search (if needed) to identify the Vendor.
    *   *Input*: "SparkFun" -> *Context*: Electronics, Hobby components.
    *   **Speculative Analysis ("Best Guess")**:
        *   If the vendor is obscure or fake (Sandbox data), the AI relies on semantic clues in the name.
        *   *Example*: "Touchstone Climbing" -> Contains "Climbing" -> Inference: "Gym", "Fitness", "Recreation".
        *   **Policy**: Always populate tags. It is better to provide a wrong tag (which prompts user correction) than `Uncategorized` (which requires full manual entry).
3.  **Classification**: The AI determines:
    *   **Vendor Name**: Cleaned name (e.g., "SparkFun").
    *   **Market/Service**: High-level category (e.g., "Electronics", "Education").
    *   **Transaction Type**:
        *   `Expense`: Standard purchase.
        *   `Income`: Paycheck, refunds.
        *   `Transfer`: Credit card payments (e.g., "AUTOMATIC PAYMENT - THANK"), moving funds between own accounts.
    *   A new `Tag` entry is created and appended to the local `db_tags.json` (or database).
    *   Future transactions with this description will now match automatically (O(1)).

#### System Transactions (Bank as Vendor)
The AI must disambiguate between external merchants (e.g., "Starbucks") and the Financial Institution itself.
-   **Concept**: For Fees, Interest, and Internal Transfers, the **Vendor** is effectively the Bank (e.g., "Chase", "Wells Fargo").
-   **Workflow**: The AI uses the transaction context (Source Account Name) to attribute these correctly.
    -   *Input*: "INTRST PYMNT" + *Context*: "Chase Sapphire"
    -   *Result*: Vendor="Chase", Tags=`['Interest', 'Fees']`.

#### Special Case: Transfers & Payments
Internal transfers (like paying off a Credit Card) are not "spending" in the budgetary sense but are critical for **Cashflow Management**.
-   **Identification**: Descriptions often contain "PAYMENT", "TRANSFER", "THANK YOU".
-   **Tagging**: Must be tagged with system tags: `Transfer`, `Payment`, or `Credit Card Payment`.
-   **Logic**:
    -   *Checking Account*: Outflow (Negative).
    -   *Credit Card*: Inflow (Positive) -> Reduces the Debt balance.
    -   The system explicitly links these to execute a zero-sum transfer where possible.

#### Special Case: Interest Payments
Transactions labeled "INTRST PYMNT" or similar are fees charged by the bank/institution.
-   **Identification**: Regex matches `(?i)(INTRST|INTEREST)` or `(?i)PYMNT`.
-   **Tagging**: Map to `Interest Payment` vendor and apply `['Interest', 'Fees', 'Finance']`.
-   **Context**: Typically an expense on a credit card account, increasing the debt balance.

---

## 3. Cashflows and Cashflow Series

The Account object is defined by the users information.  As the user adds sources of transactions (banks, etc), the system creates a **Cashflow** for each source and the account knows which source maps to what cashflow.  

The Budgetizer logic is built on **Cashflows**. A Cashflow is a container for money entering and leaving over time.  Everything the system does is to observe and monitor the cashflows and alert the user about cashflow issues; mentioned below.

User spending data is arranged into **Cashflows**. Each cashflow has a **Cycle**.  Cycles are defined by a **Trigger**. The trigger is a transaction that occurs at the end of the cycle. The trigger is always a date.  But the date may be fixed, like 3rd of the month, or relative to a specific transaction, like the date you received your paycheck.

There are three types of cashflows, **Checking**, **Credit Card**, and **Savings**. 

### Cashflow Types
-   **Checking Account (Root)**: The central hub. All income enters here; bills and credit card payments leave from here.  At the beginning of each cycle, the balance is checked against the buffer.  If the balance is less than the buffer, the system will alert the user.
-   **Credit Cards (Child)**: Treated as sub-cashflows. They accumulate negative balance (debt) which is settled by a "Transfer" transaction from checking.  It can not be assumed that a billing period starts with a zero balance.  If there is a partial payment, the balance is adjusted accordingly.  That balance should always shink from cycle to cycle.  If it grows, even from zero, the user is alerted.
-   **Savings (Child)**: Also a sub-cashflow. A destination for surplus funds or specific goals, usually added from checking.  There are two kinds of savings: **Expenses** and **Investment**.  Expenses in savings are for expenses outside the usual budget such as unexpected expenses, like car repairs or medical bills. Expenses will eventually be moved to checking to support paying the credit cards.  Investments in savings are for long-term goals, like retirement or buying a house. 

Each **Cashflow** is just one in a series of cashflows over time.  The current cashflow is the one that contains the current date.  So you can ask a cashflow containing a particular date or today (current).



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


## 4.1 Account Storage

Using SQLLite as a JSON store, like a NoSQL db.  Where one column is the key and the and another column contains the JSONB content.  The keys are according to what the system needs to store.  Each key could contain a cashflow for one cycle.  There could be a column with a date key for when that cashflow started the cycle.  Another column for the cashflow type (checking, credit card, savings).  And another column for the cashflow id.  It's just about which is the most efficient way to store the data.

---

## 5. Budgeting Tags

Budgets are constraints applied to Tags, not arbitrary buckets.

### Model
Budget logic is embedded in the `Tag` definition:
-   `budgetLimit` (`double`): The max spending allowed.
-   `frequency` (`int`): The period for the limit in zero to fifteen **days**.
    -   `0`: Monthly (Calendar Month).
    -   `7`: Weekly (Rolling or Fixed 7 days).
    -   `15`: Half a month. (MAX VALUE)

A cashflow is defined based on a month of days.  So by default the Tag cycle is the entire month.  Frequency can reduce that Tag cycle to an arbitrary number of days. The max is 15 days, because that would represent two Tag cycles in a month.  But it can be any size.  The system handles overlapping Tag cycles by pro-rating the Tag limit.  So if the last period in the Tag cycle is only 10 days, the Tag limit is pro-rated to 10 days.

The last period in the Tag cycle finish out the month.  So if the month has 31 days, and the Tag cycle is 15 days, the last period is 16 days.  If the Tag cycle is 7 days, the last period is 4 days.  If the last period is less than half the number of days in the Tag cycle, then the last period is added to the previous period.  If the last period is more than half the number of days in the last period is shortened to the remaining days in the month.    

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



