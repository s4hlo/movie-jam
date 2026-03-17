extends Node

signal coins_changed(new_total: int)

const SAVE_PATH := "user://save.json"

var coins: int = 0

func _ready() -> void:
	load_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		get_tree().quit()

func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"coins": coins}))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var data = JSON.parse_string(file.get_as_text())
	if data is Dictionary:
		coins = int(data.get("coins", 0))
