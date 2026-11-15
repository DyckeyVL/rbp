
extends Area2D

var posicion_inicial: Vector2
var recogida: bool = false

func _ready() -> void:
	posicion_inicial = global_position
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("jugador"):
		return

	body.puede_disparar = true

	if body.has_method("cambiar_skin_bateria"):
		body.cambiar_skin_bateria()

	recogida = true
	hide()
	set_deferred("monitoring", false)

	print("BATERÍA RECOGIDA")

func reaparecer_bateria() -> void:
	if not recogida:
		return

	global_position = posicion_inicial
	show()
	set_deferred("monitoring", true)
	recogida = false

	print("BATERÍA REAPARECIÓ")
