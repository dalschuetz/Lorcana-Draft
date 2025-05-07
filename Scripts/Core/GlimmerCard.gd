extends "res://Scripts/Core/CardBase.gd"

# Remove signal ability_activated as it's already in CardBase
# Remove is_inkable as it's already in CardBase

func _init() -> void:
	pass

func play_card() -> bool:
	if can_play():
		is_inked = true
		emit_signal("card_played", self)
		return true
	return false

func can_play() -> bool:
	# Check if enough ink available and if can be played
	# This would connect to player controller
	return true

func exert() -> void:
	if is_inked and not is_exerted:
		is_exerted = true
		# Visual rotation or indication of exerted state
		rotation_degrees = 90

func ready_card() -> void:
	if is_inked and is_exerted:
		is_exerted = false
		# Reset visual rotation
		rotation_degrees = 0

func on_defeat() -> void:
	# Called when card is defeated or removed
	defeated = true
