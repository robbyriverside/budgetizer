import json
import os

def load_tags():
    file_path = 'packages/budgetizer_ui/assets/data/db_tags.json'
    if not os.path.exists(file_path):
        print(f"Error: {file_path} not found.")
        return []
    
    with open(file_path, 'r') as f:
        data = json.load(f)
        return data.get('tags', [])

def main():
    tags = load_tags()
    
    # Build a lookup map for tag types
    tag_type_map = {t['name']: t.get('type') for t in tags}
    
    print("--- Vendors with NO System Tags ---")
    count = 0
    missing_system_vendors = []
    
    for tag in tags:
        if tag.get('type') == 'Vendor':
            vendor_name = tag['name']
            related = tag.get('related', [])
            
            has_system = False
            associated_system_tags = []
            
            for rt in related:
                rt_type = tag_type_map.get(rt)
                if rt_type == 'System':
                    has_system = True
                    associated_system_tags.append(rt)
                elif rt_type is None:
                    # checking case sensitivity
                    # simplistic check
                    pass
            
            if not has_system:
                count += 1
                missing_system_vendors.append(vendor_name)
                print(f"Vendor: {vendor_name}")
                print(f"  Current Relations: {related}")
                # Analyze types present
                types_present = [tag_type_map.get(rt, 'UNKNOWN') for rt in related]
                print(f"  Types Present: {types_present}")
                print("-" * 20)

    print(f"\nTotal Vendors missing System tags: {count}")

if __name__ == "__main__":
    main()
