import csv
import urllib.request
import os
import json
import re

# 1. Predefined Tags from all_tags.md
VENDORS = [
    {"name": "Amazon"},
    {"name": "Target"},
    {"name": "Shell"},
    {"name": "Starbucks", "system_tags": ["Fast Food", "Coffee", "Drinks"]},
    {"name": "Uber"},
    {"name": "Whole Foods", "system_tags": ["Groceries", "Dining", "Fast Food"]},
    {"name": "AT&T", "system_tags": ["Utilities", "Mobile", "Internet", "Subscription", "Fixed", "Recurring"]},
    {"name": "Verizon", "system_tags": ["Utilities", "Mobile", "Internet", "Subscription", "Fixed", "Recurring"]},
    {"name": "T-Mobile", "system_tags": ["Utilities", "Mobile", "Internet", "Subscription", "Fixed", "Recurring"]},
    {"name": "Netflix", "system_tags": ["Subscription", "Fixed", "Recurring", "Entertainment"]},
    {"name": "Disney+", "system_tags": ["Subscription", "Fixed", "Recurring", "Entertainment"]},
    {"name": "HBO Max", "system_tags": ["Subscription", "Fixed", "Recurring", "Entertainment"]},
    {"name": "Peacock", "system_tags": ["Subscription", "Fixed", "Recurring", "Entertainment"]},
    {"name": "Paramount+", "system_tags": ["Subscription", "Fixed", "Recurring", "Entertainment"]},
    {"name": "NYTimes", "system_tags": ["News", "Subscription", "Fixed", "Recurring"]},
    {"name": "AP", "system_tags": ["News", "Subscription", "Fixed", "Recurring"]},
    {"name": "Reuters", "system_tags": ["News", "Subscription", "Fixed", "Recurring"]},
    {"name": "Guardian", "system_tags": ["News", "Subscription", "Fixed", "Recurring"]},
    {"name": "Chevron"},
    {"name": "Safeway", "system_tags": ["Groceries", "Fast Food", "Health"]},
    {"name": "McDonald's"},
    {"name": "Jiffy Lube"},
]

MARKETS = [
    {"name": "Groceries", "description": "Supermarkets, bakers, butchers (e.g., Whole Foods, Safeway)."},
    {"name": "Dining", "description": "Sit-down restaurants, bistros, bars."},
    {"name": "Fast Food", "description": "Quick service, drive-thru, cafes, smoothie/juice bars, coffee shops.", "related": ["Dining"]},
    {"name": "Drinks", "description": "Beverages, alcohol, smoothies, juice (e.g. Starbucks, Jamba).", "related": ["Dining"]},
    {"name": "Gifts", "description": "Presents, souvenirs, flowers, donations."},
    {"name": "Alcohol", "description": "Beer, wine, liquor.", "related": ["Drinks"]},
    {"name": "Music", "description": "Instruments, sheet music, lessons.", "related": ["Entertainment"]},
    {"name": "Records", "description": "Vinyl records, LPs.", "related": ["Music", "Entertainment"]},
    {"name": "CDs", "description": "Compact discs, physical media.", "related": ["Music", "Entertainment"]},
    {"name": "Home Goods", "description": "Furniture, decor, hardware (e.g., Home Depot, IKEA)."},
    {"name": "Clothing", "description": "Apparel, shoes, accessories (e.g., GAP, Nike)."},
    {"name": "Gas", "description": "Fuel stations (e.g., Shell, Chevron).", "related": ["Transport", "Auto Maintenance"]},
    {"name": "Auto Maintenance", "description": "Repairs, parts, service (e.g., Jiffy Lube).", "related": ["Transport"]},
    {"name": "Transport", "description": "Rideshare, public transit, taxis (e.g., Uber, Lyft).", "related": ["Travel"]},
    {"name": "Housing", "description": "Rent, mortgage, repairs (e.g., specific property management)."},
    {"name": "Entertainment", "description": "Fun, hobbies, media (e.g., Netflix, Cinema)."},
    {"name": "Utilities", "description": "Electricity, water, internet (e.g., PGE, Comcast).", "related": ["Housing"]},
    {"name": "Health", "description": "Medical, dental, pharmacy (e.g., Walgreens, Kaiser)."},
    {"name": "Travel", "description": "Flights, hotels, car rentals (e.g., Airbnb, Delta)."},
    {"name": "Booking", "description": "Reservations, appointments, travel agencies.", "related": ["Travel"]},
    {"name": "Tours", "description": "Guided tours, excursions, packages.", "related": ["Travel", "Booking"]},
    {"name": "Education", "description": "Tuition, courses, books."},
    {"name": "News", "description": "Newspapers, magazines, digital subscriptions.", "related": ["Education", "Entertainment"]},
    {"name": "Financial", "description": "Banks, credit unions, loans, taxes."},
    {"name": "Legal", "description": "Lawyers, courts, legal fees.", "related": ["Government"]},
    {"name": "Government", "description": "Taxes, fines, public services.", "related": ["Legal"]},
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
    {"name": "Internet", "description": "ISP services.", "related": ["Utilities"]},
    {"name": "WiFi", "description": "Wireless internet access.", "related": ["Internet", "Utilities"]},
    {"name": "Mobile", "description": "Cell phone service.", "related": ["Utilities"]},
    {"name": "Law Firm", "description": "Legal representation and advice."},
    {"name": "CPA Firm", "description": "Accounting and tax preparation."},
    {"name": "Gifts", "description": "Presents, donations."},
    {"name": "Electronics", "description": "Gadgets, tech."},
    {"name": "Alcohol", "description": "Liquor stores, bars."},
    {"name": "Bank Fees", "description": "OD fees, maintenance fees, ATM fees."},
    {"name": "Interest", "description": "Interest income or expense."},
    {"name": "Taxes", "description": "Income tax, property tax."},
    {"name": "Loan Repayment", "description": "Personal loans, car payments."},
]

# Mapping for really long names -> Short names
SHORT_NAME_MAPPING = {
    "7941": "Sports Venues", # Commercial Sports, Athletic Fields...
    "5814": "Fast Food", # Fast Food Restaurants
    "5812": "Restaurants", # Eating places and Restaurants
    "5813": "Bars & Clubs", # Drinking Places...
}

def clean_text(text):
    if not text: return ""
    return text.replace('\u2019', "'").replace('\u2013', "-").replace('\u2014', "-")

def shorten_name(name):
    # 1. Split by markers that usually indicate a list or elaboration
    parts = re.split(r'[,;]|\s+[-–—]\s+|\s*\(', name)
    candidate = parts[0].strip()
    
    # 2. If length > 3 words, try to shorten to first 2 words
    words = candidate.split()
    if len(words) > 3:
        candidate = " ".join(words[:2])
    
    # 3. Cleanup trailing " and", " or"
    # This handles "Chemicals and" -> "Chemicals"
    candidate = re.sub(r'\s+(and|or|the|of|for)$', '', candidate, flags=re.IGNORECASE).strip()

    return candidate

# AI & Caching Logic
CACHE_FILE = os.path.join(os.getcwd(), "tooling", "mcc_name_cache.json")
RELATIONS_CACHE_FILE = os.path.join(os.getcwd(), "tooling", "tag_relations_cache.json")
ENV_FILE = ".env"

def load_cache():
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                return json.load(f)
        except:
            return {}
    return {}

def save_cache(cache, filepath=CACHE_FILE):
    try:
        with open(filepath, "w") as f:
            json.dump(cache, f, indent=2)
    except Exception as e:
        print(f"Warning: Could not save cache: {e}")

def load_relations_cache():
    if os.path.exists(RELATIONS_CACHE_FILE):
        try:
            with open(RELATIONS_CACHE_FILE, "r") as f:
                return json.load(f)
        except:
            return {}
    return {}

def get_api_key():
    try:
        with open(ENV_FILE, "r") as f:
            for line in f:
                if line.startswith("OPENAI_API_KEY="):
                    return line.strip().split("=", 1)[1].strip('"')
    except:
        return None
    return None

def generate_short_name(description, api_key):
    if not api_key:
        return shorten_name(description) # Fallback to heuristic

    url = "https://api.openai.com/v1/chat/completions"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}"
    }
    
    # Prompt tuned: Extract specific BUSINESS NAME, otherwise category.
    prompt = f"Extract the specific BUSINESS NAME from this description if present. If it is a generic category, return a concise 1-2 word tag name. No punctuation. Examples: 'Stationery, Office Supplies' -> 'Stationery'. 'Holiday Inns, Holiday Inn Express' -> 'Holiday Inn'. Description: {description}"
    
    data = json.dumps({
        "model": "gpt-4o-mini",
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.3,
        "max_tokens": 10
    }).encode("utf-8")

    try:
        req = urllib.request.Request(url, data=data, headers=headers)
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode())
            candidate = result["choices"][0]["message"]["content"].strip()
            # Clean up result just in case
            return clean_text(candidate).replace(".", "")
    except Exception as e:
        print(f"AI Error for '{description}': {e}")
        return shorten_name(description) # Fallback

def find_related_markets(tag_name, tag_desc, candidates, api_key):
    if not api_key:
        return []

    url = "https://api.openai.com/v1/chat/completions"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}"
    }
    
    # Prompt: CoT, Identify first, then tag.
    prompt = (
        f"1. Identify the entity '{tag_name}' ({tag_desc}). What does it do? (e.g. 'It is a budget hotel'). "
        "Does it offer secondary services (e.g. Pharmacy in a grocery store, Fast Food in a gas station)? "
        f"2. Based on that identification, select related Markets from {candidates}. "
        f"Return a valid JSON object: {{ 'identity': 'string', 'related': ['Tag1', 'Tag2'] }}. "
        f"If none apply, return {{ 'identity': '...', 'related': [] }}."
    )
    
    data = json.dumps({
        "model": "gpt-4o-mini",
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.0,
        "max_tokens": 100
    }).encode("utf-8")

    try:
        req = urllib.request.Request(url, data=data, headers=headers)
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode())
            content = result["choices"][0]["message"]["content"].strip()
            # Try to parse JSON object
            match = re.search(r'\{.*\}', content, re.DOTALL)
            if match:
                parsed = json.loads(match.group(0))
                return parsed.get("related", [])
            return []
    except Exception as e:
        print(f"AI Relation Error for '{tag_name}': {e}")
        return []

# 2. Fetch MCC Codes
MCC_URL = "https://raw.githubusercontent.com/greggles/mcc-codes/main/mcc_codes.csv"
mcc_services = []

print("Fetching MCC codes...")
api_key = get_api_key()
if api_key:
    print("OpenAI API Key found. Using AI for naming...")
else:
    print("No OpenAI API Key found. Using heuristics...")

name_cache = load_cache()
cache_updated = False

try:
    with urllib.request.urlopen(MCC_URL) as response:
        decoded_content = response.read().decode('utf-8')
        reader = csv.DictReader(decoded_content.splitlines())
        
        seen_names = set()
        for manual in SPECIFIC_SERVICES_MANUAL:
            seen_names.add(manual["name"].lower())

        for row in reader:
            raw_desc = row.get("edited_description", "").strip()
            # Clean up character artifacts first
            original_name = clean_text(raw_desc.replace('"', '').strip())
            
            if not original_name:
                continue

            mcc_code = row.get("mcc", "")

            # Determine final name
            # 1. Check Custom Mapping
            if mcc_code in SHORT_NAME_MAPPING:
                final_name = SHORT_NAME_MAPPING[mcc_code]
            # 2. Check Cache
            elif mcc_code in name_cache:
                final_name = name_cache[mcc_code]
            # 3. Generate AI Name ONLY if description is > 3 words
            elif len(original_name.split()) > 3:
                final_name = generate_short_name(original_name, api_key)
                if final_name:
                    print(f"AI Generated (Long > 3): '{original_name}' -> '{final_name}'")
                    name_cache[mcc_code] = final_name
                    cache_updated = True
            # 4. Short enough to keep as is
            else:
                 final_name = original_name
            
            if not final_name:
                continue

            # Skip if already manually defined (checks final name)
            if final_name.lower() in seen_names:
                continue
            
            # Simple heuristic filter
            if len(final_name) < 3 or final_name.lower().startswith("test"):
                continue

            # Description logic:
            # User request: "ONLY shorten the name, leave the description as is."
            # Prefer combined_description (usually richer), else fall back to encoded/original name.
            raw_combined = row.get("combined_description", "").strip()
            
            if raw_combined:
                desc = raw_combined
            else:
                desc = original_name

            desc = clean_text(desc)
            
            mcc_services.append({
                "name": final_name,
                "description": desc,
                "source": "ISO-18245 (MCC)",
                "mcc_id": mcc_code
            })
            seen_names.add(final_name.lower())

    if cache_updated:
        save_cache(name_cache)
        print("Updated name cache.")

except Exception as e:
    print(f"Error fetching MCC codes: {e}")

# 3. Combine All Tags
all_tags = []

for t in VENDORS:
    tag = {
        "name": t["name"],
        "type": "Vendor",
        "description": f"Vendor: {t['name']}",
        "regex": f"(?i){t['name']}"
    }
    if "system_tags" in t:
        tag["related"] = t["system_tags"]
    all_tags.append(tag)

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
        "description": t["description"],
        "mcc_id": t.get("mcc_id"),
        "source": "MCC"
    })

# 3b. Second Pass: Cross-Referencing (Tags -> Markets)
print("Starting Second Pass: Cross-Referencing Tags...")
relations_cache = load_relations_cache()
relations_updated = False
market_names = [m["name"] for m in MARKETS]

for tag in all_tags:
    # Only process Vendors and Services
    if tag["type"] not in ["Vendor", "Service"]:
        continue
    
    # key for cache
    tag_key = tag["name"]
    
    # Merge with existing tags (e.g. System tags manually added)
    existing_related = tag.get("related", [])
    
    ai_related = []
    if tag_key in relations_cache:
        ai_related = relations_cache[tag_key]
    else:
        # Ask AI
        if api_key:
            related = find_related_markets(tag["name"], tag.get("description", ""), market_names, api_key)
            if related:
                valid_related = [r for r in related if r in market_names]
                print(f"AI Related: '{tag['name']}' -> {valid_related}")
                ai_related = valid_related
                relations_cache[tag_key] = valid_related
                relations_updated = True
            else:
                 relations_cache[tag_key] = []
                 relations_updated = True
    
    # Final merge: System Tags + AI Market Tags (deduplicated)
    if ai_related:
        tag["related"] = list(dict.fromkeys(existing_related + ai_related))
    elif existing_related:
         tag["related"] = existing_related 
    else:
         tag["related"] = []

if relations_updated:
    save_cache(relations_cache, RELATIONS_CACHE_FILE)
    print("Updated relations cache.")

# 4. Write to YAML (Manual formatting to avoid pyyaml dependency)
output_path = os.path.join(os.getcwd(), "assets", "data", "db_tags.yaml")
os.makedirs(os.path.dirname(output_path), exist_ok=True)

def escape_yaml_str(s):
    if not s: return ""
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
            
            if "mcc_id" in tag and tag["mcc_id"]:
                 f.write("    mcc_id: " + escape_yaml_str(tag["mcc_id"]) + "\n")
            
            if "related" in tag and tag["related"]:
                f.write("    related:\n")
                for related_tag in tag["related"]:
                    f.write(f"      - {escape_yaml_str(related_tag)}\n")

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
