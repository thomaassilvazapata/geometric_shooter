extends Node

var musica_menu: AudioStreamPlayer
var musica_juego: AudioStreamPlayer
var escena_actual: String = ""

@export var musica_menu_stream: AudioStream = preload("res://audio/menu_geodefense.ogg")
@export var musica_juego_stream: AudioStream = preload("res://audio/geodefense.ogg")

func _ready():
	get_tree().debug_collisions_hint = true
	
	musica_menu = AudioStreamPlayer.new()
	musica_juego = AudioStreamPlayer.new()
	
	musica_menu.volume_db = 0
	musica_juego.volume_db = 0
	
	musica_menu.stream = musica_menu_stream
	musica_juego.stream = musica_juego_stream
	
	add_child(musica_menu)
	add_child(musica_juego)

func _process(_delta):
	var escena = get_tree().current_scene
	if escena != null and escena.name != escena_actual:
		escena_actual = escena.name
		_actualizar_musica()

func _actualizar_musica():
	if escena_actual == "menu" or escena_actual == "opciones":
		_reproducir_musica_menu()
	elif escena_actual == "Mundo":
		_reproducir_musica_juego()

func _reproducir_musica_menu():
	if musica_juego.playing:
		musica_juego.stop()
	
	if not musica_menu.playing:
		musica_menu.play()

func _reproducir_musica_juego():
	if musica_menu.playing:
		musica_menu.stop()
	
	if not musica_juego.playing:
		musica_juego.play()

func _detener_todas():
	if musica_menu.playing:
		musica_menu.stop()
	if musica_juego.playing:
		musica_juego.stop()

func set_volumen_menu(volumen: float):
	musica_menu.volume_db = volumen

func set_volumen_juego(volumen: float):
	musica_juego.volume_db = volumen
