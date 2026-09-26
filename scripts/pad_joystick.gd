extends Control
## Feather-style 2D joystick: a fixed pad that moves, rotates, and scales the
## current transform target (selected ink, else the active guide) in the view
## plane. Center stick = move, outer ring = rotate around the view axis,
## corner dot = uniform scale. Mouse and single-touch; the stick springs back.

const PAD_RADIUS := 80.0
const STICK_RADIUS := 34.0
const RING_INNER := 56.0
const SCALE_DOT_OFFSET := Vector2(41, -63)
const SCALE_DOT_RADIUS := 16.0

var app: Node3D
var dragging := ""
var stick_offset := Vector2.ZERO
var last_position := Vector2.ZERO
var last_angle := 0.0
var history_started := false
var touch_index := -1

func setup(app_node: Node3D) -> void:
	app = app_node
	custom_minimum_size = Vector2(170, 170)
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "2D joystick"

func pad_center() -> Vector2:
	return size / 2.0

func has_target() -> bool:
	if not is_instance_valid(app):
		return false
	if not app.selected_strokes.is_empty():
		return true
	if app.transform_joystick == null:
		return false
	return app.transform_joystick.guide_target() != null or app.transform_joystick.cursor_active()

func for_strokes() -> bool:
	return not app.selected_strokes.is_empty()

func for_vertex() -> bool:
	return app.transform_joystick != null and app.transform_joystick.vertex_active()

func for_cursor() -> bool:
	return not for_strokes() and not for_vertex() and app.transform_joystick.guide_target() == null

func view_scale() -> float:
	return app.view_height() / maxf(get_viewport_rect().size.y, 1.0)

func apply_move(delta: Vector2) -> void:
	var shift: Vector3 = (app.camera.basis.x * delta.x - app.camera.basis.y * delta.y) * view_scale()
	if for_strokes():
		app.transform_group(shift, 0.0, 1.0, Vector3.ZERO, false, true)
	elif for_vertex():
		app.transform_guide_vertices(shift, 0.0, 1.0, Vector3.ZERO, false, true)
	elif for_cursor():
		app.move_cursor(shift)
	else:
		app.transform_guide(shift, 0.0, 1.0, Vector3.ZERO, false)

func apply_rotate(angle_delta: float) -> void:
	# A point cursor cannot rotate or scale; silently keep the grab.
	if for_cursor():
		return
	var axis: Vector3 = app.camera.basis.z
	if for_strokes():
		app.transform_group(Vector3.ZERO, angle_delta, 1.0, axis, false, true)
	elif for_vertex():
		app.transform_guide_vertices(Vector3.ZERO, angle_delta, 1.0, axis, false, true)
	else:
		app.transform_guide(Vector3.ZERO, angle_delta, 1.0, axis, false)

func apply_scale(amount: float) -> void:
	if for_cursor():
		return
	var factor := clampf(amount, 0.9, 1.1)
	if for_strokes():
		app.transform_group(Vector3.ZERO, 0.0, factor, Vector3.ZERO, false, true)
	elif for_vertex():
		app.transform_guide_vertices(Vector3.ZERO, 0.0, factor, Vector3.ZERO, false, true)
	else:
		app.transform_guide(Vector3.ZERO, 0.0, factor, Vector3.ZERO, false)

func begin_at(local: Vector2) -> bool:
	if not has_target():
		return false
	var center := pad_center()
	if local.distance_to(center + SCALE_DOT_OFFSET) < SCALE_DOT_RADIUS:
		dragging = "scale"
	elif local.distance_to(center) < STICK_RADIUS + 6.0:
		dragging = "move"
	elif local.distance_to(center) >= RING_INNER:
		dragging = "rotate"
		last_angle = (local - center).angle()
	else:
		return false
	last_position = local
	history_started = false
	queue_redraw()
	return true

func drag_to(local: Vector2) -> void:
	if dragging.is_empty():
		return
	var center := pad_center()
	if not history_started and not for_cursor():
		app.checkpoint()
		history_started = true
	if dragging == "move":
		apply_move(local - last_position)
		stick_offset = (local - center).limit_length(PAD_RADIUS - 20.0)
	elif dragging == "rotate":
		var current_angle := (local - center).angle()
		apply_rotate(rad_to_deg(angle_difference(last_angle, current_angle)))
		last_angle = current_angle
	else:
		var before := (last_position - center).length()
		var after := (local - center).length()
		apply_scale(1.0 + (after - before) * 0.005)
	last_position = local
	queue_redraw()

func end_gesture() -> void:
	if dragging.is_empty():
		return
	# Clear state before notifying: changed() re-enters refresh, which must
	# see an idle pad instead of finalizing again (infinite recursion).
	var was_started := history_started
	dragging = ""
	stick_offset = Vector2.ZERO
	history_started = false
	if was_started:
		app.finish_vertex_drag()
		app.changed()
	queue_redraw()

func _draw() -> void:
	var center := pad_center()
	var cursor_only := for_cursor()
	var ring_color := Color("8da4b1", 0.25) if cursor_only else Color("8da4b1")
	draw_circle(center, PAD_RADIUS, Color("18232d"))
	draw_arc(center, PAD_RADIUS, 0.0, TAU, 72, ring_color, 2.0, true)
	draw_arc(center, RING_INNER, 0.0, TAU, 72, Color(ring_color, 0.6), 2.0, true)
	var dot := center + SCALE_DOT_OFFSET
	var dot_base := Color("354956", 0.4) if cursor_only else Color("354956")
	draw_circle(dot, SCALE_DOT_RADIUS, Color("f2c879") if dragging == "scale" and not cursor_only else dot_base)
	draw_circle(dot, 5, Color("e8eff2", 0.4) if cursor_only else Color("e8eff2"))
	var stick := center + stick_offset
	var stick_color := Color("73e6bb") if dragging == "move" else Color("e8eff2")
	draw_circle(stick, 24, Color("354956"))
	draw_circle(stick, 24, Color("8da4b1"), false, 2.0)
	draw_circle(stick, 8, stick_color)

func _input(event: InputEvent) -> void:
	# A hidden pad must never steal touches from the canvas.
	if not is_visible_in_tree():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var local_position: Vector2 = event.position - global_position
		if event.pressed:
			if Rect2(Vector2.ZERO, size).has_point(local_position) and begin_at(local_position):
				get_viewport().set_input_as_handled()
		else:
			if not dragging.is_empty():
				end_gesture()
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and not dragging.is_empty() and touch_index < 0:
		drag_to(event.position - global_position)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var local_position: Vector2 = event.position - global_position
		if event.pressed and touch_index < 0:
			if Rect2(Vector2.ZERO, size).has_point(local_position) and begin_at(local_position):
				touch_index = event.index
				get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == touch_index:
			touch_index = -1
			end_gesture()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == touch_index and not dragging.is_empty():
		drag_to(event.position - global_position)
		get_viewport().set_input_as_handled()
