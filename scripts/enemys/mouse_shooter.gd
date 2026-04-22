extends "res://scripts/enemys/rat.gd"

const ENEMY_BULLET = preload("res://scenes/gunshot/enemy_bullet.tscn")
const SHOOT_RANGE := 350.0
const SHOOT_COOLDOWN := 1.2
const MOUSE_DEATH_FRAME := 12

var _shoot_cooldown_time := 0.0

@onready var gun: Node2D = $EnemyGun
@onready var muzzle: Marker2D = $EnemyGun/Marker2D
var mousedelay:bool = false

func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			anim.play("idle")
			gun.visible = false
		State.CHASING:
			if mousedelay == true:
				if target:
					var dir = global_position.direction_to(target.global_position)
					var dist = global_position.distance_to(target.global_position)
					sprite.flip_h = dir.x > 0
					_aim_gun_at(target.global_position)
					if dist <= SHOOT_RANGE:
						velocity = Vector2.ZERO
						anim.play("idle")
						_shoot_cooldown_time -= delta
						if _shoot_cooldown_time <= 0.0:
							_shoot()
							_shoot_cooldown_time = SHOOT_COOLDOWN
					else:
						velocity = dir * SPEED
						anim.play("walk")
				else:
					velocity = Vector2.ZERO
					anim.play("idle")
					gun.visible = false
		State.DEAD:
			velocity = Vector2.ZERO
			gun.visible = false

	velocity += knockback
	knockback *= KNOCKBACK_FRICTION
	if knockback.length() < 5.0:
		knockback = Vector2.ZERO

	move_and_slide()

func _aim_gun_at(target_pos: Vector2) -> void:
	gun.visible = true
	gun.look_at(target_pos)
	var deg = wrapf(rad_to_deg(gun.rotation), 0.0, 360.0)
	if deg > 90.0 and deg < 270.0:
		gun.scale.y = -1
	else:
		gun.scale.y = 1

func _shoot() -> void:
	var b = ENEMY_BULLET.instantiate()
	get_tree().root.add_child(b)
	b.global_position = muzzle.global_position
	b.rotation = gun.rotation

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
	
	if randi_range(1, 2) == 1 :
		var coin = COIN.instantiate()
		coin.global_position = global_position
		get_parent().add_child(coin)


func _on_timer_timeout() -> void:
	mousedelay = true
