extends Node2D

signal hovered
signal hovered_off
signal card_played(card)
signal ability_activated(card, ability_name)

# Common properties for all cards
var card_id: String = ""
var original_id: int = 0
var card_name: String = ""
var card_version: String = ""
var card_full_name: String = ""
var card_simple_name: String = ""
var card_type: String = ""
var card_subtypes: Array = []
var card_subtypes_text: String = ""
var card_classification: String = ""
var ink_cost: int = 0
var ink_color: String = ""
var rarity: String = ""
var lore: int = 0
var set_code: String = ""
var set_number: int = 0
var code: String = ""
var flavor_text: String = ""
var story: String = ""
var artists: Array = []
var artists_text: String = ""
var abilities: Array = []
var keyword_abilities: Array = []
var abilities_text: String = ""
var abilities_sections: Array = []
var foil_types: Array = []
var external_links: Dictionary = {}

# Game state
var hand_position: Vector2
var card_slot_card_is_in: Node2D
var is_exerted: bool = false  # Whether the card is exerted (tapped)
var is_inked: bool = false    # Whether the card is in play
var is_inkable: bool = true   # Whether the card can be inked
var defeated: bool = false

# Visual elements
var images = {
	"full": "",
	"thumbnail": "",
	"foil_mask": ""
}
var local_art_path: String = ""

func _ready() -> void:
	# Register with card manager
	if get_parent().has_method("connect_card_signals"):
		get_parent().connect_card_signals(self)
	
	# Load card image if available
	if local_art_path != "" and ResourceLoader.exists(local_art_path):
		get_node("CardImage").texture = load(local_art_path)

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)

# Initialize card from database entry
func initialize_from_data(data: Dictionary) -> void:
	if data.is_empty():
		return
		
	# Set basic properties
	if "id" in data: card_id = data["id"]
	if "original_id" in data: original_id = data["original_id"]
	if "name" in data: card_name = data["name"]
	if "version" in data: card_version = data["version"]
	if "full_name" in data: card_full_name = data["full_name"]
	if "simple_name" in data: card_simple_name = data["simple_name"]
	if "type" in data: card_type = data["type"]
	if "subtypes" in data: card_subtypes = data["subtypes"]
	if "subtypes_text" in data: card_subtypes_text = data["subtypes_text"]
	if "classification" in data: card_classification = data["classification"]
	if "ink_cost" in data: ink_cost = data["ink_cost"]
	if "ink_color" in data: ink_color = data["ink_color"]
	if "rarity" in data: rarity = data["rarity"]
	if "lore" in data: lore = data["lore"]
	if "set_code" in data: set_code = data["set_code"]
	if "set_number" in data: set_number = data["set_number"]
	if "code" in data: code = data["code"]
	if "flavor_text" in data: flavor_text = data["flavor_text"]
	if "story" in data: story = data["story"]
	if "artists" in data: artists = data["artists"]
	if "artists_text" in data: artists_text = data["artists_text"]
	if "abilities" in data: abilities = data["abilities"]
	if "keyword_abilities" in data: keyword_abilities = data["keyword_abilities"]
	if "abilities_text" in data: abilities_text = data["abilities_text"]
	if "abilities_sections" in data: abilities_sections = data["abilities_sections"]
	if "foil_types" in data: foil_types = data["foil_types"]
	if "external_links" in data: external_links = data["external_links"]
	if "inkable" in data: is_inkable = data["inkable"]
	
	# Store image info
	if "images" in data: images = data["images"]
	if "art" in data: local_art_path = data["art"]
	
	# Set card image
	if local_art_path != "" and ResourceLoader.exists(local_art_path):
		get_node("CardImage").texture = load(local_art_path)
	
	# Initialize additional properties based on card type
	# (This would be done in subclasses)
