extends Area2D

var health: int = 100

func take_damage():
	health -= 10
	print("Centro dañado! Vida restante: ", health)
	if health <= 0:
		game_over()

func block_damage():
	print("Golpe bloqueado por el escudo!")

func game_over():
	print("Game Over - Centro destruido")


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

func validar_bloqueo(pos_jugador, dir_jugador, pos_enemigo, dir_enemigo) -> bool:
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
	
	# Snap visual (sin variable extra)
	if snap_activado and abs(angulo_actual - 90) <= tolerancia_angulo:
		var angulo_90 = dir_jugador.angle() + deg_to_rad(90)
		dir_enemigo = Vector2(cos(angulo_90), sin(angulo_90))
	
	# Semirrectas
	draw_line(ultima_pos_jugador, ultima_pos_jugador + dir_jugador * 100, Color(0,1,0), 3)
	draw_line(ultima_pos_enemigo, ultima_pos_enemigo + dir_enemigo * 100, Color(1,0,0), 3)
	
	# Arco del ángulo
	var angulo_j = dir_jugador.angle()
	var angulo_e = dir_enemigo.angle()
	var diff = angulo_e - angulo_j
	if diff > PI: diff -= TAU
	elif diff < -PI: diff += TAU
	
	draw_arc(vertice, 55, angulo_j, angulo_j + diff, 32, Color(1,1,0), 2)
	
	# Arco de tolerancia
	var dentro = abs(angulo_actual - 90) <= tolerancia_angulo
	var color_tol = Color(0,1,0,0.4) if dentro else Color(1,0,0,0.4)
	var tol_inicio = angulo_j + deg_to_rad(90 - tolerancia_angulo)
	var tol_fin = angulo_j + deg_to_rad(90 + tolerancia_angulo)
	draw_arc(vertice, 67, tol_inicio, tol_fin, 16, color_tol, 5)
	
	# Número del ángulo
	var angulo_mostrar = 90 if (snap_activado and dentro) else angulo_actual
	var font = ThemeDB.fallback_font
	draw_string(font, vertice + Vector2(70, -10), str(round(angulo_mostrar)) + "°", HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(1,1,0))
	
	# Vértice
	draw_circle(vertice, 5, Color(1,1,1))
	draw_circle(vertice, 2, Color(0,0,0))

func _on_enemigo_colision_con_jugador(pos_jugador, dir_jugador, pos_enemigo, dir_enemigo) -> bool:
	var resultado = validar_bloqueo(pos_jugador, dir_jugador, pos_enemigo, dir_enemigo)
	print("Ángulo: ", round(angulo_actual), "° | Bloqueo: ", "✓" if resultado else "✗")
	return resultado

func efecto_bloqueo_exitoso() -> void:
	pass

func efecto_impacto_fallido() -> void:
	pass
