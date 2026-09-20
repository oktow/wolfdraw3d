extends RefCounted

const Store = preload("res://scripts/project_store.gd")
const Previous = preload("res://tests/stage2_test.gd")

func reset(app: Node) -> void:
	app.restore_document({"format": Store.FORMAT, "version": 2,
		"groups": [{"id": 0, "name": "Grup 1", "visible": true}], "active_group": 0,
		"strokes": [], "guides": [], "active_guide": -1})
	app.history.clear()
	app.future.clear()
	app.target = Vector3.ZERO
	app.distance = 12
	app.yaw = 0
	app.pitch = 0
	app.update_camera()
	app.current_path = ""
	app.saved_state = Store.encode(app.document())
	app.set_tool("draw")
	app.changed()

func mouse(app: Node, position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	app._input(event)
	if pressed:
		app._unhandled_input(event)

func run(app: Node) -> void:
	var helper := Previous.new()
	assert(helper.run(app), "Prior editing/storage regression must pass")
	reset(app)
	var temp := "user://guide-test-%d" % Time.get_ticks_usec()
	assert(DirAccess.make_dir_recursive_absolute(temp) == OK)
	app.autosave_path = temp + "/autosave.wolf3d"
	var center: Vector2 = app.get_viewport().get_visible_rect().size / 2
	assert(app.guides.current() == null)
	app.begin_stroke(center)
	assert(app.active == null and app.strokes.is_empty(), "No guide means no ink")
	# Dragging in creation mode builds a preview surface, not a brush stroke.
	app.guides.start_placing()
	mouse(app, center - Vector2(220, 170), true)
	app.extend_stroke(center + Vector2(220, 170))
	assert(app.guides.preview != null and app.guides.current() == null)
	assert(app.strokes.is_empty() and app.history.is_empty())
	mouse(app, center + Vector2(220, 170), false)
	assert(app.guides.current() != null and not app.guides.placing)
	assert(app.guides.current().mesh.get_surface_count() == 1)
	assert(app.strokes.is_empty() and app.history.size() == 1)
	assert(app.hit_point(center) != null)
	assert(app.hit_point(center + Vector2(300, 0)) == null, "Finite surface bounds")
	var first_geometry: PackedVector3Array = app.guides.current().corners.duplicate()
	helper.draw(app, center - Vector2(100, 50), center + Vector2(100, 50))
	assert(app.strokes.size() == 1)
	var first_ink: PackedVector3Array = app.strokes[0].points.duplicate()
	app.orbit(Vector2(80, 30))
	app.pan(Vector2(15, 5))
	app.zoom(0.9)
	assert(app.guides.current().corners == first_geometry, "Navigation cannot alter an active surface")
	assert(app.strokes[0].points == first_ink)
	# Inspect the back of the same surface and draw on it.
	app.target = Vector3.ZERO
	app.yaw = PI
	app.pitch = 0
	app.update_camera()
	assert(app.hit_point(center) != null, "Guide must be drawable from its back")
	helper.draw(app, center - Vector2(80, 20), center + Vector2(80, 20))
	for point in app.strokes[-1].points:
		assert(absf(point.z) < 0.00001)
	# Opacity affects display, never the drawing target; one drag is one undo.
	var old_opacity: float = app.guides.current().opacity
	var history_size: int = app.history.size()
	app.guides.begin_opacity()
	app.guides.change_opacity(0.1)
	app.guides.change_opacity(0.0)
	app.guides.end_opacity(true)
	assert(app.history.size() == history_size + 1)
	assert(app.hit_point(center) != null and app.guides.current().opacity == 0)
	app.undo()
	assert(app.guides.current().opacity == old_opacity)
	app.redo()
	assert(app.guides.current().opacity == 0)
	app.undo()
	# Close removes an unsaved guide, not ink; undo restores the surface.
	var ink_count: int = app.strokes.size()
	app.guides.close_active()
	assert(app.guides.current() == null and app.guides.surfaces.is_empty())
	assert(app.strokes.size() == ink_count)
	app.undo()
	assert(app.guides.current() != null and app.strokes.size() == ink_count)
	app.guides.save_active()
	assert(app.guides.current() == null and app.guides.surfaces.size() == 1)
	assert(app.guides.surfaces[0].saved and app.guides.surfaces[0].visible)
	assert(app.hit_point(center) == null, "Visible inactive resource must not receive ink")
	# A second independent guide is created from a different view.
	app.yaw = -0.9
	app.pitch = 0.15
	app.update_camera()
	app.guides.quick_plane()
	assert(app.guides.surfaces.size() == 2 and app.guides.active_id == 1)
	assert(app.guides.surfaces[0].corners == first_geometry)
	var current_id: int = app.guides.active_id
	app.guides.start_placing()
	assert(not app.guides.placing and app.guides.active_id == current_id, "Active guide blocks creation")
	app.set_brush_color(Color("ffbd78"))
	helper.draw(app, center - Vector2(130, 80), center + Vector2(110, -50))
	assert(app.strokes.size() == ink_count + 1)
	app.guides.save_active()
	app.guides.picker.select(app.guides.picker.get_item_index(0))
	app.guides.activate_picked()
	assert(app.guides.active_id == 0)
	app.guides.toggle_visibility()
	assert(app.guides.active_id == -1 and not app.guides.surfaces[0].visible)
	app.undo()
	assert(app.guides.active_id == 0 and app.guides.surfaces[0].visible)
	app.guides.close_active()
	assert(app.guides.surfaces.size() == 2 and not app.guides.surfaces[0].visible)
	app.guides.picker.select(app.guides.picker.get_item_index(0))
	app.guides.activate_picked()
	app.face_guide()
	assert(app.hit_point(center) != null)
	# Round-trip active and inactive resources, visibility, opacity, and ink.
	var expected: Dictionary = app.document()
	assert(Store.validate(expected).is_empty())
	assert(app.save_to(temp + "/guides.wolf3d"))
	app.guides.close_active()
	assert(app.load_from(temp + "/guides.wolf3d"))
	assert(helper.equivalent(app.document(), expected))
	assert(app.guides.current() != null and app.guides.surfaces.size() == 2)
	app.guides.change_opacity(0.35)
	assert(app.autosave())
	assert(app.load_from(app.autosave_path, true))
	assert(is_equal_approx(app.guides.current().opacity, 0.35) and app.dirty)
	# Validate before mutating: unsupported meshes, broken rectangles, bad IDs.
	var malformed := expected.duplicate(true)
	malformed.guides[0].corners[2] = [0, 0, 99]
	assert(not Store.validate(malformed).is_empty())
	malformed = expected.duplicate(true)
	malformed.active_guide = 900
	assert(not Store.validate(malformed).is_empty())
	malformed = expected.duplicate(true)
	malformed.guides[0].visible = false
	assert(not Store.validate(malformed).is_empty())
	malformed = expected.duplicate(true)
	malformed.guides[0].opacity = 1
	assert(not Store.validate(malformed).is_empty())
	# Legacy v1 loads without fabricating guides or changing existing ink.
	var legacy := expected.duplicate(true)
	legacy.version = 1
	legacy.erase("guides")
	legacy.erase("active_guide")
	var file := FileAccess.open(temp + "/legacy.wolf3d", FileAccess.WRITE)
	file.store_string(Store.encode(legacy))
	file.close()
	assert(app.load_from(temp + "/legacy.wolf3d"))
	assert(app.guides.surfaces.is_empty() and app.guides.active_id == -1)
	assert(helper.equivalent(app.document().strokes, legacy.strokes))
	assert(app.save_to(temp + "/upgraded.wolf3d"))
	assert(Store.load_project(temp + "/upgraded.wolf3d").data.version == Store.VERSION)
	# Two fingers, navigation, and focus loss must cancel unfinished previews.
	app.set_finger_drawing(true)
	app.guides.start_placing()
	var finger := InputEventScreenTouch.new()
	finger.index = 0
	finger.position = center - Vector2(80, 80)
	finger.pressed = true
	app._unhandled_input(finger)
	app.extend_stroke(center + Vector2(80, 80))
	assert(app.guides.preview != null)
	var second := InputEventScreenTouch.new()
	second.index = 1
	second.position = center
	second.pressed = true
	app._unhandled_input(second)
	assert(app.guides.preview == null and app.guides.current() == null)
	second.pressed = false
	app._input(second)
	finger.pressed = false
	app._input(finger)
	assert(app.guides.current() == null and app.touches.is_empty())
	app.guides.begin_preview(center - Vector2(80, 80))
	app.guides.extend_preview(center + Vector2(80, 80))
	app.orbit(Vector2(10, 0))
	assert(app.guides.preview == null)
	app.guides.begin_preview(center)
	app.cancel_input()
	assert(app.guides.preview == null)
	# Delete a saved resource is undoable and leaves ink intact.
	assert(app.load_from(temp + "/guides.wolf3d"))
	app.guides.picker.select(0)
	app.guides.delete_picked()
	assert(app.guides.surfaces.size() == 1 and app.strokes.size() == expected.strokes.size())
	app.undo()
	assert(helper.equivalent(app.document(), expected))
	assert(preload("res://tests/touch_test.gd").new().run(app))
	assert(preload("res://tests/view_test.gd").new().run(app))
	assert(await preload("res://tests/profile_test.gd").new().run(app, temp))
	assert(await preload("res://tests/projection_test.gd").new().run(app, temp))
	assert(await preload("res://tests/eraser_test.gd").new().run(app, temp))
	assert(await preload("res://tests/ink_test.gd").new().run(app, temp))
	assert(await preload("res://tests/shape_test.gd").new().run(app, temp))
	app.yaw = 0.65
	app.pitch = 0.3
	app.distance = 13
	app.update_camera()
	print("GUIDE 3A PASS: explicit creation, mesh bounds, backface ink, stable orbit, lifecycle, opacity, history, resources, v2 round-trip, v1 migration, autosave, gesture cancellation")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		app.get_viewport().get_texture().get_image().save_png("res://build/guide-3a.png")
		if "--capture-menu" in OS.get_cmdline_user_args():
			app.toggle_menu()
			await RenderingServer.frame_post_draw
			app.get_viewport().get_texture().get_image().save_png("res://build/menu-hidden.png")
			app.show_menu_button.pressed.emit()
			await RenderingServer.frame_post_draw
			app.get_viewport().get_texture().get_image().save_png("res://build/menu-restored.png")
			app.set_projection(1)
			await RenderingServer.frame_post_draw
			app.get_viewport().get_texture().get_image().save_png("res://build/orthographic.png")
			app.view_menu.show_popup()
			await RenderingServer.frame_post_draw
			app.get_viewport().get_texture().get_image().save_png("res://build/view-dropdown.png")
			app.view_menu.get_popup().hide()
			app.set_projection(0)
		if "--capture-picker" in OS.get_cmdline_user_args():
			app.brush_picker.get_popup().popup_centered()
			await RenderingServer.frame_post_draw
			app.get_viewport().get_texture().get_image().save_png("res://build/color-picker.png")
	for name in DirAccess.get_files_at(temp):
		DirAccess.remove_absolute(temp.path_join(name))
	DirAccess.remove_absolute(temp)
	app.get_tree().quit()
