import json
import pandas as pd
import os

# Define paths
FILE_PATH = 'apps/desktop/assets/data/db_tags.json'
OUTPUT_PATH = 'docs/inventory.xlsx'

def analyze_tags():
    # Load JSON data
    try:
        with open(FILE_PATH, 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: File not found at {FILE_PATH}")
        return

    # Counter for tags
    tag_counts = {}

    # Iterate through each entry in the 'tags' list
    for entry in data.get('tags', []):
        # We only care about Vendor entries as per requirement
        if entry.get('type') == 'Vendor':
            # Get the list of related tags for this vendor
            related_tags = entry.get('related', [])
            
            # Count each tag
            for tag in related_tags:
                tag_counts[tag] = tag_counts.get(tag, 0) + 1

    # Convert to DataFrame
    df = pd.DataFrame(list(tag_counts.items()), columns=['Tag', 'Count'])

    # Sort by Count in descending order
    df = df.sort_values(by='Count', ascending=False)

    # Ensure output directory exists
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)

    # Write to Excel
    try:
        df.to_excel(OUTPUT_PATH, index=False)
        print(f"Successfully wrote {len(df)} tags to {OUTPUT_PATH}")
        print(df.head())
    except Exception as e:
        print(f"Error writing to Excel: {e}")

if __name__ == "__main__":
    analyze_tags()
