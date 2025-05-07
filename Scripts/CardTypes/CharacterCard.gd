extends "../Core/GlimmerCard.gd"

var strength: int = 0
var willpower: int = 0
var current_willpower: int = 0
var is_challenge_ready: bool = false
var has_bodyguard: bool = false
var has_evasive: bool = false
var has_shift: bool = false
var shift_cost: int = 0
var shift_target: String = ""
var singer_value: int = 0

func _init() -> void:
	card_type = "Character"

func _ready() -> void:
	super._ready()

func initialize_from_data(data: Dictionary) -> void:
	super.initialize_from_data(data)
	
	# Character-specific properties
	if "strength" in data: 
		strength = data["strength"]
	
	if "willpower" in data:
		willpower = data["willpower"]
		current_willpower = willpower
	
	# Process keyword abilities
	for ability in abilities:
		if ability.get("type", "") == "keyword":
			var keyword = ability.get("keyword", "")
			
			match keyword:
				"Shift":
					has_shift = true
					if "keyword_value" in ability:
						shift_cost = int(ability["keyword_value"])
						
				"Bodyguard":
					has_bodyguard = true
					
				"Evasive":
					has_evasive = true
					
				"Singer":
					if "keyword_value" in ability:
						singer_value = int(ability["keyword_value"])

func play_card() -> bool:
	if can_play():
		is_inked = true
		is_challenge_ready = false  # Characters can't challenge on the turn they're played
		
		# Handle Bodyguard (may enter play exerted)
		if has_bodyguard:
			# Ask player if they want to enter exerted
			# This would connect to UI system
			# For now, simulate with random choice
			if randf() > 0.5:  # 50% chance to enter exerted
				is_exerted = true
				rotation_degrees = 90
		
		play_triggered_abilities()
		emit_signal("card_played", self)
		return true
	return false

func can_play() -> bool:
	# Check if enough ink available and if can be played
	# This would connect to player controller
	
	# Check for shift play
	if has_shift:
		# Check if can shift onto another card
		# This would need to check if a valid target exists
		pass
		
	return true

func exert() -> void:
	if is_inked and not is_exerted:
		is_exerted = true
		# Visual rotation or indication
		rotation_degrees = 90

func ready_card() -> void:
	if is_inked and is_exerted:
		is_exerted = false
		# Reset visual rotation
		rotation_degrees = 0

func take_damage(amount: int) -> void:
	current_willpower = max(0, current_willpower - amount)
	if current_willpower <= 0:
		on_defeat()

func heal(amount: int) -> void:
	current_willpower = min(willpower, current_willpower + amount)

func on_defeat() -> void:
	defeated = true
	# Move to discard pile logic

func can_challenge() -> bool:
	return is_inked and not is_exerted and is_challenge_ready

func can_be_challenged_by(character) -> bool:
	# Check for Evasive
	if has_evasive:
		return character.has_evasive
	return true

func challenge(target_character) -> Dictionary:
	if not can_challenge():
		return {"success": false, "reason": "Character not ready to challenge"}
	
	# Check if target has Bodyguard protection
	# In a real implementation, this would be handled by BattleManager
	
	# Check if target has Evasive
	if not target_character.can_be_challenged_by(self):
		return {"success": false, "reason": "Target has Evasive and this character doesn't"}
	
	exert()
	
	# Calculate damage
	var damage_to_target = strength
	var damage_to_self = target_character.strength
	
	# Apply damage
	target_character.take_damage(damage_to_target)
	take_damage(damage_to_self)
	
	return {
		"success": true,
		"damage_dealt": damage_to_target,
		"damage_received": damage_to_self,
		"target_defeated": target_character.current_willpower <= 0,
		"self_defeated": current_willpower <= 0
	}

func can_quest() -> bool:
	return is_inked and not is_exerted

func quest() -> int:
	if can_quest():
		exert()
		return lore
	return 0

func can_sing(song_card) -> bool:
	if song_card.card_type == "Song" or "Song" in song_card.card_type:
		if is_inked and not is_exerted:
			# Check if ink cost or Singer ability meets requirements
			var required_cost = song_card.ink_cost
			
			# If has Singer ability
			if singer_value > 0:
				return singer_value >= required_cost
			
			# Otherwise check ink cost
			return ink_cost >= required_cost
	
	return false

func sing(song_card) -> bool:
	if can_sing(song_card):
		exert()
		return true
	return false

func play_triggered_abilities() -> void:
	# Handle triggered abilities like "When you play this character..."
	for ability in abilities:
		if ability.get("type", "") == "triggered":
			var ability_name = ability.get("name", "")
			
			# Each specific character would override this to implement their abilities
			# or use a signal system to handle specific abilities
			emit_signal("ability_activated", self, ability_name)
