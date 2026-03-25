extends CharacterBody2D

enum State { IDLE, CHASING, DEAD }

const SPEED := 150.0
const KNOCKBACK_FORCE := 500.0
const KNOCKBACK_FRICTION := 0.85

const DAMAGE_COOLDOWN := 0.5

var health: int = 20
var damage: int = 1
var knockback := Vector2.ZERO

var current_state: State = State.IDLE
var target: Node2D = null
var player_in_hurt_area: Node2D = null
var can_damage := true

@onready var detection_area: Area2D = $DetectionArea
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite
@onready var damage_timer: Timer = Timer.new()
@onready var hurt_area: Area2D = $HurtArea

func _ready() -> void:
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	damage_timer.wait_time = DAMAGE_COOLDOWN
	damage_timer.one_shot = true
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	add_child(damage_timer)

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
	hurt_area.queue_free()
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

func try_damage() -> void:
	if player_in_hurt_area and can_damage:
		var knock_dir = global_position.direction_to(player_in_hurt_area.global_position)
		player_in_hurt_area.take_damage(damage, knock_dir)
		can_damage = false
		damage_timer.start()

func _on_damage_timer_timeout() -> void:
	can_damage = true
	try_damage()

func _on_hurt_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_hurt_area = body
		try_damage()

func _on_hurt_area_body_exited(body: Node2D) -> void:
	if body == player_in_hurt_area:
		player_in_hurt_area = null
