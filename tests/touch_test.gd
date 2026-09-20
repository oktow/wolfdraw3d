extends RefCounted

func press(app: Node, index: int, position: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = true
	if app.touches.is_empty():
		app._unhandled_input(event)
	else:
		app._input(event)

func drag(app: Node, index: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	app._input(event)

func release(app: Node, index: int, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = app.touches[index]
	event.pressed = false
	event.canceled = canceled
	app._input(event)

func run(app: Node) -> bool:
	var before: Dictionary = app.document()
	var center: Vector2 = app.get_viewport().get_visible_rect().size / 2
	app.set_tool("draw")
	app.set_finger_drawing(false)
	app.face_guide()
	app.distance = 12
	app.update_camera()
	var initial_yaw: float = app.yaw
	press(app, 4, center)
	drag(app, 4, center + Vector2(70, 35))
	assert(app.yaw != initial_yaw and app.active == null, "One finger rotates without drawing")
	release(app, 4)
	assert(app.document() == before, "Navigation leaves ink and guides unchanged")
	# Translate both fingers equally: pan only, no zoom or rotation.
	var initial_distance: float = app.distance
	var initial_target: Vector3 = app.target
	initial_yaw = app.yaw
	press(app, 4, center - Vector2(100, 0))
	press(app, 9, center + Vector2(100, 0))
	drag(app, 4, center + Vector2(-60, 20))
	drag(app, 9, center + Vector2(140, 20))
	app.flush_touch_navigation()
	assert(is_equal_approx(app.distance, initial_distance))
	assert(app.target.distance_to(initial_target) > 0.1 and app.yaw == initial_yaw)
	release(app, 9)
	var camera_after_pair: Transform3D = app.camera.transform
	drag(app, 4, center)
	assert(app.camera.transform == camera_after_pair, "Remaining finger cannot jump into orbit or ink")
	release(app, 4)
	# Pinch around an off-center point and verify that point stays under the fingers.
	var midpoint := center + Vector2(180, 55)
	press(app, 0, midpoint - Vector2(100, 0))
	press(app, 1, midpoint + Vector2(100, 0))
	var plane := Plane(app.camera.basis.z, app.camera.basis.z.dot(app.target))
	var anchor: Vector3 = plane.intersects_ray(app.camera.project_ray_origin(midpoint), app.camera.project_ray_normal(midpoint))
	initial_distance = app.distance
	drag(app, 0, midpoint - Vector2(150, 0))
	drag(app, 1, midpoint + Vector2(150, 0))
	app.flush_touch_navigation()
	assert(is_equal_approx(app.distance, initial_distance * 2 / 3), "Spread fingers zooms in")
	assert(app.camera.unproject_position(anchor).distance_to(midpoint) < 0.01)
	drag(app, 0, midpoint - Vector2(100, 0))
	drag(app, 1, midpoint + Vector2(100, 0))
	app.flush_touch_navigation()
	assert(is_equal_approx(app.distance, initial_distance), "Pinch fingers zooms out")
	assert(app.camera.unproject_position(anchor).distance_to(midpoint) < 0.01)
	# Three fingers suspend navigation, then resume two fingers with a fresh baseline.
	press(app, 2, center)
	camera_after_pair = app.camera.transform
	drag(app, 0, midpoint - Vector2(110, 10))
	app.flush_touch_navigation()
	assert(app.camera.transform == camera_after_pair)
	release(app, 2)
	app.flush_touch_navigation()
	assert(app.camera.transform == camera_after_pair)
	release(app, 0)
	release(app, 1)
	# Finger drawing is explicit; a second finger cancels tentative ink.
	app.face_guide()
	app.set_finger_drawing(true)
	press(app, 0, center - Vector2(60, 20))
	drag(app, 0, center + Vector2(60, 20))
	assert(app.active != null)
	press(app, 1, center + Vector2(100, 50))
	assert(app.active == null)
	drag(app, 0, center + Vector2(70, 30))
	drag(app, 1, center + Vector2(110, 60))
	app.flush_touch_navigation()
	release(app, 1)
	release(app, 0)
	assert(app.document() == before)
	app.face_guide()
	var stroke_count: int = app.strokes.size()
	press(app, 0, center - Vector2(50, 20))
	drag(app, 0, center + Vector2(50, 20))
	release(app, 0)
	assert(app.strokes.size() == stroke_count + 1)
	app.undo()
	# Android cancellation must discard a stroke instead of committing it.
	press(app, 0, center - Vector2(50, 20))
	drag(app, 0, center + Vector2(50, 20))
	release(app, 0, true)
	assert(app.active == null and app.strokes.size() == stroke_count)
	assert(app.touches.is_empty() and not app.touch_blocked)
	# Backgrounding must clear pointer IDs so the next gesture starts fresh.
	app.set_finger_drawing(false)
	press(app, 0, center)
	press(app, 1, center + Vector2(100, 0))
	drag(app, 1, center + Vector2(130, 0))
	app._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	assert(app.touches.is_empty() and not app.pair_pending)
	app.set_finger_drawing(true)
	# Both gesture modes remain available when all other menu panels are hidden.
	app.toggle_menu()
	assert(app.compact_finger_button.visible)
	app.compact_finger_button.pressed.emit()
	assert(not app.finger_drawing)
	initial_yaw = app.yaw
	press(app, 0, center)
	drag(app, 0, center + Vector2(35, 0))
	release(app, 0)
	assert(app.yaw != initial_yaw)
	app.toggle_menu()
	assert(not app.compact_finger_button.visible)
	assert(app.document() == before)
	app.set_finger_drawing(false)
	app.face_guide()
	print("TOUCH PASS: one-finger orbit, two-finger pan, pinch in/out, centroid anchor, finger transitions, draw/navigation separation, cancellation, hidden menus")
	return true
