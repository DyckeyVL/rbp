
extends CharacterBody2D

@export_group("Vida")
@export var vida_maxima: int = 1000
var vida_actual: int = 1000
var combate_activo: bool = false
var derrotado: bool = false

@export_group("Invocaciones")
@export var escena_dron: PackedScene
@export var escena_arana: PackedScene
@export var tiempo_invocacion: float = 10.0

@export_group("Interfaz")
@export var barra_vida: ProgressBar

@onready var Anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer_spawn: Timer = $TimerSpawn
@onready var punto_dron: Marker2D = $PuntoSpawnDron
@onready var punto_arana: Marker2D = $PuntoSpawnArana

func _ready() -> void:
	vida_actual = vida_maxima
	add_to_group("boss")

	# Animación inicial
	if Anim.sprite_frames.has_animation("default"):
		Anim.play("default")
	else:
		print("ERROR: No existe la animación default")

	# Configurar barra de vida
	if barra_vida != null:
		barra_vida.max_value = vida_maxima
		barra_vida.value = vida_actual
		barra_vida.visible = false

	# Configurar temporizador
	timer_spawn.wait_time = tiempo_invocacion
	timer_spawn.one_shot = false
	timer_spawn.timeout.connect(_invocar_enemigos)

	print("BOSS: PREPARADO")

func activar_combate() -> void:
	if combate_activo or derrotado:
		return

	combate_activo = true

	if barra_vida != null:
		barra_vida.visible = true

	timer_spawn.start()

	print("BOSS: COMBATE INICIADO")

func _invocar_enemigos() -> void:
	if derrotado:
		timer_spawn.stop()
		return

	# Determinar hacia dónde mira el Boss
	var direccion = -1 if Anim.flip_h else 1

	# Posición frente al Boss
	var posicion_frontal = global_position + Vector2(100 * direccion, 0)

	# Invocar 2 drones
	if escena_dron != null:
		for i in range(2):
			var nuevo_dron = escena_dron.instantiate()
			get_tree().current_scene.add_child(nuevo_dron)
			nuevo_dron.global_position = posicion_frontal + Vector2(i * 35 * direccion, 0)

	# Invocar 2 arañas
	if escena_arana != null:
		for i in range(2):
			var nueva_arana = escena_arana.instantiate()
			get_tree().current_scene.add_child(nueva_arana)
			nueva_arana.global_position = posicion_frontal + Vector2(i * 35 * direccion, 40)

	print("BOSS: INVOCÓ 2 DRONES Y 2 ARAÑAS")
	
func recibir_danio(cantidad: int) -> void:
	if derrotado:
		return

	vida_actual = maxi(vida_actual - cantidad, 0)

	if barra_vida != null:
		barra_vida.value = vida_actual

	print("BOSS: VIDA ", vida_actual)

	if vida_actual <= 0:
		_morir()

func _morir() -> void:
	if derrotado:
		return

	derrotado = true
	combate_activo = false
	timer_spawn.stop()

	if Anim.sprite_frames.has_animation("morir"):
		Anim.play("morir")
		await Anim.animation_finished

	if barra_vida != null:
		barra_vida.visible = false

	hide()
	set_physics_process(false)
	set_process(false)
	print("BOSS: DERROTADO")
