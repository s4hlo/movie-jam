extends Area2D

signal state_changed(new_state: String)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		SaveManager.add_coins(1)
		state_changed.emit("collected")
		queue_free()
