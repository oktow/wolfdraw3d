extends RefCounted
const Shape = preload("res://scripts/shape_assist.gd")
const Store = preload("res://scripts/project_store.gd")

func run(app: Node3D, temp: String) -> bool:
	var initial: Dictionary = app.document()
	var helper = preload("res://tests/stage2_test.gd").new()
	var touch = preload("res://tests/touch_test.gd").new()
	var center: Vector2 = app.get_viewport().get_visible_rect().size / 2
	# Noisy line and rotated ellipse detection do not depend on world orientation.
	var line := PackedVector2Array()
	for i in 40:
		line.append(Vector2(i * 5, sin(i * 0.4) * 14))
	assert(Shape.fit(line).kind == "line")
	for ratio in [1.0, 0.5]:
		var loop := PackedVector2Array()
		for i in 65:
			var angle := TAU * i / 64
			loop.append((Vector2(cos(angle) * 100, sin(angle) * 100 * ratio) * (1 + 0.02 * sin(i))).rotated(0.6))
		assert(Shape.fit(loop).kind == ("circle" if ratio == 1 else "ellipse"))
	for projection in [0,1]:
		app.restore_document({"format": Store.FORMAT, "version": Store.VERSION, "groups": [{"id":0,"name":"Shape","visible":true}], "active_group":0,"strokes":[],"guides":[],"active_guide":-1})
		app.target = Vector3.ZERO
		app.distance = 12
		app.set_projection(projection)
		app.snap_view(Vector3.BACK)
		app.guides.create_plane(Transform3D.IDENTITY, Vector2(9,7))
		app.shape_picker.select(1)
		app.shape_picker.item_selected.emit(1)
		app.set_tool("draw")
		app.set_finger_drawing(true)
		var baseline: Dictionary = app.document()
		# Early release must not straighten a wobbly line.
		var old_smoothing: bool = app.smoothing
		app.smoothing = false
		app.begin_stroke(center - Vector2(140,0))
		for i in range(1,31):
			app.extend_stroke(center + Vector2(-140+i*9,sin(i*0.4)*16))
		var uncorrected: PackedVector3Array = app.active.points.duplicate()
		app.shape_assist.tick(0.3)
		assert(not app.shape_assist.locked)
		app.finish_stroke()
		assert(app.strokes[-1].points == uncorrected)
		app.undo()
		assert(app.document() == baseline)
		app.smoothing = old_smoothing
		var start := center + Vector2(-150, -140)
		app.begin_stroke(start)
		for i in range(1,41):
			app.extend_stroke(start + Vector2(i * 7, sin(i) * 2))
		app.shape_assist.tick(Shape.HOLD_SECONDS + 0.05)
		assert(app.shape_assist.locked and app.shape_assist.model.kind == "line")
		var end := start + Vector2(320,10)
		app.extend_stroke(end)
		app.finish_stroke()
		assert(app.strokes.size() == 1)
		for point in app.strokes[0].points:
			var screen: Vector2 = app.camera.unproject_position(point)
			assert(screen.distance_to(Geometry2D.get_closest_point_to_segment(screen, start, end)) < 0.01)
		app.undo()
		assert(app.document() == baseline)
		app.redo()
		# Curvature adjustment changes the interior, keeping endpoints fixed.
		start = center + Vector2(-150, -40)
		app.begin_stroke(start)
		for i in range(1,31):
			var t := i / 30.0
			app.extend_stroke(start + Vector2(t * 300, -sin(t * PI) * 45))
		app.shape_assist.tick(Shape.HOLD_SECONDS + 0.05)
		assert(app.shape_assist.model.kind == "curve")
		var first: Vector3 = app.active.points[0]
		var last: Vector3 = app.active.points[-1]
		var middle: Vector3 = app.active.points[32]
		app.extend_stroke(app.shape_assist.held_at + Vector2(0,35))
		assert(app.active.points[0].is_equal_approx(first) and app.active.points[-1].is_equal_approx(last))
		assert(app.active.points[32].distance_to(middle) > 0.1)
		app.finish_stroke()
		# Holding before drawing creates a radius-controlled circle.
		start = center + Vector2(-90,95)
		app.begin_stroke(start)
		# Exercise the actual frame timer as well as deterministic hold checks.
		await app.get_tree().create_timer(Shape.HOLD_SECONDS + 0.1).timeout
		assert(app.shape_assist.locked)
		app.extend_stroke(start + Vector2(55,0))
		app.finish_stroke()
		var circle = app.strokes[-1]
		for point in circle.points:
			assert(absf(app.camera.unproject_position(point).distance_to(start) - 55) < 0.01)
		assert(circle.taper == 0)
		# A slightly oval, shaky loop becomes circular on hold, then resizes radially.
		var rough_circle := PackedVector2Array()
		for i in 65:
			var a := TAU * i / 64
			rough_circle.append(center + Vector2(cos(a)*70,sin(a)*56) * (1.0 + 0.04*sin(i)))
		app.begin_stroke(rough_circle[0])
		for point in rough_circle.slice(1):
			app.extend_stroke(point)
		assert(not app.shape_assist.locked)
		app.shape_assist.tick(Shape.HOLD_SECONDS + 0.05)
		assert(app.shape_assist.model.kind == "circle")
		var fitted_center: Vector2 = app.shape_assist.model.center
		var fitted_radius: float = app.shape_assist.model.radii.x
		var initial_distance: float = app.shape_assist.held_at.distance_to(fitted_center)
		for direction in [Vector2.UP,Vector2.LEFT,Vector2.DOWN]:
			app.extend_stroke(fitted_center + direction * (initial_distance + 25))
			for point in app.active.points:
				assert(absf(app.camera.unproject_position(point).distance_to(fitted_center) - fitted_radius - 25) < 0.01)
		app.extend_stroke(fitted_center + Vector2.RIGHT * (initial_distance - 20))
		assert(absf(app.camera.unproject_position(app.active.points[0]).distance_to(fitted_center) - fitted_radius + 20) < 0.01)
		app.active.queue_free()
		app.active = null
		app.shape_assist.cancel()
		# Holding corrects a rotated ellipse before release.
		var loop := PackedVector2Array()
		for i in 65:
			var a := TAU * i / 64
			loop.append(center + Vector2(95,100) + Vector2(cos(a)*65,sin(a)*35).rotated(-0.3))
		app.begin_stroke(loop[0])
		for point in loop.slice(1):
			app.extend_stroke(point)
		app.shape_assist.tick(Shape.HOLD_SECONDS + 0.05)
		app.finish_stroke()
		assert(app.strokes[-1].points[0].distance_to(app.strokes[-1].points[-1]) < 0.001)
		assert(Store.validate(app.document()).is_empty())
		assert(Store.save_project(temp + "/shapes.wolf3d", app.document()) == OK)
		assert(helper.equivalent(Store.load_project(temp + "/shapes.wolf3d").data, app.document()))
		# Invalid corrections do not partially replace a stroke.
		app.begin_stroke(center)
		app.extend_stroke(center + Vector2(20,10))
		var original_points: PackedVector3Array = app.active.points.duplicate()
		assert(not app.shape_assist.apply_path(PackedVector2Array([center,center + Vector2(5000,0)])))
		assert(app.active.points == original_points)
		assert(not app.shape_assist.apply_path(PackedVector2Array([center,center,center])))
		assert(app.active.points == original_points)
		app.active.queue_free()
		app.active = null
		app.shape_assist.cancel()
		# A second finger cancels held shapes without history/document edits.
		var before_touch: Dictionary = app.document()
		touch.press(app,0,center)
		touch.drag(app,0,center + Vector2(70,10))
		app.shape_assist.tick(Shape.HOLD_SECONDS + 0.05)
		touch.press(app,1,center + Vector2(100,20))
		touch.release(app,1)
		touch.release(app,0)
		assert(app.document() == before_touch and not app.shape_assist.drawing)
		if "--capture" in OS.get_cmdline_user_args() and projection == 1:
			app.guides.current().set_opacity(0)
			await RenderingServer.frame_post_draw
			app.get_viewport().get_texture().get_image().save_png("res://build/draw-shape.png")
		# Draw Shape also corrects profile guide creation and Bend.
		app.guides.close_active()
		app.guides.start_profile()
		app.begin_stroke(center - Vector2(100,0))
		for i in range(1,21):
			app.extend_stroke(center + Vector2(-100+i*10,sin(i)))
		app.shape_assist.tick(Shape.HOLD_SECONDS + 0.05)
		app.guides.finish_preview()
		assert(app.guides.current().columns == 64)
		assert(Store.validate(app.document()).is_empty())
		app.yaw = 0.7
		app.update_camera()
		app.guides.start_bend()
		app.begin_stroke(center)
		for i in range(1,21):
			app.extend_stroke(center + Vector2(sin(i*0.1)*40,-i*5))
		app.shape_assist.tick(Shape.HOLD_SECONDS + 0.05)
		app.guides.finish_preview()
		assert(app.guides.current().rows == 64)
		assert(Store.validate(app.document()).is_empty())
	app.shape_assist.cancel()
	app.shape_assist.mode = "off"
	app.shape_picker.select(0)
	app.restore_document(initial)
	app.set_projection(0)
	app.set_finger_drawing(false)
	app.face_guide()
	print("SHAPE PASS: auto line/circle/rotated ellipse, hold endpoints/curvature/radius, guide Draw/Bend, bounds rollback, touch cancellation, undo, file roundtrip, both projections")
	return true
