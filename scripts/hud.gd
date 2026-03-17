extends CanvasLayer

@onready var label: Label = $CoinLabel

func _ready() -> void:
	SaveManager.coins_changed.connect(_on_coins_changed)
	_update_label(SaveManager.coins)

func _on_coins_changed(new_total: int) -> void:
	_update_label(new_total)

func _update_label(total: int) -> void:
	label.text = "Coins: " + str(total)
