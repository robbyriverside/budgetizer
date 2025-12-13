import json
import os

# Paths
BASE_DIR = os.getcwd()
DB_TAGS_PATH = os.path.join(BASE_DIR, "assets", "data", "db_tags.yaml")
MOCK_DATA_PATH = os.path.join(BASE_DIR, "assets", "data", "mock_transactions.json")

# 1. Load Allowable Tags
if os.path.exists(DB_TAGS_PATH):
    print(f"Loading tags from {DB_TAGS_PATH}...")
    with open(DB_TAGS_PATH, "r") as f:
        # Simple manual parse looking for "- name: Link"
        ALLOWED_TAG_NAMES = set()
        for line in f:
            if "  - name: " in line:
                # Strip "- name: " and quotes
                raw_name = line.split("name: ")[1].strip()
                clean_name = raw_name.strip("'").strip('"')
                ALLOWED_TAG_NAMES.add(clean_name)
else:
    print("Error: db_tags.yaml not found!")
    exit(1)

print(f"Loaded {len(ALLOWED_TAG_NAMES)} valid canonical tags.")

# 2. Define Manual Mappings (Simulate AI Classification)
# Key: Vendor Name (or substring), Value: List of [Market, Service, System...]
# Vendor tag is preserved from the transaction name/ID.
MAPPINGS = {
    "Mortgage Payment": ["Housing", "Fixed"],
    "Starbucks": ["Dining", "Coffee"],
    "Safeway": ["Groceries"],
    "Chevron": ["Gas"], # 'Service Stations' is likely in MCC but Gas is sufficient Market
    "Netflix": ["Entertainment", "Streaming", "Subscription"],
    "Salary Deposit": ["Income"],
    "Uber": ["Transport", "Ride Services"],
    # For generated randoms if they exist in the file:
    "UBER RIDE": ["Transport", "Ride Services"], 
    "WHOLE FOODS": ["Groceries"]
}

# 3. Process Mock Data
print(f"Processing {MOCK_DATA_PATH}...")
with open(MOCK_DATA_PATH, "r") as f:
    transactions = json.load(f)

updated_count = 0
for tx in transactions:
    vendor_name = tx["name"]
    vendor_tag = tx["category"][0] # Legacy: First item was usually vendor-ish
    
    # Logic: Keep the vendor tag (first item). Replace the rest with Canonical tags.
    
    new_tags = [vendor_tag] # Start with Vendor
    
    # Find mapping
    canonical_tags = []
    # Try exact match first
    if vendor_name in MAPPINGS:
        canonical_tags = MAPPINGS[vendor_name]
    else:
        # Try substring match
        for key, val in MAPPINGS.items():
            if key.upper() in vendor_name.upper():
                canonical_tags = val
                break
    
    # Validate against DB
    valid_canonicals = []
    for tag in canonical_tags:
        if tag in ALLOWED_TAG_NAMES:
            valid_canonicals.append(tag)
        else:
            print(f"Warning: mapped tag '{tag}' for '{vendor_name}' is NOT in db_tags.yaml. Skipping.")
            
    if valid_canonicals:
        new_tags.extend(valid_canonicals)
        tx["category"] = new_tags
        updated_count += 1
    else:
        print(f"No mapping found for '{vendor_name}', keeping original tags: {tx['category']}")

# 4. Save
with open(MOCK_DATA_PATH, "w") as f:
    json.dump(transactions, f, indent=4)

print(f"Migration complete. Updated {updated_count} transactions.")
