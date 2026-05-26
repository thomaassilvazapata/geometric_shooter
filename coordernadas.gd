extends Node2D

@export var grid_color: Color = Color(0.5, 0.5, 0.5, 0.4)
@export var axis_color_x: Color = Color(1, 0, 0, 0.8)   # Red X axis
@export var axis_color_y: Color = Color(0, 1, 0, 0.8)   # Green Y axis
@export var cell_size: int = 100
@export var line_width: float = 0.5
@export var axis_width: float = 0.7

func _process(_delta: float) -> void:
	queue_redraw()  # Redraw every frame so grid follows camera

func _draw() -> void:
	var camera := get_viewport().get_camera_2d()
	if not camera:
		return

	var screen_size := get_viewport_rect().size
	var cam_pos := camera.get_screen_center_position()
	var zoom := camera.zoom

	# Visible world-space extents
	var half_w := (screen_size.x / zoom.x) / 2.0
	var half_h := (screen_size.y / zoom.y) / 2.0

	var left   := cam_pos.x - half_w
	var right  := cam_pos.x + half_w
	var top    := cam_pos.y - half_h
	var bottom := cam_pos.y + half_h

	# Snap to grid
	var start_x := int(left / cell_size) * cell_size
	var start_y := int(top  / cell_size) * cell_size

	# Vertical lines
	var x := start_x
	while x <= right:
		var color := axis_color_y if x == 0 else grid_color
		var width := axis_width  if x == 0 else line_width
		draw_line(Vector2(x, top), Vector2(x, bottom), color, width)
		x += cell_size

	# Horizontal lines
	var y := start_y
	while y <= bottom:
		var color := axis_color_x if y == 0 else grid_color
		var width := axis_width  if y == 0 else line_width
		draw_line(Vector2(left, y), Vector2(right, y), color, width)
		y += cell_size
