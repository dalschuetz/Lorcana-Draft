extends Node2D

const CARD_SCENE_PATH = "res://Scenes/OpponentCard.tscn"
const CARD_DRAW_SPEED = .25
const STARTING_HAND_SIZE = 7
var opponent_deck = ["ariel on human legs", "ariel spectacular singer", "cinderella gentle and kind", "goofy musketeer", "hades king of olympus", "goofy musketeer", "goofy musketeer", "cinderella gentle and kind", "cinderella gentle and kind"]
var card_database_reference

func _ready() -> void:
	opponent_deck.shuffle()
	$RichTextLabel.text = str(opponent_deck.size())
	card_database_reference = preload("res://Scripts/Game/CardDatabase.gd")
	for i in range(STARTING_HAND_SIZE):
		draw_card()

func draw_card():
	var card_drawn_name = opponent_deck[0]
	opponent_deck.erase(card_drawn_name)
	
	if opponent_deck.size() == 0:
		$DeckImage.visible = false
		$RichTextLabel.visible = false
		
	$RichTextLabel.text = str(opponent_deck.size())
	
	# Load and instantiate the card
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	
	# Set card properties
	var card_image_path = str("res://Assets/CardFronts/" + card_drawn_name + ".jpg")
	new_card.get_node("CardImage").texture = load(card_image_path)
	new_card.strength = card_database_reference.CARDS[card_drawn_name][5]
	new_card.willpower = card_database_reference.CARDS[card_drawn_name][6]
	new_card.lore = card_database_reference.CARDS[card_drawn_name][7]
	
	# Add the card to the CardManager
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	
	# Set initial position to be at the opponent's deck position
	new_card.global_position = global_position
	
	# Now add the card to the opponent's hand with the animation
	$"../OpponentHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
