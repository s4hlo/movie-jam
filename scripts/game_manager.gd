extends Node2D

const ROOM_SCENE := preload("res://scenes/room.tscn")
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ROOM_SIZE := Vector2(640, 360)

var current_room: Node2D = null
var player: CharacterBody2D = null

func _ready() -> void:
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	_load_room()
	player.position = ROOM_SIZE / 2.0

func _load_room() -> void:
	current_room = ROOM_SCENE.instantiate()
	add_child(current_room)
	move_child(current_room, 0)
