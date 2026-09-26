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
	app.guides.quick_plane()
	assert(app.guides.current() != null)
	app.set_vertex_edit(true)
	app.set_tool("select")
	# Valid live drag: ticks move geometry cheaply, finish validates once.
	app.selected_guide_vertices.assign([0])
	app.push_subobj_selection()
	var pristine: PackedVector3Array = app.guides.current().corners.duplicate()
	app.checkpoint()
	for i in 3:
		app.transform_guide_vertices(Vector3(0.1, 0, 0), 0.0, 1.0, Vector3.ZERO, false, true)
	assert(app.guides.current().kind == "mesh")
	assert(app.guides.current().vertices[0].is_equal_approx(pristine[0] + Vector3(0.3, 0, 0)))
	app.finish_vertex_drag()
	assert(Store.validate(app.document()).is_empty())
	app.undo()
	assert(app.guides.current().kind == "plane")
	assert(app.guides.current().corners == pristine)
	# Degenerate live drag: collapsing every corner reverts on finish.
	app.selected_guide_vertices.assign([0, 1, 2, 3])
	app.push_subobj_selection()
	app.checkpoint()
	app.transform_guide_vertices(Vector3.ZERO, 0.0, 0.0, Vector3.ZERO, false, true)
	app.finish_vertex_drag()
	assert(app.guides.current().kind == "plane")
	assert(app.guides.current().corners == pristine)
	assert(Store.validate(app.document()).is_empty())
	app.set_vertex_edit(false)
	for i in cleanups + 1:
		app.undo()
	assert(app.document() == before)
	print("DRAG PASS: live ticks, single finish validation, degenerate revert, undo restore")
	return true
