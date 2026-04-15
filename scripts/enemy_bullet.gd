extends Area2D

const SPEED: int = 700
var damage: int = 1

func _process(delta: float) -> void:
	position += transform.x * SPEED * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var knock_dir = transform.x.normalized()
		body.take_damage(damage, knock_dir)
		queue_free()
	elif body is StaticBody2D:
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
