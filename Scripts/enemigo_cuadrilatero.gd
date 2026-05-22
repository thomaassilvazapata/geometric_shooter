extends CharacterBody2D

var speed: float = 50
@onready var nucleo = get_node("/root/Mundo/Centro/AreaVulnerable")

@onready var flecha_direccion: Line2D
var direccion_real: Vector2 = Vector2.ZERO
var direccion_suavizada: Vector2 = Vector2.ZERO
var velocidad_suavizado: float = 0.2
var bloqueado: bool = false  # Nueva variable para evitar doble eliminación

func _ready():
	collision_layer = 1
	collision_mask = 1
	add_to_group("enemigo")
	print("Enemigo listo - Posición:", global_position)
	crear_flecha()

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

func _physics_process(_delta):
	direccion_real = (Vector2.ZERO - global_position).normalized()
	velocity = direccion_real * speed
	move_and_slide()
	
	direccion_suavizada = direccion_suavizada.lerp(direccion_real, velocidad_suavizado)
	actualizar_flecha()

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
