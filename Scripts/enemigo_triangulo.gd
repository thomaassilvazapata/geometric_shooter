extends CharacterBody2D

var speed: float = 120
#var detection_range: float = 500.0

@onready var jugador = get_parent().find_child("Jugador")

func _ready():
	jugador = get_tree().get_first_node_in_group("Jugador")

func _physics_process(_delta):
	if jugador == null:
		print("no me puedo mover")
		return
	
	# Calcular dirección hacia el jugador
	var direction = global_position.direction_to(jugador.global_position)
	
	# Opcional: solo perseguir si está dentro del rango
	# var distance = global_position.distance_to(player.global_position)
	# if distance > detection_range:
	#     return
	
	# Mover hacia el jugador
	velocity = direction * speed
	move_and_slide()
