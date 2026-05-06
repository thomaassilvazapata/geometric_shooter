extends CharacterBody2D

@export var bullet_speed: float = 500.0
@export var bullet_scene: PackedScene
var velocidad = 200

func _physics_process(_delta: float) -> void:
	var input_vector = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()
	velocity = input_vector * velocidad

	move_and_slide()

func _process(delta):
	# Movimiento del jugador (opcional)
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_dir * 300
	move_and_slide()
	
	# Disparo con clic izquierdo del mouse
	if Input.is_action_just_pressed("ui_left_click"):
		shoot_mouse_direction()

func shoot_mouse_direction():
	# Obtener la posición del mouse en el mundo
	var mouse_pos = get_global_mouse_position()
	
	# Calcular dirección desde el jugador hacia el mouse
	var direction = (mouse_pos - global_position).normalized()
	
	# Instanciar la bala
	var bullet = bullet_scene.instantiate()
	
	# Posicionar la bala en la posición del jugador
	bullet.global_position = global_position
	
	# Establecer la dirección de la bala
	bullet.direction = direction
	bullet.speed = bullet_speed
	get_parent().add_child(bullet)
