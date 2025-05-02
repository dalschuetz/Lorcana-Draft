extends Node2D
const CARD_SCENE_PATH = "res://Scenes/Card.tscn"
const CARD_DRAW_SPEED = .25
const STARTING_HAND_SIZE = 7

var player_deck = ["ariel on human legs", "ariel spectacular singer", "cinderella gentle and kind", "goofy musketeer", "hades king of olympus", "goofy musketeer", "goofy musketeer", "cinderella gentle and kind", "cinderella gentle and kind"]
var card_database_reference
var drawn_card_this_turn = false

func _ready() -> void:
	player_deck.shuffle()
	$RichTextLabel.text = str(player_deck.size())
	card_database_reference = preload("res://Scripts/CardDatabase.gd")
	for i in range(STARTING_HAND_SIZE):
		draw_card()
		drawn_card_this_turn = false
	drawn_card_this_turn = true

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
	var card_image_path = str("res://Assets/CardFronts/" + card_drawn_name + ".jpg")
	new_card.get_node("CardImage").texture = load(card_image_path)
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	new_card.get_node("AnimationPlayer").play("card_flip")
	
func reset_draw():
	drawn_card_this_turn = false
