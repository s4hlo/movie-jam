extends CharacterBody2D

#const BROKEN_SKATE_SCENE = preload("res://scenes/broken_skate.tscn")

# SINAIS
signal state_changed(new_state: String)

# ESTADOS E FASES
enum State { IDLE, CHASING, DEAD }
enum Phases { FIRST, SECOND }
var current_Phases = Phases.FIRST
var current_state: State = State.IDLE

# STATUS RATO
const SPEED_RAT := 150.0
const KNOCKBACK_FORCE := 500.0
const SPEED_RUSH := 400.0
const KNOCKBACK_FRICTION := 0.85
var health: int = 200
var damage: int = 1

# TEMPOS DE RECARGA
const DAMAGE_COOLDOWN := 0.5
const PONG_DURATION := 5.0
const RELOAD_DURATION := 3.0

# CONDICIONAIS
var can_damage: bool = true
var is_reloading_rush: bool = false

# RATO ATIRADOR

const ENEMY_BULLET = preload("res://scenes/enemy_bullet.tscn")
const SHOOT_RANGE := 350.0
const SHOOT_COOLDOWN := 1.2

var _shoot_cooldown_time := 2.0

@onready var gun: Node2D = $EnemyGun
@onready var muzzle: Marker2D = $EnemyGun/Marker2D

# OUTROS
var knockback := Vector2.ZERO
var pong_direction := Vector2.ZERO

var target: Node2D = null
var player_in_hurt_area: Node2D = null
var randfile: int = 0

#@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite
@onready var damage_timer: Timer = Timer.new()
@onready var hurt_area: Area2D = $HurtArea
@onready var pong_timer: Timer = Timer.new()
@onready var reload_timer: Timer = Timer.new()
#@onready var chitter: AudioStreamPlayer2D = $chitter
#@onready var chittertimer: Timer = $chittertimer

func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")
	
	gun.visible = false
	
	damage_timer.wait_time = DAMAGE_COOLDOWN
	damage_timer.one_shot = true
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	add_child(damage_timer)
	
	pong_timer.wait_time = PONG_DURATION
	pong_timer.one_shot = true
	pong_timer.timeout.connect(_on_pong_timer_timeout)
	add_child(pong_timer)
	
	reload_timer.wait_time = RELOAD_DURATION
	reload_timer.one_shot = true
	reload_timer.timeout.connect(_on_reload_timer_timeout)
	add_child(reload_timer)
	
	start_chasing_sequence()
	
func start_chasing_sequence() -> void:
	current_state = State.IDLE
	current_Phases = Phases.FIRST
	# anim.play("idle")
	
	await get_tree().create_timer(1.5).timeout
	
	var angle_rad = deg_to_rad(30.0)
	pong_direction = Vector2(cos(angle_rad), sin(angle_rad))
	
	current_state = State.CHASING
	is_reloading_rush = false
	pong_timer.start()
	
func _physics_process(_delta: float) -> void:
	if current_state == State.IDLE:
		velocity = Vector2.ZERO
		#anim.play("idle")
		return
	
	if current_state == State.DEAD:
		velocity = Vector2.ZERO
	else:
		if not is_reloading_rush:
			velocity = pong_direction * SPEED_RUSH
			#anim.play("walk")
		else:
			if target:
				var dir = global_position.direction_to(target.global_position)
				velocity = dir * SPEED_RAT
				sprite.flip_h = dir.x > 0
				#anim.play("walk_reloading"
				
		if Phases.SECOND == current_Phases:
			if target:
				var dir = global_position.direction_to(target.global_position)
				sprite.flip_h = dir.x > 0
				_aim_gun_at(target.global_position)
				
				_shoot_cooldown_time -= _delta
				if _shoot_cooldown_time <= 0.0:
					_shoot()
					_shoot_cooldown_time = SHOOT_COOLDOWN

	velocity += knockback
	knockback *= KNOCKBACK_FRICTION
	if knockback.length() < 5.0:
		knockback = Vector2.ZERO

	move_and_slide()
	
	if current_Phases == Phases.FIRST and current_state == State.CHASING and not is_reloading_rush:
		if get_slide_collision_count() > 0:
			var collision = get_slide_collision(0)
			pong_direction = pong_direction.bounce(collision.get_normal())
			sprite.flip_h = pong_direction.x > 0
			
func _on_pong_timer_timeout() -> void:
	is_reloading_rush = true
	reload_timer.start()

func _on_reload_timer_timeout() -> void:
	is_reloading_rush = false
	
	var dir = global_position.direction_to(target.global_position)
	pong_direction = dir
	pong_timer.start()
	
func die() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
	set_physics_process(false)
	hurt_area.queue_free()
	#anim.stop()
	#sprite.frame = 22
	state_changed.emit("destroyed")
	SaveManager.add_rat_kill()
	await get_tree().create_timer(0.5).timeout
	queue_free()

func flash_hit() -> void:
	sprite.material.set_shader_parameter("hit", true)
	await get_tree().create_timer(0.1).timeout
	sprite.material.set_shader_parameter("hit", false)

func try_damage() -> void:
	if player_in_hurt_area and can_damage:
		var knock_dir = global_position.direction_to(player_in_hurt_area.global_position)
		player_in_hurt_area.take_damage(damage, knock_dir)
		can_damage = false
		damage_timer.start()

func _on_damage_timer_timeout() -> void:
	can_damage = true
	try_damage()
	
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

#####################################################
############ SINAIS ############
#####################################################
func _on_hurt_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullets"):
		var knock_dir = area.transform.x.normalized()
		knockback = knock_dir * KNOCKBACK_FORCE
		health -= area.damage
		area.queue_free()
		flash_hit()
		if health <= 100 and current_Phases == Phases.FIRST:
			current_Phases = Phases.SECOND 
			# animacao da troca
			
			#drop_skate()
			#sprite.frame = 18
		if health <= 0:
			die()

func _on_hurt_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_hurt_area = body
		try_damage()

func _on_hurt_area_body_exited(body: Node2D) -> void:
	if body == player_in_hurt_area:
		player_in_hurt_area = null
		
#####################################################
############ SONS ############
#####################################################

#func _on_chittertimer_timeout() -> void:
	#makeratnoise(-15.0, 0.5)
#
#func makeratnoise(volmin:float, volmax:float):
	#randfile = randi_range(1, 6)
	#match randfile:
		#1: 
			#chitter.set_stream(load("res://assets/soundfx/rat1.wav"))
		#2: 
			#chitter.set_stream(load("res://assets/soundfx/rat2.wav"))
		#3: 
			#chitter.set_stream(load("res://assets/soundfx/rat3.wav"))
		#4: 
			#chitter.set_stream(load("res://assets/soundfx/rat4.wav"))
		#5: 
			#chitter.set_stream(load("res://assets/soundfx/rat5.wav"))
		#6:
			#chitter.set_stream(load("res://assets/soundfx/rat6.wav"))
	#chitter.volume_db = randf_range(-15.0, 0.0)
	#chitter.pitch_scale = randf_range(0.8, 1.5)
	#chitter.play()
