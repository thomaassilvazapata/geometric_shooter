extends Area2D

@export var speed: float = 500.0
@export var direction: Vector2 = Vector2.RIGHT
@export var lifetime: float = 2.0

var current_lifetime: float = 0.0

func _ready():
	# Rotar la bala para que apunte en la dirección del movimiento
	rotation = direction.angle()
	
	# Opcional: Configurar la forma de la bala (como una línea)
	setup_bullet_shape()

func _process(delta):
	# Mover la bala
	global_position += direction * speed * delta
	
	# Temporizador de vida
	current_lifetime += delta
	if current_lifetime >= lifetime:
		queue_free()

func setup_bullet_shape():
	# Crear una línea visual para la bala
	var line = Line2D.new()
	line.width = 4
	line.default_color = Color.YELLOW
	line.add_point(Vector2(0, 0))
	line.add_point(Vector2(100, 0))  # Longitud de la línea
	add_child(line)
	
	# Colisión (opcional)
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(20, 6)
	collision.shape = rect_shape
	add_child(collision)

func _on_body_entered(body):
	# Manejar colisión con enemigos u otros objetos
	if body.has_method("take_damage"):
		body.take_damage()
	queue_free()
