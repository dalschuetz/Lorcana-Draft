extends "res://Scripts/CardTypes/ActionCard.gd"

var sing_cost: int = 0

func _init() -> void:
	card_type = "Action • Song"

func initialize_from_data(data: Dictionary) -> void:
	super.initialize_from_data(data)
	
	# Get sing cost from ink cost
	sing_cost = ink_cost

func play_card() -> bool:
	# Play as an action (default)
	return super.play_card()

func play_as_song(character) -> bool:
	# Play as a song using a character
	if character.can_sing(self):
		if character.sing(self):
			execute_effect([])
			emit_signal("card_played", self)
			move_to_discard()
			return true
	return false

func determine_play_method() -> String:
	# Let player decide whether to play as action or song
	# This would connect to UI system
	# For now, return "action" by default
	return "action"
