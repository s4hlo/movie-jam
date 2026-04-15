extends "res://scripts/room_base.gd"

const SHOP_ITEMS := {
	"triple_shot": {"name": "Triple Shot", "price": 8},
	"speed_boost": {"name": "Speed Boost", "price": 6},
	"heal_small": {"name": "Bandage", "price": 5},
	"heal_big": {"name": "Medkit", "price": 15},
}

@onready var pedestal1: Area2D = $ShopPedestal1
@onready var pedestal2: Area2D = $ShopPedestal2
@onready var pedestal3: Area2D = $ShopPedestal3

func _ready() -> void:
	super._ready()
	_setup_pedestals()

func _setup_pedestals() -> void:
	var player = get_tree().get_first_node_in_group("player")
	var available_keys: Array = []
	for key in SHOP_ITEMS:
		if not player or not player.active_items.has(key):
			available_keys.append(key)
	available_keys.shuffle()

	var pedestals := [pedestal1, pedestal2, pedestal3]
	for i in range(3):
		if i < available_keys.size():
			var key: String = available_keys[i]
			var item_data: Dictionary = SHOP_ITEMS[key]
			pedestals[i].setup(key, item_data["price"], item_data["name"])
		else:
			pedestals[i].visible = false
			pedestals[i].set_process(false)
			pedestals[i].get_node("CollisionShape2D").set_deferred("disabled", true)
