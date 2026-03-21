extends Node2D

const PLAYER_SCENE := preload("res://scenes/player.tscn")

var player: CharacterBody2D = null
var room_manager: Node2D = null

func _ready() -> void:
	# Create RoomManager as first child (renders behind player)
	room_manager = preload("res://scripts/room_manager.gd").new()
	room_manager.name = "RoomManager"
	add_child(room_manager)
	move_child(room_manager, 0)

	player = PLAYER_SCENE.instantiate()
	add_child(player)

	room_manager.start_new_run(player)
