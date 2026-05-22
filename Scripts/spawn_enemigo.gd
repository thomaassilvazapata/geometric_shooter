extends Node2D

@export var point_1: Vector2
@export var point_2: Vector2

@onready var triangle_node: Resource = preload("res://Escenas/enemigo_triangulo.tscn") #nodo del enemigo
@onready var rectangle_node: Resource = preload("res://Escenas/enemigo_cuadrilatero.tscn")

var timer1: float = 0.0 #contador usado para compararse su tiempo con el intervalo
var interval1: float = 5 #cada cuanto aparece un nuevo enemigo triangulo

var timer2: float = 0.0
var interval2: float = 20 # enemigo cuadrilatero

@export var radio_spawn: float = 500.0

func spawn_enemigo(tipo: String):
	var enemigo: Node
	
	if tipo == "triangulo":
		enemigo = triangle_node.instantiate()
	elif tipo == "cuadrilatero":
		enemigo = rectangle_node.instantiate()
	
	# Posición aleatoria en círculo
	var angulo = randf_range(0, 360)
	var radianes = deg_to_rad(angulo)
	var x = cos(radianes) * radio_spawn
	var y = sin(radianes) * radio_spawn
	
	enemigo.global_position = Vector2(x, y)
	add_child(enemigo)
	print("Enemigo spawn en: ", enemigo.global_position)

#se encarga de obtener resultados aleatorios cada vez
func _ready():
	randomize()

#instancia un enemigo indefinidamente respecto a la relacion contador-intervalo
func _process(delta):
	timer1 += delta
	if timer1 >= interval1:
		timer1 = 0.0
		spawn_enemigo("triangulo")
		
	timer2 += delta
	if timer2 >= interval2:
		timer2 = 0.0
		spawn_enemigo("cuadrilatero")
