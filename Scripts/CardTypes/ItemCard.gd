extends "../Core/GlimmerCard.gd"

var equipped_to = null  # Reference to character this item is equipped to
var is_equipped: bool = false
var bonus_strength: int = 0
var bonus_willpower: int = 0

func _init() -> void:
	card_type = "Item"

func initialize_from_data(data: Dictionary) -> void:
	super.initialize_from_data(data)
	
	# Parse abilities to determine bonuses
	# This is a simple example - in practice, you'd need more sophisticated parsing
	for ability in abilities:
		if ability.get("type", "") == "static":
			var effect_text = ability.get("effect", "").to_lower()
			
			# Look for +X strength/willpower patterns
			if "gets +1 strength" in effect_text:
				bonus_strength = 1
			elif "gets +2 strength" in effect_text:
				bonus_strength = 2
			
			if "gets +1 willpower" in effect_text:
				bonus_willpower = 1
			elif "gets +2 willpower" in effect_text:
				bonus_willpower = 2

func play_card() -> bool:
	if can_play():
		is_inked = true
		emit_signal("card_played", self)
		return true
	return false

func can_play() -> bool:
	# Check if enough ink available
	return true

func can_equip(character) -> bool:
	return is_inked and not is_exerted and character.is_inked

func equip_to(character) -> bool:
	if can_equip(character):
		equipped_to = character
		is_equipped = true
		
		# Apply bonuses
		character.strength += bonus_strength
		character.willpower += bonus_willpower
		character.current_willpower = min(character.willpower, character.current_willpower + bonus_willpower)
		
		# Apply special effects based on character
		apply_special_effects(character)
		
		return true
	return false

func unequip() -> void:
	if is_equipped and equipped_to:
		# Remove bonuses
		equipped_to.strength -= bonus_strength
		equipped_to.willpower -= bonus_willpower
		equipped_to.current_willpower = min(equipped_to.current_willpower, equipped_to.willpower)
		
		# Remove special effects
		remove_special_effects(equipped_to)
		
		is_equipped = false
		equipped_to = null

func apply_special_effects(_character) -> void:
	# Override in specific items to apply special effects
	pass

func remove_special_effects(_character) -> void:
	# Override in specific items to remove special effects
	pass

func on_defeat() -> void:
	unequip()
	defeated = true
