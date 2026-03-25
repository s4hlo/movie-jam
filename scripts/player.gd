extends CharacterBody2D

const SPEED := 300.0

# Referências aos nós
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite 

# Começa em -1.0 pois o sprite original olha para a esquerda
var last_horizontal_dir: float = -1.0

var max_life: float = 100.0
var current_life: float = 100.0

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
	velocity = input.normalized() * SPEED
	move_and_slide()

	# Lógica de Animação
	sprite.flip_h = last_horizontal_dir > 0 # Como o sprite padrão é para a esquerda a direção é invertida.
	if input != Vector2.ZERO:
		# Se houver qualquer movimento, executa a animação de andar
		anim.play("walk")
	else:
		# Se estiver parado, executa a animação idle
		anim.play("idle")

func take_damage(amount: float):
	current_life -= amount
	current_life = clamp(current_life, 0.0, max_life)
	
	get_tree().call_group("Interface", "update_life", current_life, max_life)
