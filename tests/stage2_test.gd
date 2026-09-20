extends RefCounted

const Store = preload("res://scripts/project_store.gd")
const Stroke = preload("res://scripts/stroke.gd")

func equivalent(a: Variant, b: Variant) -> bool:
	if (a is float or a is int) and (b is float or b is int):
		return is_equal_approx(float(a), float(b))
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size():
			return false
		for key in a:
			if not b.has(key) or not equivalent(a[key], b[key]):
				return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for i in a.size():
			if not equivalent(a[i], b[i]):
				return false
		return true
	return a == b

func draw(app: Node, start: Vector2, end: Vector2) -> void:
	app.begin_stroke(start)
	for i in range(1, 13):
		app.extend_stroke(start.lerp(end, i / 12.0))
	app.finish_stroke()

func run(app: Node) -> bool:
	var center: Vector2 = app.get_viewport().get_visible_rect().size / 2
	var test_dir := "user://stage2-test-%d" % Time.get_ticks_usec()
	assert(DirAccess.make_dir_recursive_absolute(test_dir) == OK)
	app.autosave_path = test_dir + "/autosave.wolf3d"
	var path := test_dir + "/drawing.wolf3d"
	app.guides.create_plane(Transform3D.IDENTITY, Vector2(8, 8))
	draw(app, center - Vector2(90, 0), center + Vector2(90, 0))
	assert(app.strokes.size() == 1 and app.strokes[0].mesh.get_surface_count() == 1)
	var original: Vector3 = app.strokes[0].points[0]
	app.guides.close_active()
	app.guides.create_plane(Transform3D(Basis.IDENTITY, Vector3(0, 0, 2)), Vector2(8, 8))
	assert(app.strokes[0].points[0] == original)
	draw(app, center - Vector2(90, 0), center + Vector2(90, 0))
	assert(app.strokes.size() == 2 and absf(app.strokes[1].points[0].z - 2) < 0.001)
	assert(app.pick_stroke(center) == app.strokes[1], "Closest overlapping stroke must win")
	app.undo()
	assert(app.strokes.size() == 1 and app.future.size() == 1)
	app.redo()
	assert(app.strokes.size() == 2 and app.future.is_empty())
	app.set_tool("select")
	app.edit_at(center)
	assert(app.selected == app.strokes[1])
	app.delete_selected()
	assert(app.strokes.size() == 1)
	app.undo()
	assert(app.strokes.size() == 2)
	app.redo()
	assert(app.strokes.size() == 1)
	app.undo()
	app.add_group()
	assert(app.groups.size() == 2 and app.future.is_empty())
	app.group_name.text = "Detail"
	app.rename_group()
	assert(app.group_data(app.active_group).name == "Detail")
	app.choose_stroke(app.strokes[1])
	app.move_selected_to_group()
	assert(app.strokes[1].group_id == app.active_group)
	app.toggle_group(false)
	assert(not app.strokes[1].visible and app.selected == null)
	assert(app.pick_stroke(center) == app.strokes[0], "Hidden ink must not be pickable")
	app.undo()
	assert(app.strokes[1].visible)
	var before: Dictionary = app.document()
	app.transform_group(Vector3(0.25, 0.5, -0.25), 15, 1.1)
	assert(app.strokes[0].points[0] == original, "Transform must affect only active group")
	assert(absf(app.strokes[1].radius - 0.0385) < 0.0001)
	app.undo()
	assert(app.document() == before, "Transform undo must restore exact samples")
	app.redo()
	assert(app.document() != before)
	var expected_data: Dictionary = app.document()
	var expected: String = Store.encode(expected_data)
	assert(app.save_to(path))
	assert(not app.dirty and app.current_path == path)
	app.choose_stroke(app.strokes[0])
	app.delete_selected()
	assert(app.dirty)
	assert(app.load_from(path))
	assert(equivalent(app.document(), expected_data), "Round trip must preserve geometry and groups")
	assert(not app.dirty and app.history.is_empty())
	# Invalid input must not change the live document.
	var invalid := FileAccess.open(test_dir + "/invalid.wolf3d", FileAccess.WRITE)
	invalid.store_string('{"format":"wolfdraw3d","version":999}')
	invalid.close()
	assert(not app.load_from(test_dir + "/invalid.wolf3d"))
	assert(equivalent(app.document(), expected_data))
	var bad: Dictionary = app.document()
	bad.strokes[0].normal = [0, 0, 0]
	assert(not Store.validate(bad).is_empty())
	bad = app.document()
	bad.strokes[0].points[0][0] = "not a number"
	assert(not Store.validate(bad).is_empty())
	bad = app.document()
	bad.strokes[0].group = 999
	assert(not Store.validate(bad).is_empty())
	# A failed temp write leaves the original bytes untouched.
	assert(DirAccess.make_dir_absolute(path + ".tmp") == OK)
	assert(Store.save_project(path, app.document()) != OK)
	assert(FileAccess.get_file_as_string(path) == expected)
	assert(DirAccess.remove_absolute(path + ".tmp") == OK)
	# A blocked backup rotation must also leave the original file intact.
	assert(DirAccess.make_dir_absolute(path + ".bak") == OK)
	assert(Store.save_project(path, app.document()) != OK)
	assert(FileAccess.get_file_as_string(path) == expected)
	assert(DirAccess.remove_absolute(path + ".bak") == OK)
	# Saving again creates a backup; corrupting primary exercises recovery.
	assert(Store.save_project(path, app.document()) == OK)
	var corrupt := FileAccess.open(path, FileAccess.WRITE)
	corrupt.store_string("incomplete JSON")
	corrupt.close()
	var recovered := Store.load_project(path)
	assert(recovered.error.is_empty() and recovered.recovered)
	assert(equivalent(recovered.data, expected_data))
	assert(app.load_from(path) and app.dirty and app.current_path.is_empty())
	assert(app.autosave())
	assert(FileAccess.file_exists(app.autosave_path))
	assert(app.load_from(app.autosave_path, true))
	assert(app.dirty and app.current_path.is_empty())
	assert(equivalent(app.document(), expected_data))
	# Recovery must wait for a decision, even while the blank scene is clean.
	var autosave_bytes := FileAccess.get_file_as_string(app.autosave_path)
	app.recovery_pending = true
	app.dirty = false
	assert(app.autosave())
	assert(FileAccess.get_file_as_string(app.autosave_path) == autosave_bytes)
	app.recovery_pending = false
	app.dirty = true
	assert(app.save_to(test_dir + "/clean.wolf3d"))
	assert(not FileAccess.file_exists(app.autosave_path))
	app.choose_stroke(app.strokes[0])
	app.delete_selected()
	assert(app.autosave() and FileAccess.file_exists(app.autosave_path))
	app.undo()
	assert(not app.dirty)
	assert(app.autosave() and not FileAccess.file_exists(app.autosave_path), "Undo to saved state must clear stale recovery")
	app.choose_stroke(app.strokes[0])
	app.delete_selected()
	assert(app.autosave())
	assert(app.load_from(test_dir + "/clean.wolf3d"))
	assert(not FileAccess.file_exists(app.autosave_path), "Opening a saved project must clear stale recovery")
	for file in DirAccess.get_files_at(test_dir):
		DirAccess.remove_absolute(test_dir.path_join(file))
	DirAccess.remove_absolute(test_dir)
	print("STAGE 2 REGRESSION PASS: editing, groups, history, storage, recovery, autosave")
	return true
