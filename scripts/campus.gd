extends Node3D

var player: CharacterBody3D
var spawn_point := Vector3(155, 0.35, 570)
var collision_count := 0

func _ready() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	var sky := Sky.new()
	var sky_material := PanoramaSkyMaterial.new()
	sky_material.panorama = preload("res://assets/environment/ocean_sky.hdr")
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d7e5f0")
	environment.ambient_light_energy = 0.65
	env.environment = environment
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = false
	add_child(sun)
	var campus: Node3D = preload("res://assets/campus.glb").instantiate()
	add_child(campus)
	prepare_meshes(campus)
	player = load("res://scripts/player.gd").new()
	player.name = "Player"
	add_child(player)
	# Find the ground below the starting road, then ensure the body fits.
	await get_tree().physics_frame
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(155, 30, 570), Vector3(155, -10, 570), 1))
	if not hit.is_empty():
		spawn_point = hit.position + Vector3.UP * 0.05
	player.global_position = spawn_point
	player.home = spawn_point
	print("CAMPUS_READY colliders=", collision_count, " spawn=", spawn_point)

func prepare_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		var n := str(node.name)
		# Source restriction polygons are map annotations, not physical terrain.
		if n.begins_with("restricted_"):
			mesh_node.visible = false
		var material := StandardMaterial3D.new()
		material.roughness = 0.95
		material.albedo_color = Color("bdc6a5")
		if n.begins_with("bld_"):
			material.albedo_color = Color("d6c5a5")
		elif n.begins_with("road_"):
			material.albedo_color = Color("505d63")
		elif n.begins_with("path_"):
			material.albedo_color = Color("a6a18b")
		elif n.begins_with("area_"):
			material.albedo_color = Color("799362")
		mesh_node.material_override = material
		if n.begins_with("bld_") or n.begins_with("ground"):
			mesh_node.create_trimesh_collision()
			for child in mesh_node.get_children():
				if child is StaticBody3D:
					child.collision_layer = 2 if n.begins_with("bld_") else 1
					child.collision_mask = 0
					collision_count += 1
		if n.begins_with("bld_") and not n.trim_prefix("bld_").is_valid_int():
			var label := Label3D.new()
			label.text = n.trim_prefix("bld_").replace("_", " ")
			label.font_size = 48
			label.pixel_size = 0.035
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.modulate = Color("f7ead2")
			label.outline_modulate = Color("172b36")
			label.visibility_range_end = 160
			mesh_node.add_child(label)
			var box := mesh_node.get_aabb()
			label.position = box.get_center() + Vector3.UP * (box.size.y / 2 + 3)
	for child in node.get_children():
		prepare_meshes(child)
