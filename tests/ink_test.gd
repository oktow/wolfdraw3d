extends RefCounted

const Stroke = preload("res://scripts/stroke.gd")
const Store = preload("res://scripts/project_store.gd")

func run(app: Node3D, temp: String) -> bool:
	var original: Dictionary = app.document()
	var helper = preload("res://tests/stage2_test.gd").new()
	app.restore_document({"format": Store.FORMAT, "version": Store.VERSION, "groups": [{"id": 0, "name": "Brush", "visible": true}], "active_group": 0, "strokes": [], "guides": [], "active_guide": -1})
	app.target = Vector3.ZERO
	app.distance = 10
	app.set_projection(1)
	app.snap_view(Vector3.BACK)
	var row := 0
	for kind in ["pen", "pencil", "brush"]:
		var stroke := Stroke.new()
		stroke.brush_kind = kind
		stroke.radius = 0.11
		stroke.opacity = 0.8
		stroke.ink = Color("263238")
		app.add_child(stroke)
		for i in range(61):
			stroke.add_point(Vector3(-2.6 + i * 0.0867, 1.2 - row * 1.1 + sin(i * 0.12) * 0.25, 0), Vector3.BACK)
		app.strokes.append(stroke)
		var arrays: Array = stroke.mesh.surface_get_arrays(0)
		assert(arrays[Mesh.ARRAY_VERTEX].size() == stroke.points.size() * 2)
		assert(arrays[Mesh.ARRAY_TEX_UV].size() == stroke.points.size() * 2)
		assert(stroke.material_override is ShaderMaterial)
		assert(is_equal_approx(stroke.material_override.get_shader_parameter("opacity"), 0.8))
		stroke.set_selected(true)
		assert(stroke.material_override.get_shader_parameter("selected"))
		stroke.set_selected(false)
		row += 1
	var intact: Dictionary = app.document()
	assert(Store.validate(intact).is_empty())
	assert(Store.save_project(temp + "/ink.wolf3d", intact) == OK)
	assert(helper.equivalent(Store.load_project(temp + "/ink.wolf3d").data, intact))
	app.restore_document(Store.load_project(temp + "/ink.wolf3d").data)
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		app.get_viewport().get_texture().get_image().save_png("res://build/grease-style-brushes.png")
	# Erase across all styles without resetting UV coordinates or taper endpoints.
	app.eraser.begin(Vector2(640, 220))
	app.eraser.extend(Vector2(640, 590))
	app.eraser.finish()
	assert(app.strokes.size() == 6)
	for stroke in app.strokes:
		assert(stroke.sample_normals.size() == stroke.points.size())
		assert(stroke.path_uv.size() == stroke.points.size())
		assert(stroke.opacity == 0.8 and stroke.taper == 0.15)
		var source: Dictionary = intact.strokes[["pen", "pencil", "brush"].find(stroke.brush_kind)]
		assert(is_equal_approx(stroke.uv_length, source.uv_length))
		if stroke.points[0].x > 0:
			assert(stroke.path_uv[0] > 1.0, "Eraser must not restart the texture")
	assert(Store.validate(app.document()).is_empty())
	app.undo()
	assert(helper.equivalent(app.document(), intact))
	app.redo()
	assert(app.strokes.size() == 6)
	var uv: PackedFloat32Array = app.strokes[0].path_uv.duplicate()
	app.transform_group(Vector3.ZERO, 0.5, 1.1)
	assert(app.strokes[0].path_uv == uv)
	assert(Store.validate(app.document()).is_empty())
	var bad: Dictionary = intact.duplicate(true)
	bad.strokes[0].normals.pop_back()
	assert(not Store.validate(bad).is_empty())
	bad = intact.duplicate(true)
	bad.strokes[0].uv[1] = -1
	assert(not Store.validate(bad).is_empty())
	# Legacy stroke dictionaries remain tubes without forced visual conversion.
	var old := Stroke.new()
	old.restore({"points": [[0,0,0],[1,0,0]], "radius": 0.04, "color": [0,0,0,1], "normal": [0,0,1], "group": 0})
	assert(old.brush_kind == "tube" and old.material_override is StandardMaterial3D)
	old.free()
	app.restore_document(original)
	app.set_projection(0)
	app.set_tool("draw")
	app.face_guide()
	print("INK PASS: flat textured shaders, opacity/taper, v4 roundtrip, eraser UV/normal preservation, undo/redo, group transforms, validation, legacy tubes")
	return true
