
import json

input_file = 'db_tags.json'

try:
    with open(input_file, 'r') as f:
        data = json.load(f)

    tags_list = data.get('tags', []) if isinstance(data, dict) else data
    tags_map = {tag['name']: tag for tag in tags_list}

    def get_related_types(tag_entry):
        types_found = set()
        related_names = tag_entry.get('related', [])
        for r_name in related_names:
            if r_name in tags_map:
                types_found.add(tags_map[r_name].get('type'))
            else:
                pass # Missing tags printed in separate check if needed
        return types_found

    violating_vendors = []
    missing_definitions = set()

    print("Checking Vendor tags for compliance...")
    for tag in tags_list:
        if tag.get('type') == 'Vendor':
            # Check for missing definitions first
            for r_name in tag.get('related', []):
                if r_name not in tags_map:
                    missing_definitions.add(r_name)

            related_types = get_related_types(tag)
            
            has_market = 'Market' in related_types
            has_system = 'System' in related_types
            
            if not (has_market or has_system):
                violating_vendors.append({
                    'name': tag['name'],
                    'related': tag.get('related', []),
                    'related_types': list(related_types)
                })

    if missing_definitions:
        print(f"\nFATAL: Still missing definitions for tags: {missing_definitions}")

    if violating_vendors:
        print(f"\nFound {len(violating_vendors)} vendors violating the rule (NO Market or System tag):")
        for v in violating_vendors:
            print(f" - {v['name']} (Related: {v['related']} -> Types: {v['related_types']})")
    else:
        print("\nSUCCESS: All Vendor tags comply with the rule.")

except Exception as e:
    print(f"Error: {e}")
