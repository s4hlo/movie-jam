extends CharacterBody2D

const SPEED := 150.0

# Referências aos nós
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite 

# Começa em -1.0 pois o sprite original olha para a esquerda
var last_horizontal_dir: float = -1.0

func _physics_process(_delta: float) -> void:
	# Input (WASD ou Setas)
	var input := Vector2.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.y = Input.get_axis("move_up", "move_down")
	
	if input.x != 0:
		last_horizontal_dir = input.x
		
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
