extends Area2D

var item_key: String = ""
var item_price: int = 0
var is_purchased: bool = false
var player_in_range: bool = false

@onready var item_label: Label = $ItemLabel
@onready var prompt_label: Label = $PromptLabel
@onready var item_sprite: ColorRect = $ItemSprite

func setup(key: String, price: int, display_name: String) -> void:
	item_key = key
	item_price = price
	item_label.text = display_name + " - " + str(price)
	prompt_label.visible = false

func _process(_delta: float) -> void:
	if player_in_range and not is_purchased and Input.is_action_just_pressed("interact"):
		_try_purchase()

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
