# Budgetizer UI Design - Version 1

## 1. Platform & Aesthetic
-   **Target**: macOS Desktop.
-   **Framework**: Flutter.
-   **Theme**: "Vibrant & Premium".
    -   Dark Mode default.
    -   clean, modern typography (Inter/SF Pro).

## 2. Interaction Metaphor
**"Files & Folders" Concept**:
-   **Transaction**: A File.
-   **Cashflow Transaction**: A Folder (e.g., Credit Card Payment).
-   **Navigation**: Double-click a "Folder" transaction to drill down into that Cashflow's cycle.
-   **Back Navigation**: Standard Breadcrumb or Back button to return to parent.

## 3. Screen Layout

### 3.1. Main Content (Center - The Stream)
No Left Sidebar. The Transaction View is the focus.
-   **Header**:
    -   **Breadcrumbs**: `Checking > Credit Card (AMEX) > Cycle (Oct)`
    -   **Big Number**: Current Balance of the active node.
-   **New Transactions Pane (Uninitialized Queue)**:
    -   **Visibility**: Hidden if empty. Appears at the TOP of the list when uninitialized items exist.
    -   **Content**: List of *only* new/unmapped transactions.
    -   **Action**: User must "Resolve" (initialize/match) these items to clear the pane.
    -   **Goal**: Empty this list. When empty, it disappears.
-   **Transaction List (Initialized)**:
    -   **Multi-Select**: Standard OS behavior (Shift+Click, Cmd+Click).
    -   **Columns**: Date, Description, Tags, Amount.
    -   **Visuals**:
        -   **Folder Icon** for Child Cashflows (Credit Card Payments).
        -   Income: Green Text.
        -   Expense: White Text.

### 3.2. Right Sidebar (Tools & Inspection)
Always visible, divided into three sections: Top, Middle, and Bottom.

#### **A. Top Toolbar (Calculations & Actions)**
-   **Actions**:
    -   **Sync Button**: "Pull Transactions".
    -   **Status Dot**: Green (Synced/Safe) / Red (Over Budget).
-   **Live Calculator**:
    -   **Scope**: Displays totals for the **Current Selection**.
        -   *If 0 items selected*: Shows totals for **ALL** items in view.
        -   *If N items selected*: Shows totals for **Selected** items.
    -   **Display**:
        -   `Income: $X`
        -   `Expense: $Y`
        -   `Net: $Z`
        -   `Diff: $D` (Variance from Budget)

#### **B. Transaction Inspector (Middle)**
Context-aware details when a row is selected.
-   **Single Selection**:
    -   Full Description & Date.
    -   **Vendor**: Identified business.
    -   **Tags**: List of assigned tags (editable).
    -   **Match Rule**: View/Edit the Regex linking this description to the Vendor.
-   **Folder Selection**:
    -   "Open Cashflow" button.
    -   Quick stats for that specific sub-cashflow.
-   **Multi Selection (Bulk Edit Mode)**:
    -   **Inspection**:
        -   "5 items selected"
        -   **Breakdown**: List of Tags in selection + counts.
    -   **Bulk Actions**:
        -   **Add/Remove Tags**: Modify tags for all selected items.
        -   **Set Budget**: Apply a budget limit to a specific Tag.
-   **No Selection**: Empty or summary text.

#### **C. Tag Inspector (Bottom)**
A dedicated pane for managing the budget of a specific tag.
-   **Visibility**:
    -   **Visible**: When a specific Tag is selected in the Middle Pane, or if the user is in a "Tag View" context.
    -   **Hidden**: If no unique tag is in focus (e.g., multiple items with different tags selected, or no selection).
-   **Content**:
    -   **Header**: Tag Name (e.g., "Groceries").
    -   **Budget Config**:
        -   **Limit Input**: Field to set/edit the budget limit (e.g., $500).
        -   **Frequency**: Dropdown (Monthly, Weekly, Custom).
    -   **Stats**:
        -   Current Cycle Spend.
        -   Remaining Budget.
        -   Average Spend (History).
    -   **Actions**: "Save Budget", "Clear Budget".

## 4. Implementation Priorities (V1)
1.  **Shell**: Main list + Right Sidebar layout.
2.  **Navigation**: Implement the "Double Click" drill-down logic (Mock data needs hierarchical structure).
3.  **Selection Logic**: Implement the "All vs Selected" calculation engine.
4.  **Mock Data**: Generate nested cashflow data (Checking -> CC Payment).
