extends Node2D

# Bubble settings
var bubbles = []
var bubble_spawn_interval = 1.0
var bubble_spawn_timer = 0.0
var bubble_speed = 100.0

# Circle radii
var base_radius = 50
var pulse_amplitude = 5
var pulse_speed = 2.0

# Swordfish (player)
var swordfish: CharacterBody2D
var dash_speed = 800.0
var dashing = false
var dash_target = Vector2()

# Arrow settings
var arrow_angle = 0.0
var arrow_speed = 2.0 # Rotation speed in radians per second

# Camera settings
var camera: Camera2D
var camera_speed = 50.0 # Pixels per second

# Time accumulator for animations
var time = 0.0

func _ready():
	set_process(true)
	# Reference the Swordfish and Camera2D nodes
	swordfish = $Swordfish
	camera = $Camera2D

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
		# Rotate the arrow around the swordfish
		arrow_angle += arrow_speed * delta
	else:
		# Dash the swordfish
		var direction = (dash_target - swordfish.position).normalized()
		swordfish.position += direction * dash_speed * delta
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
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if not dashing:
			# Start a dash in the arrow's direction
			var arrow_direction = Vector2(cos(arrow_angle), sin(arrow_angle))
			dash_target = swordfish.position + arrow_direction * 200 # Dash distance
			dashing = true

func _draw():
	# Draw bubbles
	for bubble in bubbles:
		var radius = base_radius + sin((time + bubble["time_offset"]) * pulse_speed) * pulse_amplitude
		draw_circle(bubble["position"], radius, Color(0.5, 0.5, 1))

	# Draw the rotating arrow
	if not dashing:
		var arrow_position = swordfish.position + Vector2(cos(arrow_angle), sin(arrow_angle)) * 30
		draw_triangle(arrow_position, 10, arrow_angle)

func draw_triangle(position, size, rotation):
	# Helper function to draw a triangular arrow
	var p1 = position + Vector2(cos(rotation), sin(rotation)) * size
	var p2 = position + Vector2(cos(rotation + 1.5), sin(rotation + 1.5)) * size * 0.5
	var p3 = position + Vector2(cos(rotation - 1.5), sin(rotation - 1.5)) * size * 0.5
	draw_polygon([p1, p2, p3], [Color(0.662745, 0.662745, 0.662745, 1)])
