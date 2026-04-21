extends Area2D

var item_key: String = ""
var item_price: int = 0
var is_purchased: bool = false
var player_in_range: bool = false

#animação dos itens
var float_amplitude: float = 4.0 
var float_speed: float = 3.0     
var start_y: float = 0.0         
var time_passed: float = 0.0     

@onready var item_label: Label = $ItemLabel
@onready var prompt_label: Label = $PromptLabel
@onready var item_sprite: Sprite2D = $ItemSprite

func _ready() -> void:
	# Guarda a posição original do Sprite no eixo Y
	start_y = item_sprite.position.y
	
	# Inicia o tempo num ponto aleatório. (para que os itens não flutuem na mesma posição)
	time_passed = randf() * PI * 2
	
func setup(key: String, price: int, display_name: String, texture: Texture2D) -> void:
	item_key = key
	item_price = price
	item_label.text = display_name + " - " + str(price)
	prompt_label.visible = false
	item_sprite.texture = texture

func _process(delta: float) -> void:
	if player_in_range and not is_purchased and Input.is_action_just_pressed("interact"):
		_try_purchase()
	if not is_purchased:
		time_passed += delta * float_speed
		# Aplica a onda de seno na posição Y do sprite
		item_sprite.position.y = start_y + (sin(time_passed) * float_amplitude)

func _try_purchase() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	if SaveManager.coins >= item_price:
		SaveManager.add_coins(-item_price)
		if item_key == "heal_small":
			var heal_amount = player.max_life * 0.1
			player.current_life = min(player.current_life + heal_amount, player.max_life)
			get_tree().call_group("Interface", "update_life", player.current_life, player.max_life)
		elif item_key == "heal_big":
			var heal_amount = player.max_life * 0.5
			player.current_life = min(player.current_life + heal_amount, player.max_life)
			get_tree().call_group("Interface", "update_life", player.current_life, player.max_life)
		else:
			player.active_items[item_key] = true
			if item_key == "speed_boost":
				player.speed_multiplier = 1.4
		is_purchased = true
		item_sprite.visible = false
		item_label.visible = false
		prompt_label.visible = false
	else:
		_flash_no_coins()

func _flash_no_coins() -> void:
	var original_color = item_label.modulate
	item_label.modulate = Color.RED
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(item_label):
		item_label.modulate = original_color

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_purchased:
		player_in_range = true
		prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		prompt_label.visible = false
