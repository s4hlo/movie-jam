extends Control

func _ready() -> void:
	$VBox/Start.grab_focus()
	$VBox/CoinLabel.text = "Coins: " + str(SaveManager.coins)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_quit_pressed() -> void:
	SaveManager.save_game()
	get_tree().quit()


func _on_start_mouse_entered() -> void:
	$AudioStreamPlayer2D.pitch_scale = randf_range(0.5, 1.5)
	$AudioStreamPlayer2D.play()


func _on_quit_mouse_entered() -> void:
	$AudioStreamPlayer2D.pitch_scale = randf_range(0.5, 1.5)
	$AudioStreamPlayer2D.play()
