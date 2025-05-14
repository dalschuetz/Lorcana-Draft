extends Node2D
signal hovered
signal hovered_off
var hand_position
var card_slot_card_is_in: Node2D
var strength
var willpower
var lore
var defeated = false
var on_battlefield = false  # Added this property
var in_inkwell = false

func _ready() -> void:
	#All cards must be a child of CardManager
	get_parent().connect_card_signals(self)
	
func _process(delta: float) -> void:
	pass

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)
	
func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)

func set_on_battlefield(variable) -> void:
	on_battlefield = variable

func update_card_display() -> void:
	pass

func is_on_battlefield() -> bool:
	return on_battlefield

func set_in_inkwell(variable) -> void:
	in_inkwell = variable

func is_in_inkwell() -> bool:
	return in_inkwell
