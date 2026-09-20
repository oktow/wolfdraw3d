extends RefCounted

func run(app: Node3D, temp: String) -> bool:
	var before: Dictionary = app.document()
	var old_target: Vector3 = app.target
	var old_distance: float = app.distance
	var old_yaw: float = app.yaw
	var old_pitch: float = app.pitch
	var sample: Vector3 = app.target + app.camera.basis.x
	var screen: Vector2 = app.camera.unproject_position(sample)
	app.projection_picker.item_selected.emit(1)
	assert(app.camera.projection == Camera3D.PROJECTION_ORTHOGONAL)
	assert(app.camera.unproject_position(sample).distance_to(screen) < 0.01)
	assert(app.target == old_target and app.distance == old_distance)
	var center: Vector2 = app.camera.unproject_position(app.target)
	var front: Vector3 = sample + app.camera.basis.z * 2
	var back: Vector3 = sample - app.camera.basis.z * 2
	assert(app.camera.unproject_position(front).distance_to(app.camera.unproject_position(back)) < 0.01)
	app.zoom(0.5)
	assert(is_equal_approx(app.camera.unproject_position(sample).distance_to(center), screen.distance_to(center) * 2))
	app.zoom(2)
	app.projection_picker.item_selected.emit(0)
	assert(app.camera.unproject_position(front).distance_to(center) > app.camera.unproject_position(back).distance_to(center))
	assert(app.camera.unproject_position(sample).distance_to(screen) < 0.01)
	app.set_projection(1)
	assert(preload("res://tests/touch_test.gd").new().run(app))
	assert(preload("res://tests/view_test.gd").new().run(app))
	assert(await preload("res://tests/profile_test.gd").new().run(app, temp))
	assert(app.document() == before)
	app.target = old_target
	app.distance = old_distance
	app.yaw = old_yaw
	app.pitch = old_pitch
	app.set_projection(0)
	print("PROJECTION PASS: scale-preserving switch, orthographic equal depth scale, zoom, perspective depth, orthographic touch/snap/profile/Bend/ink")
	return true
