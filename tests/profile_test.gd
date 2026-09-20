extends RefCounted

const Store = preload("res://scripts/project_store.gd")
const Surface = preload("res://scripts/guide_surface.gd")

func run(app: Node3D, temp: String) -> bool:
	var initial: Dictionary = app.document()
	var helper = preload("res://tests/stage2_test.gd").new()
	app.restore_document({"format": Store.FORMAT, "version": 3, "groups": [{"id": 0, "name": "Profil", "visible": true}], "active_group": 0, "strokes": [], "guides": [], "active_guide": -1})
	app.target = Vector3.ZERO
	app.distance = 12
	app.snap_view(Vector3.BACK)
	var center: Vector2 = app.get_viewport().get_visible_rect().size / 2
	var touch = preload("res://tests/touch_test.gd").new()
	app.guides.start_profile()
	assert(app.finger_drawing and app.guides.placing)
	touch.press(app, 0, center + Vector2(-170, 60))
	var authored := PackedVector2Array([Vector2(-100, 60), Vector2(-100, -20), Vector2(-40, -20)])
	for point in authored:
		touch.drag(app, 0, center + point)
	for i in range(1, 41):
		touch.drag(app, 0, center + Vector2(-40 + i * 5, -20 - sin(i * PI / 40) * 80))
	touch.release(app, 0)
	var guide = app.guides.current()
	assert(guide != null and guide.kind == "mesh" and guide.columns > 20)
	assert(Store.validate(app.document()).is_empty())
	# Authored corners remain exact; the surface has world-space depth.
	for i in authored.size():
		assert(app.camera.unproject_position(guide.vertices[i + 1]).distance_to(center + authored[i]) < 0.01)
	assert(guide.vertices[0].distance_to(guide.vertices[guide.columns]) > 3.9)
	var profile_doc: Dictionary = app.document()
	app.undo()
	assert(app.guides.current() == null)
	app.redo()
	assert(app.document() == profile_doc)
	guide = app.guides.current()
	# Ray queries work on both faces and return the nearest overlapping surface.
	var test_surface := Surface.new()
	test_surface.configure_profile(PackedVector3Array([Vector3(-1, 0, 0), Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(-1, 1, 0)]), Vector3(0, 0, -2))
	assert(test_surface.intersect_ray(Vector3(0, 3, -1), Vector3.DOWN).is_equal_approx(Vector3(0, 1, -1)))
	assert(test_surface.intersect_ray(Vector3(0, -3, -1), Vector3.UP).is_equal_approx(Vector3(0, 0, -1)))
	test_surface.free()
	app.target = guide.center()
	app.yaw = 0.6
	app.pitch = 0.6
	app.update_camera()
	assert(app.document() == profile_doc)
	# Draw along the first surface strip; all samples stay on the mesh.
	var p: Vector3 = guide.vertices[0].lerp(guide.vertices[1], 0.25).lerp(guide.vertices[guide.columns].lerp(guide.vertices[guide.columns + 1], 0.25), 0.5)
	var q: Vector3 = guide.vertices[0].lerp(guide.vertices[1], 0.75).lerp(guide.vertices[guide.columns].lerp(guide.vertices[guide.columns + 1], 0.75), 0.5)
	app.begin_stroke(app.camera.unproject_position(p))
	app.extend_stroke(app.camera.unproject_position(q))
	app.finish_stroke()
	assert(app.strokes.size() == 1)
	assert(app.pick_stroke(app.camera.unproject_position(app.strokes[0].points[0])) == app.strokes[0])
	for point in app.strokes[0].points:
		var screen: Vector2 = app.camera.unproject_position(point)
		assert(guide.intersect_ray(app.camera.project_ray_origin(screen), app.camera.project_ray_normal(screen)).distance_to(point) < 0.001)
	var before_bend: Dictionary = app.document()
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		app.get_viewport().get_texture().get_image().save_png("res://build/profile-draw.png")
	var edge: PackedVector3Array = guide.edge_points()
	app.guides.start_bend()
	app.guides.begin_preview(center)
	for i in range(1, 30):
		app.guides.extend_preview(center + Vector2(sin(i * 0.05) * 120, -i * 5))
	app.guides.finish_preview()
	guide = app.guides.current()
	assert(guide.rows > 2 and guide.edge_points() == edge)
	assert(app.document().strokes == before_bend.strokes)
	assert(Store.validate(app.document()).is_empty())
	var bent: Dictionary = app.document()
	app.undo()
	assert(app.document() == before_bend)
	app.redo()
	assert(app.document() == bent)
	assert(Store.save_project(temp + "/profile.wolf3d", bent) == OK)
	var loaded: Dictionary = Store.load_project(temp + "/profile.wolf3d")
	assert(loaded.error.is_empty() and helper.equivalent(loaded.data, bent))
	app.restore_document(loaded.data)
	assert(helper.equivalent(app.document(), bent))
	# Bend cancellation leaves the original surface and ink untouched.
	app.guides.start_bend()
	app.guides.begin_preview(center)
	app.guides.extend_preview(center + Vector2(60, 100))
	app.cancel_input()
	assert(helper.equivalent(app.document(), bent))
	app.guides.cancel_placing()
	# A second touch cancels Bend without replacing the original mesh.
	app.guides.start_bend()
	touch.press(app, 0, center)
	touch.drag(app, 0, center + Vector2(40, 80))
	touch.press(app, 1, center + Vector2(100, 0))
	assert(app.guides.preview == null)
	touch.release(app, 0)
	touch.release(app, 1)
	assert(helper.equivalent(app.document(), bent))
	app.guides.cancel_placing()
	var bad: Dictionary = bent.duplicate(true)
	bad.guides[0].rows = 2.5
	assert(not Store.validate(bad).is_empty())
	bad = bent.duplicate(true)
	bad.guides[0].vertices.pop_back()
	assert(not Store.validate(bad).is_empty())
	bad = bent.duplicate(true)
	for i in bad.guides[0].vertices.size():
		bad.guides[0].vertices[i] = [0, 0, 0]
	assert(not Store.validate(bad).is_empty())
	# Version 2 planes remain loadable under the new format.
	var legacy: Dictionary = initial.duplicate(true)
	legacy.version = 2
	assert(Store.save_project(temp + "/legacy-v2.wolf3d", legacy) == OK)
	assert(Store.load_project(temp + "/legacy-v2.wolf3d").data.version == Store.VERSION)
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		app.get_viewport().get_texture().get_image().save_png("res://build/profile-bend.png")
	# Long input is simplified, not truncated; retain the final point and undo state.
	app.guides.save_active()
	app.guides.start_profile()
	app.guides.begin_preview(center - Vector2(160, 0))
	var final_screen := center
	for i in range(1, 301):
		final_screen = center + Vector2(-160 + i, sin(i * 0.1) * 60)
		app.guides.extend_preview(final_screen)
	assert(app.guides.profile.size() <= 256)
	assert(app.camera.unproject_position(app.guides.profile[-1]).distance_to(final_screen) < 3.1)
	app.guides.cancel_placing()
	app.restore_document(initial)
	app.set_finger_drawing(false)
	app.face_guide()
	print("PROFILE PASS: freehand corners and curves, surface ink, nearest/backface hits, Bend anchored edge, undo/redo, v3 save/load, v2 migration, cancellation, invalid mesh rejection")
	return true
