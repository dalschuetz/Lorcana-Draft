# Scripts/CardTypes/ActionCard.gd
extends "../Core/CardBase.gd"

var targets_required: bool = false
var target_type: String = ""  # e.g., "Character", "Princess", "Villain"

func _init() -> void:
	card_type = "Action"

func initialize_from_data(data: Dictionary) -> void:
	super.initialize_from_data(data)
	
	# Analyze abilities to determine targeting requirements
	for ability in abilities:
		if "effect" in ability:
			var effect = ability["effect"].to_lower()
			
			# Check for targeting patterns
			if "chosen" in effect or "target" in effect:
				targets_required = true
				
				# Try to determine target type
				if "character" in effect:
					target_type = "Character"
				elif "princess" in effect:
					target_type = "Princess"
				elif "villain" in effect:
					target_type = "Villain"

func play_card() -> bool:
	if can_play():
		if targets_required:
			var targets = select_targets()
			if targets.size() > 0:
				execute_effect(targets)
				emit_signal("card_played", self)
				move_to_discard()
				return true
			return false
		else:
			execute_effect([])
			emit_signal("card_played", self)
			move_to_discard()
			return true
	return false

func can_play() -> bool:
	# Check if enough ink available
	return true

func execute_effect(_targets: Array) -> void:
	# Override this in specific action cards
	pass

func select_targets() -> Array:
	# In a real implementation, this would show UI for target selection
	# For now, return empty array
	return []

func move_to_discard() -> void:
	# Logic to move card to discard pile
	# This would connect to player controller
	pass
