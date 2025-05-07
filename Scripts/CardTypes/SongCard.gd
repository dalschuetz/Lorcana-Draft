extends "../Core/CardBase.gd"

var sing_cost: int = 0

func _init() -> void:
	card_type = "Song"

func initialize_from_data(data: Dictionary) -> void:
	super.initialize_from_data(data)
	
	# Get sing cost from ink cost
	sing_cost = ink_cost

func play_card() -> bool:
	if can_play():
		execute_effect()
		emit_signal("card_played", self)
		move_to_discard()
		return true
	return false

func can_play() -> bool:
	# Check if enough ink available
	return true

func execute_effect() -> void:
	# Override this in specific song cards
	pass

func can_be_sung_by(character) -> bool:
	return character.can_sing(self)

func play_as_song(character) -> bool:
	if character.can_sing(self):
		if character.sing(self):
			execute_effect()
			emit_signal("card_played", self)
			move_to_discard()
			return true
	return false

func move_to_discard() -> void:
	# Logic to move card to discard pile
	# This would connect to player controller
	pass
