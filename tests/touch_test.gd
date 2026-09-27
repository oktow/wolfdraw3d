extends RefCounted

func press(app: Node, index: int, position: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = true
	if app.touches.is_empty():
		app._unhandled_input(event)
	else:
		app._input(event)

func drag(app: Node, index: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	app._input(event)

func release(app: Node, index: int, canceled: bool = false) -> void:
	if not app.touches.has(index):
		return
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = app.touches[index]
	event.pressed = false
	event.canceled = canceled
	app._input(event)

func run(app: Node) -> bool:
	var before: Dictionary = app.document()
	var center: Vector2 = app.get_viewport().get_visible_rect().size / 2
	app.set_tool("draw")
	app.set_finger_drawing(false)
	app.face_guide()
	app.distance = 12
	app.update_camera()
	var initial_yaw: float = app.yaw
	press(app, 4, center)
	drag(app, 4, center + Vector2(70, 35))
	assert(app.yaw != initial_yaw and app.active == null, "One finger rotates without drawing")
	release(app, 4)
	assert(app.document() == before, "Navigation leaves ink and guides unchanged")
	# Translate both fingers equally: pan only, no zoom or rotation.
	var initial_distance: float = app.distance
	var initial_target: Vector3 = app.target
	initial_yaw = app.yaw
	press(app, 4, center - Vector2(100, 0))
	press(app, 9, center + Vector2(100, 0))
	drag(app, 4, center + Vector2(-60, 20))
	drag(app, 9, center + Vector2(140, 20))
	app.flush_touch_navigation()
	assert(is_equal_approx(app.distance, initial_distance))
	assert(app.target.distance_to(initial_target) > 0.1 and app.yaw == initial_yaw)
	release(app, 9)
	var camera_after_pair: Transform3D = app.camera.transform
	drag(app, 4, center)
	assert(app.camera.transform == camera_after_pair, "Remaining finger cannot jump into orbit or ink")
	release(app, 4)
	# Pinch around an off-center point and verify that point stays under the fingers.
	var midpoint := center + Vector2(180, 55)
	press(app, 0, midpoint - Vector2(100, 0))
	press(app, 1, midpoint + Vector2(100, 0))
	var plane := Plane(app.camera.basis.z, app.camera.basis.z.dot(app.target))
	var anchor: Vector3 = plane.intersects_ray(app.camera.project_ray_origin(midpoint), app.camera.project_ray_normal(midpoint))
	initial_distance = app.distance
	drag(app, 0, midpoint - Vector2(150, 0))
	drag(app, 1, midpoint + Vector2(150, 0))
	app.flush_touch_navigation()
	assert(is_equal_approx(app.distance, initial_distance * 2 / 3), "Spread fingers zooms in")
	assert(app.camera.unproject_position(anchor).distance_to(midpoint) < 0.01)
	drag(app, 0, midpoint - Vector2(100, 0))
	drag(app, 1, midpoint + Vector2(100, 0))
	app.flush_touch_navigation()
	assert(is_equal_approx(app.distance, initial_distance), "Pinch fingers zooms out")
	assert(app.camera.unproject_position(anchor).distance_to(midpoint) < 0.01)
	# Three fingers suspend navigation, then resume two fingers with a fresh baseline.
	press(app, 2, center)
	camera_after_pair = app.camera.transform
	drag(app, 0, midpoint - Vector2(110, 10))
	app.flush_touch_navigation()
	assert(app.camera.transform == camera_after_pair)
	release(app, 2)
	app.flush_touch_navigation()
	assert(app.camera.transform == camera_after_pair)
	release(app, 0)
	release(app, 1)
	# Finger drawing is explicit; a second finger cancels tentative ink.
	app.face_guide()
	app.set_finger_drawing(true)
	press(app, 0, center - Vector2(60, 20))
	drag(app, 0, center + Vector2(60, 20))
	assert(app.active != null)
	press(app, 1, center + Vector2(100, 50))
	assert(app.active == null)
	drag(app, 0, center + Vector2(70, 30))
	drag(app, 1, center + Vector2(110, 60))
	app.flush_touch_navigation()
	release(app, 1)
	release(app, 0)
	assert(app.document() == before)
	app.face_guide()
	var stroke_count: int = app.strokes.size()
	press(app, 0, center - Vector2(50, 20))
	drag(app, 0, center + Vector2(50, 20))
	release(app, 0)
	assert(app.strokes.size() == stroke_count + 1)
	app.undo()
	# Android cancellation must discard a stroke instead of committing it.
	press(app, 0, center - Vector2(50, 20))
	drag(app, 0, center + Vector2(50, 20))
	release(app, 0, true)
	assert(app.active == null and app.strokes.size() == stroke_count)
	assert(app.touches.is_empty() and not app.touch_blocked)
	# Backgrounding must clear pointer IDs so the next gesture starts fresh.
	app.set_finger_drawing(false)
	press(app, 0, center)
	press(app, 1, center + Vector2(100, 0))
	drag(app, 1, center + Vector2(130, 0))
	app._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	assert(app.touches.is_empty() and not app.pair_pending)
	app.set_finger_drawing(true)
	# Normalize to the icon-rail state before testing compact gesture controls.
	if app.menu_visible:
		app.toggle_menu()
	assert(app.compact_finger_button.visible)
	app.compact_finger_button.pressed.emit()
	assert(not app.finger_drawing)
	initial_yaw = app.yaw
	press(app, 0, center)
	drag(app, 0, center + Vector2(35, 0))
	release(app, 0)
	assert(app.yaw != initial_yaw)
	app.toggle_menu()
	assert(not app.compact_finger_button.visible)
	# Feather gestures: double-tap perfect view, hold orbit/reset, three-finger projection/FOV.
	app.set_finger_drawing(false)
	app.yaw = 0.3
	app.pitch = 0.2
	app.update_camera()
	press(app, 5, center)
	release(app, 5)
	press(app, 5, center)
	release(app, 5)
	assert(app.camera.basis.z == Vector3.BACK, "Double-tap snaps to the nearest standard view")
	# Double-tap snaps in draw mode too, leaving no ink behind.
	app.set_tool("draw")
	app.set_finger_drawing(true)
	app.yaw = 0.3
	app.pitch = 0.2
	app.update_camera()
	var ink_before: int = app.strokes.size()
	press(app, 5, center)
	release(app, 5)
	press(app, 5, center)
	release(app, 5)
	assert(app.camera.basis.z == Vector3.BACK, "Double-tap snaps in draw mode")
	assert(app.strokes.size() == ink_before and app.active == null)
	app.set_finger_drawing(false)
	app.target = Vector3(3, 4, 5)
	app.distance = 20
	app.update_camera()
	press(app, 5, Vector2(40, 40))
	app.touch_press_msec -= 1000
	app.tick_touch_hold()
	assert(app.hold_fired, "Stationary hold fires after half a second")
	release(app, 5)
	assert(app.target != Vector3(3, 4, 5), "Hold re-targets the orbit point or resets the view")
	var proj_before: int = app.camera.projection
	press(app, 0, center - Vector2(60, 0))
	press(app, 1, center + Vector2(60, 0))
	press(app, 2, center + Vector2(0, 60))
	release(app, 2)
	release(app, 0)
	release(app, 1)
	press(app, 0, center - Vector2(60, 0))
	press(app, 1, center + Vector2(60, 0))
	press(app, 2, center + Vector2(0, 60))
	release(app, 2)
	assert(app.camera.projection != proj_before, "Three-finger double-tap toggles the projection")
	release(app, 0)
	release(app, 1)
	press(app, 0, center - Vector2(60, 0))
	press(app, 1, center + Vector2(60, 0))
	press(app, 2, center + Vector2(0, 60))
	var fov_before: float = app.camera.fov
	drag(app, 2, center + Vector2(0, -40))
	assert(app.camera.fov > fov_before, "Three-finger swipe up widens the FOV")
	release(app, 2)
	release(app, 0)
	release(app, 1)
	app.camera.fov = 45.0
	app.update_camera()
	# Draw mode: a drag on empty space orbits without leaving draw mode.
	app.set_tool("draw")
	app.set_finger_drawing(true)
	var had_guide := app.guides.current() != null
	if had_guide:
		app.guides.close_active()
	var yaw_before_empty: float = app.yaw
	press(app, 6, center)
	drag(app, 6, center + Vector2(120, 40))
	assert(app.active == null, "Empty drag in draw mode draws nothing")
	assert(app.yaw != yaw_before_empty, "Empty drag in draw mode orbits")
	release(app, 6)
	if had_guide:
		app.undo()
	# Fill tools orbit when started outside any guide, fill when inside.
	var prev_brush: String = app.brush_kind
	app.brush_kind = "lasso_fill"
	var fill_had_guide := app.guides.current() != null
	if fill_had_guide:
		app.guides.close_active()
	var yaw_before_fill: float = app.yaw
	press(app, 6, center)
	drag(app, 6, center + Vector2(120, 40))
	assert(app.active == null and not app.fill_active, "Empty fill drag draws nothing")
	assert(app.yaw != yaw_before_fill, "Empty fill drag orbits")
	release(app, 6)
	app.brush_kind = prev_brush
	if fill_had_guide:
		app.undo()
	# Select (tap mode): any drag orbits without leaving the tool.
	app.set_tool("select")
	app.selection_mode = "tap"
	app.set_finger_drawing(true)
	var yaw_before_select: float = app.yaw
	press(app, 6, center)
	drag(app, 6, center + Vector2(120, 40))
	assert(app.yaw != yaw_before_select, "Drag in tap-select orbits")
	release(app, 6)
	# Erase: pressing far from ink orbits instead of erasing.
	app.set_tool("erase")
	var yaw_before_erase: float = app.yaw
	press(app, 6, Vector2(30, 30))
	drag(app, 6, Vector2(150, 70))
	assert(app.yaw != yaw_before_erase, "Empty pressing in erase orbits")
	release(app, 6)
	app.set_tool("draw")
	# Rail sits right of the sidebar with a real width, never inside the menu.
	app.layout_context_rail()
	assert(app.context_rail.offset_left >= 270.0)
	assert(app.context_rail.offset_right - app.context_rail.offset_left >= 48.0)
	# The rail only shows while menus are hidden.
	var menu_was_visible: bool = app.menu_visible
	if menu_was_visible:
		app.toggle_menu()
	# Rail Draw section shows only without an active guide; tap popups mirror live state.
	var rail_had_guide := app.guides.current() != null
	if rail_had_guide:
		app.guides.close_active()
	assert(app.context_rail.visible)
	assert(app.rail_draw_brush_button.visible and not app.rail_guide_save_button.visible)
	app.select_brush_tool(3)
	assert(app.brush_kind == "marker" and app.nib_slider.editable)
	assert(app.rail_draw_brush_button.icon == preload("res://scripts/ui_icons.gd").texture("marker"))
	app.refresh_brush_menu_checks()
	assert(app.brush_tool_menu.is_item_checked(3))
	app.refresh_shape_menu_checks()
	assert(app.compact_shape_menu.is_item_checked(0))
	assert(is_equal_approx(app.rail_props_radius_slider.min_value, 0.005))
	assert(is_equal_approx(app.rail_props_radius_slider.max_value, 0.5))
	app.set_brush_color(Color(1, 0, 0))
	app.sync_rail_props()
	assert(app.rail_props_color.color.is_equal_approx(Color(1, 0, 0)))
	assert(is_equal_approx(app.rail_props_radius_slider.value, app.brush_radius))
	app.rail_props_opacity_slider.set_value(0.5)
	assert(is_equal_approx(app.brush_opacity, 0.5))
	app.rail_props_opacity_slider.set_value(1.0)
	assert(is_equal_approx(app.brush_opacity, 1.0))
	app.set_brush_color(Color("263238"))
	app.select_brush_tool(0)
	assert(app.brush_kind == "pen" and not app.nib_slider.editable)
	if rail_had_guide:
		app.undo()
	else:
		app.guides.quick_plane()
	assert(app.guides.current() != null)
	# Rail mirrors the active tool: Draw shows only its own section even
	# with a guide active; the guide section returns on Select.
	app.set_tool("draw")
	assert(app.rail_draw_brush_button.visible and not app.rail_guide_save_button.visible)
	app.set_tool("select")
	assert(app.rail_guide_save_button.visible and not app.rail_draw_brush_button.visible)
	# Rail Select section and single-tap mode switching (needs no guide).
	app.guides.close_active()
	app.set_tool("select")
	assert(app.context_rail.visible)
	assert(app.rail_select_mode_button.visible and not app.rail_draw_brush_button.visible)
	app.select_mode_pressed(1)
	assert(app.selection_mode == "rectangle")
	app.select_mode_pressed(0)
	assert(app.selection_mode == "tap")
	# Brush select: a swept path selects touched ink, a far path selects nothing.
	app.select_mode_pressed(3)
	assert(app.selection_mode == "brush")
	app.target = Vector3.ZERO
	app.distance = 12
	app.yaw = 0.0
	app.pitch = 0.0
	app.update_camera()
	var BrushStroke = preload("res://scripts/stroke.gd")
	var bsrc = BrushStroke.new()
	bsrc.points = PackedVector3Array([Vector3(-1, 0, 0), Vector3(1, 0, 0)])
	bsrc.rebuild()
	app.add_child(bsrc)
	app.strokes.append(bsrc)
	var bmid: Vector2 = app.camera.unproject_position(Vector3.ZERO)
	app.apply_brush_selection(PackedVector2Array([bmid + Vector2(0, -40), bmid + Vector2(0, 40)]))
	assert(app.selected_strokes.has(bsrc))
	app.deselect_all()
	app.apply_brush_selection(PackedVector2Array([bmid + Vector2(300, 300), bmid + Vector2(360, 340)]))
	assert(app.selected_strokes.is_empty())
	app.select_mode_pressed(0)
	assert(app.selection_mode == "tap")
	app.strokes.erase(bsrc)
	app.remove_child(bsrc)
	bsrc.free()
	# Liquify top icon + session rail: needs a selection, then shows only
	# Liquify controls until applied or cancelled.
	assert(app.compact_liquify_button.visible)
	app.deselect_all()
	app.toggle_liquify_top()
	assert(not app.liquify_active)
	var lsrc = BrushStroke.new()
	lsrc.points = PackedVector3Array([Vector3(-1, 0, 0), Vector3(1, 0, 0)])
	lsrc.rebuild()
	app.add_child(lsrc)
	app.strokes.append(lsrc)
	app.choose_stroke(lsrc)
	app.toggle_liquify_top()
	assert(app.liquify_active)
	assert(app.compact_liquify_button.button_pressed)
	assert(app.rail_liq_apply_button.visible and app.rail_liq_cancel_button.visible)
	assert(not app.rail_draw_brush_button.visible and not app.rail_select_mode_button.visible and not app.rail_guide_new_button.visible)
	app.liquify_cancel()
	assert(not app.liquify_active and not app.compact_liquify_button.button_pressed)
	app.deselect_all()
	app.strokes.erase(lsrc)
	app.remove_child(lsrc)
	lsrc.free()
	# Top icons mirror live state: exactly the active tool stays pressed.
	app.set_tool("select")
	app.refresh_top_icons()
	assert(app.compact_select_button.button_pressed and not app.compact_draw_button.button_pressed)
	app.set_tool("draw")
	app.refresh_top_icons()
	assert(app.compact_draw_button.button_pressed and not app.compact_select_button.button_pressed)
	app.set_rail_transform_mode("rotate")
	assert(app.transform_joystick.mode == "rotate")
	assert(app.rail_mode_rotate_button.button_pressed and not app.rail_mode_move_button.button_pressed)
	app.set_rail_transform_mode("scale")
	assert(app.transform_joystick.mode == "scale")
	assert(app.rail_mode_scale_button.button_pressed and not app.rail_mode_rotate_button.button_pressed)
	app.set_rail_transform_mode("move")
	assert(app.transform_joystick.mode == "move" and app.rail_mode_move_button.button_pressed)
	# 2D pad: toggled rail on the right, tap straight to move/rotate/scale.
	app.set_tool("select")
	assert(not app.pad_rail.visible)
	app.compact_pad_button.button_pressed = true
	app.compact_pad_button.pressed.emit()
	assert(app.pad_visible and app.pad_rail.visible)
	app.pad_stick.size = Vector2(170, 170)
	var pad_center := Vector2(85, 85)
	assert(app.pad_stick.begin_at(pad_center))
	assert(app.pad_stick.dragging == "move")
	app.pad_stick.end_gesture()
	var PadStroke = preload("res://scripts/stroke.gd")
	var pad_stroke = PadStroke.new()
	pad_stroke.points = PackedVector3Array([Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 1, 0)])
	pad_stroke.rebuild()
	app.add_child(pad_stroke)
	app.strokes.append(pad_stroke)
	app.choose_stroke(pad_stroke)
	assert(app.pad_stick.begin_at(pad_center))
	assert(app.pad_stick.dragging == "move")
	app.pad_stick.drag_to(pad_center + Vector2(40, 0))
	assert(pad_stroke.points[0].distance_to(Vector3.ZERO) > 0.01)
	app.pad_stick.end_gesture()
	app.undo()
	pad_stroke = app.strokes[-1]
	assert(pad_stroke.points[0].is_equal_approx(Vector3.ZERO))
	app.choose_stroke(pad_stroke)
	assert(app.pad_stick.begin_at(pad_center + Vector2(0, -67)))
	assert(app.pad_stick.dragging == "rotate")
	app.pad_stick.drag_to(pad_center + Vector2(67, 0))
	assert(not pad_stroke.points[1].is_equal_approx(Vector3(1, 0, 0)))
	app.pad_stick.end_gesture()
	app.undo()
	pad_stroke = app.strokes[-1]
	assert(pad_stroke.points[1].is_equal_approx(Vector3(1, 0, 0)))
	app.choose_stroke(pad_stroke)
	assert(app.pad_stick.begin_at(pad_center + Vector2(41, -63)))
	assert(app.pad_stick.dragging == "scale")
	app.pad_stick.drag_to(pad_center + Vector2(61, -83))
	assert(pad_stroke.points[1].distance_to(pad_stroke.points[0]) > 1.0)
	app.pad_stick.end_gesture()
	app.undo()
	pad_stroke = app.strokes[-1]
	app.strokes.erase(pad_stroke)
	app.remove_child(pad_stroke)
	pad_stroke.free()
	app.deselect_all()
	app.compact_pad_button.button_pressed = false
	app.compact_pad_button.pressed.emit()
	assert(not app.pad_visible and not app.pad_rail.visible)
	app.select_all_visible()
	var expected_selected := []
	for stroke in app.strokes:
		if stroke.visible:
			expected_selected.append(stroke)
	assert(app.selected_strokes == expected_selected)
	app.deselect_all()
	assert(app.selected_strokes.is_empty())
	app.select_group(app.active_group)
	var expected_group := []
	for stroke in app.strokes:
		if stroke.group_id == app.active_group and stroke.visible:
			expected_group.append(stroke)
	assert(app.selected_strokes == expected_group)
	app.deselect_all()
	assert(app.selected_strokes.is_empty())
	# Duplicate stays in place with the new copies selected.
	app.select_all_visible()
	if not app.selected_strokes.is_empty():
		var dup_src: Array = app.selected_strokes.duplicate()
		var dup_count: int = app.strokes.size()
		app.duplicate_selected()
		assert(app.strokes.size() == dup_count + dup_src.size())
		for i in dup_src.size():
			assert(app.selected_strokes[i].points == dup_src[i].points)
			assert(not (dup_src[i] in app.selected_strokes))
		app.undo()
		assert(app.strokes.size() == dup_count)
		app.deselect_all()
	# Mirror seleksi: in place across cursor planes, one undo.
	app.select_all_visible()
	if not app.selected_strokes.is_empty():
		var mir_hist: int = app.history.size()
		app.mirror_selected()
		assert(app.history.size() == mir_hist)
		var mir_before: PackedVector3Array = app.selected_strokes[0].points.duplicate()
		app.mirror_axes["x"] = true
		app.cursor_pos = Vector3(1, 0, 0)
		app.mirror_selected()
		var p0: Vector3 = mir_before[0]
		assert(app.selected_strokes[0].points[0].is_equal_approx(Vector3(2.0 - p0.x, p0.y, p0.z)))
		app.undo()
		var back := false
		for stroke in app.strokes:
			if stroke.points == mir_before:
				back = true
		assert(back)
		app.mirror_axes["x"] = false
		app.cursor_pos = Vector3.ZERO
		app.deselect_all()
	# Mirror reflects across the 3D cursor planes, not the origin.
	var mirror_before: int = app.strokes.size()
	var MirrorStroke = preload("res://scripts/stroke.gd")
	var msrc = MirrorStroke.new()
	msrc.points = PackedVector3Array([Vector3(2, 0, 0), Vector3(3, 0, 0)])
	msrc.rebuild()
	app.add_child(msrc)
	app.strokes.append(msrc)
	app.mirror_axes["x"] = true
	app.cursor_pos = Vector3(1, 0, 0)
	app.mirror_stroke(msrc)
	assert(app.strokes.size() == mirror_before + 2)
	var mirrored: PackedVector3Array = app.strokes[-1].points
	assert(mirrored[0].is_equal_approx(Vector3.ZERO) and mirrored[1].is_equal_approx(Vector3(-1, 0, 0)))
	app.mirror_axes["x"] = false
	app.cursor_pos = Vector3.ZERO
	var mcopy = app.strokes[-1]
	app.strokes.erase(mcopy)
	app.remove_child(mcopy)
	mcopy.free()
	app.strokes.erase(msrc)
	app.remove_child(msrc)
	msrc.free()
	# Hidden transform controls never grab input; hiding mid-drag commits.
	app.select_all_visible()
	if not app.selected_strokes.is_empty():
		app.set_tool("select")
		var hidden_center: Vector2 = app.transform_joystick.gizmo_center()
		var hidden_dir: Vector2 = app.transform_joystick.axis_screen(Vector3.RIGHT, hidden_center)
		var hidden_before: PackedVector3Array = app.selected_strokes[0].points.duplicate()
		app.set_tool("draw")
		var grab := InputEventMouseButton.new()
		grab.button_index = MOUSE_BUTTON_LEFT
		grab.pressed = true
		grab.position = hidden_center + hidden_dir * 74.0
		app.transform_joystick._input(grab)
		assert(not app.transform_joystick.dragging)
		grab.pressed = false
		app.transform_joystick._input(grab)
		app.set_tool("select")
		assert(app.selected_strokes[0].points == hidden_before)
		app.set_tool("draw")
		var pad_press := InputEventMouseButton.new()
		pad_press.button_index = MOUSE_BUTTON_LEFT
		pad_press.pressed = true
		pad_press.position = Vector2(100, 100)
		app.pad_stick._input(pad_press)
		assert(app.pad_stick.dragging.is_empty())
		assert(app.selected_strokes[0].points == hidden_before)
		app.set_tool("select")
		app.pad_stick.size = Vector2(170, 170)
		assert(app.pad_stick.begin_at(Vector2(85, 85)))
		app.pad_stick.drag_to(Vector2(125, 85))
		app.set_tool("draw")
		assert(app.pad_stick.dragging.is_empty())
		assert(app.selected_strokes[0].points != hidden_before)
		app.undo()
		var restored := false
		for stroke in app.strokes:
			if stroke.points == hidden_before:
				restored = true
		assert(restored)
		app.set_tool("select")
		app.deselect_all()
	# Rail Erase section: radius applies through the shared popup slider.
	app.set_tool("erase")
	assert(app.rail_erase_radius_button.visible and not app.rail_select_mode_button.visible)
	var erase_popup_slider: HSlider = app.rail_erase_radius_popup.get_meta("slider")
	erase_popup_slider.set_value(48.0)
	assert(is_equal_approx(app.eraser.radius, 48.0))
	assert(app.eraser_radius_slider.value == 48.0)
	erase_popup_slider.set_value(24.0)
	assert(is_equal_approx(app.eraser.radius, 24.0))
	app.set_tool("draw")
	# Undo the close above plus the quick_plane when this block created it.
	app.undo()
	if not rail_had_guide:
		app.undo()
	# Single creation button opens the type popup; per-type state disables.
	assert(app.rail_guide_new_button.visible)
	var create_had_guide := app.guides.current() != null
	app.refresh_guide_type_menu()
	assert(app.guide_type_menu.item_count == 6)
	assert(app.guide_type_menu.get_item_icon(0).get_width() <= 24)
	assert(app.guide_type_menu.is_item_disabled(2) == (not create_had_guide))
	assert(app.guide_type_menu.is_item_disabled(3) == create_had_guide)
	if create_had_guide:
		app.guides.close_active()
	app.guide_type_menu.id_pressed.emit(3)
	assert(app.guides.placing and app.guides.creation_mode == "cube")
	app.guides.cancel_placing()
	# Polyline commits itself after 2s without new points; no Done button.
	app.guide_type_menu.id_pressed.emit(1)
	assert(app.guides.placing and app.guides.creation_mode == "polyline")
	press(app, 6, center)
	release(app, 6)
	press(app, 6, center + Vector2(80, 40))
	release(app, 6)
	press(app, 6, center + Vector2(-70, 60))
	release(app, 6)
	assert(app.guides.placing and app.guides.current() == null)
	while Time.get_ticks_msec() < 3100:
		OS.delay_msec(50)
	app.guides.poly_last_msec = Time.get_ticks_msec() - 3000
	app.guides.tick_polyline_idle()
	assert(not app.guides.placing and app.guides.current() != null)
	assert(app.guides.current().columns == 3)
	app.undo()
	# Top icon toggles the remembered last rail choice (polyline above).
	assert(app.last_guide_type == "polyline")
	app.toggle_guide_create()
	assert(app.guides.placing and app.guides.creation_mode == "polyline")
	app.toggle_guide_create()
	assert(not app.guides.placing)
	app.guide_type_menu.id_pressed.emit(3)
	assert(app.last_guide_type == "cube")
	app.guides.cancel_placing()
	app.toggle_guide_create()
	assert(app.guides.placing and app.guides.creation_mode == "cube")
	app.guides.cancel_placing()
	app.last_guide_type = "profile"
	app.toggle_guide_create()
	assert(app.guides.placing and app.guides.creation_mode == "profile")
	app.toggle_guide_create()
	assert(not app.guides.placing)
	if create_had_guide:
		app.undo()
	# 3D cursor tool: touch places it, guides are born at it, select moves it.
	var cursor_had_guide := app.guides.current() != null
	if cursor_had_guide:
		app.guides.close_active()
	app.set_tool("cursor")
	assert(app.cursor_button.button_pressed and app.compact_cursor_button.button_pressed)
	app.cursor_pos = Vector3(9, 9, 9)
	press(app, 6, center)
	release(app, 6)
	assert(app.cursor_pos != Vector3(9, 9, 9))
	app.update_status()
	assert("Kursor 3D: (" in app.status.text or "3D cursor: (" in app.status.text)
	app.guides.creation_depth = 0.0
	app.guides.quick_plane()
	assert(app.guides.current() != null)
	assert(app.guides.current().center().is_equal_approx(app.cursor_pos))
	app.undo()
	app.deselect_all()
	app.set_tool("select")
	app.deselect_all()
	assert(app.transform_joystick.selected_points() == PackedVector3Array([app.cursor_pos]))
	assert("kursor" in app.selection_label.text or "cursor" in app.selection_label.text.to_lower())
	assert(app.rail_mode_rotate_button.disabled and app.rail_mode_scale_button.disabled and not app.rail_mode_move_button.disabled)
	assert(app.transform_joystick.cursor_active())
	var cursor_before: Vector3 = app.cursor_pos
	var cursor_history: int = app.history.size()
	app.pad_stick.size = Vector2(170, 170)
	assert(app.pad_stick.begin_at(Vector2(85, 85)))
	app.pad_stick.drag_to(Vector2(125, 85))
	assert(app.cursor_pos != cursor_before)
	assert(app.history.size() == cursor_history)
	app.pad_stick.end_gesture()
	app.cursor_pos = Vector3.ZERO
	app.set_tool("draw")
	if cursor_had_guide:
		app.undo()
	if menu_was_visible:
		app.toggle_menu()
	assert(app.document() == before)
	app.set_finger_drawing(false)
	app.face_guide()
	print("TOUCH PASS: one-finger orbit, two-finger pan, pinch in/out, centroid anchor, finger transitions, draw/navigation separation, cancellation, hidden menus, double-tap view, hold orbit, three-finger projection/FOV, rail draw/select/erase sections, 2D pad")
	return true
