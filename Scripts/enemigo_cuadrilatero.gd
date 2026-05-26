extends CharacterBody2D

var speed: float = 50
@onready var nucleo = get_node("/root/Mundo/Centro/AreaVulnerable")

@onready var flecha_direccion: Line2D
var direccion_real: Vector2 = Vector2.ZERO
var direccion_suavizada: Vector2 = Vector2.ZERO
var velocidad_suavizado: float = 0.2
var bloqueado: bool = false  # Nueva variable para evitar doble eliminación

#calculo del punto crítico (eje de simetria)
@export var tolerancia_disparo: float = 8.0
var punto_critico: Vector2
var polygon_node: Polygon2D

func calcular_centro_simetria():
	var vertices = polygon_node.polygon
	if vertices.size() < 4:
		print("Error: Se necesitan 4 vértices para el romboide")
		return
	
	var A = vertices[0]
	var C = vertices[2]
	
	# Centro de simetría = punto medio de la diagonal
	punto_critico = (A + C) / 2
	
	print("Romboide - Centro de simetría: ", punto_critico)

func verificar_impacto(linea_origen: Vector2, linea_direccion: Vector2) -> bool:
	var punto_global = to_global(punto_critico)
	var distancia = distancia_punto_a_semirrecta(punto_global, linea_origen, linea_direccion)
	
	if distancia <= tolerancia_disparo:
		exito_simetria()
		return true
	return false

func distancia_punto_a_semirrecta(punto: Vector2, origen: Vector2, direccion: Vector2) -> float:
	var al_punto = punto - origen
	var proyeccion = al_punto.dot(direccion)
	
	if proyeccion <= 0:
		return al_punto.length()
	
	var punto_cercano = origen + direccion * proyeccion
	return punto.distance_to(punto_cercano)

func exito_simetria():
	print("✓ Romboide destruido por centro de simetría")
	queue_free()



func _ready():
	collision_layer = 1
	collision_mask = 1
	add_to_group("enemigo")
	print("Enemigo listo - Posición:", global_position)
	crear_flecha()
	
	polygon_node = get_node("Polygon2D")
	calcular_centro_simetria()

#vector de dirección
func crear_flecha():
	flecha_direccion = Line2D.new()
	flecha_direccion.width = 3
	flecha_direccion.default_color = Color(1, 0, 0, 0.8)
	add_child(flecha_direccion)
	
	var punta_izq = Line2D.new()
	var punta_der = Line2D.new()
	punta_izq.width = 2
	punta_der.width = 2
	punta_izq.default_color = Color(1, 0, 0, 0.8)
	punta_der.default_color = Color(1, 0, 0, 0.8)
	flecha_direccion.add_child(punta_izq)
	flecha_direccion.add_child(punta_der)

#movimiento del enemigo
func _physics_process(_delta):
	direccion_real = (Vector2.ZERO - global_position).normalized()
	velocity = direccion_real * speed
	move_and_slide()
	
	direccion_suavizada = direccion_suavizada.lerp(direccion_real, velocidad_suavizado)
	actualizar_flecha()

#actualiza movimiento del vector dirección
func actualizar_flecha():
	if not is_instance_valid(flecha_direccion):
		return
		
	var longitud = 50.0
	
	if direccion_suavizada == Vector2.ZERO:
		flecha_direccion.visible = false
		return
	
	flecha_direccion.visible = true
	
	var inicio = Vector2.ZERO
	var fin = direccion_suavizada * longitud
	flecha_direccion.points = PackedVector2Array([inicio, fin])
	
	var punta = fin
	var perp = Vector2(-direccion_suavizada.y, direccion_suavizada.x) * 6
	var izquierda = fin - direccion_suavizada * 12 + perp
	var derecha = fin - direccion_suavizada * 12 - perp
	
	if flecha_direccion.get_child_count() >= 2:
		flecha_direccion.get_child(0).points = PackedVector2Array([punta, izquierda])
		flecha_direccion.get_child(1).points = PackedVector2Array([punta, derecha])

#detección de colisión perpendicular
func _on_body_entered(body):
	if bloqueado:
		return  # Evita procesar múltiples veces
	
	if body.is_in_group("jugador"):
		print("💥 Enemigo colisionó con jugador")
		if nucleo:
			# Llamar al núcleo y esperar su respuesta
			var resultado = nucleo._on_enemigo_colision_con_jugador(
				body.global_position,
				body.direccion_suavizada,
				global_position,
				direccion_suavizada
			)
			
			# Solo eliminarse si el bloqueo fue exitoso
			if resultado == true:
				bloqueado = true
				print("  → Enemigo BLOQUEADO - Eliminado")
				queue_free()
			else:
				print("  → Enemigo NO bloqueado - Continúa hacia el centro")
				# El enemigo NO se elimina, sigue su camino
