import json
import requests

# URL for the LorcanaJSON allCards.json file
json_url = "https://lorcanajson.org/files/current/en/allCards.json"
# Path where to save the output text or markdown file
output_file = 'lorcana_cards.txt'  # You can change this to .md if preferred

# Default values for fields that might be missing
DEFAULT_STRENGTH = 0
DEFAULT_WILLPOWER = 0
DEFAULT_LORE = 0
DEFAULT_COST = 0
DEFAULT_DRYING = 0
DEFAULT_INKED = 0
DEFAULT_TAPPED = 0

def process_abilities(abilities):
    if not abilities:
        return "", ""
    
    ability_texts = []
    ability_types = []
    
    for ability in abilities:
        if 'fullText' in ability:
            ability_texts.append(ability['fullText'])
        
        if 'type' in ability:
            ability_types.append(ability['type'])
    
    return "\\n".join(ability_texts), ", ".join(ability_types)

def main():
    try:
        # Fetch the JSON data from the URL
        print("Fetching data from LorcanaJSON...")
        response = requests.get(json_url)
        response.raise_for_status()  # Raise an exception for HTTP errors
        data = response.json()
        print("Data fetched successfully!")
        
        cards = {}
        
        # Process each card
        print(f"Processing {len(data['cards'])} cards...")
        for card in data['cards']:
            # Get the simpleName as the key
            simple_name = card.get('simpleName', '')
            if not simple_name:
                continue
                
            # Extract required fields with defaults for missing values
            card_id = card.get('id', 0)
            image_url = card.get('images', {}).get('full', '')
            color = card.get('color', '')
            
            ability_text, ability_types = process_abilities(card.get('abilities', []))
            
            strength = card.get('strength', DEFAULT_STRENGTH)
            willpower = card.get('willpower', DEFAULT_WILLPOWER)
            lore = card.get('lore', DEFAULT_LORE)
            cost = card.get('cost', DEFAULT_COST)
            inkwell = 'true' if card.get('inkwell', False) else 'false'
            
            # Add to cards dictionary
            cards[simple_name] = [
                card_id,
                f'"{image_url}"',
                f'"{color}"',
                f'"{ability_text}"',
                f'"{ability_types}"',
                strength,
                willpower,
                lore,
                cost,
                inkwell,
                DEFAULT_DRYING,
                DEFAULT_INKED,
                DEFAULT_TAPPED
            ]
        
        # Create the text/markdown file with the same content
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write('const CARDS = {\n')
            
            for name, values in cards.items():
                # Format the values list as a string
                values_str = ', '.join(str(v) for v in values)
                f.write(f'    "{name}": [{values_str}],\n')
            
            f.write('}\n')
            
        print(f"Successfully created {output_file} with {len(cards)} cards!")
        
    except requests.exceptions.RequestException as e:
        print(f"Error fetching data: {e}")
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

if __name__ == '__main__':
    main()