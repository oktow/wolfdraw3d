extends RefCounted

func run(app: Node3D) -> bool:
	var original_target: Vector3 = app.target
	var original_distance: float = app.distance
	var original_yaw: float = app.yaw
	var original_pitch: float = app.pitch
	var before: Dictionary = app.document()
	app.target = Vector3(1.2, -0.6, 0.8)
	app.distance = 9.0
	var axes := [Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3.LEFT, Vector3.DOWN, Vector3.FORWARD]
	for index in axes.size():
		app.view_menu.get_popup().id_pressed.emit(index)
		assert(app.camera.basis.z.is_equal_approx(axes[index]))
		assert(is_equal_approx(app.camera.basis.determinant(), 1.0))
		assert(app.camera.position.is_equal_approx(app.target + axes[index] * 9.0))
		assert(app.target.is_equal_approx(Vector3(1.2, -0.6, 0.8)))
		assert(is_equal_approx(app.distance, 9.0))
		app.pan(Vector2(15, 20))
		app.zoom(0.9)
		app.orbit(Vector2(0, 1 if axes[index].y < 0 else -1))
		assert(app.camera.transform.is_finite())
		app.target = Vector3(1.2, -0.6, 0.8)
		app.distance = 9.0
	app.toggle_menu()
	assert(app.view_controls.is_visible_in_tree())
	app.view_menu.get_popup().id_pressed.emit(1)
	assert(app.camera.basis.z.is_equal_approx(Vector3.UP))
	app.toggle_menu()
	assert(app.document() == before)
	app.target = original_target
	app.distance = original_distance
	app.yaw = original_yaw
	app.pitch = original_pitch
	app.update_camera()
	print("VIEW PASS: six axis dropdown actions, exact poles, retained target/distance, navigation after snap, hidden menus, unchanged document")
	return true
