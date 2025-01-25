extends Node2D

# Bubble settings
var bubbles = []
var bubble_spawn_interval = 1.0
var bubble_spawn_timer = 0.0
var bubble_speed = 100.0
var bubble = Area2D

# Circle radii
var base_radius = 50
var pulse_amplitude = 5
var pulse_speed = 2.0

# Swordfish (player)
var swordfish: CharacterBody2D
var dash_speed = 400.0
var dashing = false
var dash_target = Vector2()

# Dash settings
var rotation_angle = 0.0 # Swordfish's current rotation
var rotation_speed = 2.0 # Speed of the up-and-down motion
var max_rotation_angle = PI / 3 # Maximum angle for up-and-down motion (30 degrees)
var is_facing_left = false # Tracks the swordfish's facing direction

# Camera settings
var camera: Camera2D
var camera_speed = 20.0 # Pixels per second

# Time accumulator for animations
var time = 0.0

func _ready():
	set_process(true)
	# Reference the Swordfish and Camera2D nodes
	swordfish = $Swordfish
	camera = $Camera2D
	bubble = $Bubble

func _process(delta):
	time += delta

	# Move the camera upwards
	move_camera(delta)

	# Update bubbles
	bubble_spawn_timer += delta
	if bubble_spawn_timer >= bubble_spawn_interval:
		bubble_spawn_timer = 0.0
		spawn_bubble()

	for bubble in bubbles:
		bubble["position"].y -= bubble_speed * delta
		# Bubbles do not despawn anymore, but continue moving

	if not dashing:
		 # Adjust the rotation of the swordfish for up-and-down motion
		rotation_angle = sin(time * rotation_speed) * max_rotation_angle
		swordfish.rotation = rotation_angle * (-1 if is_facing_left else 1)
	else:
	# Calculate adjusted rotation
		var adjusted_rotation = swordfish.rotation
		if is_facing_left:
			adjusted_rotation += PI  # Mirror rotation for left-facing

	# Calculate dash direction
		var direction = Vector2(cos(adjusted_rotation), sin(adjusted_rotation)).normalized()

		# Move and check for collisions
		var collision = swordfish.move_and_collide(direction * dash_speed * delta)
		if collision:
		 # Handle collision (e.g., stop the dash, play an effect)
			dashing = false
			print("Collided with: ", collision.get_collider())
		else:
			# Check if dash target is reached
			if swordfish.position.distance_to(dash_target) < 5.0:
				swordfish.position = dash_target
				dashing = false




	# Check for collisions
	check_collisions()

	# Request a redraw of the scene
	queue_redraw()

func move_camera(delta):
	# Move the camera upwards
	camera.position.y -= camera_speed * delta

func spawn_bubble():
	# Spawn a new bubble at a random horizontal position at the bottom
	var position = Vector2(randi() % 800, camera.position.y + 300) # Spawn near the bottom of the view
	bubbles.append({"position": position, "time_offset": randi() % 100 / 100.0})

func check_collisions():
	for bubble in bubbles:
		if swordfish.position.distance_to(bubble["position"]) < base_radius + 10: # Adjust radius if needed
			print("Game Over!")
			get_tree().reload_current_scene()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE and not dashing:
			# Calculate adjusted rotation based on facing direction
			var adjusted_rotation = swordfish.rotation
			if is_facing_left:
				adjusted_rotation += PI  # Mirror rotation for left-facing

			# Calculate dash direction
			var direction = Vector2(cos(adjusted_rotation), sin(adjusted_rotation)).normalized()

			# Calculate dash target
			dash_target = swordfish.position + direction * 100  # Dash distance
			dashing = true
		elif event.keycode == KEY_LEFT:
			# Switch facing direction to left and flip swordfish
			is_facing_left = true
			swordfish.scale.x = -1  # Flip swordfish horizontally
		elif event.keycode == KEY_RIGHT:
			# Switch facing direction to right and reset swordfish flip
			is_facing_left = false
			swordfish.scale.x = 1  # Reset swordfish to normal orientation

func _draw():
	# Draw bubbles
	for b in bubbles:
		var radius = base_radius + sin((time + b["time_offset"]) * pulse_speed) * pulse_amplitude
		#draw_circle(bubble["position"], radius, Color(0.5, 0.5, 1))
		
