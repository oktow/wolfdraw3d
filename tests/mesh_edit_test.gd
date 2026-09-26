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
	# Rename the object; undo restores the old title.
	app.guides.rename_target("Kotak Uji")
	assert(app.guides.current().title == "Kotak Uji")
	app.undo()
	assert(app.guides.current().title != "Kotak Uji")
	# Vertex mode: tap selects corner 0, tap again deselects.
	app.set_tool("select")
	app.set_vertex_edit(true)
	assert(app.vertex_edit and app.selected_strokes.is_empty())
	assert(app.rail_subobj_button.button_pressed)
	var corner_screen: Vector2 = app.camera.unproject_position(app.guides.current().corners[0])
	var mesh_center_screen: Vector2 = app.camera.unproject_position(app.guides.current().center())
	var corner_tap: Vector2 = corner_screen + (mesh_center_screen - corner_screen).normalized() * 10.0
	app.edit_at(corner_tap)
	assert(app.selected_guide_vertices == [0])
	app.edit_at(corner_tap)
	assert(app.selected_guide_vertices.is_empty())
	app.edit_at(corner_tap)
	assert(app.selected_guide_vertices == [0])
	# Move one vertex; a plane is promoted to an equivalent 2x2 mesh
	# (a plane cannot bend one corner and stay a rectangle); undo restores.
	var moved_before: PackedVector3Array = app.guides.current().corners.duplicate()
	app.transform_guide_vertices(Vector3(1, 0, 0))
	assert(app.guides.current().kind == "mesh")
	assert(app.guides.current().vertices[0].is_equal_approx(moved_before[0] + Vector3(1, 0, 0)))
	for i in [1, 2, 3]:
		assert(app.guides.current().vertices[i].is_equal_approx(moved_before[i]))
	assert(Store.validate(app.document()).is_empty())
	app.undo()
	assert(app.guides.current().kind == "plane")
	assert(app.guides.current().corners == moved_before)
	# Mesh vertices move through the same path, then everything is cleaned.
	app.guides.save_active()
	app.guides.create_cube()
	assert(app.guides.current().kind == "mesh")
	app.set_vertex_edit(true)
	app.set_tool("select")
	var apex_screen: Vector2 = app.camera.unproject_position(app.guides.current().vertices[0])
	var apex_tap: Vector2 = apex_screen + (app.camera.unproject_position(app.guides.current().center()) - apex_screen).normalized() * 10.0
	var picked: int = app.pick_guide_vertex(apex_tap)
	assert(picked >= 0)
	app.edit_at(apex_tap)
	assert(app.selected_guide_vertices == [picked])
	var cube_before: PackedVector3Array = app.guides.current().vertices.duplicate()
	app.transform_guide_vertices(Vector3(0, 2, 0))
	assert(app.guides.current().vertices[picked].is_equal_approx(cube_before[picked] + Vector3(0, 2, 0)))
	assert(Store.validate(app.document()).is_empty())
	app.undo()
	assert(app.guides.current().vertices == cube_before)
	app.undo()
	app.undo()
	app.set_vertex_edit(false)
	for i in cleanups + 1:
		app.undo()
	assert(app.document() == before)
	print("MESH PASS: rename, vertex tap/deselect, plane+mesh move, validation, undo restore")
	return true
