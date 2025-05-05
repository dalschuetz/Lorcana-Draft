extends Node
const CARD_SMALLER_SCALE = 0.6
const CARD_MOVE_SPEED = 0.2
const BATTLE_POS_OFFSET = 25
var empty_card_slots = []
var opponent_cards_on_battlefield = []
var player_cards_on_battlefield = []
var player_cards_that_attacked_this_turn = []
var player_lore
var opponent_lore
var is_opponent_turn = false
var player_is_attacking = false

func _ready() -> void:
	empty_card_slots.append($"../CardSlots/OpponentCardSlot6")
	empty_card_slots.append($"../CardSlots/OpponentCardSlot7")
	empty_card_slots.append($"../CardSlots/OpponentCardSlot8")
	empty_card_slots.append($"../CardSlots/OpponentCardSlot9")
	empty_card_slots.append($"../CardSlots/OpponentCardSlot10")
	player_lore = 0
	$"../PlayerLore".text = str(player_lore)
	opponent_lore = 0
	$"../OpponentLore".text = str(opponent_lore)
	
func _on_end_turn_button_pressed() -> void:
	is_opponent_turn = true
	$"../CardManager".unselect_selected_card()
	player_cards_that_attacked_this_turn = []
	opponent_turn()
	
func opponent_turn():
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false
	
	if $"../OpponentDeck".opponent_deck.size() != 0:
		$"../OpponentDeck".draw_card()
	
	# Check if free slot exists, and if not, end turn
	if empty_card_slots.size() != 0:
		try_play_card_with_highest_strength()
	
	#try attack
	if opponent_cards_on_battlefield.size() != 0:
		var oppoment_cards_to_attack = opponent_cards_on_battlefield
		for card in oppoment_cards_to_attack:
			if player_cards_on_battlefield.size() != 0:
				var card_to_attack = player_cards_on_battlefield.pick_random()
				attack(card, card_to_attack, "Opponent")
			else:
				quest(card, "Opponent")
				#add amount of lore to self
	
	#end turn
	end_opponent_turn()
	
	# Note: End turn is now called after the tween completes in try_play_card_with_highest_strength()

func quest(questing_card, quester):
	var new_pos_y
	if quester == "Opponent":
		new_pos_y = 0
	else:
		$"../EndTurnButton".disabled = true
		$"../EndTurnButton".visible = false
		player_is_attacking = true
		new_pos_y = 1080
		player_cards_that_attacked_this_turn.append(questing_card)
	
	var new_pos = Vector2(questing_card.position.x, new_pos_y)
	questing_card.z_index = 5
	
	#Animate card to position
	var tween = get_tree().create_tween()
	tween.tween_property(questing_card, "position", questing_card.card_slot_card_is_in.position, CARD_MOVE_SPEED)

	
	if quester == "Opponent":
		opponent_lore = opponent_lore + questing_card.lore
		$"../OpponentLore".text = str(opponent_lore)
		#add lore to opponent
	else:
		player_lore = player_lore + questing_card.lore
		$"../PlayerLore".text = str(player_lore)
		#add lore to player
	
	var tween2 = get_tree().create_tween()
	tween2.tween_property(questing_card, "position", new_pos, CARD_MOVE_SPEED)
	
	questing_card.z_index = 0
	if quester == "Player":
		player_is_attacking = false
		$"../EndTurnButton".disabled = false
		$"../EndTurnButton".visible = true

func attack(attacking_card, defending_card, attacker):
	if attacker == "Player":
		$"../EndTurnButton".disabled = true
		$"../EndTurnButton".visible = false
		player_is_attacking = true
		$"../CardManager".selected_opponent_card = null
		player_cards_that_attacked_this_turn.append(attacking_card)
	attacking_card.z_index = 5
	var new_pos = Vector2(defending_card.position.x, defending_card.position.y + BATTLE_POS_OFFSET)
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, CARD_MOVE_SPEED)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_is_in.position, CARD_MOVE_SPEED)
	
	#Card Damage Trade
	defending_card.willpower = max(0, defending_card.willpower - attacking_card.strength)
	attacking_card.willpower = max(0, attacking_card.willpower - defending_card.strength)
	#could update the health dynamically here, but would have to overwrite the card, maybe figure that out
	
	var card_was_destoryed = false
	#Banish if card health is 0
	if attacking_card.willpower == 0:
		banish_card(attacking_card, attacker)
		card_was_destoryed = true
	if defending_card.willpower == 0:
		if attacker == "Player":
			banish_card(defending_card, "Opponent")
		else:
			banish_card(defending_card, "Player")
		card_was_destoryed = true
	if attacker == "Player":
		$"../EndTurnButton".disabled = false
		$"../EndTurnButton".visible = true
		player_is_attacking = false

func banish_card(card, card_owner):
	var new_pos
	
	# Clear card from battlefield list
	if card_owner == "Player":
		if card in player_cards_on_battlefield:
			player_cards_on_battlefield.erase(card)
	else:
		if card in opponent_cards_on_battlefield:
			opponent_cards_on_battlefield.erase(card)

	# Mark the card as defeated and disable interactions
	card.defeated = true
	card.get_node("Area2D/CollisionShape2D").disabled = true
	
	# Check if card slot exists and is valid before clearing
	if card.card_slot_card_is_in and card.card_slot_card_is_in.has_method("get_node"):
		# Make sure this is a Node with the expected properties, not a Vector2
		if card.card_slot_card_is_in.get("card_in_slot") != null:
			card.card_slot_card_is_in.card_in_slot = false
		
		# Only try to access nodes if it's an actual Node
		if card.card_slot_card_is_in is Node:
			if card.card_slot_card_is_in.has_node("Area2D/CollisionShape2D"):
				card.card_slot_card_is_in.get_node("Area2D/CollisionShape2D").disabled = false
		
		# Add the slot back to empty slots if it's not already there
		if card.card_slot_card_is_in not in empty_card_slots:
			empty_card_slots.append(card.card_slot_card_is_in)
		
		card.card_slot_card_is_in = null
	
	# Move to appropriate discard pile
	if card_owner == "Player":
		new_pos = $"../PlayerDiscard".position
	else:
		new_pos = $"../OpponentDiscard2".position

	# Animate the movement to discard pile
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_pos, CARD_MOVE_SPEED)
	#remove card from arrays

func enemy_card_selected(defending_card):
	var attacking_card = $"../CardManager".selected_opponent_card
	if attacking_card:
		if defending_card in opponent_cards_on_battlefield:
			if player_is_attacking == false:
				$"../CardManager".selected_opponent_card = null
				attack(attacking_card, defending_card, "Player")

func try_play_card_with_highest_strength():
	# Get opponent's hand
	var opponent_hand = $"../OpponentHand".opponent_hand
	if opponent_hand.size() == 0:
		end_opponent_turn()
		return
		
	# Get a random empty card slot
	var random_empty_card_slot = empty_card_slots.pick_random()
	
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
		
		card_highest_strength.card_slot_card_is_in = random_empty_card_slot
		opponent_cards_on_battlefield.append(card_highest_strength)
		
		# End opponent turn after everything is set
		end_opponent_turn()
	)
	
func end_opponent_turn():
	# Reset player deck draw
	$"../Deck".reset_draw()
	is_opponent_turn = false
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true
