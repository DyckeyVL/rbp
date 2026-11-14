
extends CharacterBody2D

@export_group("Movimiento")
@export var velocidad: float = 65.0
@export var aceleracion: float = 300.0
@export var gravedad: float = 980.0

@export_group("Salto")
@export var fuerza_salto: float = 300.0
@export var velocidad_salto: float = 180.0
@export var distancia_salto: float = 250.0
@export var tiempo_entre_saltos: float = 0.5

@export_group("Vida y daño")
@export var vida_maxima: int = 30
@export var danio: int = 15

@onready var Anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Area2D2
@onready var hitbox: Area2D = $hitbox
@onready var colision: CollisionShape2D = $CollisionShape2D

var jugador: CharacterBody2D = null
var vida: int
var muriendo: bool = false
var en_salto: bool = false
var temporizador_salto: float = 0.0


func _ready() -> void:

	vida = vida_maxima

	# La detección grande permanece activa.
	detection_area.monitoring = true

	# El hitbox pequeño empieza desactivado.
	hitbox.monitoring = false

	# Conectar señales.
	detection_area.body_entered.connect(_al_detectar_jugador)
	detection_area.body_exited.connect(_al_perder_jugador)

	hitbox.body_entered.connect(_al_golpear_jugador)

	Anim.play("caminar")

	print("ARAÑA: INICIALIZADA")


func _physics_process(delta: float) -> void:

	if muriendo:
		return

	temporizador_salto = maxf(temporizador_salto - delta, 0.0)

	if not is_instance_valid(jugador):
		jugador = null
		hitbox.set_deferred("monitoring", false)

	# Activar hitbox únicamente cuando existe un jugador detectado.
	if jugador != null:
		hitbox.set_deferred("monitoring", true)

	# Gravedad.
	if not is_on_floor():
		velocity.y += gravedad * delta

	else:

		if en_salto:
			en_salto = false
			temporizador_salto = tiempo_entre_saltos

		# Perseguir jugador.
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

	_actualizar_animacion()


func _saltar_hacia_jugador(direccion: Vector2) -> void:

	en_salto = true

	velocity.y = -fuerza_salto
	velocity.x = direccion.x * velocidad_salto

	if abs(direccion.x) > 0.01:
		Anim.flip_h = direccion.x < 0

	print("ARAÑA: SALTANDO")


func _actualizar_animacion() -> void:

	if muriendo:
		return

	if not is_on_floor():

		if Anim.animation != "saltar":
			Anim.play("saltar")

	else:

		if Anim.animation != "caminar":
			Anim.play("caminar")


# DETECCIÓN GRANDE

func _al_detectar_jugador(body: Node2D) -> void:

	if body is CharacterBody2D and not muriendo:

		jugador = body as CharacterBody2D

		print("ARAÑA: JUGADOR DETECTADO")


func _al_perder_jugador(body: Node2D) -> void:

	if body == jugador:

		jugador = null
		hitbox.set_deferred("monitoring", false)

		print("ARAÑA: JUGADOR PERDIDO")


# CONTACTO PEQUEÑO

func _al_golpear_jugador(body: Node2D) -> void:

	print("HITBOX DETECTÓ: ", body.name)

	if muriendo:
		return

	if jugador == null:
		return

	if body != jugador:
		return

	if not body.has_method("recibir_danio"):
		return

	print("CONTACTO CONFIRMADO")

	body.recibir_danio(danio)

	_morir()

	# Aplicar daño.
	body.recibir_danio(danio)

	# Explotar.
	_morir()


# VIDA

func recibir_danio(cantidad: int) -> void:

	if muriendo:
		return

	vida -= cantidad

	print("-15", vida)

	if vida <= 0:
		_morir()


# MUERTE

func _morir() -> void:

	if muriendo:
		return

	muriendo = true

	jugador = null
	velocity = Vector2.ZERO

	detection_area.set_deferred("monitoring", false)
	hitbox.set_deferred("monitoring", false)
	colision.set_deferred("disabled", true)

	Anim.stop()
	Anim.play("explosion")

	print("ARAÑA: explotando")

	await Anim.animation_finished

	print("ARAÑA: ELIMINADA	")

	queue_free()
