extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	for i in range(30):
		await process_frame
	world.player.set_process_unhandled_input(false)
	world.player.origin.rotation = Vector3.ZERO
	world.player.head.rotation = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/desktop-preview.png")
	quit()
