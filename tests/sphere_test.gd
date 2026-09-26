extends RefCounted

const Store = preload("res://scripts/project_store.gd")

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
	app.guides.create_sphere()
	var surface: MeshInstance3D = app.guides.current()
	assert(surface != null)
	assert(surface.kind == "mesh")
	assert(surface.vertices.size() == surface.columns * surface.rows)
	assert(surface.columns >= 3 and surface.rows >= 2)
	# NOTE: average-based center() is seam-biased on wrapped grids (the
	# duplicated seam column double-counts one side); the AABB center is exact.
	var center: Vector3 = surface.bounds.get_center()
	for point in surface.vertices:
		assert(point.distance_to(center) > 0.0)
	# Radius uniformity: every vertex sits on the ball shell.
	var radii := []
	for point in surface.vertices:
		radii.append(point.distance_to(center))
	radii.sort()
	assert(radii[-1] - radii[0] < maxf(0.05, radii[-1] * 0.05))
	assert(Store.validate(app.document()).is_empty())
	for i in cleanups + 1:
		app.undo()
	assert(app.document() == before)
	print("SPHERE PASS: grid ball creation, shell uniformity, validation, undo restore")
	return true
