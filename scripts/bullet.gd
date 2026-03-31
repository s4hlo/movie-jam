extends Area2D

const SPEED: int = 1300
var damage: int = 10

# Referência ao nó de som
@onready var som_disparo: AudioStreamPlayer2D = $SomDisparo

func _ready() -> void:
	som_disparo.play()

func _process(delta: float) -> void:
	position += transform.x * SPEED * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	self.visible = false
	$CollisionShape2D.queue_free()
	await som_disparo.finished
	queue_free()
