extends CharacterBody2D

# ============ MOVIMIENTO ============
var velocidad: float = 200
var posicion_anterior: Vector2
var direccion_actual: Vector2 = Vector2.RIGHT
var direccion_suavizada: Vector2 = Vector2.RIGHT
var velocidad_suavizado: float = 0.2

# ============ LÍNEA DE DISPARO ============
@export var line_duration: float = 0.5
@export var line_color: Color = Color.WHITE
@export var line_width: float = 1.0
@export var tolerancia_alineacion: float = 0.03

var line_node: Line2D
var line_timer: float = 0.0
var is_drawing_line: bool = false
var line_end_point: Vector2

# ============ TEMBLOR DE PANTALLA ============
@export var shake_intensity: float = 8.0
@export var shake_duration: float = 0.15

var shake_timer: float = 0.0
var camera: Camera2D

# ============ BISECTRIZ VISUAL ============
var bisectriz_visible: bool = false
var bisectriz_vertice: Vector2 = Vector2.ZERO
var bisectriz_lado1: Vector2 = Vector2.ZERO
var bisectriz_lado2: Vector2 = Vector2.ZERO
var bisectriz_direccion: Vector2 = Vector2.ZERO
var bisectriz_timer: float = 0.0
var bisectriz_duration: float = 0.5

# ============ REFERENCIAS ============
@onready var nucleo = get_node("/root/Mundo/Centro/AreaVulnerable")
var flecha_direccion: Line2D

func _ready():
	collision_layer = 1
	collision_mask = 1
	add_to_group("jugador")
	
	posicion_anterior = global_position
	camera = get_viewport().get_camera_2d()
	
	crear_flecha()
	create_line_node()
	
	print("Jugador listo")

func _physics_process(_delta: float) -> void:
	var input_vector = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()
	
	velocity = input_vector * velocidad
	move_and_slide()
	
	if input_vector != Vector2.ZERO:
		direccion_actual = input_vector
	
	direccion_suavizada = direccion_suavizada.lerp(direccion_actual, velocidad_suavizado)
	if direccion_suavizada.length() < 0.05:
		direccion_suavizada = Vector2.ZERO
	
	actualizar_flecha()
	posicion_anterior = global_position

func crear_flecha():
	flecha_direccion = Line2D.new()
	flecha_direccion.width = 3
	flecha_direccion.default_color = Color(0, 1, 0, 0.8)
	add_child(flecha_direccion)
	
	var punta_izq = Line2D.new()
	var punta_der = Line2D.new()
	punta_izq.width = 2
	punta_der.width = 2
	punta_izq.default_color = Color(0, 1, 0, 0.8)
	punta_der.default_color = Color(0, 1, 0, 0.8)
	flecha_direccion.add_child(punta_izq)
	flecha_direccion.add_child(punta_der)

func actualizar_flecha():
	if direccion_suavizada == Vector2.ZERO:
		flecha_direccion.visible = false
		return
	
	flecha_direccion.visible = true
	var longitud = 50.0
	var inicio = Vector2.ZERO
	var fin = direccion_suavizada * longitud
	flecha_direccion.points = PackedVector2Array([inicio, fin])
	
	var punta = fin
	var perp = Vector2(-direccion_suavizada.y, direccion_suavizada.x) * 6
	var izquierda = fin - direccion_suavizada * 12 + perp
	var derecha = fin - direccion_suavizada * 12 - perp
	
	flecha_direccion.get_child(0).points = PackedVector2Array([punta, izquierda])
	flecha_direccion.get_child(1).points = PackedVector2Array([punta, derecha])

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		shoot()
		start_shake()

func shoot():
	var mouse_pos: Vector2 = get_global_mouse_position()
	var start_point: Vector2 = global_position
	var direction: Vector2 = (mouse_pos - start_point).normalized()
	
	line_end_point = calculate_line_end(start_point, direction)
	update_line(start_point, line_end_point)
	show_line()
	
	verificar_enemigos_colineales(start_point, direction)
	
	line_timer = line_duration
	is_drawing_line = true

func _process(delta):
	if is_drawing_line:
		line_timer -= delta
		if line_timer <= 0:
			hide_line()
	
	if bisectriz_visible:
		bisectriz_timer -= delta
		if bisectriz_timer <= 0:
			bisectriz_visible = false
			queue_redraw()
	
	if shake_timer > 0:
		shake_timer -= delta
		if camera:
			var intensity = shake_intensity * (shake_timer / shake_duration)
			camera.offset = Vector2(
				randf_range(-intensity, intensity),
				randf_range(-intensity, intensity)
			)
			if shake_timer <= 0:
				camera.offset = Vector2.ZERO

func calculate_line_end(start: Vector2, direction: Vector2) -> Vector2:
	if not camera:
		return start + direction * 2000
	
	var camera_center = camera.global_position
	var viewport_size = get_viewport().get_visible_rect().size
	var camera_left = camera_center.x - viewport_size.x / 2
	var camera_right = camera_center.x + viewport_size.x / 2
	var camera_top = camera_center.y - viewport_size.y / 2
	var camera_bottom = camera_center.y + viewport_size.y / 2
	
	var t_values = []
	
	if direction.x != 0:
		t_values.append((camera_left - start.x) / direction.x)
		t_values.append((camera_right - start.x) / direction.x)
	
	if direction.y != 0:
		t_values.append((camera_top - start.y) / direction.y)
		t_values.append((camera_bottom - start.y) / direction.y)
	
	var min_t: float = INF
	for t in t_values:
		if t > 0 and t < min_t:
			min_t = t
	
	return start + direction * (min_t if min_t != INF else 2000)

func create_line_node():
	line_node = Line2D.new()
	line_node.width = line_width
	line_node.default_color = line_color
	add_child(line_node)
	line_node.visible = false

func update_line(start: Vector2, end: Vector2):
	line_node.points = PackedVector2Array([to_local(start), to_local(end)])

func show_line():
	line_node.visible = true

func hide_line():
	line_node.visible = false
	is_drawing_line = false

func start_shake():
	shake_timer = shake_duration

# ============ VALIDACIÓN DE COLINEALIDAD ============
func verificar_enemigos_colineales(linea_origen: Vector2, linea_direccion: Vector2):
	var enemigos = get_tree().get_nodes_in_group("enemigo")
	var enemigo_a_eliminar = null
	var vertice_guardado = Vector2.ZERO
	var punto_critico_guardado = Vector2.ZERO
	var lado1_guardado = Vector2.ZERO
	var lado2_guardado = Vector2.ZERO
	
	for enemigo in enemigos:
		if not enemigo.has_method("obtener_vertices") or not enemigo.has_method("obtener_punto_critico"):
			continue
		
		if not is_instance_valid(enemigo):
			continue
		
		var vertices = enemigo.obtener_vertices()
		var vertices_locales = enemigo.obtener_vertices_locales()  # ← NECESITAS ESTE MÉTODO
		var punto_critico = enemigo.obtener_punto_critico()
		
		for i in range(vertices.size()):
			var vertice = vertices[i]
			if son_colineales(linea_origen, vertice, punto_critico):
				print("✓ Disparo alineado: ", enemigo.name)
				
				# === CÓDIGO NUEVO PARA LA BISECTRIZ ===
				# Obtener los dos lados del triángulo desde ese vértice
				var idx = i
				var lado1 = enemigo.to_global(vertices_locales[(idx + 1) % vertices_locales.size()])
				var lado2 = enemigo.to_global(vertices_locales[(idx - 1 + vertices_locales.size()) % vertices_locales.size()])
				var direccion_bisectriz = (punto_critico - vertice).normalized()
				
				mostrar_bisectriz(vertice, lado1, lado2, direccion_bisectriz)
				# ====================================
				
				enemigo_a_eliminar = enemigo
				vertice_guardado = vertice
				punto_critico_guardado = punto_critico
				break
		
		if enemigo_a_eliminar:
			break
	
	if enemigo_a_eliminar:
		enemigo_a_eliminar.exito_simetria()

func _draw():
	if bisectriz_visible and bisectriz_vertice != Vector2.ZERO:
		var vertice_local = to_local(bisectriz_vertice)
		var lado1_local = to_local(bisectriz_lado1)
		var lado2_local = to_local(bisectriz_lado2)
		
		# Calcular dirección de la bisectriz (ángulo medio entre lado1 y lado2)
		var dir1 = (lado1_local - vertice_local).normalized()
		var dir2 = (lado2_local - vertice_local).normalized()
		var angulo_medio = (dir1.angle() + dir2.angle()) / 2
		var direccion_bisectriz = Vector2(cos(angulo_medio), sin(angulo_medio))
		var bisectriz_local = vertice_local + direccion_bisectriz * 150
		
		# Lado 1 (verde)
		draw_line(vertice_local, lado1_local, Color(0, 0.8, 0), 3)
		
		# Lado 2 (rojo)
		draw_line(vertice_local, lado2_local, Color(0.8, 0, 0), 3)
		
		# Bisectriz (amarillo punteado)
		var puntos_bisectriz = generar_linea_punteada(vertice_local, bisectriz_local, 10)
		for i in range(puntos_bisectriz.size() - 1):
			draw_line(puntos_bisectriz[i], puntos_bisectriz[i + 1], Color(1, 1, 0), 2)
		
		# Arco del ángulo (gris)
		var radio_arco = 45
		var angulo_inicio = dir1.angle()
		var angulo_fin = dir2.angle()
		
		if angulo_fin < angulo_inicio:
			angulo_fin += PI * 2
		
		draw_arc(vertice_local, radio_arco, angulo_inicio, angulo_fin, 24, Color(0.6, 0.6, 0.6), 2)
		
		# Círculo en el vértice (blanco)
		draw_circle(vertice_local, 5, Color.WHITE)

func generar_linea_punteada(inicio: Vector2, fin: Vector2, longitud_tramo: float) -> Array[Vector2]:
	var puntos: Array[Vector2] = []
	var direccion = (fin - inicio).normalized()
	var distancia_total = inicio.distance_to(fin)
	var tramos = max(2, int(distancia_total / longitud_tramo))
	
	for i in range(tramos + 1):
		var t = float(i) / tramos
		var punto = inicio.lerp(fin, t)
		puntos.append(punto)
	
	return puntos

# ============ MOSTRAR BISECTRIZ ============
func mostrar_bisectriz(vertice: Vector2, lado1: Vector2, lado2: Vector2, direccion: Vector2):
	bisectriz_vertice = vertice
	bisectriz_lado1 = lado1
	bisectriz_lado2 = lado2
	bisectriz_direccion = direccion
	bisectriz_visible = true
	bisectriz_timer = bisectriz_duration
	queue_redraw()

func son_colineales(punto_base: Vector2, punto_a: Vector2, punto_b: Vector2) -> bool:
	var vector_a = (punto_a - punto_base).normalized()
	var vector_b = (punto_b - punto_base).normalized()
	
	var diferencia = abs(vector_a.angle_to(vector_b))
	var minima = min(diferencia, abs(PI - diferencia))
	var diff_grados = rad_to_deg(minima)
	var umbral_grados = rad_to_deg(tolerancia_alineacion)
	
	print("  → Ángulo: ", round(diff_grados * 100) / 100, "° / Umbral: ", round(umbral_grados * 100) / 100, "°")
	
	return minima <= tolerancia_alineacion

# ============ COLISIÓN ============
func _on_body_entered(body):
	if body.is_in_group("enemigo") and nucleo:
		nucleo._on_jugador_colision_con_enemigo(
			global_position,
			obtener_trayectoria(),
			direccion_suavizada,
			body.global_position
		)

func obtener_trayectoria() -> Vector2:
	var trayectoria = global_position - posicion_anterior
	return trayectoria if trayectoria.length() >= 0.01 else Vector2.ZERO
