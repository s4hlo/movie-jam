extends CharacterBody2D

const BROKEN_SKATE_SCENE = preload("res://scenes/broken_skate.tscn")

enum State { IDLE, CHASING, DEAD }
enum Status { RAT, RAT_SKATE }

var current_Status = Status.RAT_SKATE
const SPEED_SKATE := 500.0
const ONRUSH_COOLDOWN := 1.0

const SPEED_RAT := 150.0
const KNOCKBACK_FORCE := 500.0
const KNOCKBACK_FRICTION := 0.85
const DAMAGE_COOLDOWN := 0.5

var health: int = 40
var damage: int = 1
var knockback := Vector2.ZERO
var charge_direction := Vector2.ZERO

var current_state: State = State.IDLE
var target: Node2D = null
var player_in_hurt_area: Node2D = null
var can_damage :bool= true
var randfile:int = 0


@onready var detection_area: Area2D = $DetectionArea
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite
@onready var damage_timer: Timer = Timer.new()
@onready var charge_timer: Timer = Timer.new()
@onready var hurt_area: Area2D = $HurtArea
@onready var chitter: AudioStreamPlayer2D = $chitter
@onready var chittertimer: Timer = $chittertimer

func _ready() -> void:
	chittertimer.start(randf_range(0, 3.0))
	chittertimer.wait_time = 3.0
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	damage_timer.wait_time = DAMAGE_COOLDOWN
	damage_timer.one_shot = true
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	add_child(damage_timer)
	
	charge_timer.wait_time = ONRUSH_COOLDOWN
	charge_timer.one_shot = true
	charge_timer.timeout.connect(_on_charge_timer_timeout)
	add_child(charge_timer)

func _physics_process(_delta: float) -> void:
	if current_state == State.DEAD:
		velocity = Vector2.ZERO
	else:
		match current_Status:
			Status.RAT_SKATE:
				match current_state:
					State.IDLE:
						velocity = Vector2.ZERO
						anim.play("idle_skate")
					State.CHASING:
						velocity = charge_direction * SPEED_SKATE
						anim.play("walk_skate")
			Status.RAT:
				match current_state:
					State.IDLE:
						velocity = Vector2.ZERO
						anim.play("idle")
					State.CHASING:
						if target:
							var dir = global_position.direction_to(target.global_position)
							velocity = dir * SPEED_RAT
							sprite.flip_h = dir.x > 0
						anim.play("walk")
	
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
		if current_state == State.IDLE:
			if current_Status == Status.RAT_SKATE:
				onrush()
			else:
				current_state = State.CHASING

func onrush() -> void:
	if target == null or current_state == State.DEAD or current_Status != Status.RAT_SKATE: 
		return
		
	current_state = State.CHASING
	charge_direction = global_position.direction_to(target.global_position)
	sprite.flip_h = charge_direction.x > 0

	await get_tree().create_timer(0.5).timeout

	if current_state != State.DEAD and current_Status == Status.RAT_SKATE:
		current_state = State.IDLE
		charge_timer.start()

func _on_charge_timer_timeout() -> void:
	if current_state != State.DEAD and target != null and current_Status == Status.RAT_SKATE:
		onrush()

func flash_hit() -> void:
	sprite.material.set_shader_parameter("hit", true)
	await get_tree().create_timer(0.1).timeout
	sprite.material.set_shader_parameter("hit", false)

func _on_hurt_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullets"):
		makeratnoise(1.0, 3.0)
		var knock_dir = area.transform.x.normalized()
		knockback = knock_dir * KNOCKBACK_FORCE
		health -= area.damage
		area.queue_free()
		flash_hit()
		if health <= 20 and current_Status == Status.RAT_SKATE:
			drop_skate()
			sprite.frame = 18
		if health <= 0:
			die()
	
func drop_skate() -> void:
	current_Status = Status.RAT
	current_state = State.CHASING
	charge_timer.stop()
	
	var broken_skate = BROKEN_SKATE_SCENE.instantiate()
	broken_skate.global_position = global_position
	get_parent().add_child(broken_skate)
	
	# quando o rato for apagado da cena, apaga o skate tambem
	tree_exiting.connect(broken_skate.queue_free)

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


func _on_chittertimer_timeout() -> void:
	makeratnoise(-15.0, 0.5)

func makeratnoise(volmin:float, volmax:float):
	randfile = randi_range(1, 6)
	match randfile:
		1: 
			chitter.set_stream(load("res://assets/soundfx/rat1.wav"))
		2: 
			chitter.set_stream(load("res://assets/soundfx/rat2.wav"))
		3: 
			chitter.set_stream(load("res://assets/soundfx/rat3.wav"))
		4: 
			chitter.set_stream(load("res://assets/soundfx/rat4.wav"))
		5: 
			chitter.set_stream(load("res://assets/soundfx/rat5.wav"))
		6:
			chitter.set_stream(load("res://assets/soundfx/rat6.wav"))
	chitter.volume_db = randf_range(-15.0, 0.0)
	chitter.pitch_scale = randf_range(0.8, 1.5)
	chitter.play()
