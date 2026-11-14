extends CharacterBody2D

@export_group("Movimiento")
@export var speed: float = 125.0
@export var bonus_carrera: float = 50.0
@export var acceleration: float = 900.0
@export var deceleration: float = 1200.0

@export_group("Salto")
@export var jump_force: float = -200.0
@export var gravity: float = 400.0
@export var max_fall_speed: float = 900.0

@export_group("Carrera")
@export var tiempo_carrera: float = 3.0

@export_group("Vida")
@export var vida_maxima: int = 100
var vida_actual: int = 100

@export_group("Disparo")
@export var bala: PackedScene
@export var intervalo_disparo: float = 1.0

var puede_disparar: bool = false
var tiempo_restante_disparo: float = 0.0

@onready var barra_vida: ProgressBar = $CanvasLayer/ProgressBar
@onready var Anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer

signal no_se_mueve
signal se_mueve

var moviendo: bool = false:
	set(valor):
		if valor != moviendo:
			moviendo = valor
			if moviendo:
				se_mueve.emit()
			else:
				no_se_mueve.emit()

var corriendo: bool = false


func _ready() -> void:
	Anim.play("idle")

	se_mueve.connect(en_movimiento)
	no_se_mueve.connect(sin_movimiento)

	timer.one_shot = true
	timer.timeout.connect(_al_terminar_tiempo)

	barra_vida.max_value = vida_maxima
	barra_vida.value = vida_actual
	barra_vida.show_percentage = false
	barra_vida.position = Vector2(20, 20)
	barra_vida.size = Vector2(250, 24)
	
	add_to_group("jugador")


func _physics_process(delta: float) -> void:

	# Tiempo de espera entre disparos
	tiempo_restante_disparo = maxf(
		tiempo_restante_disparo - delta, 0.0
	)

	var dir: float = Input.get_axis("izquierda", "derecha")

	moviendo = not is_zero_approx(dir)

	var velocidad_objetivo: float = speed

	if corriendo:
		velocidad_objetivo += bonus_carrera

	if moviendo:
		velocity.x = move_toward(
			velocity.x,
			dir * velocidad_objetivo,
			acceleration * delta
		)
	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			deceleration * delta
		)

	# Dirección hacia donde mira el personaje
	if dir > 0:
		Anim.flip_h = false
	elif dir < 0:
		Anim.flip_h = true

	# Salto
	if Input.is_action_just_pressed("salto") and is_on_floor():
		velocity.y = jump_force
	elif not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)

	move_and_slide()

	actualizar_animaciones()

	# Disparo
	if Input.is_action_just_pressed("disparar"):
		if puede_disparar and tiempo_restante_disparo <= 0.0:
			disparar()


func disparar() -> void:

	if bala == null:
		print("ERROR: No has asignado la escena de la bala")
		return

	var nueva_bala = bala.instantiate()

	if nueva_bala == null:
		print("ERROR: No se pudo crear la bala")
		return

	# Si mira a la izquierda, dirección -1.
	# Si mira a la derecha, dirección 1.
	var direccion_disparo: float = -1.0 if Anim.flip_h else 1.0

	nueva_bala.set("direccion", direccion_disparo)

	get_parent().add_child(nueva_bala)

	# Aparece delante del personaje
	nueva_bala.global_position = global_position + Vector2(
		24.0 * direccion_disparo, 0.0
	)

	# Esperar un segundo antes del siguiente disparo
	tiempo_restante_disparo = intervalo_disparo

	print("BALA CREADA")


func en_movimiento() -> void:
	corriendo = false
	timer.start(tiempo_carrera)


func sin_movimiento() -> void:
	timer.stop()
	corriendo = false


func _al_terminar_tiempo() -> void:
	if moviendo:
		corriendo = true


func actualizar_animaciones() -> void:
	if not is_on_floor():
		if Anim.animation != "saltar":
			Anim.play("saltar")
	elif abs(velocity.x) > 5.0:
		if Anim.animation != "correr":
			Anim.play("correr")
	else:
		if Anim.animation != "idle":
			Anim.play("idle")


func recibir_danio(cantidad: int) -> void:
	if vida_actual <= 0:
		return

	vida_actual -= cantidad
	vida_actual = clampi(vida_actual, 0, vida_maxima)
	barra_vida.value = vida_actual

	if vida_actual == 0:
		print("Jugador derrotado")
