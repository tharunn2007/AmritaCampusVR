extends CharacterBody3D

const WALK_SPEED := 4.317
const SPRINT_SPEED := 5.612
const DEADZONE := 0.18
var origin: XROrigin3D
var head: Camera3D
var left: XRController3D
var right: XRController3D
var capsule: CollisionShape3D
var marker: MeshInstance3D
var beam: MeshInstance3D
var beam_mesh := ImmediateMesh.new()
var xr_active := false
var turn_latched := false
var was_aiming := false
var target_valid := false
var target := Vector3.ZERO
var home := Vector3.ZERO
var mouse_pitch := 0.0
var left_ctrl_held := false
var help_label: Label
var comfort_overlay: MeshInstance3D
var comfort_material: ShaderMaterial
var comfort_strength := 0.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 3
	floor_snap_length = 0.3
	floor_max_angle = deg_to_rad(40)
	capsule = CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.25
	shape.height = 1.7
	capsule.shape = shape
	capsule.position.y = 0.88
	add_child(capsule)
	origin = XROrigin3D.new()
	add_child(origin)
	var xr := XRServer.find_interface("OpenXR")
	xr_active = xr != null and xr.is_initialized()
	if xr_active:
		get_viewport().use_xr = true
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		head = XRCamera3D.new()
		origin.add_child(head)
		left = XRController3D.new()
		left.tracker = &"left_hand"
		left.pose = &"aim"
		origin.add_child(left)
		right = XRController3D.new()
		right.tracker = &"right_hand"
		right.pose = &"aim"
		origin.add_child(right)
		for controller in [left, right]:
			var hand := MeshInstance3D.new()
			var hand_mesh := CapsuleMesh.new()
			hand_mesh.radius = 0.025
			hand_mesh.height = 0.12
			hand.mesh = hand_mesh
			controller.add_child(hand)
		var instructions := Label3D.new()
		instructions.text = "AMRITA CAMPUS\nLeft stick: move | Hold stick click: sprint\nRight stick: snap turn\nRight trigger: aim, release to teleport\nY: return to start"
		instructions.font_size = 32
		instructions.pixel_size = 0.001
		instructions.position = Vector3(0, 0.09, -0.18)
		instructions.rotation_degrees.x = -45
		left.add_child(instructions)
	else:
		head = Camera3D.new()
		head.position.y = 1.7
		origin.add_child(head)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	head.far = 2200
	head.current = true
	# Shader-only port of the tutorial's movement vignette; no image asset needed.
	comfort_overlay = MeshInstance3D.new()
	comfort_overlay.name = "MovementVignette"
	var screen_quad := QuadMesh.new()
	screen_quad.size = Vector2(2, 2)
	comfort_overlay.mesh = screen_quad
	comfort_material = ShaderMaterial.new()
	comfort_material.shader = preload("res://scripts/movement_vignette.gdshader")
	comfort_material.render_priority = 127
	comfort_overlay.material_override = comfort_material
	comfort_overlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	comfort_overlay.custom_aabb = AABB(Vector3(-1000, -1000, -1000), Vector3(2000, 2000, 2000))
	comfort_overlay.visible = false
	head.add_child(comfort_overlay)
	marker = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.27
	ring.outer_radius = 0.35
	marker.mesh = ring
	marker.material_override = unshaded(Color("55e5be"))
	get_parent().add_child.call_deferred(marker)
	marker.visible = false
	beam = MeshInstance3D.new()
	beam.mesh = beam_mesh
	beam.material_override = unshaded(Color("55e5be"))
	get_parent().add_child.call_deferred(beam)
	if not xr_active:
		var layer := CanvasLayer.new()
		add_child(layer)
		var panel := PanelContainer.new()
		panel.position = Vector2(24, 24)
		layer.add_child(panel)
		help_label = Label.new()
		help_label.text = "  AMRITA / CAMPUS WALK  \n  WASD / Arrows  Move   •   Left Ctrl  Sprint   •   Mouse  Look   •   Q/E  Turn  \n  Hold/release T  Teleport   •   R  Return   •   Esc  Release mouse  "
		panel.add_child(help_label)

func unshaded(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.physical_keycode == KEY_CTRL and event.location == KEY_LOCATION_LEFT:
		left_ctrl_held = event.pressed

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		left_ctrl_held = false

# Radial deadzone rescaling adapted from the reference VR controller.
func thumbstick_input(raw: Vector2) -> Vector2:
	var magnitude := minf(raw.length(), 1.0)
	if magnitude <= DEADZONE:
		return Vector2.ZERO
	return raw.normalized() * ((magnitude - DEADZONE) / (1.0 - DEADZONE))

func update_vignette(moving: bool, delta: float) -> void:
	comfort_strength = move_toward(comfort_strength, 0.65 if moving and xr_active else 0.0, delta * 3.0)
	comfort_material.set_shader_parameter("strength", comfort_strength)
	comfort_overlay.visible = comfort_strength > 0.001

func horizontal_velocity(axis: Vector2, sprinting: bool = false) -> Vector3:
	axis = axis.limit_length()
	# Use the head's up axis to keep heading continuous past vertical pitch.
	var look := -head.global_basis.z
	var top := head.global_basis.y
	var forward := Vector3(look.x, 0, look.z) - Vector3(top.x, 0, top.z) * look.y
	if forward.length_squared() < 0.0001:
		forward = -origin.global_basis.z
		forward.y = 0
	forward = forward.normalized()
	var sideways := forward.cross(Vector3.UP)
	var speed := SPRINT_SPEED if sprinting else WALK_SPEED
	return (sideways * axis.x - forward * axis.y) * speed

func _unhandled_input(event: InputEvent) -> void:
	if xr_active:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		origin.rotate_y(-event.relative.x * 0.002)
		mouse_pitch = clampf(mouse_pitch - event.relative.y * 0.002, -1.4, 1.4)
		head.rotation.x = mouse_pitch
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				left_ctrl_held = false
			KEY_R:
				reset_home()
			KEY_Q:
				snap_turn(deg_to_rad(30))
			KEY_E:
				snap_turn(deg_to_rad(-30))
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func reset_home() -> void:
	global_position = home
	origin.position.x = 0
	origin.position.z = 0
	velocity = Vector3.ZERO

func snap_turn(angle: float) -> void:
	var pivot := head.global_position
	origin.rotate_y(angle)
	var difference := pivot - head.global_position
	origin.global_position += Vector3(difference.x, 0, difference.z)

func _physics_process(delta: float) -> void:
	var axis := Vector2.ZERO
	var aiming := false
	var sprinting := false
	if xr_active:
		if left.get_is_active():
			axis = thumbstick_input(left.get_vector2("primary"))
			axis.y = -axis.y
			sprinting = left.is_button_pressed("primary_click")
			if left.is_button_pressed("by_button"):
				reset_home()
		if right.get_is_active():
			var turn := right.get_vector2("primary").x
			if absf(turn) < 0.3:
				turn_latched = false
			if absf(turn) > 0.7 and not turn_latched:
				snap_turn(-signf(turn) * deg_to_rad(30))
				turn_latched = true
			aiming = right.get_float("trigger") > 0.6
		else:
			# Tracking loss cancels teleport instead of acting like a trigger release.
			target_valid = false
		# Bring the collision capsule under the tracked head without moving the view.
		var offset := head.global_position - global_position
		offset.y = 0
		var previous := global_position
		move_and_collide(offset)
		origin.global_position -= global_position - previous
		var tracked_height := clampf(head.global_position.y - global_position.y, 0.7, 2.2)
		capsule.shape.height = tracked_height
		capsule.position.y = tracked_height * 0.5 + 0.03
	elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		axis = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		aiming = Input.is_physical_key_pressed(KEY_T)
		sprinting = left_ctrl_held
	var movement := horizontal_velocity(axis, sprinting)
	velocity.x = movement.x
	velocity.z = movement.z
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0
	move_and_slide()
	update_vignette(Vector2(velocity.x, velocity.z).length() > 0.05, delta)
	if global_position.y < -15:
		reset_home()
	if aiming:
		update_teleport(right if xr_active else head)
	elif was_aiming and target_valid:
		var offset := head.global_position - global_position
		offset.y = 0
		global_position = target + Vector3.UP * 0.04 - offset
		velocity = Vector3.ZERO
	marker.visible = aiming and target_valid
	beam.visible = aiming
	was_aiming = aiming

func landing_clear(point: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule.shape
	query.transform = Transform3D(Basis.IDENTITY, point + Vector3.UP * (capsule.shape.height * 0.5 + 0.04))
	query.collision_mask = 3
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query).is_empty()

# Point-and-teleport, adapted from the reference; retain capsule clearance checks.
func update_teleport(pointer: Node3D) -> void:
	target_valid = false
	var point := pointer.global_position
	var end := point - pointer.global_basis.z * 25.0
	var query := PhysicsRayQueryParameters3D.create(point, end, 3, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	beam_mesh.clear_surfaces()
	beam_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	beam_mesh.surface_add_vertex(point)
	beam_mesh.surface_add_vertex(hit.position if not hit.is_empty() else end)
	beam_mesh.surface_end()
	if not hit.is_empty() and hit.normal.y >= 0.85 and hit.collider.collision_layer == 1 and landing_clear(hit.position):
		target = hit.position
		target_valid = true
		marker.global_position = target + Vector3.UP * 0.04
