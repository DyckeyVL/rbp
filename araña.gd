
extends CharacterBody2D

# ==========================================
# MOVIMIENTO
# ==========================================

@export_group("Movimiento")
@export var velocidad: float = 65.0
@export var aceleracion: float = 300.0
@export var gravedad: float = 980.0

# ==========================================
# SALTO
# ==========================================

@export_group("Salto")
@export var fuerza_salto: float = 300.0
@export var velocidad_salto: float = 180.0
@export var distancia_salto: float = 250.0
@export var tiempo_entre_saltos: float = 0.5

# ==========================================
# VIDA Y DAÑO
# ==========================================

@export_group("Vida y daño")
@export var vida_maxima: int = 30
@export var danio: int = 10

# ==========================================
# NODOS
# ==========================================

@onready var Anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Area2D2
@onready var hitbox: Area2D = $hitbox
@onready var colision: CollisionShape2D = $CollisionShape2D

# ==========================================
# VARIABLES
# ==========================================

var jugador: CharacterBody2D = null

var vida: int
var muriendo: bool = false
var derrotado: bool = false

var en_salto: bool = false
var temporizador_salto: float = 0.0

var posicion_inicial: Vector2


# ==========================================
# INICIALIZACIÓN
# ==========================================

func _ready() -> void:

	add_to_group("arañas")

	posicion_inicial = global_position
	vida = vida_maxima

	detection_area.monitoring = true
	hitbox.monitoring = false

	detection_area.body_entered.connect(_al_detectar_jugador)
	detection_area.body_exited.connect(_al_perder_jugador)

	hitbox.body_entered.connect(_al_golpear_jugador)

	Anim.play("caminar")

	print("ARAÑA: INICIALIZADA")


# ==========================================
# MOVIMIENTO PRINCIPAL
# ==========================================

func _physics_process(delta: float) -> void:

	if muriendo or derrotado:
		return

	temporizador_salto = maxf(
		temporizador_salto - delta,
		0.0
	)

	if not is_instance_valid(jugador):
		jugador = null
		hitbox.set_deferred("monitoring", false)

	if not is_on_floor():

		velocity.y += gravedad * delta

	else:

		if en_salto:

			en_salto = false
			temporizador_salto = tiempo_entre_saltos

		if jugador != null:

			var diferencia = jugador.global_position - global_position
			var direccion = diferencia.normalized()
			var distancia = diferencia.length()

			if distancia <= distancia_salto and temporizador_salto <= 0.0:

				_saltar_hacia_jugador(direccion)

			else:

				velocity.x = move_toward(
					velocity.x,
					direccion.x * velocidad,
					aceleracion * delta
				)

				if abs(velocity.x) > 1.0:
					Anim.flip_h = velocity.x < 0

		else:

			velocity.x = move_toward(
				velocity.x,
				0.0,
				aceleracion * delta
			)

	move_and_slide()

	# Detectar contacto físico con el jugador

	for i in get_slide_collision_count():

		var choque = get_slide_collision(i)
		var body = choque.get_collider()

		if body.is_in_group("jugador"):

			_golpear_jugador(body)
			return

	_actualizar_animacion()


# ==========================================
# SALTAR HACIA EL JUGADOR
# ==========================================

func _saltar_hacia_jugador(direccion: Vector2) -> void:

	en_salto = true

	velocity.y = -fuerza_salto
	velocity.x = direccion.x * velocidad_salto

	if abs(direccion.x) > 0.01:
		Anim.flip_h = direccion.x < 0

	print("ARAÑA: SALTANDO")


# ==========================================
# ANIMACIONES
# ==========================================

func _actualizar_animacion() -> void:

	if muriendo or derrotado:
		return

	if not is_on_floor():

		if Anim.animation != "saltar":
			Anim.play("saltar")

	else:

		if Anim.animation != "caminar":
			Anim.play("caminar")


# ==========================================
# DETECCIÓN DEL JUGADOR
# ==========================================

func _al_detectar_jugador(body: Node2D) -> void:

	if body.is_in_group("jugador") and not muriendo and not derrotado:

		jugador = body as CharacterBody2D

		hitbox.set_deferred("monitoring", true)

		print("ARAÑA: JUGADOR DETECTADO")


func _al_perder_jugador(body: Node2D) -> void:

	if body == jugador:

		jugador = null

		hitbox.set_deferred("monitoring", false)

		print("ARAÑA: JUGADOR PERDIDO")


# ==========================================
# CONTACTO CON EL JUGADOR
# ==========================================

func _golpear_jugador(body: Node2D) -> void:

	if muriendo or derrotado:
		return

	if not body.is_in_group("jugador"):
		return

	if body.has_method("recibir_danio"):

		body.recibir_danio(danio)

		print("ARAÑA: JUGADOR GOLPEADO -", danio, " PV")

	_morir()


func _al_golpear_jugador(body: Node2D) -> void:

	_golpear_jugador(body)


# ==========================================
# RECIBIR DAÑO
# ==========================================

func recibir_danio(cantidad: int) -> void:

	if muriendo or derrotado:
		return

	vida -= cantidad
	vida = clampi(vida, 0, vida_maxima)

	print("ARAÑA: VIDA RESTANTE ", vida)

	if vida <= 0:
		_morir()


# ==========================================
# MORIR
# ==========================================

func _morir() -> void:

	if muriendo or derrotado:
		return

	muriendo = true

	jugador = null
	velocity = Vector2.ZERO

	detection_area.set_deferred("monitoring", false)
	hitbox.set_deferred("monitoring", false)

	colision.set_deferred("disabled", true)

	Anim.stop()
	Anim.play("explosion")

	print("ARAÑA: EXPLOTANDO")

	await Anim.animation_finished

	derrotado = true

	add_to_group("enemigos_muertos")

	hide()

	set_physics_process(false)
	set_process(false)

	print("ARAÑA: DERROTADA")


# ==========================================
# REAPARECER
# ==========================================

func reiniciar_enemigo() -> void:

	if not derrotado:
		return

	global_position = posicion_inicial

	velocity = Vector2.ZERO

	vida = vida_maxima

	jugador = null

	muriendo = false
	derrotado = false

	en_salto = false
	temporizador_salto = 0.0

	show()

	colision.set_deferred("disabled", false)

	detection_area.set_deferred("monitoring", true)
	hitbox.set_deferred("monitoring", false)

	set_physics_process(true)
	set_process(true)

	Anim.play("caminar")

	remove_from_group("enemigos_muertos")

	print("ARAÑA: REAPARECIÓ CON ", vida, " PV")
