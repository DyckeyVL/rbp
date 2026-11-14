extends Area2D

func _ready() -> void:
	body_entered.connect(_al_tocar_jugador)

func _al_tocar_jugador(body: Node2D) -> void:

	if not body.is_in_group("jugador"):
		return

	print("ORBE RECOGIDO: CERRANDO JUEGO")

	get_tree().quit()
