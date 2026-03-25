extends CharacterBody2D

enum State { IDLE, CHASING, DEAD }

const SPEED := 150.0
const KNOCKBACK_FORCE := 500.0
const KNOCKBACK_FRICTION := 0.85

var health: int = 20
var damage: int = 5
var knockback := Vector2.ZERO

var current_state: State = State.IDLE
var target: Node2D = null

@onready var detection_area: Area2D = $DetectionArea
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	detection_area.body_entered.connect(_on_detection_area_body_entered)

func _physics_process(_delta: float) -> void:
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			anim.play("idle")
		State.CHASING:
			if target:
				var dir = global_position.direction_to(target.global_position)
				velocity = dir * SPEED
				sprite.flip_h = dir.x > 0
			anim.play("walk")
		State.DEAD:
			velocity = Vector2.ZERO

	velocity += knockback
	knockback *= KNOCKBACK_FRICTION
	if knockback.length() < 5.0:
		knockback = Vector2.ZERO

	move_and_slide()

func die() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
	set_physics_process(false)
	anim.stop()
	sprite.frame = 22
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body
		current_state = State.CHASING

func flash_hit() -> void:
	sprite.material.set_shader_parameter("hit", true)
	await get_tree().create_timer(0.1).timeout
	sprite.material.set_shader_parameter("hit", false)

func _on_hurt_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullets"):
		var knock_dir = area.transform.x.normalized()
		knockback = knock_dir * KNOCKBACK_FORCE
		health -= area.damage
		area.queue_free()
		flash_hit()
		if health <= 0:
			die()
	if area.is_in_group("player"):
		area.take_damage(damage)
		print("recebeu dano")
