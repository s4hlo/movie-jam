extends "res://scripts/rat.gd"

const ENEMY_BULLET = preload("res://scenes/enemy_bullet.tscn")
const SHOOT_RANGE := 350.0
const SHOOT_COOLDOWN := 1.2
const MOUSE_DEATH_FRAME := 12
const BULLET_SPAWN_OFFSET := 40.0

var _shoot_cooldown_time := 0.0

func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			anim.play("idle")
		State.CHASING:
			if target:
				var dir = global_position.direction_to(target.global_position)
				var dist = global_position.distance_to(target.global_position)
				sprite.flip_h = dir.x > 0
				if dist <= SHOOT_RANGE:
					velocity = Vector2.ZERO
					anim.play("idle")
					_shoot_cooldown_time -= delta
					if _shoot_cooldown_time <= 0.0:
						_shoot(dir)
						_shoot_cooldown_time = SHOOT_COOLDOWN
				else:
					velocity = dir * SPEED
					anim.play("walk")
		State.DEAD:
			velocity = Vector2.ZERO

	velocity += knockback
	knockback *= KNOCKBACK_FRICTION
	if knockback.length() < 5.0:
		knockback = Vector2.ZERO

	move_and_slide()

func _shoot(dir: Vector2) -> void:
	var b = ENEMY_BULLET.instantiate()
	get_tree().root.add_child(b)
	b.global_position = global_position + dir * BULLET_SPAWN_OFFSET
	b.rotation = dir.angle()

func die() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
	set_physics_process(false)
	hurt_area.queue_free()
	anim.stop()
	sprite.frame = MOUSE_DEATH_FRAME
	state_changed.emit("destroyed")
	SaveManager.add_rat_kill()
	await get_tree().create_timer(0.5).timeout
	queue_free()
