extends "../Core/GlimmerCard.gd"

var location_effect_active: bool = true

func _init() -> void:
	card_type = "Location"

func initialize_from_data(data: Dictionary) -> void:
	super.initialize_from_data(data)
	
	# Location-specific initializations
	# Parse abilities for location effects

func play_card() -> bool:
	if can_play():
		is_inked = true
		location_effect_active = true
		execute_effect()
		emit_signal("card_played", self)
		return true
	return false

func can_play() -> bool:
	# Check if enough ink available
	return true

func execute_effect() -> void:
	# Override this in specific location cards
	pass

func move_to_discard() -> void:
	# Logic to move card to discard pile
	# This would connect to player controller
	pass

func toggle_effect() -> void:
	location_effect_active = !location_effect_active
	
	# Visual indication of active/inactive state
	if location_effect_active:
		# Activate visuals
		pass
	else:
		# Deactivate visuals
		pass
