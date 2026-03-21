extends Node2D

const ROOM_SIZE := Vector2(1280, 720)
const WALL_THICKNESS := 20.0
const DOOR_SIZE := 120.0
const SEALED_COLOR := Color(0.5, 0.2, 0.2, 1.0)

# Set by RoomManager before add_child
var door_config: Dictionary = {}  # "north" → "open"/"sealed"
var entity_states: Dictionary = {}  # node_name → state string
var _changed_entities: Dictionary = {}

signal door_entered(direction: String)

func _ready() -> void:
	_build_doors()
	_apply_entity_states()
	_connect_entity_signals()

func _get_door_geometry(direction: String) -> Dictionary:
	match direction:
		"north": return {"pos": Vector2(ROOM_SIZE.x / 2, WALL_THICKNESS / 2), "size": Vector2(DOOR_SIZE, WALL_THICKNESS)}
		"south": return {"pos": Vector2(ROOM_SIZE.x / 2, ROOM_SIZE.y - WALL_THICKNESS / 2), "size": Vector2(DOOR_SIZE, WALL_THICKNESS)}
		"east": return {"pos": Vector2(ROOM_SIZE.x - WALL_THICKNESS / 2, ROOM_SIZE.y / 2), "size": Vector2(WALL_THICKNESS, DOOR_SIZE)}
		_: return {"pos": Vector2(WALL_THICKNESS / 2, ROOM_SIZE.y / 2), "size": Vector2(WALL_THICKNESS, DOOR_SIZE)}

func _has_gap(direction: String) -> bool:
	var suffix := "Left" if direction in ["north", "south"] else "Top"
	return has_node("Wall" + direction.capitalize() + suffix)

func get_native_exits() -> Array[String]:
	var exits: Array[String] = []
	for direction in ["north", "south", "east", "west"]:
		if _has_gap(direction):
			exits.append(direction)
	return exits

func _build_doors() -> void:
	for direction in ["north", "south", "east", "west"]:
		if not _has_gap(direction):
			continue
		var state: String = door_config.get(direction, "sealed")
		var geo := _get_door_geometry(direction)
		if state == "open":
			_add_door_area(geo.pos, geo.size, direction)
		else:
			_add_sealed_wall(geo.pos, geo.size)

func _add_sealed_wall(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	add_child(body)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	body.add_child(col)
	var visual := ColorRect.new()
	visual.position = -size / 2.0
	visual.size = size
	visual.color = SEALED_COLOR
	body.add_child(visual)

func _add_door_area(pos: Vector2, size: Vector2, direction: String) -> void:
	var area := Area2D.new()
	area.position = pos
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	area.add_child(col)
	area.body_entered.connect(_on_door_body_entered.bind(direction))
	add_child(area)

func _on_door_body_entered(body: Node2D, direction: String) -> void:
	if body is CharacterBody2D:
		door_entered.emit(direction)

func _apply_entity_states() -> void:
	for entity_name in entity_states:
		var state: String = entity_states[entity_name]
		if state in ["collected", "destroyed", "removed"]:
			var node = find_child(entity_name, true, false)
			if node:
				node.queue_free()

func _connect_entity_signals() -> void:
	for node in find_children("*"):
		if node.has_signal("state_changed") and str(node.name) not in entity_states:
			node.state_changed.connect(_on_entity_state_changed.bind(str(node.name)))

func _on_entity_state_changed(new_state: String, entity_name: String) -> void:
	_changed_entities[entity_name] = new_state

func get_changed_entities() -> Dictionary:
	return _changed_entities
