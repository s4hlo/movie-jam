extends Node2D

const BULLET = preload("res://scenes/bullet.tscn")
const FIRE_RATE := 0.25
@onready var muzzle: Marker2D = $Marker2D
var _shoot_cooldown := 0.0

func _process(delta: float) -> void:
	look_at(get_global_mouse_position())

	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -1
	else:
		scale.y = 1

	if _shoot_cooldown > 0.0:
		_shoot_cooldown -= delta

	if Input.is_action_pressed("shoot") and _shoot_cooldown <= 0.0:
		_shoot_cooldown = FIRE_RATE
		_spawn_bullet(0.0)
		if get_parent().active_items.has("triple_shot"):
			_spawn_bullet(deg_to_rad(15.0))
			_spawn_bullet(deg_to_rad(-15.0))

func _spawn_bullet(angle_offset: float) -> void:
	var bullet_instance = BULLET.instantiate()
	get_tree().root.add_child(bullet_instance)
	bullet_instance.global_position = muzzle.global_position
	bullet_instance.rotation = rotation + angle_offset
