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
	# Edge mode: tap selects the full top border edge, tap again deselects.
	app.set_mesh_select_mode("edge")
	app.set_tool("select")
	var corners: PackedVector3Array = app.guides.current().corners
	var edge_mid: Vector2 = (app.camera.unproject_position(corners[0]) + app.camera.unproject_position(corners[1])) / 2.0
	var tri0_center: Vector2 = (app.camera.unproject_position(corners[0]) + app.camera.unproject_position(corners[1]) + app.camera.unproject_position(corners[2])) / 3.0
	var edge_tap: Vector2 = edge_mid + (tri0_center - edge_mid).normalized() * 6.0
	app.edit_at(edge_tap)
	assert(app.selected_guide_edges == [Vector2i(0, 1)])
	app.edit_at(edge_tap)
	assert(app.selected_guide_edges.is_empty())
	app.edit_at(edge_tap)
	assert(app.selected_guide_edges == [Vector2i(0, 1)])
	# Moving an edge promotes the plane to a mesh and shifts both endpoints.
	var edge_before: PackedVector3Array = app.guides.current().corners.duplicate()
	app.transform_guide_vertices(Vector3(0, 1, 0))
	assert(app.guides.current().kind == "mesh")
	for i in [0, 1]:
		assert(app.guides.current().vertices[i].is_equal_approx(edge_before[i] + Vector3(0, 1, 0)))
	for i in [2, 3]:
		assert(app.guides.current().vertices[i].is_equal_approx(edge_before[i]))
	assert(Store.validate(app.document()).is_empty())
	app.undo()
	assert(app.guides.current().kind == "plane")
	# Extrude grows one grid row from the fully selected boundary edge.
	app.edit_at(edge_tap)
	assert(app.selected_guide_edges == [Vector2i(0, 1)])
	assert(app.can_extrude())
	app.extrude_mesh_boundary()
	assert(app.guides.current().kind == "mesh")
	assert(app.guides.current().rows == 3)
	assert(app.guides.current().vertices.size() == 6)
	assert(Store.validate(app.document()).is_empty())
	app.undo()
	app.undo()
	assert(app.guides.current().kind == "plane")
	assert(app.guides.current().corners == edge_before)
	# Face mode on a cube: tap selects one triangle, transform moves its corners.
	app.guides.save_active()
	app.guides.create_cube()
	assert(app.guides.current().kind == "mesh")
	app.set_mesh_select_mode("face")
	app.set_tool("select")
	var face_tap: Vector2 = app.camera.unproject_position(app.guides.current().center())
	var picked_face: int = app.pick_guide_face(face_tap)
	assert(picked_face >= 0)
	app.edit_at(face_tap)
	assert(app.selected_guide_faces == [picked_face])
	var cube_before: PackedVector3Array = app.guides.current().vertices.duplicate()
	var tri := [app.guides.current().index_cache[picked_face], app.guides.current().index_cache[picked_face + 1], app.guides.current().index_cache[picked_face + 2]]
	app.transform_guide_vertices(Vector3(0, 0.5, 0))
	for idx in tri:
		assert(app.guides.current().vertices[idx].is_equal_approx(cube_before[idx] + Vector3(0, 0.5, 0)))
	assert(Store.validate(app.document()).is_empty())
	app.undo()
	assert(app.guides.current().vertices == cube_before)
	app.undo()
	app.undo()
	app.set_vertex_edit(false)
	app.mesh_select_mode = "vertex"
	for i in cleanups + 1:
		app.undo()
	assert(app.document() == before)
	print("EDGEFACE PASS: edge tap/deselect/move, extrude row, face tap/move, validation, undo restore")
	return true
