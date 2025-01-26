extends Node2D

var seagull_template: AnimatedSprite2D
var spawn_interval: float = 2.0  # Time between spawns
var spawn_timer: float = 0.0
var speed_range: Vector2 = Vector2(150, 300)  # Random speed range

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	seagull_template = $Seagull
	seagull_template.visible = false  # Hide the template node

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_seagull()

	# Clean up seagulls that are out of bounds
	for seagull in get_children():
		if seagull != seagull_template:  # Ignore the template
			if seagull.position.x > 800 or seagull.position.x < -800:  # Adjust bounds as needed
				seagull.queue_free()

func spawn_seagull() -> void:
	# Duplicate the template node
	var seagull_instance = seagull_template.duplicate()
	seagull_instance.visible = true  # Make the duplicate visible
	add_child(seagull_instance)

	# Randomize y position
	var y_position = randf_range(-3500, -2300)

	# Determine if it spawns from the left or right
	var from_left = randf() < 0.5

	# Set position and direction
	if from_left:
		seagull_instance.position = Vector2(-800, y_position)  # Start off-screen to the left
		seagull_instance.set("direction", Vector2(1, 0))  # Move to the right
		seagull_instance.scale.x = -1  # Face right
	else:
		seagull_instance.position = Vector2(800, y_position)  # Start off-screen to the right
		seagull_instance.set("direction", Vector2(-1, 0))  # Move to the left
		seagull_instance.scale.x = 1  # Face left

	# Set random speed
	seagull_instance.set("speed", randf_range(speed_range.x, speed_range.y))
