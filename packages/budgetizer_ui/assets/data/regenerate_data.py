import json
import os

DB_TAGS_PATH = 'packages/budgetizer_ui/assets/data/db_tags.json'
DB_TAG_TYPES_PATH = 'packages/budgetizer_ui/assets/data/db_tag_types.json'
DB_SYSTEM_TAGS_PATH = 'packages/budgetizer_ui/assets/data/db_system_tags.json'

def load_tags():
    with open(DB_TAGS_PATH, 'r') as f:
        return json.load(f).get('tags', [])

def generate_types(tags):
    grouped = {}
    for tag in tags:
        t_type = tag.get('type', 'Unknown')
        if t_type not in grouped:
            grouped[t_type] = []
        grouped[t_type].append(tag)
    
    with open(DB_TAG_TYPES_PATH, 'w') as f:
        json.dump(grouped, f, indent=2)
    print(f"Generated {DB_TAG_TYPES_PATH}")

def generate_system_tags(tags):
    # Map tag_name -> tag_type
    type_map = {t['name']: t.get('type') for t in tags}
    
    # 1. Identify all System Tags
    system_tags = [t['name'] for t in tags if t.get('type') == 'System']
    
    # 2. Build map: SystemTag -> [Related Tags]
    # Relationships are defined on the Vendor/Market side pointing to System/Market/etc.
    # But wait, `related` is a list of strings on any tag.
    # If "Walmart" (Vendor) has related=["Variable"], then "Variable" is related to "Walmart".
    # The `db_system_tags.json` likely wants:
    # { "Variable": ["Walmart", "Safeway", ...], "Fixed": [...] }
    
    sys_map = {st: [] for st in system_tags}
    
    for tag in tags:
        related = tag.get('related', [])
        for r in related:
            if r in sys_map:
                sys_map[r].append(tag['name'])
                
    with open(DB_SYSTEM_TAGS_PATH, 'w') as f:
        json.dump(sys_map, f, indent=2)
    print(f"Generated {DB_SYSTEM_TAGS_PATH}")

def main():
    if not os.path.exists(DB_TAGS_PATH):
        print(f"Error: {DB_TAGS_PATH} missing")
        return
        
    tags = load_tags()
    generate_types(tags)
    generate_system_tags(tags)

if __name__ == "__main__":
    main()
