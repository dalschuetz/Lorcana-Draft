extends Node2D

signal hovered
signal hovered_off

var hand_position
var card_slot_card_is_in: Node2D
var strength
var willpower
var lore
var defeated = false

func _ready() -> void:
	#All cards must be a child of CardManager
	get_parent().connect_card_signals(self)
	
func _process(delta: float) -> void:
	pass

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
