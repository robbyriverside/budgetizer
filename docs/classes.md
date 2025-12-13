# Data Classes

## BankTransaction
Represents a single financial transaction imported from a bank feed or source. It serves as the core unit of data for the budget.

### Fields
- **id** (`String`): Unique identifier for the transaction.
  - *Purpose*: Used as the primary key for updates and selection.
- **date** (`DateTime`): The date the transaction occurred or was posted.
- **name** (`String`): The raw description or merchant name provided by the bank.
- **amount** (`double`): The value of the transaction. Negative values typically represent expenses, positive values represent income/refunds.
- **tags** (`List<String>`): An ordered list of tags.
  - *Rule*: The first tag is always the **Vendor Tag** (immutable). Subsequent tags are user-defined categories.
- **pending** (`bool`): Indicates if the transaction is still pending settlement.
- **isInitialized** (`bool`): A client-side flag.
  - *Purpose*: `false` indicates a "New" transaction that "Needs Review". `true` indicates it has been reviewed/posted.

### Plaid Mapping
The `BankTransaction` class is designed to ingest data directly from the Plaid API.
### Plaid Mapping
The `BankTransaction` class is designed to ingest data directly from the Plaid API response.

<table>
  <colgroup>
    <col width="25%" />
    <col width="25%" />
    <col width="50%" />
  </colgroup>
  <thead>
    <tr>
      <th>App Field</th>
      <th>Plaid Field</th>
      <th>Transformation Logic</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>id</code></td>
      <td><code>transaction_id</code></td>
      <td><strong>Copied as-is</strong>. Uniquely identifies the transaction (provided by Plaid/Bank).</td>
    </tr>
    <tr>
      <td><code>date</code></td>
      <td><code>date</code></td>
      <td><strong>String → DateTime</strong>. Plaid sends "YYYY-MM-DD", app parses this into a native Dart <code>DateTime</code> object.</td>
    </tr>
    <tr>
      <td><code>name</code></td>
      <td><code>name</code></td>
      <td><strong>Copied as-is</strong>. The description/merchant name provided by Plaid.</td>
    </tr>
    <tr>
      <td><code>amount</code></td>
      <td><code>amount</code></td>
      <td><strong>Copied as-is</strong>. Plaid provides a <code>double</code>.</td>
    </tr>
    <tr>
      <td><code>tags</code></td>
      <td><code>category</code></td>
      <td><strong>Renamed</strong>. Plaid provides a field called <code>category</code> (a list of hierarchy strings like <code>['Food and Drink', 'Coffee Shop']</code>). The app imports this data into the field named <code>tags</code>.</td>
    </tr>
    <tr>
      <td><code>pending</code></td>
      <td><code>pending</code></td>
      <td><strong>Copied as-is</strong>. Boolean flag.</td>
    </tr>
  </tbody>
</table>

### Storage & Keys
- **Primary Key**: `id`
- **Storage Format**: JSON
  - Currently loaded from `assets/data/mock_transactions.json`.
  - Maps `transaction_id` -> `id`.
  - Maps `category` -> `tags`.

---

## Tag
Represents a metadata label that can be applied to transactions. Tags drive the budgeting logic, replacing explicit "Types" and "Categories".

### Fields
- **name** (`String`): The display name of the tag.
  - *Purpose*: Unique identifier for the tag; used in `BankTransaction.tags`.
- **budgetLimit** (`double?`): Optional monetary limit for this tag's budget.
- **frequency** (`String?`): The time period for the budget limit (e.g., 'Weekly', 'Monthly', 'Yearly').

### Storage & Keys
- **Primary Key**: `name` (Implied unique constraint).
- **Storage Format**: In-Memory (Mock) / Database (Future)
  - Currently stored in a runtime list in `BankService`.
  - Intended to be persisted (likely JSON/SQL) to save user's budget settings.
