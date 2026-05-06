extends CharacterBody2D

var speed: float = 120
#var detection_range: float = 500.0

@onready var area = get_parent().find_child("AreaVulnerable")

func _ready():
	area = get_tree().get_first_node_in_group("Jugador")

func _physics_process(_delta):
	if area == null:
		return
	
	# Calcular dirección hacia el jugador
	var direction = global_position.direction_to(area.global_position)

	velocity = direction * speed
	move_and_slide()
