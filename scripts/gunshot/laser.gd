extends Area2D

const LIFETIME := 0.12
var damage: int = 15

@onready var som_disparo: AudioStreamPlayer2D = $SomDisparo

func _ready() -> void:
	som_disparo.volume_db = randf_range(-5.0, -8.0)
	som_disparo.play()
	await get_tree().create_timer(LIFETIME).timeout
	queue_free()
