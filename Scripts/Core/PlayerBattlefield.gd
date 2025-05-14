extends Node2D

class_name PlayerBattlefield

const CARD_SPACING = 120  # Adjust based on your card width and desired spacing
const CARD_MOVE_DURATION = 0.3  # Time for cards to move to new positions

var battlefield_width
var battlefield_cards = []  # Array to hold all cards on the battlefield

func _ready():
	# Get the width of the battlefield area - assuming you have a sprite or collision shape
	# that defines the width of your battlefield area
	var battlefield_collision = $Area2D/CollisionShape2D
	battlefield_width = battlefield_collision.shape.extents.x * 2
	
	# You might need to adjust based on your actual battlefield setup
	# If using a sprite instead:
	# battlefield_width = $Sprite2D.texture.get_width() * $Sprite2D.scale.x

func add_card_to_battlefield(card):
	battlefield_cards.append(card)
	rearrange_battlefield_cards()

func remove_card_from_battlefield(card):
	battlefield_cards.erase(card)
	card.on_battlefield = false
	rearrange_battlefield_cards()

func rearrange_battlefield_cards():
	if battlefield_cards.size() == 0:
		return
		
	# Calculate the total width needed for all cards
	var total_cards_width = battlefield_cards.size() * CARD_SPACING
	
	# Determine the starting X position to center the cards
	var start_x = position.x - (total_cards_width / 2) + (CARD_SPACING / 2)
	
	# If there's only one card, center it
	if battlefield_cards.size() == 1:
		start_x = position.x
	
	# Assign new positions to each card
	for i in range(battlefield_cards.size()):
		var card = battlefield_cards[i]
		var target_position = Vector2(start_x + i * CARD_SPACING, position.y)
		
		# Use a tween to animate the card movement
		var tween = create_tween()
		tween.tween_property(card, "position", target_position, CARD_MOVE_DURATION).set_ease(Tween.EASE_OUT)

# Call this if the battlefield width changes (e.g., window resize)
func update_battlefield_width(new_width):
	battlefield_width = new_width
	rearrange_battlefield_cards()

# You'll need to add this method to handle when a card is removed
# (e.g., when destroyed in battle)
func card_destroyed(card):
	remove_card_from_battlefield(card)
