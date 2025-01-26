extends Node2D

var bubbles = []
var bubble_spawn_interval = 1.0
var bubble_spawn_timer = 0.0
var bubble_speed = 100.0
var bubble_scene: PackedScene

var manual_bubbles: Array = []

var base_radius = 50
var pulse_amplitude = 5
var pulse_speed = 2.0

var swordfish: CharacterBody2D
var dash_speed = 400.0
var dashing = false
var dash_target = Vector2()
var dash_power = 0.0
var max_dash_power = 2.0
var is_charging_dash = false

var camera: Camera2D
var camera_speed = 40.0

var time = 0.0

var gravity = 300.0
var vertical_velocity = 0.0

var fish_in_bubble = false

# Sounds
var wii: AudioStreamPlayer2D
var charge: AudioStreamPlayer2D

func _ready():
	set_process(true)
	swordfish = $Swordfish
	camera = $Camera2D
	wii = $Wii
	charge = $Charge

	bubble_scene = preload("res://scenes/Bubble.tscn")  

	for i in range(1, 9):
		var node_name = "Bubble%d" % i
		if has_node(node_name):
			var bubble_node = get_node(node_name)
			manual_bubbles.append(bubble_node)
		else:
			print("Warning: No node named %s found in scene." % node_name)

func _process(delta):
	time += delta
	
	### ADDED ###
	# Make the audio players follow the camera
	wii.position = camera.position
	charge.position = camera.position
	### END ADDED ###

	if is_charging_dash:
		dash_power = clamp(dash_power + delta * 2, 0.0, max_dash_power)
	else:
		charge.stop()

	if not fish_in_bubble and swordfish.position.y < -1700 and not dashing:
		vertical_velocity += gravity * delta
		swordfish.position.y += vertical_velocity * delta
	else:
		vertical_velocity = 0.0

	move_camera(delta)

	bubble_spawn_timer += delta
	var y_pos_sf = swordfish.position.y
	if y_pos_sf > -1500:
		if bubble_spawn_timer >= bubble_spawn_interval:
			bubble_spawn_timer = 0.0
			spawn_bubble()
			print(y_pos_sf)

	for bubble in bubbles:
		bubble.position.y -= bubble_speed * delta
		if bubble.position.y < camera.position.y - 300:
			bubble.queue_free()
			bubbles.erase(bubble)

	if dashing:
		if not wii.playing:
			wii.play()
		var direction = (dash_target - swordfish.position).normalized()
		swordfish.rotation = direction.angle()
		var collision = swordfish.move_and_collide(direction * dash_speed * delta)
		if collision:
			dashing = false
			print("Collided with: ", collision.get_collider())
		else:
			if swordfish.position.distance_to(dash_target) < 5.0:
				swordfish.position = dash_target
				dashing = false
				fish_in_bubble = false

	if not dashing and not is_charging_dash:
		if wii.playing:
			wii.stop()
		swordfish.rotation = 0.0

	check_collisions()

	queue_redraw()

func move_camera(delta):
	if camera.position.y < -1600:
		var target_y = swordfish.position.y
		camera.position.y = lerp(camera.position.y, target_y, 0.1)
	else:
		camera.position.y -= camera_speed * delta

func spawn_bubble():
	var bubble_instance = bubble_scene.instantiate()
	bubble_instance.position = Vector2(randi() % 800, camera.position.y + 300)
	add_child(bubble_instance)
	bubbles.append(bubble_instance)

func check_collisions():
	for bubble in bubbles:
		if swordfish.position.distance_to(bubble.position) < base_radius + 10:
			print("Game Over!")
			get_tree().reload_current_scene()

	if not fish_in_bubble:
		for bubble_node in manual_bubbles:
			if bubble_node and swordfish.position.distance_to(bubble_node.position) < base_radius + 10:
				swordfish.position = bubble_node.position
				fish_in_bubble = true
				print("Fish entered %s!" % bubble_node.name)
				break

func _input(event):
	if event is InputEventKey and event.keycode == KEY_SPACE:
		if event.pressed:
			if not charge.playing:
				charge.play()
			is_charging_dash = true
		else:
			if charge.playing:
				charge.stop()
			var dash_distance = dash_power * 200.0
			dash_power = 0.0
			is_charging_dash = false

			if fish_in_bubble:
				fish_in_bubble = false
				print("Dashing out of the bubble!")

			var mouse_position = camera.get_global_mouse_position()
			var direction = (mouse_position - swordfish.position).normalized()
			dash_target = swordfish.position + direction * dash_distance
			dashing = true

			var is_facing_left = dash_target.x < swordfish.position.x
			swordfish.scale.x = -1 if is_facing_left else 1

func _draw():
	var bar_width = 100
	var bar_height = 10
	var bar_position = swordfish.position + Vector2(-bar_width / 2, -50)
	var fill_width = (dash_power / max_dash_power) * bar_width

	draw_rect(Rect2(bar_position, Vector2(bar_width, bar_height)), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(bar_position, Vector2(fill_width, bar_height)), Color(0.8, 0.8, 1.0))
