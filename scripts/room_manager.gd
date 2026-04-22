extends Node2D

const RoomBase = preload("res://scripts/room_base.gd")

const ROOM_SCENES := {
	"empty": preload("res://scenes/rooms/room_empty.tscn"),
	"empty2": preload("res://scenes/rooms/room_empty2.tscn"),
	"1coin": preload("res://scenes/rooms/room_1coin.tscn"),
	"2coins": preload("res://scenes/rooms/room_2coins.tscn"),
	"3coins": preload("res://scenes/rooms/room_3coins.tscn"),
	"4coins": preload("res://scenes/rooms/room_4coins.tscn"),
	"hall2": preload("res://scenes/rooms/room_hall2.tscn"),
	"hall3": preload("res://scenes/rooms/room_hall3.tscn"),
	"shop": preload("res://scenes/rooms/room_shop.tscn"),
	"boss": preload("res://scenes/rooms/room_boss.tscn"),
}

const ROOMS_BEFORE_BOSS := 8

var _exits_cache: Dictionary = {}  # type_name -> Array[String]

const DIRECTION_OFFSETS := {
	"north": Vector2i(0, -1),
	"south": Vector2i(0, 1),
	"east": Vector2i(1, 0),
	"west": Vector2i(-1, 0),
}

const OPPOSITE := {
	"north": "south",
	"south": "north",
	"east": "west",
	"west": "east",
}

# Spawn positions: past the door, far enough to not re-trigger the Area2D
const SPAWN_POSITIONS := {
	"north": Vector2(640, 60),
	"south": Vector2(640, 660),
	"east": Vector2(1220, 360),
	"west": Vector2(60, 360),
}

# There's no type def in this language XD
var grid: Dictionary = {}  # Vector2i -> { "type": String, "entity_states": Dictionary }
var current_position: Vector2i = Vector2i.ZERO
var current_room: Node2D = null
var player: CharacterBody2D = null
var _transitioning: bool = false
var _rooms_since_shop: int = 0
var _boss_placed: bool = false

func _ready() -> void:
	for type_name in ROOM_SCENES:
		var instance = ROOM_SCENES[type_name].instantiate()
		_exits_cache[type_name] = instance.get_native_exits()
		instance.free()

func start_new_run(p_player: CharacterBody2D) -> void:
	player = p_player
	SaveManager.reset_run()
	grid.clear()
	_rooms_since_shop = 0
	_boss_placed = false
	current_position = Vector2i.ZERO
	grid[current_position] = {"type": "empty", "entity_states": {}}
	_load_room(current_position)

func _load_room(pos: Vector2i, spawn_at_door: String = "") -> void:
	if current_room:
		_save_room_state()
		current_room.door_entered.disconnect(_on_door_entered)
		current_room.queue_free()
		current_room = null

	var room_data: Dictionary = grid[pos]
	var type_name: String = room_data["type"]

	current_room = ROOM_SCENES[type_name].instantiate()

	# Configure doors based on current grid state
	var door_config := {}
	for direction in _exits_cache[type_name]:
		if type_name == "boss":
			door_config[direction] = "sealed"
		else:
			door_config[direction] = _get_door_state(pos, direction)
	current_room.door_config = door_config
	current_room.entity_states = room_data["entity_states"]

	add_child(current_room)
	move_child(current_room, 0)

	if spawn_at_door != "":
		player.position = SPAWN_POSITIONS[spawn_at_door]
	else:
		player.position = RoomBase.ROOM_SIZE / 2.0

	current_position = pos

	# Without this the player move 1+ stages
	# Wait 2 physics frames for the player position to settle
	# before allowing door transitions
	await get_tree().physics_frame
	await get_tree().physics_frame

	if current_room:
		current_room.door_entered.connect(_on_door_entered)
	_transitioning = false

func _get_door_state(pos: Vector2i, direction: String) -> String:
	var neighbor_pos: Vector2i = pos + DIRECTION_OFFSETS[direction]
	if not grid.has(neighbor_pos):
		return "open"

	var neighbor_type: String = grid[neighbor_pos]["type"]
	var neighbor_exits: Array = _exits_cache[neighbor_type]
	if not OPPOSITE[direction] in neighbor_exits:
		return "sealed"
	if neighbor_type == "boss":
		return "boss"
	return "open"

func _generate_room(pos: Vector2i, from_direction: String) -> void:
	var entry_direction: String = OPPOSITE[from_direction]
	var compatible: Array[String] = []

	for type_name in ROOM_SCENES:
		if type_name == "shop" or type_name == "boss":
			continue
		var exits: Array = _exits_cache[type_name]
		if entry_direction in exits:
			compatible.append(type_name)

	# Shop has all 4 exits so it's always compatible
	# Force shop after 4+ rooms without one, otherwise 20% chance
	if _rooms_since_shop >= 4:
		grid[pos] = {"type": "shop", "entity_states": {}}
		_rooms_since_shop = 0
		_try_place_boss_near(pos)
		return
	elif randf() < 0.2:
		compatible.append("shop")

	assert(compatible.size() > 0, "No compatible room for direction: " + entry_direction)
	var chosen: String = compatible[randi() % compatible.size()]
	grid[pos] = {"type": chosen, "entity_states": {}}

	if chosen == "shop":
		_rooms_since_shop = 0
	else:
		_rooms_since_shop += 1

	_try_place_boss_near(pos)

func _try_place_boss_near(center_pos: Vector2i) -> void:
	if _boss_placed:
		return
	if grid.size() < ROOMS_BEFORE_BOSS:
		return
	var host_type: String = grid[center_pos]["type"]
	for direction in _exits_cache[host_type]:
		var neighbor: Vector2i = center_pos + DIRECTION_OFFSETS[direction]
		if not grid.has(neighbor):
			grid[neighbor] = {"type": "boss", "entity_states": {}}
			_boss_placed = true
			return

func _on_door_entered(direction: String) -> void:
	if _transitioning:
		return
		
	get_tree().call_group("bullets", "queue_free")
	get_tree().call_group("enemy_bullets", "queue_free")
	_transitioning = true

	var target_pos: Vector2i = current_position + DIRECTION_OFFSETS[direction]

	if not grid.has(target_pos):
		_generate_room(target_pos, direction)

	var entry_direction: String = OPPOSITE[direction]
	call_deferred("_load_room", target_pos, entry_direction)
	

func _save_room_state() -> void:
	if current_room and grid.has(current_position):
		var changed: Dictionary = current_room.get_changed_entities()
		for entity_name in changed:
			grid[current_position]["entity_states"][entity_name] = changed[entity_name]
