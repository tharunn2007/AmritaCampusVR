extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
		assert(condition, message)
	print("PASS: ", message)

func run() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	for i in range(90):
		await physics_frame
	var p = world.player
	check(world.collision_count == 119, "All buildings and ground have collisions")
	check(p.is_on_floor(), "Player settles on campus ground")
	check(p.landing_clear(world.spawn_point), "Spawn has capsule clearance")
	# Ground movement must work in all eight directions at every view heading.
	for yaw in [0.0, PI / 2.0, PI, -PI / 2.0]:
		p.origin.rotation.y = yaw
		for pitch in [-1.4, 0.0, 1.4]:
			p.head.rotation.x = pitch
			for axis in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				var walk: Vector3 = p.horizontal_velocity(axis)
				var run: Vector3 = p.horizontal_velocity(axis, true)
				check(absf(walk.length() - 4.317) < 0.001 and absf(run.length() - 5.612) < 0.001 and is_zero_approx(walk.y), "Directional walking/sprinting speed is independent of diagonal and pitch")
				var expected: Vector3 = Basis(Vector3.UP, yaw) * Vector3(axis.x, 0, axis.y).normalized()
				check(walk.normalized().distance_to(expected) < 0.001, "Movement follows view heading")
	# Regression: looking through vertical must not reverse forward movement.
	for yaw_degrees in [0, 90, 180, 270]:
		var yaw := deg_to_rad(float(yaw_degrees))
		p.origin.rotation.y = yaw
		var expected := Basis(Vector3.UP, yaw) * Vector3.FORWARD
		for pitch_degrees in range(-100, 101):
			p.head.rotation.x = deg_to_rad(float(pitch_degrees))
			var walk: Vector3 = p.horizontal_velocity(Vector2.UP)
			check(absf(walk.length() - 4.317) < 0.001, "Pitch sweep speed: yaw=%d pitch=%d" % [yaw_degrees, pitch_degrees])
			check(walk.normalized().dot(expected) > 0.99, "Pitch sweep heading: yaw=%d pitch=%d" % [yaw_degrees, pitch_degrees])
	p.xr_active = true
	for axis in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.ONE]:
		check(absf(p.horizontal_velocity(axis).length() - 4.317) < 0.001, "VR walking speed matches desktop")
		check(absf(p.horizontal_velocity(axis, true).length() - 5.612) < 0.001, "VR sprint speed matches desktop")
	check(absf(p.horizontal_velocity(Vector2(0.5, 0), true).length() - 2.806) < 0.001, "VR thumbstick retains analog speed control")
	p.xr_active = false
	p.origin.rotation = Vector3.ZERO
	p.head.rotation = Vector3.ZERO
	for location in [KEY_LOCATION_RIGHT, KEY_LOCATION_LEFT]:
		var ctrl := InputEventKey.new()
		ctrl.physical_keycode = KEY_CTRL
		ctrl.location = location
		ctrl.pressed = true
		p._input(ctrl)
		check(p.left_ctrl_held == (location == KEY_LOCATION_LEFT), "Only Left Ctrl enables sprint")
		ctrl.pressed = false
		p._input(ctrl)
		check(not p.left_ctrl_held, "Releasing Ctrl restores walk")
	p.left_ctrl_held = true
	p._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not p.left_ctrl_held, "Focus loss clears sprint")
	check(p.thumbstick_input(Vector2(0.1, 0.1)) == Vector2.ZERO, "Stick drift stays inside radial deadzone")
	check(p.thumbstick_input(Vector2(0.1801, 0)).length() < 0.001, "Stick starts smoothly at deadzone boundary")
	check(absf(p.thumbstick_input(Vector2(0.59, 0)).length() - 0.5) < 0.001, "Stick magnitude rescales continuously")
	check(absf(p.thumbstick_input(Vector2.ONE).length() - 1.0) < 0.001, "Diagonal stick magnitude is capped")
	p.xr_active = true
	p.update_vignette(true, 1.0)
	check(p.comfort_overlay.visible and p.comfort_strength > 0.0, "VR movement activates vignette")
	p.update_vignette(false, 1.0)
	check(not p.comfort_overlay.visible, "Stopping clears vignette")
	p.xr_active = false
	var old_head: Vector3 = p.head.global_position
	p.snap_turn(deg_to_rad(30))
	check(p.head.global_position.distance_to(old_head) < 0.001, "Snap turn preserves head position")
	var start: Vector3 = p.global_position
	for i in range(60):
		p.velocity = Vector3(0, 0, -2.2)
		p.move_and_slide()
		await physics_frame
	check(p.global_position.distance_to(start) > 1.5, "Walking moves across ground")
	p.reset_home()
	p.head.rotation.x = -0.5
	p.update_teleport(p.head)
	check(p.target_valid, "Teleport finds valid ground ahead")
	check(p.landing_clear(p.target), "Teleport destination has body clearance")
	p.head.rotation.x = 0.5
	p.update_teleport(p.head)
	check(not p.target_valid, "Aiming into sky clears the previous teleport target")
	# Cast through the library from outside to verify walls block traversal.
	var library = world.find_child("bld_Central_Library", true, false)
	check(library != null, "Named campus landmarks preserved")
	var box: AABB = library.get_aabb()
	var center: Vector3 = library.to_global(box.get_center())
	var query := PhysicsRayQueryParameters3D.create(center + Vector3(100, 0, 0), center, 2)
	check(not world.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "Building wall blocks a ray")
	p.global_position.y = -30
	for i in range(4):
		await physics_frame
	check(p.global_position.distance_to(p.home) < 1, "Falling out of bounds returns to start")
	print("NAVIGATION_TESTS_OK")
	quit()
