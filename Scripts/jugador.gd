extends CharacterBody2D

var velocidad = 200

func _physics_process(_delta: float) -> void:
	var input_vector = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()
	velocity = input_vector * velocidad

	move_and_slide()
	
	if input_vector != Vector2.ZERO:
		direccion_actual = input_vector.normalized()
	
	# Suavizar dirección para la flecha
	direccion_suavizada = direccion_suavizada.lerp(direccion_actual, velocidad_suavizado)
	if direccion_suavizada.length() < 0.05:
		direccion_suavizada = Vector2.ZERO
	
	actualizar_flecha()
	posicion_anterior = global_position


@export var line_duration: float = 0.5
@export var line_color: Color = Color.WHITE
@export var line_width: float = 1.0

@onready var flecha_direccion: Line2D
var posicion_anterior: Vector2
var direccion_actual: Vector2 = Vector2.RIGHT
var direccion_suavizada: Vector2 = Vector2.RIGHT
var velocidad_suavizado: float = 0.2

var line_node: Line2D
var line_timer: float = 0.0
var is_drawing_line: bool = false
var line_end_point: Vector2

func _ready():
	create_line_node()
	collision_layer = 1
	collision_mask = 1
	
	add_to_group("jugador")
	print("Jugador listo - Capa:", collision_layer)
	
	posicion_anterior = global_position
	crear_flecha()

func crear_flecha():
	flecha_direccion = Line2D.new()
	flecha_direccion.width = 3
	flecha_direccion.default_color = Color(0, 1, 0, 0.8)
	add_child(flecha_direccion)
	
	# Crear puntas
	var punta_izq = Line2D.new()
	var punta_der = Line2D.new()
	punta_izq.width = 2
	punta_der.width = 2
	punta_izq.default_color = Color(0, 1, 0, 0.8)
	punta_der.default_color = Color(0, 1, 0, 0.8)
	flecha_direccion.add_child(punta_izq)
	flecha_direccion.add_child(punta_der)

func actualizar_flecha():
	var longitud = 50.0
	
	if direccion_suavizada == Vector2.ZERO:
		flecha_direccion.visible = false
		return
	
	flecha_direccion.visible = true
	
	# Línea principal suavizada
	var inicio = Vector2.ZERO
	var fin = direccion_suavizada * longitud
	flecha_direccion.points = PackedVector2Array([inicio, fin])
	
	# Puntas de flecha
	var punta = fin
	var perp = Vector2(-direccion_suavizada.y, direccion_suavizada.x) * 6
	var izquierda = fin - direccion_suavizada * 12 + perp
	var derecha = fin - direccion_suavizada * 12 - perp
	
	flecha_direccion.get_child(0).points = PackedVector2Array([punta, izquierda])
	flecha_direccion.get_child(1).points = PackedVector2Array([punta, derecha])

func obtener_trayectoria() -> Vector2:
	var trayectoria = global_position - posicion_anterior
	if trayectoria.length() < 0.01:
		return Vector2.ZERO
	return trayectoria

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		shoot()

func _process(delta):
	if is_drawing_line:
		line_timer -= delta
		if line_timer <= 0:
			hide_line()

func shoot():
	var mouse_pos: Vector2 = get_global_mouse_position()
	var start_point: Vector2 = global_position
	var direction: Vector2 = (mouse_pos - start_point).normalized()
	
	line_end_point = calculate_line_end(start_point, direction)
	
	update_line(start_point, line_end_point)
	show_line()
	
	line_timer = line_duration
	is_drawing_line = true

func calculate_line_end(start: Vector2, direction: Vector2) -> Vector2:
	var viewport_rect: Rect2 = get_viewport_rect()
	
	var t_values = []
	
	if direction.x != 0:
		t_values.append((viewport_rect.position.x - start.x) / direction.x)
		t_values.append((viewport_rect.end.x - start.x) / direction.x)
	
	if direction.y != 0:
		t_values.append((viewport_rect.position.y - start.y) / direction.y)
		t_values.append((viewport_rect.end.y - start.y) / direction.y)
	
	var max_t: float = -1.0
	for t in t_values:
		if t > 0 and t > max_t:
			max_t = t
	
	return start + direction * max_t

func create_line_node():
	line_node = Line2D.new()
	line_node.width = line_width
	line_node.default_color = line_color
	add_child(line_node)
	line_node.visible = false

func update_line(start: Vector2, end: Vector2):
	var local_start = to_local(start)
	var local_end = to_local(end)
	line_node.points = PackedVector2Array([local_start, local_end])

func show_line():
	line_node.visible = true

func hide_line():
	line_node.visible = false
	is_drawing_line = false


@onready var nucleo = get_node("/root/Mundo/Centro/AreaVulnerable")
var velocidad_anterior: Vector2 = Vector2.ZERO

func _on_body_entered(body):
	if body.is_in_group("enemigo"):
		print("💥 Jugador colisionó con enemigo")
		var trayectoria = obtener_trayectoria()
		print("  Trayectoria real: ", trayectoria)
		
		if nucleo:
			nucleo._on_jugador_colision_con_enemigo(global_position,
				trayectoria,
				direccion_suavizada,
				body.global_position
			)
