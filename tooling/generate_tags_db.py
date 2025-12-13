import csv
import urllib.request
import os
import json

# 1. Predefined Tags from all_tags.md
# 1. Predefined Tags from all_tags.md
VENDORS = [
    {"name": "Amazon"},
    {"name": "Target"},
    {"name": "Shell"},
    {"name": "Starbucks"},
    {"name": "Uber"},
    {"name": "Whole Foods"},
    {"name": "Netflix"},
    {"name": "Chevron"},
    {"name": "Safeway"},
    {"name": "McDonald's"},
    {"name": "Jiffy Lube"},
]

MARKETS = [
    {"name": "Groceries", "description": "Supermarkets, bakers, butchers (e.g., Whole Foods, Safeway)."},
    {"name": "Dining", "description": "Restaurants, fast food, bars (e.g., McDonald's)."},
    {"name": "Home Goods", "description": "Furniture, decor, hardware (e.g., Home Depot, IKEA)."},
    {"name": "Clothing", "description": "Apparel, shoes, accessories (e.g., GAP, Nike)."},
    {"name": "Gas", "description": "Fuel stations (e.g., Shell, Chevron)."},
    {"name": "Auto Maintenance", "description": "Repairs, parts, service (e.g., Jiffy Lube)."},
    {"name": "Transport", "description": "Rideshare, public transit, taxis (e.g., Uber, Lyft)."},
    {"name": "Housing", "description": "Rent, mortgage, repairs (e.g., specific property management)."},
    {"name": "Entertainment", "description": "Fun, hobbies, media (e.g., Netflix, Cinema)."},
    {"name": "Utilities", "description": "Electricity, water, internet (e.g., PGE, Comcast)."},
    {"name": "Health", "description": "Medical, dental, pharmacy (e.g., Walgreens, Kaiser)."},
    {"name": "Travel", "description": "Flights, hotels, car rentals (e.g., Airbnb, Delta)."},
    {"name": "Education", "description": "Tuition, courses, books."},
]

SYSTEM_TAGS = [
    {"name": "Subscription", "description": "Fixed recurring expense"},
    {"name": "Fixed", "description": "Fixed non-recurring expense"},
    {"name": "Variable", "description": "Variable non-recurring expense"},
    {"name": "Recurring", "description": "Variable recurring expense"},
    {"name": "Income", "description": "Positive amount added to the budget"},
    {"name": "Transfer", "description": "Transfer between accounts"},
    {"name": "Pending", "description": "Pending transaction"},
]

SPECIFIC_SERVICES_MANUAL = [
    {"name": "Ride Services", "description": "Taxis, Uber, Lyft."},
    {"name": "Oil Change", "description": "Preventative maintenance (e.g., Jiffy Lube)."},
    {"name": "Auto Repair", "description": "Mechanical repairs and fixes."},
    {"name": "Coffee", "description": "Coffee shops, cafes."},
    {"name": "Fast Food", "description": "Quick service dining."},
    {"name": "Streaming", "description": "Digital media subscriptions."},
    {"name": "Internet", "description": "ISP services."},
    {"name": "Mobile", "description": "Cell phone service."},
    {"name": "Gifts", "description": "Presents, donations."},
    {"name": "Electronics", "description": "Gadgets, tech."},
    {"name": "Alcohol", "description": "Liquor stores, bars."},
]

# 2. Fetch MCC Codes
MCC_URL = "https://raw.githubusercontent.com/greggles/mcc-codes/main/mcc_codes.csv"
mcc_services = []

print("Fetching MCC codes...")
try:
    with urllib.request.urlopen(MCC_URL) as response:
        decoded_content = response.read().decode('utf-8')
        reader = csv.DictReader(decoded_content.splitlines())
        
        seen_names = set()
        for manual in SPECIFIC_SERVICES_MANUAL:
            seen_names.add(manual["name"].lower())

        for row in reader:
            raw_desc = row.get("edited_description", "").strip()
            # Clean up description
            name = raw_desc.replace('"', '').strip()
            
            if not name:
                continue

            # Skip if already manually defined or too generic/weird
            if name.lower() in seen_names:
                continue
            
            # Simple heuristic filter
            if len(name) < 3 or name.lower().startswith("test"):
                continue

            # Use combined_description as description if good, else reuse name
            desc = row.get("combined_description", name).strip()
            
            mcc_services.append({
                "name": name,
                "description": desc,
                "source": "ISO-18245 (MCC)"
            })
            seen_names.add(name.lower())

except Exception as e:
    print(f"Error fetching MCC codes: {e}")

# 3. Combine All Tags
all_tags = []

for t in VENDORS:
    all_tags.append({
        "name": t["name"],
        "type": "Vendor",
        "description": f"Vendor: {t['name']}",
        "regex": f"(?i){t['name']}"
    })

for t in MARKETS:
    all_tags.append({
        "name": t["name"],
        "type": "Market",
        "description": t["description"]
    })

for t in SYSTEM_TAGS:
    all_tags.append({
        "name": t["name"],
        "type": "System",
        "description": t["description"]
    })

for t in SPECIFIC_SERVICES_MANUAL:
    all_tags.append({
        "name": t["name"],
        "type": "Service",
        "description": t["description"],
        "source": "Manual"
    })

for t in mcc_services:
    all_tags.append({
        "name": t["name"],
        "type": "Service",
        "description": t["description"]
    })

# 4. Write to YAML (Manual formatting to avoid pyyaml dependency)
output_path = os.path.join(os.getcwd(), "assets", "data", "db_tags.yaml")
os.makedirs(os.path.dirname(output_path), exist_ok=True)

def escape_yaml_str(s):
    # Basic escaping for single-line strings
    if ":" in s or "#" in s or "[" in s or "]" in s or "{" in s or "}" in s or '"' in s:
        return '"' + s.replace('"', '\\"') + '"'
    return s

try:
    with open(output_path, "w") as f:
        f.write("tags:\n")
        for tag in all_tags:
            f.write("  - name: " + escape_yaml_str(tag["name"]) + "\n")
            f.write("    type: " + escape_yaml_str(tag["type"]) + "\n")
            
            # Handle description carefully
            desc = tag.get("description", "").replace("\n", " ").strip()
            if desc:
                f.write("    description: " + escape_yaml_str(desc) + "\n")
            
            if "regex" in tag:
                f.write("    regex: " + escape_yaml_str(tag["regex"]) + "\n")

            if "source" in tag:
                f.write("    source: " + escape_yaml_str(tag["source"]) + "\n")

    print(f"Successfully wrote {len(all_tags)} tags to {output_path}")
    print(f" - Vendors: {len(VENDORS)}")
    print(f" - Markets: {len(MARKETS)}")
    print(f" - System: {len(SYSTEM_TAGS)}")
    print(f" - Manual Services: {len(SPECIFIC_SERVICES_MANUAL)}")
    print(f" - MCC Services: {len(mcc_services)}")

except Exception as e:
    print(f"Error writing YAML file: {e}")

# 5. Write to JSON (For Flutter App Consumption)
json_output_path = os.path.join(os.getcwd(), "assets", "data", "db_tags.json")
try:
    with open(json_output_path, "w") as f:
        json.dump({"tags": all_tags}, f, indent=2)
    print(f"Successfully wrote JSON to {json_output_path}")
except Exception as e:
    print(f"Error writing JSON file: {e}")
