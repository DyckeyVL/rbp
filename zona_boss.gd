extends Area2D

@export var boss: Node2D
var activado: bool = false

func _ready() -> void:
	body_entered.connect(_al_entrar_jugador)

func _al_entrar_jugador(body: Node2D) -> void:
	if activado:
		return

	if not body.is_in_group("jugador"):
		return

	activado = true

	if boss != null:
		boss.activar_combate()

	print("ZONA BOSS: COMBATE ACTIVADO")
