extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_BATTLEFIELD = 2  # Changed from CARD_SLOT to BATTLEFIELD
const COLLISION_MASK_INKWELL = 7
const DEFAULT_CARD_MOVE_SPEED = 0.1
const DEFAULT_CARD_SCALE = 0.8
const CARD_BIGGER_SCALE = 0.85
const CARD_SMALLER_SCALE = 0.6

var screen_size
var card_being_dragged
var is_hovering_on_card
var player_hand_reference
var selected_opponent_card
var player_battlefield_reference  # Reference to the new battlefield area

func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand_reference = $"../PlayerHand"
	player_battlefield_reference = $"../PlayerBattlefield"  # Get reference to new battlefield node
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)

func _process(delta:float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x), 
			clamp(mouse_pos.y, 0, screen_size.y))

func card_clicked(card):
	print(str(card) + " was clicked")
	# Make sure to check if the property exists before accessing it
	if card.has_method("is_on_battlefield") and card.on_battlefield:
		print(str(card) + " can be played")
		if $"../BattleManager".is_opponent_turn == false:
			if $"../BattleManager".player_is_attacking == false:
				if card not in $"../BattleManager".player_cards_that_attacked_this_turn:
					if $"../BattleManager".opponent_cards_on_battlefield.size() == 0:
						$"../BattleManager".quest(card, "Player")
						return
					else:
						select_card_for_battle(card)
	#elif card.has_method("is_in_inkwell") and card.in_inkwell:
		#print("Card in inkwell, adding ink")
		#if player = "Opponent":
			#opponent_ink = $"../BattleManager".opponent_ink + card.ink
			#$"../OpponentInk".text = str(opponent_ink)
		#else:
			#player_ink = $"../BattleManager".player_ink + card.ink
			#$"../PlayerInk".text = str(player_lore)
	else:
		print(str(card) + " can't play, only drag")
		start_drag(card)

func select_card_for_battle(card):
	if selected_opponent_card:
		if selected_opponent_card == card:
			card.position.y += 20
			selected_opponent_card = null
		else:
			selected_opponent_card.position.y += 20
			selected_opponent_card = card
			card.position.y -= 20
	else:
		selected_opponent_card = card
		card.position.y -= 20

func start_drag(card):
	card_being_dragged = card
	card.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)

func finish_drag():
	card_being_dragged.scale = Vector2(1.05, 1.05)
	
	if raycast_check_for_inkwell():
		# Card dropped on Inkwell
		print("Dropped on inkwell")
		if card_being_dragged.has_method("set_on_battlefield"):
			card_being_dragged.set_in_inkwell(true)
		#flip_card(card_being_dragged)  # Trigger flip animation
		player_hand_reference.remove_card_from_hand(card_being_dragged)
		card_being_dragged.queue_free()  # Or hide/remove as needed
	elif raycast_check_for_battlefield():
		# Card dropped on battlefield
		card_being_dragged.scale = Vector2(CARD_SMALLER_SCALE, CARD_SMALLER_SCALE)
		card_being_dragged.z_index = -1
		player_hand_reference.remove_card_from_hand(card_being_dragged)
		
		if card_being_dragged.has_method("set_on_battlefield"):
			card_being_dragged.set_on_battlefield(true)
		player_battlefield_reference.add_card_to_battlefield(card_being_dragged)
		$"../BattleManager".player_cards_on_battlefield.append(card_being_dragged)
	else:
		player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)

	card_being_dragged = null


func unselect_selected_card():
	if selected_opponent_card:
		selected_opponent_card.position.y += 20
		selected_opponent_card = null

func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)

func on_left_click_released():
	if card_being_dragged:
		finish_drag()

func on_hovered_over_card(card):
	# Make sure to check if the property exists before accessing it
	if card.has_method("is_on_battlefield") and card.is_on_battlefield():
		return
	if !is_hovering_on_card:
		is_hovering_on_card = true
		highlight_card(card, true)

func on_hovered_off_card(card):
	if card.has_method("is_defeated") and !card.is_defeated():
		# Check if card is NOT on battlefield AND NOT being dragged
		if (not card.has_method("is_on_battlefield") or not card.is_on_battlefield()) and !card_being_dragged:
			highlight_card(card, false)
			# Check if hovered off card straight on to another card
			var new_card_hovered = raycast_check_for_card()
			if new_card_hovered:
				highlight_card(new_card_hovered, true)
			else:
				is_hovering_on_card = false
	
func highlight_card(card, hovered):
	if hovered:
		card.scale = Vector2(CARD_BIGGER_SCALE, CARD_BIGGER_SCALE)
		card.z_index = 2
	else:
		card.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)
		card.z_index = 1

func raycast_check_for_battlefield():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_BATTLEFIELD
	var result = space_state.intersect_point(parameters)
	return result.size() > 0

func raycast_check_for_inkwell():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_INKWELL
	var result = space_state.intersect_point(parameters)
	return result.size() > 0

func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return get_card_with_highest_z_index(result)
	return null

func get_card_with_highest_z_index(cards):
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	# Loop through rest of cards checking for a higher z index
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card
