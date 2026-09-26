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
	# The drawn line sits mid-surface (cursor = median); the surface has depth.
	for i in authored.size():
		var mid: Vector3 = (guide.vertices[i + 1] + guide.vertices[i + 1 + guide.columns]) / 2.0
		assert(app.camera.unproject_position(mid).distance_to(center + authored[i]) < 0.01)
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
	# Polyline: clicks append vertices, release never commits, Done commits.
	# Two points are rejected (a straight edge extrudes edge-on to the view).
	app.guides.save_active()
	app.set_tool("draw")
	app.guides.start_polyline()
	assert(app.guides.placing and app.guides.creation_mode == "polyline")
	for offset in [Vector2(-120, 40), Vector2(-40, -60)]:
		touch.press(app, 0, center + offset)
		touch.release(app, 0)
	assert(app.guides.current() == null and app.guides.profile.size() == 2)
	app.guides.finish_preview(true)
	assert(app.guides.current() == null and app.guides.placing)
	touch.press(app, 0, center + Vector2(60, 30))
	touch.release(app, 0)
	assert(app.guides.current() == null and app.guides.profile.size() == 3)
	assert(app.guides.preview != null and app.guides.preview.visible)
	app.guides.finish_preview(true)
	var poly = app.guides.current()
	assert(poly != null and poly.kind == "mesh" and poly.columns == 3)
	assert(Store.validate(app.document()).is_empty())
	app.undo()
	assert(app.guides.current() == null)
	app.undo()
	assert(app.document() == bent)
	# Plane taps: two opposite corner taps create the plane at once.
	app.guides.save_active()
	app.guides.start_plane_taps()
	assert(app.guides.placing and app.guides.creation_mode == "plane_taps")
	touch.press(app, 0, center + Vector2(-100, 50))
	touch.release(app, 0)
	assert(app.guides.current() == null and app.guides.placing)
	touch.press(app, 0, center + Vector2(100, -50))
	touch.release(app, 0)
	var tap_plane = app.guides.current()
	assert(tap_plane != null and tap_plane.kind == "plane")
	assert(Store.validate(app.document()).is_empty())
	app.undo()
	assert(app.guides.current() == null)
	app.undo()
	assert(app.document() == bent)
	# Curve: a dragged V is smoothed (endpoints kept, more columns than raw).
	app.guides.save_active()
	app.guides.start_curve()
	assert(app.guides.placing and app.guides.creation_mode == "curve")
	touch.press(app, 0, center + Vector2(-140, 50))
	for i in range(1, 40):
		touch.drag(app, 0, center + Vector2(-140 + i * 7, 50 - absf(i - 20) * 6))
	touch.release(app, 0)
	var curve = app.guides.current()
	assert(curve != null and curve.kind == "mesh" and curve.columns > 40)
	assert(curve.columns <= 256)
	assert(Store.validate(app.document()).is_empty())
	app.undo()
	app.undo()
	assert(app.document() == bent)
	var sharp := PackedVector3Array([Vector3.ZERO, Vector3(1, 0, 0), Vector3(1, 1, 0)])
	var smooth: PackedVector3Array = app.guides.smooth_chaikin(sharp)
	assert(smooth[0].is_equal_approx(Vector3.ZERO) and smooth[smooth.size() - 1].is_equal_approx(Vector3(1, 1, 0)))
	assert(smooth.size() > 3)
	# Hold while drawing a profile auto-fits: near-straight becomes a line.
	app.guides.save_active()
	app.set_tool("draw")
	app.guides.start_profile()
	touch.press(app, 0, center + Vector2(-120, 60))
	for i in range(1, 20):
		touch.drag(app, 0, center + Vector2(-120 + i * 6, 60 + sin(i * 0.8) * 2))
	app.shape_assist.tick(1.0)
	assert(app.shape_assist.locked and app.shape_assist.model.kind == "line")
	assert(app.guides.profile.size() == 64)
	touch.release(app, 0)
	var straight = app.guides.current()
	assert(straight != null and straight.kind == "mesh" and straight.columns == 64)
	var held: PackedVector3Array = app.guides.profile
	var span: float = held[0].distance_to(held[held.size() - 1])
	var deviation := 0.0
	for point in held:
		deviation = maxf(deviation, point.distance_to(Geometry3D.get_closest_point_to_segment(point, held[0], held[held.size() - 1])))
	assert(deviation < span * 0.01)
	assert(Store.validate(app.document()).is_empty())
	app.undo()
	app.undo()
	assert(app.document() == bent)
	# A clearly curved hold keeps its curve instead of straightening.
	app.guides.save_active()
	app.guides.start_profile()
	touch.press(app, 0, center + Vector2(-40, 110))
	for i in range(1, 31):
		var angle := PI + float(i) / 30.0 * PI * 0.5
		touch.drag(app, 0, center + Vector2(-40, 110) + Vector2(cos(angle), sin(angle)) * 80.0 - Vector2(-80, 0))
	app.shape_assist.tick(1.0)
	assert(app.shape_assist.locked and app.shape_assist.model.kind == "curve")
	touch.release(app, 0)
	var bent_curve = app.guides.current()
	assert(bent_curve != null and bent_curve.kind == "mesh" and bent_curve.columns == 64)
	assert(Store.validate(app.document()).is_empty())
	app.undo()
	app.undo()
	assert(app.document() == bent)
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
	print("PROFILE PASS: freehand corners and curves, surface ink, nearest/backface hits, Bend anchored edge, undo/redo, v3 save/load, v2 migration, cancellation, invalid mesh rejection, polyline clicks, smoothed curve, tap plane, hold straighten")
	return true
