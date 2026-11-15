
extends CharacterBody2D

# ==========================================
# MOVIMIENTO
# ==========================================

@export_group("Movimiento")
@export var speed: float = 100.0
@export var bonus_carrera: float = 50.0
@export var acceleration: float = 800.0
@export var deceleration: float = 1000.0

# ==========================================
# SALTO
# ==========================================

@export_group("Salto")
@export var jump_force: float = -200.0
@export var gravity: float = 400.0
@export var max_fall_speed: float = 900.0

var saltos_realizados: int = 0

# ==========================================
# CARRERA
# ==========================================

@export_group("Carrera")
@export var tiempo_carrera: float = 3.0

var corriendo: bool = false

# ==========================================
# VIDA
# ==========================================

@export_group("Vida")
@export var vida_maxima: int = 100

var vida_actual: int = 100

@onready var barra_vida: ProgressBar = $CanvasLayer/ProgressBar

var derrotado: bool = false
var punto_aparicion: Vector2

# ==========================================
# DISPARO
# ==========================================

@export_group("Disparo")
@export var bala: PackedScene
@export var intervalo_disparo: float = 1.0

var puede_disparar: bool = false
var tiempo_restante_disparo: float = 0.0

# ==========================================
# SKINS
# ==========================================

@export_group("Skins")
@export var skin_bateria: SpriteFrames
@export var skin_orbe: SpriteFrames

var skin_original: SpriteFrames
var tiene_bateria: bool = false

# ==========================================
# PODER DE LA ORBE
# ==========================================

@export_group("Poder de la orbe")
@export var bonus_velocidad_orbe: float = 60.0
@export var saltos_maximos: int = 2

var poder_orbe_activo: bool = false

# ==========================================
# NODOS
# ==========================================

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


# ==========================================
# INICIALIZACIÓN
# ==========================================

func _ready() -> void:

	add_to_group("jugador")

	Anim.play("idle")
	skin_original = Anim.sprite_frames

	se_mueve.connect(en_movimiento)
	no_se_mueve.connect(sin_movimiento)

	timer.one_shot = true
	timer.timeout.connect(_al_terminar_tiempo)

	vida_actual = vida_maxima

	barra_vida.max_value = vida_maxima
	barra_vida.value = vida_actual
	barra_vida.show_percentage = false
	barra_vida.position = Vector2(20, 20)
	barra_vida.size = Vector2(250, 24)
	
	punto_aparicion = global_position


# ==========================================
# MOVIMIENTO PRINCIPAL
# ==========================================

func _physics_process(delta: float) -> void:
	
	if derrotado:
		return

	tiempo_restante_disparo = maxf(
		tiempo_restante_disparo - delta,
		0.0
	)

	var dir: float = Input.get_axis("izquierda", "derecha")

	moviendo = not is_zero_approx(dir)

	var velocidad_objetivo: float = speed

	if corriendo:
		velocidad_objetivo += bonus_carrera

	# Bonus de velocidad de la orbe
	if poder_orbe_activo:
		velocidad_objetivo += bonus_velocidad_orbe

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

	# Dirección del personaje
	if dir > 0:
		Anim.flip_h = false
	elif dir < 0:
		Anim.flip_h = true

	# ======================================
	# SALTO Y DOBLE SALTO
	# ======================================

	if is_on_floor():
		saltos_realizados = 0
	else:
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)

	if Input.is_action_just_pressed("salto"):

		var limite_saltos: int = 1

		if poder_orbe_activo:
			limite_saltos = saltos_maximos

		if saltos_realizados < limite_saltos:

			velocity.y = jump_force
			saltos_realizados += 1

	move_and_slide()

	actualizar_animaciones()

	# ======================================
	# DISPARAR
	# ======================================

	if Input.is_action_just_pressed("disparar"):

		if puede_disparar and tiempo_restante_disparo <= 0.0:
			disparar()


# ==========================================
# DISPAROS
# ==========================================

func disparar() -> void:

	if bala == null:
		print("ERROR: No has asignado la escena de la bala")
		return

	var nueva_bala = bala.instantiate()

	if nueva_bala == null:
		print("ERROR: No se pudo crear la bala")
		return

	var direccion_disparo: float = -1.0 if Anim.flip_h else 1.0

	nueva_bala.set("direccion", direccion_disparo)

	get_parent().add_child(nueva_bala)

	nueva_bala.global_position = global_position + Vector2(
		24.0 * direccion_disparo,
		0.0
	)

	tiempo_restante_disparo = intervalo_disparo

	print("BALA CREADA")


# ==========================================
# CARRERA
# ==========================================

func en_movimiento() -> void:

	corriendo = false
	timer.start(tiempo_carrera)


func sin_movimiento() -> void:

	timer.stop()
	corriendo = false


func _al_terminar_tiempo() -> void:

	if moviendo:
		corriendo = true


# ==========================================
# ANIMACIONES
# ==========================================

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


# ==========================================
# CAMBIO DE SKIN
# ==========================================

func actualizar_skin() -> void:

	if poder_orbe_activo and skin_orbe != null:
		Anim.sprite_frames = skin_orbe

	elif tiene_bateria and skin_bateria != null:
		Anim.sprite_frames = skin_bateria

	else:
		Anim.sprite_frames = skin_original

	# Reiniciar animación para aplicar la nueva apariencia
	Anim.play("idle")


# ==========================================
# BATERÍA
# ==========================================

func cambiar_skin_bateria() -> void:

	if tiene_bateria:
		return

	tiene_bateria = true

	actualizar_skin()

	print("BATERÍA: SKIN ACTIVADA")


# ==========================================
# PODER DE LA ORBE
# ==========================================

func activar_orbe() -> void:

	if poder_orbe_activo:
		return

	poder_orbe_activo = true

	actualizar_skin()

	print("ORBE: DOBLE SALTO DESBLOQUEADO")
	print("ORBE: VELOCIDAD MEJORADA")
	print("ORBE: NUEVA SKIN ACTIVADA")


# ==========================================
# RECIBIR DAÑO
# ==========================================

func recibir_danio(cantidad: int) -> void:

	if vida_actual <= 0 or derrotado:
		return

	vida_actual -= cantidad
	vida_actual = clampi(vida_actual, 0, vida_maxima)

	barra_vida.value = vida_actual

	print("VIDA DEL JUGADOR: ", vida_actual)

	if vida_actual <= 0:
		reaparecer()

func reaparecer() -> void:

	derrotado = true

	# Detener movimiento
	velocity = Vector2.ZERO

	# Regresar al inicio
	global_position = punto_aparicion

	# Recuperar vida
	vida_actual = vida_maxima
	barra_vida.value = vida_actual

	# Reiniciar animación
	Anim.play("idle")

	derrotado = false

	print("JUGADOR: REAPARECIÓ")
	
	# Revivir todos los enemigos derrotados
	var enemigos = get_tree().get_nodes_in_group("enemigos_muertos")

	for enemigo in enemigos:

		if enemigo.has_method("reiniciar_enemigo"):
			enemigo.reiniciar_enemigo()

func recuperar_vida(cantidad: int) -> void:
	vida_actual += cantidad
	vida_actual = mini(vida_actual, vida_maxima)

	if barra_vida != null:
		barra_vida.value = vida_actual

	print("JUGADOR: +", cantidad, " PV")
	
	for bateria in get_tree().get_nodes_in_group("baterias"):
		if bateria.has_method("reaparecer_bateria"):
			bateria.reaparecer_bateria()
