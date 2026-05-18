extends Area2D

## Valida si un proyectil impacta al jugador en un ángulo de aproximadamente 90°
## con respecto al radio que va desde el centro del juego hacia el jugador.

func is_peripheral_impact(
	player_position: Vector2,
	projectile_direction: Vector2,
	tolerance_degrees: float = 10.0
) -> bool:
	# Vector radio: desde el centro (0,0) hacia el jugador
	var radius_vector: Vector2 = player_position
	
	# Normalizar vectores
	var radius_normalized: Vector2 = radius_vector.normalized()
	var direction_normalized: Vector2 = projectile_direction.normalized()
	
	# Producto punto = cos(ángulo)
	var dot_product: float = radius_normalized.dot(direction_normalized)
	dot_product = clamp(dot_product, -1.0, 1.0)
	
	# Calcular ángulo y comparar con 90° ± tolerancia
	var angle_degrees: float = rad_to_deg(acos(dot_product))
	return abs(angle_degrees - 90.0) <= tolerance_degrees


## Versión más eficiente usando solo vectores (recomendada)
func is_peripheral_impact_fast(
	player_position: Vector2,
	projectile_direction: Vector2,
	tolerance_degrees: float = 10.0
) -> bool:
	var r: Vector2 = player_position.normalized()
	var d: Vector2 = projectile_direction.normalized()
	
	var dot_product: float = r.dot(d)
	var cos_tolerance: float = cos(deg_to_rad(90.0 - tolerance_degrees))
	
	return abs(dot_product) <= cos_tolerance


# Ejemplo de uso
func _ready() -> void:
	# Prueba: jugador en (100, 0), proyectil hacia arriba (0, 1)
	var resultado = is_peripheral_impact_fast(Vector2(100, 0), Vector2(0, 1))
	print(resultado)  # true (ángulo de 90°)
