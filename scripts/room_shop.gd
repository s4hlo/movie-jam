extends "res://scripts/room_base.gd"

const SHEET = preload("res://assets/Items.png")
const SHOP_ITEMS := {
	"triple_shot": {"name": "Triple Shot", "price": 8, "rect": Rect2(0, 16, 16, 16)},
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
			
			# Criamos o "recorte" da sprite sheet
			var atlas_tex = AtlasTexture.new()
			atlas_tex.atlas = SHEET
			atlas_tex.region = item_data["rect"]
			
			pedestals[i].setup(key, item_data["price"], item_data["name"], atlas_tex)
		else:
			pedestals[i].visible = false
			pedestals[i].set_process(false)
			pedestals[i].get_node("CollisionShape2D").set_deferred("disabled", true)
