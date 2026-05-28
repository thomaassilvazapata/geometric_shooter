extends CharacterBody2D

# Movimiento
var speed: float = 50
@onready var nucleo = get_node("/root/Mundo/Centro/AreaVulnerable")

# Flecha de dirección
var flecha_direccion: Line2D
var direccion_real: Vector2 = Vector2.ZERO
var direccion_suavizada: Vector2 = Vector2.ZERO
var velocidad_suavizado: float = 0.2
var bloqueado: bool = false
var ya_eliminado: bool = false

# Punto crítico (Centro de Simetría)
@export var punto_color: Color = Color.CYAN
@export var punto_tamano: float = 1.5
@export var brillo_velocidad: float = 2.0

@export var explosion_particles: PackedScene

var punto_critico: Vector2
var polygon_node: Polygon2D
var punto_visual: Node2D
var tiempo_brillo: float = 0.0

func _ready():
	collision_layer = 1
	collision_mask = 1
	add_to_group("enemigo")
	
	crear_flecha()
	
	polygon_node = get_node("Polygon2D")
	calcular_centro_simetria()
	crear_punto_visual()
	
	print("Cuadrilátero listo - ID: ", name)

# MOVIMIENTO
func _physics_process(_delta):
	direccion_real = (Vector2.ZERO - global_position).normalized()
	velocity = direccion_real * speed
	move_and_slide()
	
	# VERIFICA SI LLEGÓ AL CENTRO
	if global_position.distance_to(Vector2.ZERO) < 10:  #píxeles de tolerancia
		llegar_al_centro()
		return
	
	direccion_suavizada = direccion_suavizada.lerp(direccion_real, velocidad_suavizado)
	actualizar_flecha()
	
	if punto_visual:
		punto_visual.position = punto_critico

func llegar_al_centro():
	if ya_eliminado:
		return
	ya_eliminado = true
	
	if nucleo and nucleo.has_method("recibir_dano_enemigo"):
		nucleo.recibir_dano_enemigo(5, "Cuadragon")
	
	queue_free()

# FLECHA VISUAL
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

# CENTRO DE SIMETRÍA
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

# PUNTO VISUAL
func crear_punto_visual():
	punto_visual = Node2D.new()
	punto_visual.position = punto_critico
	punto_visual.z_index = 10
	add_child(punto_visual)
	move_child(punto_visual, get_child_count() - 1)
	
	punto_visual.draw.connect(_draw_punto_visual)
	actualizar_brillo()

func _draw_punto_visual():
	var opacidad = 0.5 + (sin(tiempo_brillo * brillo_velocidad) + 1) / 2 * 0.5
	punto_visual.draw_circle(Vector2.ZERO, punto_tamano, Color(punto_color.r, punto_color.g, punto_color.b, opacidad))

func actualizar_brillo():
	if not is_instance_valid(punto_visual):
		return
	tiempo_brillo += 0.1
	punto_visual.queue_redraw()
	await get_tree().create_timer(0.1).timeout
	actualizar_brillo()

# MÉTODOS PARA EL JUGADOR
func obtener_vertices() -> Array[Vector2]:
	if not polygon_node:
		return []
	var vertices_globales: Array[Vector2] = []
	for vertice in polygon_node.polygon:
		vertices_globales.append(to_global(vertice))
	return vertices_globales

func obtener_vertices_locales() -> Array[Vector2]:
	if not polygon_node:
		return []
	
	var vertices: Array[Vector2] = []
	for vertice in polygon_node.polygon:
		vertices.append(vertice as Vector2)
	return vertices

func obtener_punto_critico() -> Vector2:
	return to_global(punto_critico)

func exito_simetria():
	if ya_eliminado:
		return
	ya_eliminado = true
	
	crear_explosion()
	
	queue_free()

func crear_explosion():
	var particulas = CPUParticles2D.new()
	particulas.global_position = global_position
	particulas.amount = 50
	particulas.lifetime = 0.5
	particulas.one_shot = true
	particulas.emitting = true
	particulas.gravity = Vector2.ZERO
	particulas.direction = Vector2(0, -1)
	particulas.spread = 360
	particulas.initial_velocity_min = 180
	particulas.initial_velocity_max = 250
	particulas.scale_amount_min = 5.0
	particulas.scale_amount_max = 12.0
	particulas.color = Color(1.0, 0.759, 0.0, 1.0)
	
	get_tree().root.add_child(particulas)
	
	await get_tree().create_timer(particulas.lifetime).timeout
	particulas.queue_free()

# COLISIÓN CON JUGADOR (original, actualizado con ya_eliminado)
func _on_body_entered(body):
	if bloqueado or ya_eliminado:
		return
	
	if body.is_in_group("jugador"):
		print("💥 Enemigo colisionó con jugador")
		if nucleo:
			var resultado = nucleo._on_enemigo_colision_con_jugador(
				body.global_position,
				body.direccion_suavizada,
				global_position,
				direccion_suavizada
			)
			
			if resultado == true:
				bloqueado = true
				print("  → Enemigo BLOQUEADO - Eliminado")
				queue_free()
			else:
				print("  → Enemigo NO bloqueado - Continúa hacia el centro")
