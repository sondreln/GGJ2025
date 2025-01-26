extends AnimatedSprite2D

var direction: Vector2 = Vector2(1, 0)  # Default movement direction
var speed: float = 200.0  # Default movement speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += direction * speed * delta
