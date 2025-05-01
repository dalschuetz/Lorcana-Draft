extends Node2D

const CARD_SCENE_PATH = "res://Scenes/Card.tscn"
const CARD_DRAW_SPEED = .25
const STARTING_HAND_SIZE = 7

var player_deck = ["ariel on human legs", "heihei boat snack", "heihei boat snack", "heihei boat snack", "heihei boat snack", "heihei boat snack", "heihei boat snack", "heihei boat snack"]
var card_database
var drawn_card_this_turn = false

func _ready() -> void:
	player_deck.shuffle()
	$RichTextLabel.text = str(player_deck.size())
	
	# Set up the card database
	setup_card_database()
	
	for i in range(STARTING_HAND_SIZE):
		draw_card()
		drawn_card_this_turn = false
	drawn_card_this_turn = true

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
	if drawn_card_this_turn:
		return
	
	drawn_card_this_turn = true
	var card_drawn_name = player_deck[0]
	player_deck.erase(card_drawn_name)
	
	if player_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$DeckImage.visible = false
		$RichTextLabel.visible = false
		
	$RichTextLabel.text = str(player_deck.size())
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
	
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	new_card.get_node("AnimationPlayer").play("card_flip")

# Helper function to get card image URL from database in multiple ways
func get_card_image_url(card_name):
	# Try different ways to get the image URL
	
	# Option 1: Direct access to CARD_DATABASE property
	if card_database.get("CARD_DATABASE") != null:
		var card_data = card_database.CARD_DATABASE.get(card_name)
		if card_data:
			return card_data[1]  # URL is at index 1
	
	# Option 2: Using a getter method
	elif card_database.has_method("get_card"):
		var card_data = card_database.get_card(card_name)
		if card_data:
			return card_data[1]
			
	elif card_database.has_method("get_card_data"):
		var card_data = card_database.get_card_data(card_name)
		if card_data:
			return card_data[1]
	
	# Option 3: Using a specific image URL getter
	elif card_database.has_method("get_image_url"):
		return card_database.get_image_url(card_name)
		
	# Option 4: Access to different property name
	elif card_database.get("cards") != null:
		var card_data = card_database.cards.get(card_name)
		if card_data:
			return card_data[1]
	
	print("Could not find image URL for card: ", card_name)
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

func reset_draw():
	drawn_card_this_turn = false
