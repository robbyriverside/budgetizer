# System Tag Definitions

The budgeting system separates tags into different types. **System Tags** specifically categorize the nature of the transaction's frequency and amount stability.

## Definitions

Based on `packages/budgetizer_ui/assets/data/db_tags.yaml`:

| Tag Name | Definition | Key Characteristics |
| :--- | :--- | :--- |
| **Fixed** | Nature of the Amount | **Amount:** Predictable / Fixed. Meaningful only if it repeats. |
| **Variable** | Nature of the Amount | **Amount:** Varies (e.g., Usage-based) OR One-time / Random. |
| **Annual** | System Tag: Frequency | **Frequency:** Once a Year |
| **Monthly** | System Tag: Frequency | **Frequency:** Once a Month |
| **Weekly** | System Tag: Frequency | **Frequency:** Once a Week |

## Why does a tag like "AT&T" have multiple System Tags?

If a vendor like **AT&T** is associated with multiple System Tags (e.g., `Fixed`, `Variable`, and `Monthly`), it indicates that **transactions from this vendor can fall into any of these categories** depending on the specific service or context.

For example, with **AT&T**:
*   **Monthly** + **Fixed**: A standard monthly internet plan with a flat rate.
*   **Monthly** + **Variable**: A mobile phone bill that fluctuates based on data usage or roaming charges.
*   **Variable**: A one-time equipment purchase (like a modem) or an installation fee. Unlike a rental, this is a random, non-repeating expense.

### Implication for Budgeting
When a vendor is linked to multiple System Tags, the budgeting engine (or auto-tagger) may need additional logic (like analyzing the amount or memo text) to classify a specific transaction correctly. Alternatively, it serves as a broad classification indicating that this vendor *typically* represents a committed expense, whether fixed or variable.

## User Tag Removal Rules

The system tags represent a logical relationship between types of transactions.  
So a Recurring bill (variable amount) is both `Variable` and `Monthly` (or another frequency).  
A random purchase is just `Variable` (with no frequency tag).

However, if a Vendor allows multiple kinds of transactions (such as AT&T), the the user needs to be able to remove multiple possibilities.  For example...
display the Tags associated with a transaction using a different color for each Tag type.  So Market Tags are green, Vendor tags are dark blue, 

AT&T Example: It has multiple tags because it can generate different types of transactions: 
 - flat-rate internet (`Monthly`, `Fixed`), 
 - usage-based mobile bills (`Monthly`, `Variable`)
 - one-time equipment fees (`Variable`).

 So the user must answer which of these services the transaction is for?
 By default, the transactions as ALL the vendor related tags.
 But the user can remove all but one of the tags.

 So when a user tries to delete any Tag, the system must determine if that is a valid removal.
 For example, there must be one Market that this transaction is for...  like Groceries vs Gift.
 The user can must leave one Market tag, one Vendor tag, and one System tag on the transaction.

This of course requires that the tags for a specific vendor MUST also have at least one Market or System tag and only one Vendor tag.

Deleting tags will refuse to delete a tag if it would leave the transaction with any Market or System or Vendor tag.

To visually assist the user, we propose having each different type of tag use a different color.


To start review the db_tags.json file and determine if there are any vendor tags, that do not follow the tagging rules.  There must be at least one or more Market or System tag and only one Vendor tag.