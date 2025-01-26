extends Node2D

var seagull: AnimatedSprite2D
var start_position: Vector2
var end_position: Vector2
var speed: float = 200.0  # Speed of movement
var moving_right: bool = true  # Direction of movement

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	seagull = $Seagull
	
	# Define start and end positions for the movement
	start_position = Vector2(391, -2350)  # Adjust as needed
	end_position = Vector2(-92, -2350)   # Adjust as needed
	
	# Initialize the seagull's position
	seagull.position = start_position
	
	# Start the flying animation if available
	seagull.play("default")  # Replace "default" with your animation name

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Move the seagull back and forth on the x-axis
	if moving_right:
		seagull.position.x += speed * delta
		if seagull.position.x >= start_position.x:  # Reached the right boundary
			moving_right = false
			seagull.scale.x = 1  # Flip horizontally to face left
	else:
		seagull.position.x -= speed * delta
		if seagull.position.x <= end_position.x:  # Reached the left boundary
			moving_right = true
			seagull.scale.x = -1  # Reset flip to face right
