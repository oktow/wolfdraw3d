extends RefCounted

const Stroke = preload("res://scripts/stroke.gd")
const Store = preload("res://scripts/project_store.gd")

func add_line(app: Node3D, a: Vector3, b: Vector3) -> void:
	var stroke := Stroke.new()
	stroke.points = PackedVector3Array([a, b])
	stroke.ink = Color("e34e6c")
	stroke.radius = 0.04
	stroke.rebuild()
	app.add_child(stroke)
	app.strokes.append(stroke)

func run(app: Node3D, temp: String) -> bool:
	var original: Dictionary = app.document()
	var empty := {"format": Store.FORMAT, "version": Store.VERSION, "groups": [{"id": 0, "name": "Eraser", "visible": true}], "active_group": 0, "strokes": [], "guides": [], "active_guide": -1}
	var touch = preload("res://tests/touch_test.gd").new()
	var helper = preload("res://tests/stage2_test.gd").new()
	var center: Vector2 = app.get_viewport().get_visible_rect().size / 2
	for projection in [0, 1]:
		app.restore_document(empty)
		app.target = Vector3.ZERO
		app.distance = 12
		app.snap_view(Vector3.BACK)
		app.set_projection(projection)
		app.set_tool("erase")
		app.eraser.radius = 24
		add_line(app, Vector3(-3, 0, 0), Vector3(3, 0, 0))
		var intact: Dictionary = app.document()
		var history_size: int = app.history.size()
		# Sparse two-point lines split at analytic boundaries, not existing samples.
		app.edit_at(center)
		assert(app.strokes.size() == 2)
		assert(app.history.size() == mini(40, history_size + 1))
		for stroke in app.strokes:
			assert(stroke.ink == Color("e34e6c") and stroke.radius == 0.04 and stroke.group_id == 0)
			for point in stroke.points:
				assert(absf(app.camera.unproject_position(point).x - center.x) >= 23.9)
		var cut: Dictionary = app.document()
		app.undo()
		assert(app.document() == intact)
		app.redo()
		assert(app.document() == cut)
		assert(Store.save_project(temp + "/eraser.wolf3d", cut) == OK)
		assert(helper.equivalent(Store.load_project(temp + "/eraser.wolf3d").data, cut))
		# Drag sweeps the entire path between distant pointer events.
		app.restore_document(intact)
		history_size = app.history.size()
		app.eraser.begin(center + Vector2(-80, -100))
		app.eraser.extend(center + Vector2(-80, 100))
		app.eraser.extend(center + Vector2(80, 100))
		app.eraser.extend(center + Vector2(80, -100))
		app.eraser.finish()
		assert(app.strokes.size() == 3)
		assert(app.history.size() == mini(40, history_size + 1))
		app.undo()
		assert(app.document() == intact)
		# Touch rollback preserves redo, and never turns navigation into deletion.
		app.set_finger_drawing(true)
		var future_before: Array = app.future.duplicate(true)
		touch.press(app, 0, center)
		assert(app.strokes.size() == 2 and app.eraser.dragging)
		touch.press(app, 1, center + Vector2(90, 0))
		assert(app.document() == intact and not app.eraser.dragging)
		touch.release(app, 1)
		touch.release(app, 0)
		assert(app.future == future_before)
		touch.press(app, 0, center)
		touch.release(app, 0, true)
		assert(app.document() == intact)
		touch.press(app, 0, center)
		touch.drag(app, 0, center + Vector2(40, 0))
		touch.release(app, 0)
		assert(app.strokes.size() == 2 and not app.eraser.dragging)
		app.undo()
		assert(app.document() == intact)
		# Hidden ink and empty space remain untouched, without empty undo entries.
		app.strokes[0].hide()
		history_size = app.history.size()
		app.edit_at(center)
		assert(app.strokes.size() == 1 and app.history.size() == history_size)
		app.strokes[0].show()
		app.edit_at(center + Vector2(0, 150))
		assert(app.document() == intact and app.history.size() == history_size)
	# Perspective interpolation of cut points retains the original 3D line.
	app.restore_document(empty)
	app.set_projection(0)
	add_line(app, Vector3(-3, 0, -3), Vector3(3, 0, 3))
	app.edit_at(center)
	assert(app.strokes.size() == 2)
	for stroke in app.strokes:
		for point in stroke.points:
			assert(is_equal_approx(point.x, point.z))
	# Short strokes entirely inside the eraser disappear cleanly.
	app.restore_document(empty)
	add_line(app, Vector3(-0.05, 0, 0), Vector3(0.05, 0, 0))
	app.edit_at(center)
	assert(app.strokes.is_empty())
	if "--capture" in OS.get_cmdline_user_args():
		app.restore_document(empty)
		add_line(app, Vector3(-3, 0, 0), Vector3(3, 0, 0))
		app.eraser.begin(center)
		await RenderingServer.frame_post_draw
		app.get_viewport().get_texture().get_image().save_png("res://build/partial-eraser.png")
		app.eraser.finish()
	app.restore_document(original)
	app.set_tool("draw")
	app.set_finger_drawing(false)
	app.face_guide()
	print("ERASER PASS: partial sparse cuts, continuous sweep, metadata, single-step history, save/load, perspective/ortho, touch cancellation, hidden ink, no-op, complete deletion")
	return true
