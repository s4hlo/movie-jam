extends Area2D

signal state_changed(new_state: String)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var randfile:int = randi_range(1, 3)
		SaveManager.add_coins(1)
		match randfile:
			1:
				$AudioStreamPlayer2D.set_stream(load("res://assets/soundfx/coin1.wav"))
			2:
				$AudioStreamPlayer2D.set_stream(load("res://assets/soundfx/coin2.wav"))
			3:
				$AudioStreamPlayer2D.set_stream(load("res://assets/soundfx/coin3.wav"))
		$AudioStreamPlayer2D.volume_db = randf_range(-20.0, -10.0)
		$AudioStreamPlayer2D.pitch_scale = randf_range(0.6, 1.5)
		$AudioStreamPlayer2D.play()
		state_changed.emit("collected")
		self.visible = false
		await $AudioStreamPlayer2D.finished
		queue_free()
