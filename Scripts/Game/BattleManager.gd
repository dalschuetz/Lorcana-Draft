extends Node

const CARD_SMALLER_SCALE = 0.6
const CARD_MOVE_SPEED = 0.2
const BATTLE_POS_OFFSET = 25

var opponent_cards_on_battlefield = []
var player_cards_on_battlefield = []
var player_cards_that_attacked_this_turn = []
var player_lore
var opponent_lore
var is_opponent_turn = false
var player_is_attacking = false

# References to the new battlefield nodes
var player_battlefield
var opponent_battlefield

func _ready() -> void:
	# Get references to the battlefield objects
	player_battlefield = $"../PlayerBattlefield"
	opponent_battlefield = $"../OpponentBattlefield"
	
	player_lore = 0
	$"../PlayerLore".text = str(player_lore)
	opponent_lore = 0
	$"../OpponentLore".text = str(opponent_lore)
	
func _on_end_turn_button_pressed() -> void:
	if player_lore >= 20:
		print("Player Wins")
		get_tree().reload_current_scene()
	else:
		is_opponent_turn = true
		$"../CardManager".unselect_selected_card()
		player_cards_that_attacked_this_turn = []
		opponent_turn()
	
func opponent_turn():
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false
	
	if $"../OpponentDeck".opponent_deck.size() != 0:
		$"../OpponentDeck".draw_card()
	
	# Try playing a card from opponent's hand
	try_play_card_with_highest_strength()
	
	# Try attacking with all opponent cards
	if opponent_cards_on_battlefield.size() != 0:
		var opponent_cards_to_attack = opponent_cards_on_battlefield.duplicate()
		for card in opponent_cards_to_attack:
			if player_cards_on_battlefield.size() != 0:
				var card_to_attack = player_cards_on_battlefield.pick_random()
				attack(card, card_to_attack, "Opponent")
			else:
				quest(card, "Opponent")
	
	# End turn
	end_opponent_turn()

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
	
	var original_position = questing_card.position
	var new_pos = Vector2(questing_card.position.x, new_pos_y)
	questing_card.z_index = 5
	
	# Animate card to center position first
	var tween = create_tween()
	tween.tween_property(questing_card, "position", questing_card.position, CARD_MOVE_SPEED)
	
	if quester == "Opponent":
		opponent_lore = opponent_lore + questing_card.lore
		$"../OpponentLore".text = str(opponent_lore)
	else:
		player_lore = player_lore + questing_card.lore
		$"../PlayerLore".text = str(player_lore)
	
	# Animate card to edge of screen and back
	var tween2 = create_tween()
	tween2.tween_property(questing_card, "position", new_pos, CARD_MOVE_SPEED)
	tween2.tween_property(questing_card, "position", original_position, CARD_MOVE_SPEED)
	
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
	
	var original_position = attacking_card.position
	attacking_card.z_index = 5
	
	# Animate card to opponent card position
	var new_pos = Vector2(defending_card.position.x, defending_card.position.y + BATTLE_POS_OFFSET)
	var tween = create_tween()
	tween.tween_property(attacking_card, "position", new_pos, CARD_MOVE_SPEED)
	
	# Animate card back to original position
	var tween2 = create_tween()
	tween2.tween_property(attacking_card, "position", original_position, CARD_MOVE_SPEED)
	
	# Card Damage Trade
	defending_card.willpower = max(0, defending_card.willpower - attacking_card.strength)
	attacking_card.willpower = max(0, attacking_card.willpower - defending_card.strength)
	
	# Update card displays
	defending_card.update_card_display()
	attacking_card.update_card_display()
	
	# Check if any cards were destroyed
	var card_was_destroyed = false
	
	# Banish if card health is 0
	if attacking_card.willpower == 0:
		banish_card(attacking_card, attacker)
		card_was_destroyed = true
	
	if defending_card.willpower == 0:
		if attacker == "Player":
			banish_card(defending_card, "Opponent")
		else:
			banish_card(defending_card, "Player")
		card_was_destroyed = true
	
	if attacker == "Player":
		$"../EndTurnButton".disabled = false
		$"../EndTurnButton".visible = true
		player_is_attacking = false

func banish_card(card, card_owner):
	var new_pos
	
	# Clear card from battlefield lists
	if card_owner == "Player":
		if card in player_cards_on_battlefield:
			player_cards_on_battlefield.erase(card)
			player_battlefield.remove_card_from_battlefield(card)
	else:
		if card in opponent_cards_on_battlefield:
			opponent_cards_on_battlefield.erase(card)
			opponent_battlefield.remove_card_from_battlefield(card)

	# Mark the card as defeated and disable interactions
	card.defeated = true
	card.get_node("Area2D/CollisionShape2D").disabled = true
	
	# Move to appropriate discard pile
	if card_owner == "Player":
		new_pos = $"../PlayerDiscard".position
	else:
		new_pos = $"../OpponentDiscard2".position

	# Animate the movement to discard pile
	var tween = create_tween()
	tween.tween_property(card, "position", new_pos, CARD_MOVE_SPEED)
	tween.tween_property(card, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(card.queue_free)

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
	
	# Scale the card appropriately
	card_highest_strength.scale = Vector2(CARD_SMALLER_SCALE, CARD_SMALLER_SCALE)
	
	# Add the card to the opponent battlefield
	card_highest_strength.on_battlefield = true
	opponent_battlefield.add_card_to_battlefield(card_highest_strength)
	opponent_cards_on_battlefield.append(card_highest_strength)
	
	# Flip the card to show the front if needed
	if card_highest_strength.has_node("AnimationPlayer"):
		card_highest_strength.get_node("AnimationPlayer").play("card_flip")
	
func end_opponent_turn():
	if opponent_lore >= 20:
		print("Opponent Wins")
		get_tree().reload_current_scene()
	# Reset player deck draw
	$"../Deck".reset_draw()
	is_opponent_turn = false
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true
