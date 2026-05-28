extends Area2D

var game_over_panel: Control = null
var camera_ref: Camera2D = null
@onready var health := $ProgressBar
var game_over_activado: bool = false

# DEFENSA
@export var tolerancia_angulo: float = 10.0
@export var snap_activado: bool = true

var angulo_actual: float = 0.0
var ultima_pos_jugador: Vector2 = Vector2.ZERO
var ultima_direccion_jugador: Vector2 = Vector2.ZERO
var ultima_pos_enemigo: Vector2 = Vector2.ZERO
var ultima_direccion_enemigo: Vector2 = Vector2.ZERO
var tiempo_visible: float = 0.0

func _ready():
	position = Vector2.ZERO

func _process(delta):
	if tiempo_visible > 0:
		tiempo_visible -= delta
		queue_redraw()

func validar_bloqueo(pos_jugador: Vector2, dir_jugador: Vector2, pos_enemigo: Vector2, dir_enemigo: Vector2) -> bool:
	ultima_pos_jugador = pos_jugador
	ultima_direccion_jugador = dir_jugador.normalized()
	ultima_pos_enemigo = pos_enemigo
	ultima_direccion_enemigo = dir_enemigo.normalized()
	tiempo_visible = 1.5
	
	var producto_punto = ultima_direccion_jugador.dot(ultima_direccion_enemigo)
	var angulo_rad = acos(clamp(producto_punto, -1.0, 1.0))
	angulo_actual = min(rad_to_deg(angulo_rad), 180.0 - rad_to_deg(angulo_rad))
	
	var cos_tolerancia = cos(deg_to_rad(90.0 - tolerancia_angulo))
	return abs(producto_punto) <= cos_tolerancia

func _draw():
	if tiempo_visible <= 0:
		return
	
	var vertice = (ultima_pos_jugador + ultima_pos_enemigo) / 2
	var dir_jugador = ultima_direccion_jugador
	var dir_enemigo = ultima_direccion_enemigo
	
	# Snap visual
	if snap_activado and abs(angulo_actual - 90) <= tolerancia_angulo:
		var angulo_90 = dir_jugador.angle() + deg_to_rad(90)
		dir_enemigo = Vector2(cos(angulo_90), sin(angulo_90))
	
	# Semirrectas
	draw_line(ultima_pos_jugador, ultima_pos_jugador + dir_jugador * 100, Color(0, 1, 0), 3)
	draw_line(ultima_pos_enemigo, ultima_pos_enemigo + dir_enemigo * 100, Color(1, 0, 0), 3)
	
	# Arco del ángulo
	var angulo_j = dir_jugador.angle()
	var angulo_e = dir_enemigo.angle()
	var diff = angulo_e - angulo_j
	if diff > PI:
		diff -= TAU
	elif diff < -PI:
		diff += TAU
	
	draw_arc(vertice, 55, angulo_j, angulo_j + diff, 32, Color(1, 1, 0), 2)
	
	# Arco de tolerancia
	var dentro = abs(angulo_actual - 90) <= tolerancia_angulo
	var color_tol: Color
	if dentro:
		color_tol = Color(0, 1, 0, 0.4)
	else:
		color_tol = Color(1, 0, 0, 0.4)
	
	var tol_inicio = angulo_j + deg_to_rad(90 - tolerancia_angulo)
	var tol_fin = angulo_j + deg_to_rad(90 + tolerancia_angulo)
	draw_arc(vertice, 67, tol_inicio, tol_fin, 16, color_tol, 5)
	
	# Número del ángulo
	var angulo_mostrar: float
	if snap_activado and dentro:
		angulo_mostrar = 90.0
	else:
		angulo_mostrar = angulo_actual
	
	var font = ThemeDB.fallback_font
	draw_string(font, vertice + Vector2(70, -10), str(round(angulo_mostrar)) + "°", HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(1, 1, 0))
	
	# Vértice
	draw_circle(vertice, 5, Color(1, 1, 1))
	draw_circle(vertice, 2, Color(0, 0, 0))

func _on_enemigo_colision_con_jugador(pos_jugador: Vector2, dir_jugador: Vector2, pos_enemigo: Vector2, dir_enemigo: Vector2) -> bool:
	var resultado = validar_bloqueo(pos_jugador, dir_jugador, pos_enemigo, dir_enemigo)
	
	if resultado:
		# Notificación de bloqueo perpendicular
		var jugador = get_tree().get_first_node_in_group("jugador")
		if jugador and jugador.has_method("mostrar_notificacion"):
			jugador.mostrar_notificacion("¡PERPENDICULAR!", Color(1, 1, 0), pos_enemigo)

	return resultado

func recibir_dano_enemigo(cantidad: int = 10, fuente: String = "desconocida"):
	health.value -= cantidad
	print("Centro dañado por ", fuente, "! -", cantidad, " vida. Restante: ", health)
	
	if health.value <= 0:
		game_over()
		
func take_damage(cantidad: int = 10):
	if game_over_activado:
		return
	
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador:
		jugador.start_shake()
	
	health.value -= cantidad
	print("Centro dañado! Vida restante: ", health)
	if health.value <= 0:
		game_over()

func game_over():
	if game_over_activado:
		return
	game_over_activado = true
	
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador:
		jugador.visible = false
	
	# Obtener posición de la cámara
	var camara = get_viewport().get_camera_2d()
	var camara_pos = Vector2.ZERO
	if camara:
		camara_pos = camara.global_position
	
	# Crear panel
	game_over_panel = Control.new()
	game_over_panel.size = get_viewport().get_visible_rect().size
	game_over_panel.position = camara_pos - game_over_panel.size / 2
	game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Fondo oscuro
	var fondo = ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.75)
	fondo.size = game_over_panel.size
	game_over_panel.add_child(fondo)
	
	var label = Label.new()
	label.text = "GAME OVER"
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(400, 80)
	label.position = Vector2(game_over_panel.size.x / 2 - 200, game_over_panel.size.y / 2 - 100)
	game_over_panel.add_child(label)
	
	var subtitulo = Label.new()
	subtitulo.text = "El centro ha sido destruido"
	subtitulo.add_theme_font_size_override("font_size", 20)
	subtitulo.add_theme_color_override("font_color", Color(1, 1, 1))
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.size = Vector2(400, 40)
	subtitulo.position = Vector2(game_over_panel.size.x / 2 - 200, game_over_panel.size.y / 2 - 20)
	game_over_panel.add_child(subtitulo)
	
	var boton_reiniciar = Button.new()
	boton_reiniciar.text = "REINICIAR"
	boton_reiniciar.size = Vector2(120, 35)
	boton_reiniciar.position = Vector2(game_over_panel.size.x / 2 - 130, game_over_panel.size.y / 2 + 40)
	boton_reiniciar.add_theme_font_size_override("font_size", 14)
	boton_reiniciar.pressed.connect(_reiniciar_juego)
	game_over_panel.add_child(boton_reiniciar)

	var boton_salir = Button.new()
	boton_salir.text = "SALIR"
	boton_salir.size = Vector2(120, 35)
	boton_salir.position = Vector2(game_over_panel.size.x / 2 + 10, game_over_panel.size.y / 2 + 40)
	boton_salir.add_theme_font_size_override("font_size", 14)
	boton_salir.pressed.connect(_salir_juego)
	game_over_panel.add_child(boton_salir)
	
	add_child(game_over_panel)
	
	# Pausar el juego
	get_tree().paused = true

func _reiniciar_juego():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _salir_juego():
	get_tree().quit()

func efecto_bloqueo_exitoso() -> void:
	pass

func efecto_impacto_fallido() -> void:
	pass
