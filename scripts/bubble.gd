extends Area2D

signal bubble_dashed_to(center_position: Vector2)

func _on_body_entered(body):
	if body.name == "Swordfish":
		emit_signal("bubble_dashed_to", global_position)


func _on_bubble_dashed_to(center_position: Vector2) -> void:
	pass # Replace with function body.
