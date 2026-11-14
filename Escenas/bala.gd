
extends Area2D

@export var velocidad_bala: float = 400

var direccion: float = 1.0

@onready var colision: CollisionShape2D = $bala_colision
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:

	monitoring = true
	colision.disabled = false

	body_entered.connect(_on_body_entered)

	anim.play("mov_bala")


func _physics_process(delta: float) -> void:

	global_position.x += velocidad_bala * direccion * delta


func _on_body_entered(body: Node2D) -> void:

	print("BALA: CONTACTO CON ", body.name)

	# Detectar enemigos.
	if body.is_in_group("drones"):

		print("BALA: ENEMIGO DETECTADO")

		if body.has_method("recibir_danio"):
			body.recibir_danio(1)

		queue_free()
		return

	# Detectar terreno.
	if body is TileMapLayer:
		queue_free()
