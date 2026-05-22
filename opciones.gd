extends Control

@onready var botonesopciones: VBoxContainer = $botonesopciones

@onready var volumen: Panel = $volumen


func _ready():
	pass
	botonesopciones.visible = true
	volumen.visible = false


func _on_atras_pressed() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")



func _on_volumen_pressed() -> void:
	botonesopciones.visible = false
	volumen.visible = true


func _on_atras_opciones_pressed() -> void:
	get_tree().change_scene_to_file("res://opciones.tscn")
