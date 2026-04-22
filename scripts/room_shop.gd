extends "res://scripts/room_base.gd"

const SHEET = preload("res://assets/Items.png")
const SHOP_ITEMS := {
	"triple_shot": {"name": "Triple Shot", "price": 8, "rect": Rect2(0, 16, 16, 16)},
	"laser": {"name": "Laser", "price": 10, "rect": Rect2(16, 16, 16, 16)},
	"speed_boost": {"name": "Speed Boost", "price": 6, "rect": Rect2(0, 32, 16, 16)},
	"heal_small": {"name": "Fishies", "price": 5, "rect": Rect2(0, 0, 16, 16)},
	"heal_big": {"name": "Medkit", "price": 15, "rect": Rect2(16, 0, 16, 16)}
}

@onready var pedestal1: Area2D = $ShopPedestal1
@onready var pedestal2: Area2D = $ShopPedestal2
@onready var pedestal3: Area2D = $ShopPedestal3

func _ready() -> void:
	super._ready()
	_setup_pedestals()

func _setup_pedestals() -> void:
	var pedestals := [pedestal1, pedestal2, pedestal3]

	var has_stored := false
	for p in pedestals:
		if entity_states.has(str(p.name)):
			has_stored = true
			break

	if has_stored:
		_apply_stored_layout(pedestals)
	else:
		_generate_fresh_layout(pedestals)

func _generate_fresh_layout(pedestals: Array) -> void:
	var player = get_tree().get_first_node_in_group("player")
	var available_keys: Array = []
	for key in SHOP_ITEMS:
		if not player or not player.active_items.has(key):
			available_keys.append(key)
	available_keys.shuffle()

	for i in range(pedestals.size()):
		var ped_name: String = str(pedestals[i].name)
		if i < available_keys.size():
			var key: String = available_keys[i]
			_configure_pedestal(pedestals[i], key)
			_changed_entities[ped_name] = "item:" + key
		else:
			_hide_pedestal(pedestals[i])
			_changed_entities[ped_name] = "empty"

func _apply_stored_layout(pedestals: Array) -> void:
	for i in range(pedestals.size()):
		var pedestal: Area2D = pedestals[i]
		var state: String = entity_states.get(str(pedestal.name), "")
		if state.begins_with("item:"):
			# Pedestal still active: configure with stored item
			if is_instance_valid(pedestal) and not pedestal.is_queued_for_deletion():
				_configure_pedestal(pedestal, state.substr(5))
		else:
			# "removed" (purchased, already queue_freed by base) or "empty"
			if is_instance_valid(pedestal) and not pedestal.is_queued_for_deletion():
				_hide_pedestal(pedestal)

func _configure_pedestal(pedestal: Area2D, key: String) -> void:
	var item_data: Dictionary = SHOP_ITEMS[key]
	var atlas_tex = AtlasTexture.new()
	atlas_tex.atlas = SHEET
	atlas_tex.region = item_data["rect"]
	pedestal.setup(key, item_data["price"], item_data["name"], atlas_tex)
	# Base's _connect_entity_signals skips nodes that already have an entry in
	# entity_states, so on revisit we wire the signal ourselves.
	if not pedestal.state_changed.is_connected(_on_entity_state_changed):
		pedestal.state_changed.connect(_on_entity_state_changed.bind(str(pedestal.name)))

func _hide_pedestal(pedestal: Area2D) -> void:
	pedestal.visible = false
	pedestal.set_process(false)
	pedestal.get_node("CollisionShape2D").set_deferred("disabled", true)
