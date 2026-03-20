extends Node2D

const ROOM_SIZE := Vector2(1280, 720)
const WALL_THICKNESS := 20.0
const WALL_COLOR := Color(0.35, 0.35, 0.4, 1.0)

func _ready() -> void:
	_build_walls()

func _build_walls() -> void:
	var hw := ROOM_SIZE.x / 2.0
	var hh := ROOM_SIZE.y / 2.0
	_add_wall(Vector2(hw, WALL_THICKNESS / 2.0), Vector2(ROOM_SIZE.x, WALL_THICKNESS))
	_add_wall(Vector2(hw, ROOM_SIZE.y - WALL_THICKNESS / 2.0), Vector2(ROOM_SIZE.x, WALL_THICKNESS))
	_add_wall(Vector2(WALL_THICKNESS / 2.0, hh), Vector2(WALL_THICKNESS, ROOM_SIZE.y))
	_add_wall(Vector2(ROOM_SIZE.x - WALL_THICKNESS / 2.0, hh), Vector2(WALL_THICKNESS, ROOM_SIZE.y))

func _add_wall(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	add_child(body)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)

	var sprite := ColorRect.new()
	sprite.position = -size / 2.0
	sprite.size = size
	sprite.color = WALL_COLOR
	body.add_child(sprite)
