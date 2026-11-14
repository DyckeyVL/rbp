extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name.to_lower() == "personaje":
		body.puede_disparar = true
		get_parent().queue_free()
