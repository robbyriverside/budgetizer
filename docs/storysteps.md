# User Story Steps: Budgetizer Blueprint

This document details the user interactions, UI elements, and specific steps a user takes to achieve their goals in Budgetizer. It serves as a blueprint for the UI creation.

## Step 1: The Empty Workspace (Onboarding)
**Goal**: Engage the user immediately and prompt for data entry.

*   **Visuals**: Clean, minimal dashboard. No empty charts or confusing zeros.
*   **Central Element**: A large, inviting CTA button: **"Load Financial Data"**.
*   **Context**: Brief reassuring text: "Start by loading your account history to see where your money goes. Secure and private."

## Step 2: Loading Data Sources
**Goal**: Import initial transaction data from Checking, Savings, or Credit Cards.

*   **User Action**: User clicks **"Load Financial Data"**.
*   **UI Layout**: A modal or dedicated import page appears.
*   **Controls**:
    *   **"Select Source"** Dropdown or Radio buttons (Checking, Savings, Credit Card).
    *   **"Upload File"** button (for CSV/Bank export) or **"Connect Account"** (if API integration exists).
*   **Feedback**: Progress bar during ingestion. "Parsing Transactions..." -> "Analyzing Tags..." -> "Done!".
*   **Result**: The view transitions to the **Cashflow Dashboard**.

## Step 3: The Cashflow Dashboard (Main View)
**Goal**: Overview of specific account activity within a defined cycle.

*   **Header Area**:
    *   **Control**: **"Current Cashflow" Dropdown**. (e.g., displays "Checking Account"). Allows switching between different accounts (Savings, Visa, etc.).
    *   **Display**: **"Current Cycle" indicator**. Shows dates (e.g., "Oct 15 - Nov 14").
*   **Main Content**: A standard **Transaction List**.
    *   Columns: Date, Payee/Vendor, **Tags** (Chips), Amount.
*   **System Response**: Automated tagging has filled in initial data. Budgetizer has already identified potential "leaks" (increasing fixed expenses) and highlights them (e.g., with a subtle icon or colored border).

## Step 4: Refining Meaning (Tag Management)
**Goal**: User clarifies transaction specificity (e.g., narrowing "Market/Target/Groceries/Clothes" to just "Groceries").

*   **User Action**: User spots a transaction (e.g., "Target") with too many generic tags.
*   **Interaction**: User clicks the transaction row.
*   **UI Element**: **Transaction Inspector** pane slides out (or expands inline).
    *   Displays all auto-generated tags as removable chips (e.g., `[Market] [Department Store] [Groceries] [Clothing]`).
*   **User Action**: User clicks the **"x"** on `[Market]`, `[Department Store]`, and `[Clothing]`.
*   **Result**: Only `[Groceries]` remains. The app now understands this specific purchase was for food.
*   **System Feedback**: "Transaction updated. Related reports recalculated."

*   **Notes**: 
    *   When adding new transactions, the user is responsible for evaluating transactions and removing any tags that are invalid for that transaction.
    *   The user will be able to select transactions by vendor or any other tag which shows the combined Tags for the selected transaction.  The user can delete tags from this combined tags and that deletion will change all selected transactions.

## Step 5: Trend Discovery
**Goal**: Visualize spending habits for a specific tag.

*   **User Action**: In the Inspector or Transaction List, user clicks the **"Groceries"** tag chip.
*   **UI Transition**: View filters to **"Tag Details: Groceries"**.
*   **Display**:
    *   **"Trend Report"**: A chart showing Total Groceries Expense for the *current* cycle vs. *previous* cycles.
    *   **List**: Filtered list of all transactions with this tag.
*   **Insight**: User sees if the trend line is going up or down.

## Step 6: Creating a Budget (Setting Limits)
**Goal**: Establish a control on a variable expense.

*   **User Action**: On the "Tag Details" view, user clicks **"Set Limit"** or **"Create Budget"**.
*   **UI Layout**: **Budget Configuration Modal/Panel**.
*   **Controls**:
    *   **"Limit Amount" Input**: User types "$400".
    *   **"Frequency" Input**: User types "7" (for days) or selects "Weekly".
*   **Display**: "Effective Period: Every 7 days starting [Cycle Start Date]".
*   **User Action**: Click **"Save Budget"**.

## Step 7: Viewing the Budget Report (Proration Handling)
**Goal**: Review budget performance, understanding how irregular cycles are handled.

*   **Context**: The Cycle is 31 days. The Budget Frequency is 7 days.
*   **UI Display**: **Budget Report Panel**.
    *   Shows distinct 7-day blocks: "Week 1", "Week 2", "Week 3", "Week 4".
    *   **Handling Uneven Days**: Shows a final "Partial Week" (3 days).
    *   **Visuals**:
        *   Bars for each period illustrating **Actual Spending** vs **Limit**.
        *   The "Partial Week" limit is visually prorated (e.g., Limit is $171 instead of $400 for those 3 days).
*   **Status Indicators**:
    *   Green checkmark for "Under Limit".
    *   Red alert icon for "Over Limit".

## Step 8: Alerts & Dashboard Monitoring
**Goal**: Quick check-in on financial health without digging deep.

*   **Navigation**: Return to Main Dashboard.
*   **UI Element**: **"Alerts & Insights" Sidebar or Top Section**.
*   **Display**:
    *   "Groceries: Over limit in Week 3."
    *   "Fixed Expense Alert: Internet Bill increased by 10%."
*   **User Action**: Click an alert to jump directly to the relevant transaction or report context.

## Step 9: Cross-Cashflow Navigation
**Goal**: Trace money moving between accounts.

*   **User Action**: User views Checking Account. Sees a transaction "Transfer to Savings".
*   **UI Indicator**: A **"Linked Cashflow" icon** or distinct link style on the transaction.
*   **Interaction**: Click the transfer transaction.
*   **Result**:
    *   App switches context to **Savings Account Cashflow**.
    *   Focus lands on the corresponding "Deposit from Checking" transaction.
*   **Benefit**: Seamless navigation between sources of truth.
