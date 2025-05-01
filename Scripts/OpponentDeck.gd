extends Node2D

const CARD_SCENE_PATH = "res://Scenes/OpponentCard.tscn"
const CARD_DRAW_SPEED = .25
const STARTING_HAND_SIZE = 7

var opponent_deck = ["ariel spectacular singer", "heihei boat snack", "heihei boat snack", "heihei boat snack", "heihei boat snack", "heihei boat snack", "heihei boat snack", "heihei boat snack"]
var card_database

func _ready() -> void:
	opponent_deck.shuffle()
	$RichTextLabel.text = str(opponent_deck.size())
	
	# Set up the card database
	setup_card_database()
	
	for i in range(STARTING_HAND_SIZE):
		draw_card()

# Function to handle setting up the card database, with multiple options
func setup_card_database():
	var CardDatabaseScript = load("res://Scripts/CardDatabase.gd")
	
	# Try different approaches to access the database
	# Option 1: It's a class that needs to be instantiated
	card_database = CardDatabaseScript.new()
	
	# If that fails, try other options (uncomment as needed)
	# Option 2: It's a singleton with static access
	# card_database = CardDatabaseScript
	
	# Option 3: It's an autoload/singleton with a get_instance method
	# if CardDatabaseScript.has_method("get_instance"):
	#     card_database = CardDatabaseScript.get_instance()

func draw_card():
	# Check if there are cards left in the deck
	if opponent_deck.size() <= 0:
		print("No cards left in opponent's deck!")
		$DeckImage.visible = false
		$RichTextLabel.visible = false
		return
	
	var card_drawn_name = opponent_deck[0]
	opponent_deck.erase(card_drawn_name)
	
	if opponent_deck.size() == 0:
		$DeckImage.visible = false
		$RichTextLabel.visible = false
		
	$RichTextLabel.text = str(opponent_deck.size())
	
	# Load and instantiate the card
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	
	# Get card image URL from the database
	var card_image_url = get_card_image_url(card_drawn_name)
	
	if card_image_url:
		# Create HTTP request to download the image
		var http_request = HTTPRequest.new()
		new_card.add_child(http_request)
		http_request.request_completed.connect(_on_http_request_completed.bind(new_card))
		http_request.request(card_image_url)
	else:
		print("Error: Could not find image URL for card: ", card_drawn_name)
		# Use placeholder if available
		var placeholder = load("res://Assets/CardFronts/placeholder.jpg")
		if placeholder:
			new_card.get_node("CardImage").texture = placeholder
	
	# Add card strength property if available in database
	var card_strength = get_card_strength(card_drawn_name)
	if card_strength != null:
		new_card.strength = card_strength
	
	# Add the card to the CardManager
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	
	# Set initial position to be at the opponent's deck position
	new_card.global_position = global_position
	
	# Now add the card to the opponent's hand with the animation
	$"../OpponentHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)

# Helper function to get card image URL from database in multiple ways
func get_card_image_url(card_name):
	# Try different ways to get the image URL
	
	# Option 1: Direct access to CARD_DATABASE property
	if card_database.get("CARD_DATABASE") != null:
		var card_data = card_database.CARD_DATABASE.get(card_name)
		if card_data:
			return card_data[1]  # URL is at index 1
	
	# Option 2: Using a getter method
	if card_database.has_method("get_card"):
		var card_data = card_database.get_card(card_name)
		if card_data:
			return card_data[1]
			
	if card_database.has_method("get_card_data"):
		var card_data = card_database.get_card_data(card_name)
		if card_data:
			return card_data[1]
	
	# Option 3: Using a specific image URL getter
	if card_database.has_method("get_image_url"):
		return card_database.get_image_url(card_name)
		
	# Option 4: Access to different property name
	if card_database.get("cards") != null:
		var card_data = card_database.cards.get(card_name)
		if card_data:
			return card_data[1]
	
	# Option 5: Legacy CARDS property (from original script)
	if card_database.get("CARDS") != null:
		var card_data = card_database.CARDS.get(card_name)
		if card_data:
			return card_data[1]
	
	print("Could not find image URL for card: ", card_name)
	return null

# Helper function to get card strength
func get_card_strength(card_name):
	# Try different ways to get the strength
	
	# Option 1: Direct access to CARD_DATABASE property
	if card_database.get("CARD_DATABASE") != null:
		var card_data = card_database.CARD_DATABASE.get(card_name)
		if card_data:
			return card_data[0]  # Strength is at index 0
	
	# Option 2: Using a getter method
	if card_database.has_method("get_card"):
		var card_data = card_database.get_card(card_name)
		if card_data:
			return card_data[0]
			
	if card_database.has_method("get_card_data"):
		var card_data = card_database.get_card_data(card_name)
		if card_data:
			return card_data[0]
	
	# Option 3: Using a specific strength getter
	if card_database.has_method("get_strength"):
		return card_database.get_strength(card_name)
		
	# Option 4: Access to different property name
	if card_database.get("cards") != null:
		var card_data = card_database.cards.get(card_name)
		if card_data:
			return card_data[0]
	
	# Option 5: Legacy CARDS property (from original script)
	if card_database.get("CARDS") != null:
		var card_data = card_database.CARDS.get(card_name)
		if card_data:
			return card_data[0]
	
	print("Could not find strength for card: ", card_name)
	return null

func _on_http_request_completed(result, response_code, headers, body, card_node):
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var image = Image.new()
		var error = image.load_jpg_from_buffer(body)
		if error == OK:
			var texture = ImageTexture.create_from_image(image)
			card_node.get_node("CardImage").texture = texture
		else:
			# Try PNG if JPG fails
			error = image.load_png_from_buffer(body)
			if error == OK:
				var texture = ImageTexture.create_from_image(image)
				card_node.get_node("CardImage").texture = texture
			else:
				print("Failed to load image from buffer - not a JPG or PNG")
				# Load placeholder texture if available
				var placeholder = load("res://Assets/CardFronts/placeholder.jpg")
				if placeholder:
					card_node.get_node("CardImage").texture = placeholder
	else:
		print("Failed to download image, result: ", result, ", code: ", response_code)
		# Load placeholder texture if available
		var placeholder = load("res://Assets/CardFronts/placeholder.jpg")
		if placeholder:
			card_node.get_node("CardImage").texture = placeholder
	
	# Remove the HTTPRequest node after it's done
	var http_request = card_node.get_node("HTTPRequest")
	if http_request:
		http_request.queue_free()
