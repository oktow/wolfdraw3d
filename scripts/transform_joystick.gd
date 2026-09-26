extends Control

var app: Node3D
var mode := "move"
var dragging := false
var handle := ""
var last_position := Vector2.ZERO
var history_started := false
var rotate_last_angle := 0.0

func setup(app_node: Node3D) -> void:
	app = app_node
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func set_mode(value: String) -> void:
	mode = value
	queue_redraw()

func _process(_delta: float) -> void:
	if is_instance_valid(app):
		queue_redraw()

func guide_target() -> MeshInstance3D:
	# The active guide (fresh or loaded) is transformable when no ink is selected.
	if not is_instance_valid(app) or not app.selected_strokes.is_empty():
		return null
	if app.guides == null:
		return null
	return app.guides.current()

func cursor_active() -> bool:
	# The 3D cursor is the fallback transform target: move-only, no history.
	if not is_instance_valid(app) or not app.selected_strokes.is_empty():
		return false
	return guide_target() == null

func selected_points() -> PackedVector3Array:
	if not is_instance_valid(app) or app.liquify_active:
		return PackedVector3Array()
	if not app.selected_strokes.is_empty():
		var result := PackedVector3Array()
		for stroke in app.selected_strokes:
			if is_instance_valid(stroke):
				result.append_array(stroke.points)
		return result
	var surface := guide_target()
	if surface == null:
		if cursor_active():
			return PackedVector3Array([app.cursor_pos])
		return PackedVector3Array()
	if surface.kind == "plane":
		return surface.corners.duplicate()
	return surface.vertices.duplicate()

func gizmo_center() -> Vector2:
	var points := selected_points()
	if points.is_empty() or not is_instance_valid(app.camera):
		return Vector2(-1000, -1000)
	var center := Vector3.ZERO
	for point in points:
		center += point
	center /= float(points.size())
	return app.camera.unproject_position(center)

func selected_center_world() -> Vector3:
	var points := selected_points()
	var center := Vector3.ZERO
	for point in points:
		center += point
	return center / float(points.size())

func projected_ring(axis: Vector3, radius: float, world := Vector3.INF) -> PackedVector2Array:
	var center := world if world.is_finite() else selected_center_world()
	var first := axis.cross(Vector3.UP)
	if first.length_squared() < 0.01:
		first = axis.cross(Vector3.RIGHT)
	first = first.normalized()
	var second := axis.cross(first).normalized()
	var depth := maxf(-app.camera.to_local(center).z, 0.01)
	var world_radius: float = radius * app.view_height(depth) / float(get_viewport_rect().size.y)
	var points := PackedVector2Array()
	for index in 65:
		var angle := TAU * float(index) / 64.0
		var world_point: Vector3 = center + (first * cos(angle) + second * sin(angle)) * world_radius
		points.append(app.camera.unproject_position(world_point))
	return points

func axis_direction(axis: Vector3, center: Vector2, world: Vector3) -> Vector2:
	# Use a stable screen direction from the world axis at the selected object's depth.
	var end: Vector2 = app.camera.unproject_position(world + axis * 1.5)
	return (end - center).normalized()

func axis_screen(axis: Vector3, center: Vector2) -> Vector2:
	var points := selected_points()
	if points.is_empty() or not is_instance_valid(app.camera):
		return Vector2.ZERO
	var world_center := Vector3.ZERO
	for point in points:
		world_center += point
	world_center /= float(points.size())
	return axis_direction(axis, center, world_center)

func _draw() -> void:
	if not is_instance_valid(app) or app.liquify_active or app.tool != "select":
		return
	# Single pass over the target points per frame; helpers reuse the cached center.
	# The 3D cursor fallback only moves, whatever mode is picked.
	var points := selected_points()
	if points.is_empty() or not is_instance_valid(app.camera):
		return
	var draw_mode := "move" if cursor_active() else mode
	var world := Vector3.ZERO
	for point in points:
		world += point
	world /= float(points.size())
	var center: Vector2 = app.camera.unproject_position(world)
	var length := 74.0
	var axes := {"x": Vector3.RIGHT, "y": Vector3.UP, "z": Vector3.BACK}
	var colors := {"x": Color("f18cae"), "y": Color("73e6bb"), "z": Color("8eb9ff")}
	# Cursor fallback looks deliberately different so an empty selection is
	# never mistaken for selected ink: dimmed handles, amber core.
	if cursor_active():
		for axis_name in colors:
			colors[axis_name].a = 0.55
		draw_circle(center, 12, Color("18232d"))
		draw_circle(center, 6, Color("ffc570"))
	else:
		draw_circle(center, 12, Color("18232d"))
		draw_circle(center, 6, Color("e8eff2"))
	if draw_mode == "rotate":
		draw_arc(center, 106.0, 0.0, TAU, 72, Color("e8eff2", 0.8), 3, true)
	for axis_name in axes:
		var direction := axis_direction(axes[axis_name], center, world)
		var end: Vector2 = center + direction * length
		var color: Color = colors[axis_name]
		if draw_mode == "move":
			draw_line(center, end, color, 6, true)
			draw_circle(end, 11, color)
			draw_string(ThemeDB.fallback_font, end - Vector2(4, -5), axis_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("18232d"))
		elif draw_mode == "rotate":
			var ring_radius: float = {"x": 66.0, "y": 82.0, "z": 98.0}[axis_name]
			draw_polyline(projected_ring(axes[axis_name], ring_radius, world), color, 5, true)
		else:
			draw_line(center, end, color, 4, true)
			draw_circle(end, 14, color.darkened(0.1))
			draw_circle(end, 7, Color("e8eff2"))
	if draw_mode == "scale":
		draw_circle(center, 18, Color("f2c879"), false, 4)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var local_position: Vector2 = event.position - global_position
		if event.pressed:
			# Never grab while hidden: handles are only drawn in select mode.
			if not is_visible_in_tree() or app.tool != "select" or app.liquify_active:
				return
			if cursor_active() and mode != "move":
				return
			handle = pick_handle(local_position)
			if handle.is_empty():
				return
			dragging = true
			last_position = local_position
			if mode == "rotate":
				rotate_last_angle = (local_position - gizmo_center()).angle()
			history_started = false
			get_viewport().set_input_as_handled()
		else:
			var was_dragging := dragging
			if dragging and history_started:
				app.changed()
			dragging = false
			handle = ""
			history_started = false
			if was_dragging:
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and dragging:
		if app.liquify_active or (app.selected_strokes.is_empty() and guide_target() == null and not cursor_active()):
			dragging = false
			handle = ""
			return
		if cursor_active() and mode != "move":
			dragging = false
			handle = ""
			return
		var local_position: Vector2 = event.position - global_position
		var delta: Vector2 = local_position - last_position
		last_position = local_position
		var for_cursor := cursor_active()
		if not history_started and not for_cursor:
			app.checkpoint()
			history_started = true
		var center := gizmo_center()
		var for_strokes: bool = not app.selected_strokes.is_empty()
		if mode == "move":
			var direction := axis_screen(axis_vector(handle), center)
			var view_scale: float = app.view_height() / float(get_viewport_rect().size.y)
			var shift: Vector3 = axis_vector(handle) * delta.dot(direction) * view_scale
			if for_strokes:
				app.transform_group(shift, 0, 1, Vector3.ZERO, false, true)
			elif not for_cursor:
				app.transform_guide(shift, 0, 1, Vector3.ZERO, false)
			else:
				app.move_cursor(shift)
		elif mode == "rotate":
			var current_angle := (local_position - center).angle()
			var angle_delta := rad_to_deg(angle_difference(rotate_last_angle, current_angle))
			rotate_last_angle = current_angle
			if for_strokes:
				app.transform_group(Vector3.ZERO, angle_delta, 1, axis_vector(handle), false, true)
			else:
				app.transform_guide(Vector3.ZERO, angle_delta, 1, axis_vector(handle), false)
		else:
			var amount := 1.0 + (delta.x + delta.y) * 0.004
			if for_strokes:
				app.transform_group(Vector3.ZERO, 0, clampf(amount, 0.9, 1.1), Vector3.ZERO, false, true)
			else:
				app.transform_guide(Vector3.ZERO, 0, clampf(amount, 0.9, 1.1), Vector3.ZERO, false)
		get_viewport().set_input_as_handled()

func pick_handle(point: Vector2) -> String:
	var center := gizmo_center()
	var axes := {"x": Vector3.RIGHT, "y": Vector3.UP, "z": Vector3.BACK}
	if mode == "scale" and point.distance_to(center) < 28:
		return "scale"
	if mode == "rotate":
		var rings := {"x": 66.0, "y": 82.0, "z": 98.0}
		var best := ""
		var closest := 10.0
		for axis_name in rings:
			var ring := projected_ring(axes[axis_name], rings[axis_name])
			var difference := INF
			for index in range(ring.size() - 1):
				difference = minf(difference, point.distance_to(Geometry2D.get_closest_point_to_segment(point, ring[index], ring[index + 1])))
			if difference < closest:
				closest = difference
				best = axis_name
		return best
	for axis_name in axes:
		var end: Vector2 = center + axis_screen(axes[axis_name], center) * 74
		if point.distance_to(end) < 24:
			return axis_name
	return ""

func axis_vector(name: String) -> Vector3:
	return {"x": Vector3.RIGHT, "y": Vector3.UP, "z": Vector3.BACK}.get(name, Vector3.ZERO)
