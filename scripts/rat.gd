extends CharacterBody2D

enum State { IDLE, CHASING }

const SPEED := 150.0
var health:int = 10

var current_state: State = State.IDLE
var target: Node2D = null

@onready var detection_area: Area2D = $DetectionArea

func _ready() -> void:
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	print("[Rat] ready detection_area.monitoring=", detection_area.monitoring)

func _physics_process(_delta: float) -> void:
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
		State.CHASING:
			if target:
				velocity = global_position.direction_to(target.global_position) * SPEED
	move_and_slide()

func die() -> void:
	print("rato morto")
	queue_free()

func _on_detection_area_body_entered(body: Node2D) -> void:
	print("[Rat] entered body.name: ", body.name, " body.in_group_player=", body.is_in_group("player"))
	if body.is_in_group("player"):
		target = body
		current_state = State.CHASING
		print("[Rat] CHASING")

func _on_hurt_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullets"):
		health -= area.damage
		area.queue_free()

	if health <= 0:
		die()
