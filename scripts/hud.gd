extends CanvasLayer

@onready var label: Label = $CoinLabel

@onready var hp_bar = $TextureProgressBar
@export var background_textures: Array[Texture2D]

func _ready() -> void:
	SaveManager.coins_changed.connect(_on_coins_changed)
	_update_label(SaveManager.coins)

func _on_coins_changed(new_total: int) -> void:
	_update_label(new_total)

func _update_label(total: int) -> void:
	label.text = "Coins: " + str(total)
	
func update_life(current_life: float, maximum_life: float):
	hp_bar.max_value = maximum_life
	hp_bar.value = current_life
	
	var percentage = current_life / maximum_life
	
	if percentage > 0.54:
		update_texture_bar(0)
	elif percentage > 0.2:
		update_texture_bar(1)
	else:
		update_texture_bar(2)

func update_texture_bar(index: int):
	if background_textures.size() > index and background_textures[index] != null:
		hp_bar.texture_under = background_textures[index]
