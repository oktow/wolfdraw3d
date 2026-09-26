extends Control
const Localization = preload("res://scripts/localization.gd")
## Screen-space swept disk, with reversible live edits and one history entry per drag.

var app: Node3D
var radius := 24.0
var dragging := false
var before: Dictionary = {}
var last := Vector2.ZERO
var cursor := Vector2.ZERO
var cursor_visible := false
var modified := false

func _init(app_node: Node3D) -> void:
	app = app_node
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if cursor_visible and app.tool == "erase":
		draw_arc(cursor, radius, 0, TAU, 64, Color.WHITE, 3, true)
		draw_arc(cursor, radius, 0, TAU, 64, Color("425561"), 1.5, true)

func move_cursor(screen: Vector2) -> void:
	cursor = screen
	cursor_visible = true
	queue_redraw()

func begin(screen: Vector2) -> void:
	app.finish_stroke()
	app.choose_stroke(null)
	before = app.document()
	modified = false
	dragging = true
	last = screen
	extend(screen)

func finish(cancel: bool = false) -> void:
	if not dragging:
		return
	dragging = false
	if modified:
		if cancel:
			app.restore_document(before)
		else:
			app.history.append(before)
			if app.history.size() > 40:
				app.history.pop_front()
			app.future.clear()
		app.changed()
	before = {}
	modified = false
	cursor_visible = false
	queue_redraw()

static func circle_roots(a: Vector2, delta: Vector2, center: Vector2, r: float, cuts: Array[float]) -> void:
	var aa := delta.length_squared()
	if aa < 0.000001:
		return
	var offset := a - center
	var bb := 2 * offset.dot(delta)
	var disc := bb * bb - 4 * aa * (offset.length_squared() - r * r)
	if disc < 0:
		return
	for t in [(-bb - sqrt(disc)) / (2 * aa), (-bb + sqrt(disc)) / (2 * aa)]:
		if t > 0 and t < 1:
			cuts.append(t)

static func retained(a: Vector2, b: Vector2, start: Vector2, end: Vector2, r: float) -> Array[Vector2]:
	var delta := b - a
	var cuts: Array[float] = [0.0, 1.0]
	circle_roots(a, delta, start, r, cuts)
	circle_roots(a, delta, end, r, cuts)
	var path := end - start
	if path.length_squared() > 0.000001:
		var axis := path.normalized()
		var normal := Vector2(-axis.y, axis.x)
		for boundary in [-r, r]:
			var denominator := delta.dot(normal)
			if absf(denominator) > 0.000001:
				var t: float = (boundary - (a - start).dot(normal)) / denominator
				if t > 0 and t < 1:
					cuts.append(t)
	cuts.sort()
	var result: Array[Vector2] = []
	for i in range(cuts.size() - 1):
		if cuts[i + 1] - cuts[i] < 0.000001:
			continue
		var middle := a + delta * ((cuts[i] + cuts[i + 1]) / 2)
		if middle.distance_to(Geometry2D.get_closest_point_to_segment(middle, start, end)) > r:
			if not result.is_empty() and is_equal_approx(result[-1].y, cuts[i]):
				result[-1].y = cuts[i + 1]
			else:
				result.append(Vector2(cuts[i], cuts[i + 1]))
	return result

func world_fraction(a: Vector3, b: Vector3, t: float) -> float:
	if t == 0 or t == 1:
		return t
	if app.camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		return t
	var za: float = -app.camera.to_local(a).z
	var zb: float = -app.camera.to_local(b).z
	return t * za / ((1 - t) * zb + t * za)

func split(stroke: MeshInstance3D, start: Vector2, end: Vector2) -> Dictionary:
	var chunks: Array[Dictionary] = []
	var current := PackedVector3Array()
	var samples := PackedFloat32Array()
	var touched := false
	for i in range(stroke.points.size() - 1):
		var a: Vector3 = stroke.points[i]
		var b: Vector3 = stroke.points[i + 1]
		var za: float = -app.camera.to_local(a).z
		var zb: float = -app.camera.to_local(b).z
		var intervals: Array[Vector2] = [Vector2(0, 1)]
		# Preserve segments crossing/behind the near plane rather than projecting them backwards.
		if minf(za, zb) > app.camera.near:
			var thickness: float = stroke.radius * app.get_viewport().get_visible_rect().size.y / app.view_height(minf(za, zb))
			intervals = retained(app.camera.unproject_position(a), app.camera.unproject_position(b), start, end, radius + thickness)
		if intervals.size() != 1 or intervals[0] != Vector2(0, 1):
			touched = true
		for interval in intervals:
			var t0 := world_fraction(a, b, interval.x)
			var t1 := world_fraction(a, b, interval.y)
			var first := a.lerp(b, t0)
			var second := a.lerp(b, t1)
			if not current.is_empty() and not current[-1].is_equal_approx(first):
				if current.size() >= 2:
					chunks.append({"points": current, "samples": samples})
				current = PackedVector3Array()
				samples = PackedFloat32Array()
			if current.is_empty():
				current.append(first)
				samples.append(i + t0)
			if not current[-1].is_equal_approx(second):
				current.append(second)
				samples.append(i + t1)
			if interval.y < 1:
				if current.size() >= 2:
					chunks.append({"points": current, "samples": samples})
				current = PackedVector3Array()
				samples = PackedFloat32Array()
		if intervals.is_empty():
			if current.size() >= 2:
				chunks.append({"points": current, "samples": samples})
			current = PackedVector3Array()
			samples = PackedFloat32Array()
	if current.size() >= 2:
		chunks.append({"points": current, "samples": samples})
	return {"touched": touched, "chunks": chunks}

func extend(screen: Vector2) -> void:
	move_cursor(screen)
	if not dragging:
		return
	var replacements := []
	var stroke_count: int = app.strokes.size()
	var point_count: int = app.sample_count()
	var sweep := Rect2(Vector2(minf(last.x, screen.x) - radius, minf(last.y, screen.y) - radius), Vector2(absf(screen.x - last.x) + radius * 2.0, absf(screen.y - last.y) + radius * 2.0))
	for stroke in app.strokes:
		if not stroke.visible:
			continue
		if not app.stroke_covers_rect(stroke, sweep):
			continue
		var result := split(stroke, last, screen)
		if not result.touched:
			continue
		replacements.append([stroke, result.chunks])
		stroke_count += result.chunks.size() - 1
		point_count -= stroke.points.size()
		for chunk in result.chunks:
			point_count += chunk.points.size()
	last = screen
	if stroke_count > 10000 or point_count > app.Store.MAX_POINTS:
		app.status.text = Localization.translate("Potongan eraser melebihi batas proyek.")
		return
	for replacement in replacements:
		var old: MeshInstance3D = replacement[0]
		for chunk in replacement[1]:
			var stroke = app.Stroke.new()
			stroke.points = chunk.points
			stroke.radius = old.radius
			stroke.ink = old.ink
			stroke.plane_normal = old.plane_normal
			stroke.group_id = old.group_id
			stroke.copy_brush(old, chunk.samples)
			stroke.rebuild()
			app.add_child(stroke)
			app.strokes.append(stroke)
		app.strokes.erase(old)
		app.remove_child(old)
		old.queue_free()
		modified = true
