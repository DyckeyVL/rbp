
extends CharacterBody2D

# ==========================================
# PERSECUCIÓN
# ==========================================

@export_group("Persecución")
@export var chase_speed: float = 130.0
@export var acceleration: float = 400.0
@export var stop_distance: float = 35.0

# ==========================================
# VIDA
# ==========================================

@export_group("Vida")
@export var vida_maxima: int = 30

var vida: int = 30

# ==========================================
# DAÑO
# ==========================================

@export_group("Daño")
@export var danio: int = 10

# ==========================================
# NODOS
# ==========================================

@onready var Anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Area2D
@onready var hitbox: Area2D = $Area2D2
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

# ==========================================
# VARIABLES
# ==========================================

var jugador: CharacterBody2D = null

var muriendo: bool = false
var derrotado: bool = false

var posicion_inicial: Vector2


# ==========================================
# INICIALIZACIÓN
# ==========================================

func _ready() -> void:

	add_to_group("drones")

	posicion_inicial = global_position
	vida = vida_maxima

	detection_area.monitoring = true
	hitbox.monitoring = false

	detection_area.body_entered.connect(_al_detectar_jugador)
	detection_area.body_exited.connect(_al_perder_jugador)

	hitbox.body_entered.connect(_al_golpear_jugador)

	navigation_agent_2d.path_desired_distance = 4.0
	navigation_agent_2d.target_desired_distance = stop_distance

	Anim.play("mover")


# ==========================================
# MOVIMIENTO Y PERSECUCIÓN
# ==========================================

func _physics_process(delta: float) -> void:

	if muriendo or derrotado:
		return

	if not is_instance_valid(jugador):
		jugador = null

	if jugador == null:
		velocity = velocity.move_toward(
			Vector2.ZERO,
			acceleration * delta
		)

		move_and_slide()
		return

	var distancia = global_position.distance_to(
		jugador.global_position
	)

	if distancia > stop_distance:

		var direccion = global_position.direction_to(
			jugador.global_position
		)

		velocity = velocity.move_toward(
			direccion * chase_speed,
			acceleration * delta
		)

	else:

		velocity = velocity.move_toward(
			Vector2.ZERO,
			acceleration * delta
		)

	if abs(velocity.x) > 1.0:
		Anim.flip_h = velocity.x < 0

	move_and_slide()

	# Detectar contacto físico con el jugador

	for i in get_slide_collision_count():

		var colision = get_slide_collision(i)
		var body = colision.get_collider()

		if body.is_in_group("jugador"):

			if body.has_method("recibir_danio"):
				body.recibir_danio(danio)

			_morir()
			return


# ==========================================
# DETECTAR JUGADOR
# ==========================================

func _al_detectar_jugador(body: Node2D) -> void:

	if muriendo or derrotado:
		return

	if not body.is_in_group("jugador"):
		return

	jugador = body as CharacterBody2D

	print("DRON: JUGADOR DETECTADO")


func _al_perder_jugador(body: Node2D) -> void:

	if body == jugador:

		jugador = null

		hitbox.set_deferred("monitoring", false)

		print("DRON: JUGADOR PERDIDO")


# ==========================================
# GOLPEAR JUGADOR
# ==========================================

func _al_golpear_jugador(body: Node2D) -> void:

	if muriendo or derrotado:
		return

	if not body.is_in_group("jugador"):
		return

	if body.has_method("recibir_danio"):

		body.recibir_danio(danio)

		print("DRON: JUGADOR GOLPEADO -", danio, " PV")

	_morir()


# ==========================================
# RECIBIR DAÑO
# ==========================================

func recibir_danio(cantidad: int) -> void:
	if muriendo or derrotado:
		return

	vida -= cantidad
	vida = maxi(vida, 0)

	if vida <= 0:
		var jugador = get_tree().get_first_node_in_group("jugador")

		if jugador != null:
			jugador.recuperar_vida(5)

		_morir()

# ==========================================
# MORIR
# ==========================================

func _morir() -> void:

	if muriendo or derrotado:
		return

	print("DRON: ESTÁ MURIENDO")

	muriendo = true

	jugador = null
	velocity = Vector2.ZERO

	detection_area.set_deferred("monitoring", false)
	hitbox.set_deferred("monitoring", false)

	$CollisionShape2D.set_deferred("disabled", true)

	Anim.play("morir")

	await Anim.animation_finished

	derrotado = true

	add_to_group("enemigos_muertos")

	hide()

	set_physics_process(false)
	set_process(false)

	print("DRON: DERROTADO")


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

	derrotado = false
	muriendo = false

	show()

	$CollisionShape2D.set_deferred("disabled", false)

	detection_area.set_deferred("monitoring", true)
	hitbox.set_deferred("monitoring", false)

	set_physics_process(true)
	set_process(true)

	Anim.play("mover")

	remove_from_group("enemigos_muertos")

	print("DRON: REAPARECIÓ CON ", vida, " PV")
