# Canonical Tag Discovery Plan

To achieve a "canonical set of tags" that covers the diversity of global transactions, we will adopt a **Standard-First, Verify-Later** approach.

## Phase 1: The Standard (ISO 18245)
Instead of inventing tags, we will base our "Specific Services" on the **Merchant Category Codes (MCC)** standard used by the banking industry.
- **Source**: `https://raw.githubusercontent.com/greggles/mcc-codes/main/mcc_codes.csv`
- **Action**: Ingest this file to populate `all_tags.md` with standardized service names (e.g., "Veterinary Services", "Bakeries", "Shoe Stores").
- **Benefit**: guarantees coverage of every category known to the credit card network.

## Phase 2: The Dataset (Validation)
To ensure our AI prompts work and our tags feel "natural" (not too clinical), we will test against real transaction descriptions.
- **Dataset**: [USA Banking Transactions Dataset (Kaggle)](https://www.kaggle.com/datasets/priyamchoksi/credit-card-transactions-dataset)
  - Contains ~5,000 diversified transactions.
- **Action**:
  1. Download this CSV.
  2. Run a script to classify each description using our AI + Canonical Tags.
  3. Flag "Uncategorized" items to identify gaps in our tag list.

## Phase 3: The Refinement
- **Iterate**: If the AI consistently fails to tag "Uber Eats" correctly using just "Dining", we add "Food Delivery" to our taxonomy.
- **Result**: A hardened, battle-tested tag list that handles the long tail of vendors.

## Next Steps
1. I will auto-ingest the MCC codes now to expand your `all_tags.md`.
2. You can download the Kaggle dataset to `datasets/transactions.csv`.
3. We run the validation script.
