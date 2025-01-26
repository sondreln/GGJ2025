extends Area2D

signal fish_entered(bubble_position: Vector2)  # Signal to notify the main scene

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Swordfish":  # Check if the colliding body is the swordfish
		print("Fish in the bubble!")
		emit_signal("fish_entered", self.position)  # Emit the bubble's position
