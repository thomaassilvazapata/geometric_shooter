extends Node2D

@export var point_1: Vector2
@export var point_2: Vector2

@onready var triangle_node: Resource = preload("res://Escenas/enemigo_triangulo.tscn") #nodo del enemigo
@onready var rectangle_node: Resource = preload("res://Escenas/enemigo_cuadrilatero.tscn")

var timer1: float = 0.0 #contador usado para compararse su tiempo con el intervalo
var interval1: float = 5 #cada cuanto aparece un nuevo enemigo triangulo

var timer2: float = 0.0
var interval2: float = 20 # enemigo cuadrilatero

#escoge un numero aleatorio entre los maximos escogidos
func get_random_point_inside(p1: Vector2, p2: Vector2) -> Vector2:
	var x_value: float = randf_range(p1.x, p2.x)
	var y_value: float = randf_range(p1.y, p2.y)

	var random_point_inside: Vector2 = Vector2(x_value, y_value)

	return(random_point_inside)

func spawn_enemigo(tipo: String):
	var enemy_instance: Node
	
	if tipo == "triangulo":
		enemy_instance = triangle_node.instantiate()
	elif tipo == "cuadrilatero":
		enemy_instance = rectangle_node.instantiate()
	
	add_child(enemy_instance) #añada el enemigo
	
	#declara los puntos extremos segun el nodo que tiene el script
	if self.name == "Spawn1":
		point_1 = Vector2(-200,-200)
		point_2 = Vector2(200,-150)

	var spawn_location: Vector2 = get_random_point_inside(point_1, point_2)
	enemy_instance.set_position(spawn_location)

#se encarga de obtener resultados aleatorios cada vez
func _ready():
	randomize()

#instancia una guadaña indefinidamente respecto a la relacion contador-intervalo
func _process(delta):
	timer1 += delta
	if timer1 >= interval1:
		timer1 = 0.0
		spawn_enemigo("triangulo")
		
	timer2 += delta
	if timer2 >= interval2:
		timer2 = 0.0
		spawn_enemigo("cuadrilatero")
