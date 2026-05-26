extends CharacterBody2D

# Movimiento
var speed: float = 100
@onready var nucleo = get_node("/root/Mundo/Centro/AreaVulnerable")

# Flecha de dirección
var flecha_direccion: Line2D
var direccion_real: Vector2 = Vector2.ZERO
var direccion_suavizada: Vector2 = Vector2.ZERO
var velocidad_suavizado: float = 0.3
var bloqueado: bool = false
var ya_eliminado: bool = false

# Punto crítico (Incentro)
@export var punto_color: Color = Color.CYAN
@export var punto_tamano: float = 1.5
@export var brillo_velocidad: float = 2.0

var punto_critico: Vector2
var polygon_node: Polygon2D
var punto_visual: Node2D
var tiempo_brillo: float = 0.0

func _ready():
	collision_layer = 1
	collision_mask = 1
	add_to_group("enemigo")
	
	# Nombre único para debug
	name = "Triangulo_" + str(Time.get_ticks_usec())
	
	polygon_node = get_node("Polygon2D")
	calcular_incentro()
	crear_punto_visual()
	crear_flecha()
	
	print("Triángulo listo - ID: ", name)

# MOVIMIENTO
func _physics_process(_delta):
	direccion_real = (Vector2.ZERO - global_position).normalized()
	velocity = direccion_real * speed
	move_and_slide()
	
	direccion_suavizada = direccion_suavizada.lerp(direccion_real, velocidad_suavizado)
	actualizar_flecha()
	
	if punto_visual:
		punto_visual.position = punto_critico

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
	
	if flecha_direccion.get_child_count() >= 2:
		flecha_direccion.get_child(0).points = PackedVector2Array([punta, izquierda])
		flecha_direccion.get_child(1).points = PackedVector2Array([punta, derecha])

# INCENTRO
func calcular_incentro():
	var vertices = polygon_node.polygon
	if vertices.size() < 3:
		return
	
	var A = vertices[0]
	var B = vertices[1]
	var C = vertices[2]
	
	var a = (B - C).length()
	var b = (A - C).length()
	var c = (A - B).length()
	var suma = a + b + c
	punto_critico = (a * A + b * B + c * C) / suma

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
	queue_free()

# COLISIÓN CON JUGADOR
func _on_body_entered(body):
	if bloqueado or ya_eliminado:
		return
	
	if body.is_in_group("jugador"):
		if nucleo:
			var resultado = nucleo._on_enemigo_colision_con_jugador(
				body.global_position,
				body.direccion_suavizada,
				global_position,
				direccion_suavizada
			)
			if resultado == true:
				bloqueado = true
				exito_simetria()
