extends Node2D

# Bubble settings
var bubbles = []
var bubble_spawn_interval = 1.0
var bubble_spawn_timer = 0.0
var bubble_speed = 100.0
var bubble_scene: PackedScene

# Circle radii
var base_radius = 50
var pulse_amplitude = 5
var pulse_speed = 2.0

# Swordfish (player)
var swordfish: CharacterBody2D
var dash_speed = 400.0
var dashing = false
var dash_target = Vector2()
var dash_power = 0.0
var max_dash_power = 2.0  # Max time for holding space to charge dash
var is_charging_dash = false

# Camera settings
var camera: Camera2D
var camera_speed = 40.0 # Pixels per second

# Time accumulator for animations
var time = 0.0

# Gravity stuff
var gravity = 300.0  # Adjust the gravity strength as needed
var vertical_velocity = 0.0  # Swordfish's current vertical velocity


func _ready():
	set_process(true)
	# Reference the Swordfish and Camera2D nodes
	swordfish = $Swordfish
	camera = $Camera2D

	# Load the bubble scene
	bubble_scene = preload("res://scenes/Bubble.tscn")  # Path to your Bubble.tscn

func _process(delta):
	time += delta
	if is_charging_dash:
		# Increase dash power while the spacebar is held, clamped to the maximum power
		dash_power = clamp(dash_power + delta * 2, 0.0, max_dash_power)
	
	if swordfish.position.y < -1700 and not dashing:
		vertical_velocity += gravity * delta  # Apply gravity
		swordfish.position.y += vertical_velocity * delta
	else:
		vertical_velocity = 0.0  # Reset vertical velocity when above the threshold or during a dash

	# Move the camera upwards
	move_camera(delta)

	# Update bubbles
	bubble_spawn_timer += delta
	var y_pos_sf = swordfish.position.y
	if y_pos_sf > -1500:
		if bubble_spawn_timer >= bubble_spawn_interval:
			bubble_spawn_timer = 0.0
			spawn_bubble()
			print(y_pos_sf)

	for bubble in bubbles:
		bubble.position.y -= bubble_speed * delta
		# Remove bubbles that go off-screen
		if bubble.position.y < camera.position.y - 300:
			bubble.queue_free()
			bubbles.erase(bubble)

	if dashing:
		# Calculate the direction to the dash target
		print(dash_target)
		var direction = (dash_target - swordfish.position).normalized()

		# Rotate swordfish to point in the dash direction
		swordfish.rotation = direction.angle()

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

	if not dashing and not is_charging_dash:
		# Reset swordfish to horizontal idle position (facing right)
		swordfish.rotation = 0.0

	# Check for collisions
	check_collisions()
	
	queue_redraw()

func move_camera(delta):
	# Check if the camera has reached the height where gravity starts
	if camera.position.y < -1600:
		var target_y = swordfish.position.y
		camera.position.y = lerp(camera.position.y, target_y, 0.1)  # Smoothly follow the swordfish
	else:
		# Move the camera upwards at a fixed speed
		camera.position.y -= camera_speed * delta


func spawn_bubble():
	# Spawn a new bubble instance
	var bubble_instance = bubble_scene.instantiate()
	bubble_instance.position = Vector2(randi() % 800, camera.position.y + 300)  # Random horizontal position
	add_child(bubble_instance)
	bubbles.append(bubble_instance)

func check_collisions():
	for bubble in bubbles:
		if swordfish.position.distance_to(bubble.position) < base_radius + 10:  # Adjust radius if needed
			print("Game Over!")
			get_tree().reload_current_scene()

func _input(event):
	if event is InputEventKey and event.keycode == KEY_SPACE:
		if event.pressed:
			is_charging_dash = true
		else:
			is_charging_dash = false
			# Calculate the dash distance based on the charge power
			var dash_distance = dash_power * 200.0  # Scale the power to a meaningful dash distance

			# Reset the dash power
			dash_power = 0.0

			# Get the world position of the mouse
			var mouse_position = camera.get_global_mouse_position()

			# Calculate dash target based on the dash distance
			var direction = (mouse_position - swordfish.position).normalized()
			dash_target = swordfish.position + direction * dash_distance
			dashing = true

			# Determine if the swordfish should face left or right
			var is_facing_left = dash_target.x < swordfish.position.x
			swordfish.scale.x = -1 if is_facing_left else 1

func _draw():
	# Draw the dash power bar above the swordfish
	var bar_width = 100
	var bar_height = 10
	var bar_position = swordfish.position + Vector2(-bar_width / 2, -50)
	var fill_width = (dash_power / max_dash_power) * bar_width
	
	# Draw the background of the bar
	draw_rect(Rect2(bar_position, Vector2(bar_width, bar_height)), Color(0.2, 0.2, 0.2))

	# Draw the filled portion of the bar
	draw_rect(Rect2(bar_position, Vector2(fill_width, bar_height)), Color(0.8, 0.8, 1.0))
