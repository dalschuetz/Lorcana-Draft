extends Node
const CARD_SMALLER_SCALE = 0.6
const CARD_MOVE_SPEED = 0.2
var empty_card_slots = []

func _ready() -> void:
	empty_card_slots.append($"../CardSlots/OpponentCardSlot6")
	empty_card_slots.append($"../CardSlots/OpponentCardSlot7")
	empty_card_slots.append($"../CardSlots/OpponentCardSlot8")
	empty_card_slots.append($"../CardSlots/OpponentCardSlot9")
	empty_card_slots.append($"../CardSlots/OpponentCardSlot10")
	
func _on_end_turn_button_pressed() -> void:
	opponent_turn()
	
func opponent_turn():
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false
	
	if $"../OpponentDeck".opponent_deck.size() != 0:
		$"../OpponentDeck".draw_card()
	
	# Check if free slot exists, and if not, end turn
	if empty_card_slots.size() == 0:
		end_opponent_turn()
		return
	
	# Play a card
	try_play_card_with_highest_strength()
	
	# Note: End turn is now called after the tween completes in try_play_card_with_highest_strength()
	
func try_play_card_with_highest_strength():
	# Get opponent's hand
	var opponent_hand = $"../OpponentHand".opponent_hand
	if opponent_hand.size() == 0:
		end_opponent_turn()
		return
		
	# Get a random empty card slot
	var random_empty_card_slot = empty_card_slots[randi_range(0, empty_card_slots.size()-1)]
	
	# Find card with highest strength
	var card_highest_strength = opponent_hand[0]
	for card in opponent_hand:
		if card.strength >= card_highest_strength.strength:
			card_highest_strength = card
	
	# Remove card from hand BEFORE animating
	$"../OpponentHand".remove_card_from_hand(card_highest_strength)
	
	# Make sure the card is properly in the scene tree after removal from hand
	if card_highest_strength.get_parent() != $"../CardManager":
		$"../CardManager".add_child(card_highest_strength)
	
	# Make the card visible before animating (in case it was hidden)
	card_highest_strength.visible = true
	
	# Store references for continued access
	var slot_to_occupy = random_empty_card_slot
	empty_card_slots.erase(random_empty_card_slot)  # Remove this slot from available slots
	var card_to_place = card_highest_strength
	
	# Create a parent tween that will sequence all our animations
	var sequence = create_tween()
	sequence.set_parallel(false)  # Make sure animations happen in sequence
	
	# First, move the card to position
	sequence.tween_property(card_to_place, "global_position", slot_to_occupy.global_position, CARD_MOVE_SPEED)
	
	# Then scale it down
	sequence.tween_property(card_to_place, "scale", Vector2(CARD_SMALLER_SCALE, CARD_SMALLER_SCALE), CARD_MOVE_SPEED)
	
	# Flip the card to show the front
	card_to_place.get_node("AnimationPlayer").play("card_flip")
	
	# After animations complete, permanently set the card's position and finalize
	sequence.tween_callback(func():
		# Mark this card as "placed" - create a placement property if it doesn't exist
		if !card_to_place.has_meta("placed"):
			card_to_place.set_meta("placed", true)
			card_to_place.set_meta("slot", slot_to_occupy.name)  # Remember which slot it belongs to
		
		# Force the position again to ensure it stays
		card_to_place.global_position = slot_to_occupy.global_position
		
		# Add a script to maintain position if needed
		if !card_to_place.has_node("PositionKeeper"):
			var pos_keeper = Timer.new()
			pos_keeper.name = "PositionKeeper"
			pos_keeper.wait_time = 0.05
			pos_keeper.autostart = true
			card_to_place.add_child(pos_keeper)
			pos_keeper.timeout.connect(func():
				card_to_place.global_position = slot_to_occupy.global_position
			)
		
		# End opponent turn after everything is set
		end_opponent_turn()
	)
	
func end_opponent_turn():
	# Reset player deck draw
	$"../Deck".reset_draw()
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true
