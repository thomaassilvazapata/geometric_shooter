extends Control

@onready var botonesopciones: VBoxContainer = $botonesopciones

func _ready():
	botonesopciones.visible = true

func _on_atras_pressed() -> void:
	get_tree().change_scene_to_file("res://Escenas/opciones.tscn")

func _on_atras_opciones_pressed() -> void:
	get_tree().change_scene_to_file("res://Escenas/menu.tscn") 
