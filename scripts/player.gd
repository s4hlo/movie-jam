extends CharacterBody2D

const SPEED := 300.0
const KNOCKBACK_FORCE := 500.0
const KNOCKBACK_FRICTION := 0.85
const INVINCIBILITY_DURATION := 1.0
const BLINK_INTERVAL := 0.08

# Referências aos nós
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite

# Começa em -1.0 pois o sprite original olha para a esquerda
var last_horizontal_dir: float = -1.0

var max_life: float = 10.0
var current_life: float = 10.0
var is_invincible: bool = false
var knockback := Vector2.ZERO

func _ready() -> void:
	get_tree().call_group("Interface", "update_life", current_life, max_life)

func _physics_process(_delta: float) -> void:
	# Input (WASD ou Setas)
	var input := Vector2.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.y = Input.get_axis("move_up", "move_down")
	
	# Removido para virar a camera de acordo com o mouse
	#if input.x != 0:
		#last_horizontal_dir = input.x
	var mouse_position = get_global_mouse_position()
	if mouse_position.x > global_position.x:
		last_horizontal_dir = 1.0
	else:
		last_horizontal_dir = -1.0
		
	# Movimentação e Física
	velocity = input.normalized() * SPEED + knockback
	knockback *= KNOCKBACK_FRICTION
	if knockback.length() < 5.0:
		knockback = Vector2.ZERO
	move_and_slide()

	# Lógica de Animação
	sprite.flip_h = last_horizontal_dir > 0 # Como o sprite padrão é para a esquerda a direção é invertida.
	if input != Vector2.ZERO:
		# Se houver qualquer movimento, executa a animação de andar
		anim.play("walk")
	else:
		# Se estiver parado, executa a animação idle
		anim.play("idle")

func take_damage(amount: float, knock_dir := Vector2.ZERO):
	if is_invincible:
		return
	current_life -= amount
	current_life = clamp(current_life, 0.0, max_life)
	knockback = knock_dir * KNOCKBACK_FORCE
	get_tree().call_group("Interface", "update_life", current_life, max_life)
	start_invincibility()

func start_invincibility() -> void:
	is_invincible = true
	# Flash branco
	sprite.material.set_shader_parameter("hit", true)
	await get_tree().create_timer(0.1).timeout
	sprite.material.set_shader_parameter("hit", false)
	# Piscar durante invencibilidade
	var elapsed := 0.0
	while elapsed < INVINCIBILITY_DURATION:
		sprite.visible = !sprite.visible
		await get_tree().create_timer(BLINK_INTERVAL).timeout
		elapsed += BLINK_INTERVAL
	sprite.visible = true
	is_invincible = false
