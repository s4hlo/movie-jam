extends Control

# --- Layout constants ---
const CELL_SIZE := 16
const CELL_GAP := 2
const CELL_STRIDE := CELL_SIZE + CELL_GAP  # 18px per cell

# --- Colors ---
const COLOR_BG := Color(0.1, 0.1, 0.1, 0.7)
const COLOR_BORDER_OUTER := Color(0.25, 0.15, 0.1, 1.0)
const COLOR_BORDER_INNER := Color(0.35, 0.25, 0.15, 1.0)
const COLOR_ROOM_VISITED := Color(0.45, 0.38, 0.3, 1.0)
const COLOR_ROOM_CURRENT := Color(0.95, 0.85, 0.4, 1.0)
const COLOR_ROOM_CURRENT_OUTLINE := Color(1.0, 1.0, 1.0, 0.8)
const COLOR_CONNECTION := Color(0.45, 0.38, 0.3, 0.6)

var room_manager: Node = null
var _last_position: Vector2i = Vector2i(999, 999)  # force first redraw

func _ready() -> void:
	# RoomManager is a child of Main (game_manager.gd adds it)
	# HUD is also a child of Main, so we go: HUD -> Main -> RoomManager
	await get_tree().process_frame
	var main_node := get_parent().get_parent()  # HUD -> Main
	room_manager = main_node.get_node_or_null("RoomManager")

func _process(_delta: float) -> void:
	if room_manager == null:
		return
	if room_manager.current_position != _last_position:
		_last_position = room_manager.current_position
		queue_redraw()

func _draw() -> void:
	if room_manager == null:
		return

	# Draw background
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BG)

	# Draw border (outer then inner for pixel-art look)
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BORDER_OUTER, false, 2.0)
	draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), COLOR_BORDER_INNER, false, 1.0)

	var grid: Dictionary = room_manager.grid
	var current_pos: Vector2i = room_manager.current_position
	var center := size / 2.0

	# Draw each visited room
	for pos: Vector2i in grid:
		var offset: Vector2i = pos - current_pos
		var draw_pos := center + Vector2(offset.x * CELL_STRIDE, offset.y * CELL_STRIDE) - Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0)

		# Skip if outside the minimap bounds (with padding for border)
		if draw_pos.x + CELL_SIZE < 4 or draw_pos.x > size.x - 4:
			continue
		if draw_pos.y + CELL_SIZE < 4 or draw_pos.y > size.y - 4:
			continue

		var cell_rect := Rect2(draw_pos, Vector2(CELL_SIZE, CELL_SIZE))

		if pos == current_pos:
			draw_rect(cell_rect, COLOR_ROOM_CURRENT)
			draw_rect(cell_rect, COLOR_ROOM_CURRENT_OUTLINE, false, 1.0)
		else:
			draw_rect(cell_rect, COLOR_ROOM_VISITED)

		# Draw connections to adjacent visited rooms
		_draw_connections(pos, current_pos, center, grid)

func _draw_connections(pos: Vector2i, current_pos: Vector2i, center: Vector2, grid: Dictionary) -> void:
	# Only draw connections going right and down to avoid double-drawing
	var right := pos + Vector2i(1, 0)
	var down := pos + Vector2i(0, 1)

	if grid.has(right):
		var from := center + Vector2((pos.x - current_pos.x) * CELL_STRIDE + CELL_SIZE / 2.0, (pos.y - current_pos.y) * CELL_STRIDE)
		var to := center + Vector2((right.x - current_pos.x) * CELL_STRIDE - CELL_SIZE / 2.0, (right.y - current_pos.y) * CELL_STRIDE)
		draw_line(from, to, COLOR_CONNECTION, 1.0)

	if grid.has(down):
		var from := center + Vector2((pos.x - current_pos.x) * CELL_STRIDE, (pos.y - current_pos.y) * CELL_STRIDE + CELL_SIZE / 2.0)
		var to := center + Vector2((down.x - current_pos.x) * CELL_STRIDE, (down.y - current_pos.y) * CELL_STRIDE - CELL_SIZE / 2.0)
		draw_line(from, to, COLOR_CONNECTION, 1.0)
