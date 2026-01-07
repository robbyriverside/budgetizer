
import json

db_tags_file = 'db_tags.json'

try:
    with open(db_tags_file, 'r') as f:
        data = json.load(f)

    tags_list = data.get('tags', []) if isinstance(data, dict) else data

    # 1. Fix Lyft
    lyft_found = False
    for tag in tags_list:
        if tag.get('name') == 'Lyft':
            # Replace 'Transportation' with 'Transport'
            if 'Transportation' in tag.get('related', []):
                tag['related'].remove('Transportation')
                if 'Transport' not in tag['related']:
                    tag['related'].append('Transport')
                print("Updated Lyft: Swapped Transportation -> Transport")
            # Ensure it has Transport if not present
            elif 'Transport' not in tag.get('related', []):
                 tag['related'].append('Transport')
                 print("Updated Lyft: Added Transport")
            lyft_found = True
            break
            
    if not lyft_found:
        print("Warning: Lyft tag not found.")

    # 2. Fix Education Type
    edu_found = False
    for tag in tags_list:
        if tag.get('name') == 'Education':
            if tag.get('type') == 'Service':
                tag['type'] = 'Market'
                print("Updated Education: Changed Type Service -> Market")
            edu_found = True
            break
            
    if not edu_found:
        print("Warning: Education tag not found.")

    # Write back
    if isinstance(data, dict):
        data['tags'] = tags_list
        output_data = data
    else:
        output_data = tags_list

    with open(db_tags_file, 'w') as f:
        json.dump(output_data, f, indent=2)
    
    print("Successfully applied final fixes to db_tags.json")

except Exception as e:
    print(f"Error: {e}")
