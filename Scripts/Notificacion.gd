extends Label

var duracion: float = 1.0
var velocidad_flotar: float = 50.0

func _ready():
	add_theme_font_size_override("font_size", 16)
	add_theme_color_override("font_color", Color.WHITE)
	
	# Animación de salida
	var tween = create_tween()
	tween.tween_property(self, "position", position - Vector2(0, 50), duracion)
	tween.parallel().tween_property(self, "modulate:a", 0, duracion)
	tween.tween_callback(queue_free)

func configurar(texto: String, color: Color = Color.WHITE, tamanio: int = 16):
	text = texto
	add_theme_color_override("font_color", color)
	add_theme_font_size_override("font_size", tamanio)
