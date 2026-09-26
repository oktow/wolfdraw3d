extends RefCounted

const Store = preload("res://scripts/project_store.gd")

func paint_count(app: Node3D) -> int:
	var count := 0
	for stroke in app.strokes:
		if stroke.brush_kind == "paint":
			count += 1
	return count

func loop_points(center: Vector2, half: float) -> Array:
	return [
		center + Vector2(-half, -half),
		center + Vector2(half, -half),
		center + Vector2(half, half),
		center + Vector2(-half, half),
		center + Vector2(-half, -half),
	]

func draw_loop(app: Node3D, center: Vector2, half: float) -> void:
	var corners: Array = loop_points(center, half)
	app.begin_stroke(corners[0])
	for i in range(1, corners.size()):
		app.extend_stroke(corners[i])
	app.finish_stroke()

func paint_polys_total(app: Node3D) -> int:
	for stroke in app.strokes:
		if stroke.brush_kind == "paint":
			return stroke.paint_polys.size()
	return 0

func run(app: Node3D) -> bool:
	var before: Dictionary = app.document()
	app.set_tool("draw")
	app.target = Vector3.ZERO
	app.distance = 12
	app.yaw = 0
	app.pitch = 0
	app.update_camera()
	var cleanups := 0
	if app.guides.current() != null:
		app.guides.save_active()
		cleanups += 1
	app.guides.quick_plane()
	assert(app.guides.current() != null)
	app.brush_kind = "paint"
	app.ink = Color(1, 0, 0)
	app.brush_opacity = 1.0
	app.set_tool("draw")
	var middle: Vector2 = app.camera.unproject_position(app.guides.current().center())
	# First loop becomes one merged fill object.
	draw_loop(app, middle, 60.0)
	assert(paint_count(app) == 1)
	# An overlapping same-color loop merges instead of adding a stroke.
	draw_loop(app, middle + Vector2(40, 0), 60.0)
	assert(paint_count(app) == 1)
	assert(paint_polys_total(app) >= 1)
	# A disjoint same-color loop must terminate and stay in the same node.
	draw_loop(app, middle + Vector2(150, 0), 30.0)
	assert(paint_count(app) == 1)
	assert(Store.validate(app.document()).is_empty())
	app.undo()
	assert(paint_count(app) == 1)
	# Eraser removes the whole touched blob without errors.
	app.set_tool("erase")
	app.eraser.begin(middle)
	app.eraser.extend(middle)
	app.eraser.finish(false)
	assert(paint_count(app) == 0)
	app.undo()
	assert(paint_count(app) == 1)
	assert(Store.validate(app.document()).is_empty())
	app.brush_kind = "pen"
	for i in cleanups + 3:
		app.undo()
	assert(app.document() == before)
	print("PAINT PASS: closed loop fill, same-color union, eraser blob delete, undo restore")
	return true
