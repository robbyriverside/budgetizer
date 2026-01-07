import json
import os

DB_TAGS_PATH = 'packages/budgetizer_ui/assets/data/db_tags.json'

def load_tags():
    if not os.path.exists(DB_TAGS_PATH):
        print(f"Error: {DB_TAGS_PATH} not found.")
        return []
    with open(DB_TAGS_PATH, 'r') as f:
        data = json.load(f)
        return data

def save_tags(data):
    with open(DB_TAGS_PATH, 'w') as f:
        json.dump(data, f, indent=2)
    print(f"Updates saved to {DB_TAGS_PATH}")

def main():
    data = load_tags()
    tags = data.get('tags', [])
    
    # 1. Build Tag Type Map
    tag_type_map = {t['name']: t.get('type') for t in tags}
    
    # 2. Iterate and Fix
    count_fixed = 0
    vendors_fixed = []

    for tag in tags:
        if tag.get('type') == 'Vendor':
            vendor_name = tag['name']
            related = tag.get('related', [])
            
            has_system = False
            
            for rt in related:
                rt_type = tag_type_map.get(rt)
                if rt_type == 'System':
                    has_system = True
                    break
            
            if not has_system:
                # FIX: Add 'Variable'
                if "Variable" not in related:
                    related.append("Variable")
                    tag['related'] = related # update dict in place
                    count_fixed += 1
                    vendors_fixed.append(vendor_name)
                    # print(f"Fixed: {vendor_name} -> Added 'Variable'")

    if count_fixed > 0:
        print(f"Fixed {count_fixed} vendors by adding 'Variable' tag.")
        print(f"Vendors updated: {vendors_fixed}")
        data['tags'] = tags
        save_tags(data)
    else:
        print("No vendors found missing System tags. All good!")

if __name__ == "__main__":
    main()
