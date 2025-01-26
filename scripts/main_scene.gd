extends Node2D

# Bubble settings
var bubbles = []
var bubble_spawn_interval = 1.0
var bubble_spawn_timer = 0.0
var bubble_speed = 100.0
var bubble_scene: PackedScene

# Reference to all manually placed bubbles
var manual_bubbles: Array = []

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

# Sounds
var charge1: AudioStreamPlayer2D
var wiii: AudioStreamPlayer2D

# Time accumulator for animations
var time = 0.0

# Gravity stuff
var gravity = 300.0  # Adjust the gravity strength as needed
var vertical_velocity = 0.0  # Swordfish's current vertical velocity

# Track whether swordfish is inside *any* bubble
var fish_in_bubble = false


func _ready():
	set_process(true)
	# Reference the Swordfish and Camera2D nodes
	swordfish = $Swordfish
	camera = $Camera2D
	charge1 = $Charge1
	wiii = $Wiii

	# Load the bubble scene for spawning
	bubble_scene = preload("res://scenes/Bubble.tscn")  # Adjust path if needed

	# Collect all manually placed bubbles (Bubble1 to Bubble8) into an array
	for i in range(1, 9):  # 1 through 8
		var node_name = "Bubble%d" % i
		if has_node(node_name):
			var bubble_node = get_node(node_name)
			manual_bubbles.append(bubble_node)
		else:
			print("Warning: No node named %s found in scene." % node_name)


func _process(delta):
	time += delta

	if is_charging_dash:
		# Increase dash power while the spacebar is held, clamped to the maximum power
		dash_power = clamp(dash_power + delta * 2, 0.0, max_dash_power)

	# Only apply gravity if swordfish is NOT in a bubble, below -1700, and not dashing
	if not fish_in_bubble and swordfish.position.y < -1700 and not dashing:
		vertical_velocity += gravity * delta
		swordfish.position.y += vertical_velocity * delta
	else:
		vertical_velocity = 0.0  # Reset vertical velocity

	# Move the camera upwards
	move_camera(delta)

	# Spawn new bubbles automatically
	bubble_spawn_timer += delta
	var y_pos_sf = swordfish.position.y
	if y_pos_sf > -1500:
		if bubble_spawn_timer >= bubble_spawn_interval:
			bubble_spawn_timer = 0.0
			spawn_bubble()
			print(y_pos_sf)

	# Update positions of spawned bubbles
	for bubble in bubbles:
		bubble.position.y -= bubble_speed * delta
		# Remove bubbles that go off-screen
		if bubble.position.y < camera.position.y - 300:
			bubble.queue_free()
			bubbles.erase(bubble)

	# Dashing logic
	if dashing:
		var direction = (dash_target - swordfish.position).normalized()
		swordfish.rotation = direction.angle()

		var collision = swordfish.move_and_collide(direction * dash_speed * delta)
		if collision:
			dashing = false
		else:
			if swordfish.position.distance_to(dash_target) < 5.0:
				swordfish.position = dash_target
				dashing = false
				fish_in_bubble = false


	if not dashing and not is_charging_dash:
		# Reset swordfish to horizontal idle position (facing right)
		swordfish.rotation = 0.0
		

	# Check collisions with:
	# 1) Spawned bubbles
	# 2) Manually placed bubbles (Bubble1 to Bubble8)
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
	# Check collisions with auto-spawned bubbles first
	for bubble in bubbles:
		if swordfish.position.distance_to(bubble.position) < base_radius + 10:
			print("Game Over!")
			get_tree().reload_current_scene()

	# Now check collisions with manually placed bubbles
	if not fish_in_bubble:  # Only do this if we're not already in a bubble
		for bubble_node in manual_bubbles:
			if bubble_node and swordfish.position.distance_to(bubble_node.position) < base_radius + 10:
				# Center the fish in this bubble
				swordfish.position = bubble_node.position
				fish_in_bubble = true
				print("Fish entered %s!" % bubble_node.name)
				break  # We found a bubble, no need to keep checking


func _input(event):
	if event is InputEventKey and event.keycode == KEY_SPACE:
		if event.pressed:
			if not charge1.playing:
				charge1.play()  # Start playing the sound
			is_charging_dash = true
		else:
			is_charging_dash = false
			if charge1.playing:
				charge1.stop()  # Stop the sound
			wiii.play()

			# Calculate the dash distance based on the charge power
			var dash_distance = dash_power * 200.0
			dash_power = 0.0

			# If the fish is currently inside *any* bubble, we allow dashing out
			if fish_in_bubble:
				fish_in_bubble = false
				print("Dashing out of the bubble!")

			# Proceed with normal dash logic
			var mouse_position = camera.get_global_mouse_position()
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
