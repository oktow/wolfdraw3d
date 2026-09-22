extends Node3D

const Stroke = preload("res://scripts/stroke.gd")
const Store = preload("res://scripts/project_store.gd")
const GuideController = preload("res://scripts/guide_controller.gd")
const PartialEraser = preload("res://scripts/partial_eraser.gd")
const ShapeAssist = preload("res://scripts/shape_assist.gd")
const Icons = preload("res://scripts/ui_icons.gd")
const TransformJoystick = preload("res://scripts/transform_joystick.gd")
const SelectionOverlay = preload("res://scripts/selection_overlay.gd")
const Localization = preload("res://scripts/localization.gd")
const SequenceOverlay = preload("res://scripts/sequence_overlay.gd")
const GifEncoder = preload("res://scripts/gif_encoder.gd")
var mirror_axes := {"x": false, "y": false, "z": false}
var mirror_button: Button
var compact_mirror_button: Button
var mirror_menu: PopupMenu
var icon_help: AcceptDialog
var compact_help_button: Button
var compact_toolbar: HBoxContainer
var compact_draw_button: Button
var compact_guide_button: Button
var compact_guide_menu: PopupMenu
var compact_guide_hold_timer: Timer
var compact_guide_long_pressed := false
var compact_nav_button: Button
var compact_select_button: Button
var compact_duplicate_button: Button
var compact_loft_button: Button
var select_mode_menu: PopupMenu
var select_mode_timer: Timer
var select_mode_long_pressed := false
var selection_mode := "tap"
var selection_overlay: Control
var compact_erase_button: Button
var compact_undo_button: Button
var compact_redo_button: Button
var compact_brush_button: Button
var compact_color_button: ColorPickerButton
var compact_radius_button: Button
var compact_opacity_button: Button
var compact_shape_button: Button
var brush_tool_menu: PopupMenu
var brush_tool_timer: Timer
var brush_tool_long_pressed := false
var compact_shape_menu: PopupMenu
var compact_radius_popup: PopupPanel
var compact_opacity_popup: PopupPanel
var transform_joystick: Control
var transform_joystick_button: Button
var transform_mode_menu: PopupMenu
var transform_mode_timer: Timer
var transform_mode_long_pressed := false
var shape_assist: RefCounted
var shape_picker: OptionButton
var eraser: Control
var eraser_controls: VBoxContainer
var camera := Camera3D.new()
var reference_grid := Node3D.new()
var guides: RefCounted
var strokes: Array[MeshInstance3D] = []
var history: Array[Dictionary] = []
var future: Array[Dictionary] = []
var groups: Array = [{"id": 0, "name": "Grup 1", "visible": true}]
var active_group := 0
var selected: MeshInstance3D
var selected_strokes: Array[MeshInstance3D] = []
var liquify_active := false
var liquify_type := "push"
var liquify_size := 1.5
var liquify_range := 0.65
var liquify_strength := 0.35
var liquify_dragging := false
var liquify_last_position := Vector2.ZERO
var liquify_changed := false
var liquify_baseline: Dictionary = {}
var liquify_compare_preview: Dictionary = {}
var liquify_compare := false
var liquify_button: Button
var liquify_type_picker: OptionButton
var liquify_size_slider: HSlider
var liquify_range_slider: HSlider
var liquify_strength_slider: HSlider
var tool := "draw"
var dirty := false
var current_path := ""
var saved_state := ""
var autosaved_state := ""
var autosave_time := ""
var recovery_pending := false
var autosave_path := "user://autosave.wolf3d"
var testing := false
var smoothing := true
var select_button: Button
var erase_button: Button
var group_picker: OptionButton
var group_name: LineEdit
var group_visible: Button
var group_list: VBoxContainer
var group_selected_ids: Array[int] = []
var group_isolation_id := -1
var selection_label: Label
var size_label: Label
var ink_label: Label
var brush_picker: ColorPickerButton
var language_picker: OptionButton
var menu_panels: Array[Control] = []
var menu_visible := true
var show_menu_button: Button
var finger_button: Button
var compact_finger_button: Button
var view_controls: HBoxContainer
var view_menu: MenuButton
var projection_picker: OptionButton
var sequence: Array = []
var sequence_list: VBoxContainer
var sequence_selected_id := -1
var sequence_selected_ids: Array[int] = []
var sequence_next_id := 0
var sequence_playing := false
var sequence_playback_index := 0
var sequence_playback_progress := 0.0
var sequence_playback_duration := 1.0
var sequence_play_button: Button
var sequence_exit_button: Button
var sequence_speed := 1.0
var sequence_mode := "once"
var sequence_timeline: HSlider
var sequence_speed_picker: OptionButton
var sequence_mode_picker: OptionButton
var sequence_ui_always_on := false
var sequence_overlay: Control
var sequence_info_label: Label
const VIEW_AXES := [Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3.LEFT, Vector3.DOWN, Vector3.FORWARD]
var finger_drawing := false
var save_dialog: FileDialog
var open_dialog: FileDialog
var gif_dialog: FileDialog
var message_dialog: AcceptDialog
var pending_touch := Vector2.ZERO
var active: MeshInstance3D
var stroke_screen := Vector2.ZERO
var ink := Color("263238")
var brush_radius := 0.035
var brush_kind := "pen"
var brush_opacity := 1.0
var brush_taper := 0.15
var fill_screen_points := PackedVector2Array()
var fill_active := false
var target := Vector3.ZERO
var distance := 12.0
var yaw := 0.0
var pitch := 0.0
var navigation := false
var touches: Dictionary = {}
var touch_blocked := false
var touch_action := ""
var touch_travel := 0.0
var pair_center := Vector2.ZERO
var pair_span := 0.0
var pair_pending := false
var status: Label
var draw_button: Button
var nav_button: Button
var undo_button: Button
var redo_button: Button
var gif_frame_count := 36
var gif_fps := 12
var gif_resolution := 512

func _ready() -> void:
	testing = "--smoke-test" in OS.get_cmdline_user_args()
	add_child(camera)
	camera.fov = 45
	camera.current = true
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color.WHITE
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.65
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -25, 0)
	add_child(light)
	add_child(reference_grid)
	reference_grid.rotation.x = -PI / 2
	reference_grid.position.y = -2.5
	guides = GuideController.new(self)
	eraser = PartialEraser.new(self)
	shape_assist = ShapeAssist.new(self)
	build_grid()
	update_camera()
	build_ui()
	build_file_dialogs()
	connect_popup_input(self)
	saved_state = Store.encode(document())
	update_status()
	get_window().focus_exited.connect(cancel_input)
	get_tree().auto_accept_quit = false
	if testing:
		call_deferred("smoke_test")
	else:
		var timer := Timer.new()
		timer.wait_time = 8
		timer.timeout.connect(autosave)
		add_child(timer)
		timer.start()
		if FileAccess.file_exists(autosave_path) or FileAccess.file_exists(autosave_path + ".bak"):
			recovery_pending = true
			call_deferred("offer_recovery")

func build_grid() -> void:
	var lines := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	lines.surface_begin(Mesh.PRIMITIVE_LINES, material)
	for i in range(-5, 6):
		lines.surface_set_color(Color("9aa7ad") if i == 0 else Color("d5dde0"))
		lines.surface_add_vertex(Vector3(i, -5, -0.006))
		lines.surface_add_vertex(Vector3(i, 5, -0.006))
		lines.surface_add_vertex(Vector3(-5, i, -0.006))
		lines.surface_add_vertex(Vector3(5, i, -0.006))
	lines.surface_end()
	var grid := MeshInstance3D.new()
	grid.mesh = lines
	reference_grid.add_child(grid)

func update_camera() -> void:
	finish_stroke()
	guides.cancel_preview()
	camera.size = 2.0 * distance * tan(deg_to_rad(camera.fov / 2))
	var back := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	# An explicit basis stays valid at the exact top/bottom poles.
	camera.transform = Transform3D(Basis(right, back.cross(right).normalized(), back.normalized()), target + back * distance)

func snap_view(axis: Vector3) -> void:
	cancel_input()
	yaw = atan2(axis.x, axis.z) if absf(axis.y) < 0.5 else 0.0
	pitch = asin(axis.y)
	update_camera()

func set_projection(index: int) -> void:
	cancel_input()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL if index == 1 else Camera3D.PROJECTION_PERSPECTIVE
	projection_picker.select(index)
	update_projection_icon()
	update_camera()

func update_projection_icon() -> void:
	if projection_picker == null:
		return
	var is_orthographic := camera.projection == Camera3D.PROJECTION_ORTHOGONAL
	projection_picker.icon = Icons.texture("orthographic" if is_orthographic else "perspective")
	projection_picker.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	projection_picker.expand_icon = false
	projection_picker.add_theme_constant_override("icon_max_width", 24)
	projection_picker.tooltip_text = Localization.translate("Orthographic" if is_orthographic else "Perspective")
	projection_picker.text = ""

func view_height(depth: float = -1.0) -> float:
	# Match projection scale at the orbit center when switching modes.
	var effective_depth := distance if camera.projection == Camera3D.PROJECTION_ORTHOGONAL or depth < 0 else depth
	return 2.0 * effective_depth * tan(deg_to_rad(camera.fov / 2))

func orbit(delta: Vector2) -> void:
	yaw -= delta.x * 0.007
	pitch = clampf(pitch + delta.y * 0.007, -PI / 2, PI / 2)
	update_camera()

func pan(delta: Vector2) -> void:
	var scale_factor := view_height() / get_viewport().get_visible_rect().size.y
	target += (-camera.basis.x * delta.x + camera.basis.y * delta.y) * scale_factor
	update_camera()

func zoom(factor: float) -> void:
	distance = clampf(distance * factor, 2, 40)
	update_camera()

func hit_point(screen: Vector2) -> Variant:
	return guides.ray_hit(screen)

func begin_stroke(screen: Vector2) -> void:
	if active != null or fill_active or guides.preview != null:
		return
	if guides.placing:
		guides.begin_preview(screen)
		if guides.preview != null and guides.creation_mode != "plane":
			shape_assist.begin(screen, true)
		return
	if guides.current() == null:
		status.text = Localization.translate("Buat bidang guide atau aktifkan guide tersimpan sebelum menggambar.")
		return
	if strokes.size() >= 10000 or sample_count() >= Store.MAX_POINTS - 1:
		status.text = Localization.translate("Batas ukuran proyek tercapai. Hapus goresan sebelum melanjutkan.")
		return
	if not bool(group_data(active_group).visible):
		status.text = Localization.translate("Grup aktif tersembunyi. Aktifkan Tampilkan grup sebelum menggambar.")
		return
	if brush_kind == "lasso_fill" or brush_kind == "rectangle_fill":
		begin_fill(screen)
		return
	var hit: Variant = hit_point(screen)
	if hit == null:
		status.text = Localization.translate("Gambar di dalam guide aktif; gunakan Hadap guide jika terlihat dari samping.")
		return
	active = Stroke.new()
	active.ink = ink
	active.radius = brush_radius
	active.brush_kind = brush_kind
	active.opacity = brush_opacity
	active.taper = brush_taper
	active.plane_normal = guides.current().surface_normal()
	active.group_id = active_group
	add_child(active)
	active.add_point(hit, guides.current().hit_normal)
	stroke_screen = screen
	shape_assist.begin(screen, false)

func extend_stroke(screen: Vector2) -> void:
	if fill_active:
		if brush_kind == "rectangle_fill":
			if fill_screen_points.size() > 1:
				fill_screen_points[1] = screen
			else:
				fill_screen_points.append(screen)
		elif fill_screen_points.is_empty() or fill_screen_points[-1].distance_to(screen) >= 4:
			fill_screen_points.append(screen)
		selection_overlay.update_selection(screen)
		return
	if shape_assist.move(screen):
		return
	if guides.preview != null:
		guides.extend_preview(screen)
		return
	if active == null:
		return
	if active.points.size() + sample_count() >= Store.MAX_POINTS:
		finish_stroke()
		status.text = Localization.translate("Batas 200.000 titik tercapai.")
		return
	# Sample between input events so ink follows curved/folded surfaces closely.
	var steps := mini(64, maxi(1, int(ceil(stroke_screen.distance_to(screen) / 3.0))))
	var start := stroke_screen
	var remaining := Store.MAX_POINTS - sample_count()
	for step in range(1, steps + 1):
		if active.points.size() >= remaining:
			finish_stroke()
			return
		var hit: Variant = hit_point(start.lerp(screen, float(step) / steps))
		if hit == null:
			finish_stroke()
			return
		active.add_point(hit, guides.current().hit_normal)
	stroke_screen = screen

func finish_stroke() -> void:
	if shape_assist != null:
		shape_assist.finalize()
	if eraser != null:
		eraser.finish()
	if fill_active:
		finish_fill()
		return
	if active == null:
		return
	if active.points.size() < 2:
		active.queue_free()
	else:
		checkpoint()
		# World-space smoothing would cut across folds and leave a custom guide.
		if smoothing and not shape_assist.corrected and guides.current() != null and guides.current().kind == "plane":
			active.smooth_points()
		strokes.append(active)
		mirror_stroke(active)
	active = null
	shape_assist.cancel()
	changed()

func begin_fill(screen: Vector2) -> void:
	if hit_point(screen) == null:
		status.text = Localization.translate("Isi area harus berada di dalam guide aktif.")
		return
	fill_active = true
	fill_screen_points = PackedVector2Array([screen])
	selection_overlay.mode = "rectangle" if brush_kind == "rectangle_fill" else "lasso"
	selection_overlay.set_fill_preview(true, ink)
	selection_overlay.begin_selection(screen)
	if brush_kind == "rectangle_fill":
		fill_screen_points.append(screen)

func finish_fill() -> void:
	fill_active = false
	var preview_points: PackedVector2Array = selection_overlay.end_selection()
	selection_overlay.set_fill_preview(false)
	var screen_points := fill_screen_points
	fill_screen_points = PackedVector2Array()
	if preview_points.size() >= 2:
		screen_points = preview_points
	if screen_points.size() < 2:
		return
	if brush_kind == "rectangle_fill":
		var start := screen_points[0]
		var end := screen_points[1]
		screen_points = PackedVector2Array([start, Vector2(end.x, start.y), end, Vector2(start.x, end.y)])
	if screen_points.size() < 3 or strokes.size() >= 10000:
		return
	var fill := Stroke.new()
	fill.ink = ink
	fill.radius = brush_radius
	fill.brush_kind = brush_kind
	fill.opacity = brush_opacity
	fill.taper = 0.0
	fill.plane_normal = guides.current().surface_normal()
	fill.group_id = active_group
	for screen in screen_points:
		var hit: Variant = hit_point(screen)
		if hit == null:
			status.text = Localization.translate("Area isi harus seluruhnya berada di dalam guide.")
			fill.queue_free()
			return
		fill.add_point(hit, guides.current().hit_normal)
	if fill.points.size() < 3:
		fill.queue_free()
		return
	fill.rebuild()
	checkpoint()
	add_child(fill)
	strokes.append(fill)
	changed()
	status.text = Localization.translate("Area terisi dengan warna aktif.")

func cancel_fill() -> void:
	if not fill_active:
		return
	fill_active = false
	fill_screen_points = PackedVector2Array()
	if is_instance_valid(selection_overlay):
		selection_overlay.cancel_selection()
		liquify_update_cursor(get_viewport().get_visible_rect().size / 2)

func mirror_stroke(source: MeshInstance3D) -> void:
	var axes := []
	if mirror_axes["x"]:
		axes.append(Vector3.RIGHT)
	if mirror_axes["y"]:
		axes.append(Vector3.UP)
	if mirror_axes["z"]:
		axes.append(Vector3.BACK)
	if axes.is_empty():
		return
	var combinations := 1 << axes.size()
	var copies := combinations - 1
	if strokes.size() + copies > 10000 or sample_count() + source.points.size() * copies > Store.MAX_POINTS:
		status.text = Localization.translate("Batas ukuran proyek tercapai. Mirror dilewati.")
		return
	for mask in range(1, combinations):
		var copy := Stroke.new()
		copy.restore(source.serialize())
		var reflection := Vector3.ONE
		for i in axes.size():
			if mask & (1 << i):
				var axis: Vector3 = axes[i]
				reflection -= axis * 2.0
		for i in copy.points.size():
			copy.points[i] *= reflection
		copy.plane_normal = (copy.plane_normal * reflection).normalized()
		for i in copy.sample_normals.size():
			copy.sample_normals[i] = (copy.sample_normals[i] * reflection).normalized()
		copy.rebuild()
		add_child(copy)
		strokes.append(copy)

func undo() -> void:
	guides.cancel_placing()
	finish_stroke()
	if not history.is_empty():
		future.append(document())
		restore_document(history.pop_back())
	changed()

func redo() -> void:
	guides.cancel_placing()
	finish_stroke()
	if not future.is_empty():
		history.append(document())
		restore_document(future.pop_back())
	changed()

func cancel_input() -> void:
	shape_assist.cancel()
	eraser.finish(true)
	guides.cancel_preview()
	cancel_fill()
	liquify_cancel()
	finish_stroke()
	touches.clear()
	touch_blocked = false
	touch_action = ""
	pair_pending = false
	update_status()

func _process(delta: float) -> void:
	flush_touch_navigation()
	shape_assist.tick(delta)
	if sequence_playing:
		advance_sequence(delta)

func set_finger_drawing(value: bool) -> void:
	# Switching input mode mid-gesture must never turn a drag into ink.
	discard_touch_drawing()
	touch_blocked = not touches.is_empty()
	finger_drawing = value
	finger_button.set_pressed_no_signal(value)
	Icons.apply(finger_button, "Jari: gambar" if value else "Jari: putar")
	compact_finger_button.set_pressed_no_signal(value)
	Icons.apply(compact_finger_button, "Jari: gambar" if value else "Jari: putar")

func discard_touch_drawing() -> void:
	shape_assist.cancel()
	eraser.finish(true)
	guides.cancel_preview()
	cancel_fill()
	if active != null and touch_action == "edit":
		active.queue_free()
		active = null
	update_status()

func begin_touch(event: InputEventScreenTouch) -> void:
	if event.canceled:
		return
	touches[event.index] = event.position
	if touches.size() >= 2:
		discard_touch_drawing()
		touch_blocked = true
		reset_touch_pair()
	else:
		touch_travel = 0
		pending_touch = event.position
		touch_action = "edit" if finger_drawing and not navigation else "orbit"
		if liquify_active and not touch_blocked:
			liquify_update_cursor(event.position)
			liquify_begin_drag(event.position)
			return
		if not touch_blocked and touch_action == "edit" and tool == "draw":
			begin_stroke(event.position)
		elif not touch_blocked and touch_action == "edit" and tool == "erase":
			eraser.begin(event.position)
		elif not touch_blocked and touch_action == "edit" and tool == "select" and selection_mode != "tap":
			selection_overlay.begin_selection(event.position)

func reset_touch_pair() -> void:
	pair_pending = false
	if touches.size() == 2:
		var positions := touches.values()
		pair_center = (positions[0] + positions[1]) / 2
		pair_span = positions[0].distance_to(positions[1])

func drag_touch(event: InputEventScreenDrag) -> void:
	if not touches.has(event.index):
		return
	var delta: Vector2 = event.position - touches[event.index]
	touches[event.index] = event.position
	if touches.size() == 2:
		# Coalesce both fingers within the frame; do not pan once per finger.
		pair_pending = true
	elif touches.size() == 1 and not touch_blocked:
		touch_travel += delta.length()
		if liquify_active:
			liquify_update_cursor(event.position)
			liquify_drag(event.position)
			return
		if touch_action == "orbit":
			orbit(delta * 800.0 / maxf(get_viewport().get_visible_rect().size.y, 1))
		elif tool == "draw":
			extend_stroke(event.position)
		elif tool == "erase":
			eraser.extend(event.position)
		elif tool == "select" and selection_mode != "tap" and selection_overlay.active:
			selection_overlay.update_selection(event.position)

func flush_touch_navigation() -> void:
	if not pair_pending or touches.size() != 2:
		return
	var positions := touches.values()
	var midpoint: Vector2 = (positions[0] + positions[1]) / 2
	var span: float = positions[0].distance_to(positions[1])
	var ratio := pair_span / span if pair_span > 10 and span > 10 else 1.0
	# Preserve the world point under the gesture centroid while panning/zooming.
	var viewport_size := get_viewport().get_visible_rect().size
	var old_scale := view_height() / viewport_size.y
	var old_offset := pair_center - viewport_size / 2
	var anchor := target + camera.basis.x * old_offset.x * old_scale - camera.basis.y * old_offset.y * old_scale
	distance = clampf(distance * ratio, 2, 40)
	var new_scale := view_height() / viewport_size.y
	var new_offset := midpoint - viewport_size / 2
	target = anchor - camera.basis.x * new_offset.x * new_scale + camera.basis.y * new_offset.y * new_scale
	update_camera()
	pair_center = midpoint
	pair_span = span
	pair_pending = false

func end_touch(event: InputEventScreenTouch) -> void:
	if not touches.has(event.index):
		return
	if event.canceled:
		discard_touch_drawing()
		touch_blocked = true
		pair_pending = false
	else:
		flush_touch_navigation()
		if liquify_active:
			liquify_dragging = false
		else:
			if touches.size() == 1 and not touch_blocked and touch_action == "edit":
				if tool == "select" and touch_travel < 18 and event.position.distance_to(pending_touch) < 18:
					if selection_mode == "tap":
						edit_at(event.position)
					elif selection_overlay.active:
						apply_area_selection(selection_overlay.end_selection())
				guides.finish_preview()
				finish_stroke()
	touches.erase(event.index)
	reset_touch_pair()
	if touches.is_empty():
		touch_blocked = false
		touch_action = ""

func _input(event: InputEvent) -> void:
	# Emulated mouse must reach GUI controls, but never the canvas tools.
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if liquify_active:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			var hovered := get_viewport().gui_get_hovered_control()
			if hovered != null and hovered != selection_overlay:
				return
			if event.pressed:
				liquify_begin_drag(event.position)
			else:
				liquify_dragging = false
			get_viewport().set_input_as_handled()
			return
		if event is InputEventMouseMotion:
			var hovered := get_viewport().gui_get_hovered_control()
			if hovered != null and hovered != selection_overlay:
				return
			liquify_update_cursor(event.position)
			if not liquify_dragging:
				get_viewport().set_input_as_handled()
				return
			liquify_drag(event.position)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not navigation:
		var hovered := get_viewport().gui_get_hovered_control()
		var over_ui := hovered != null and hovered != selection_overlay
		if not over_ui:
			if event.pressed:
				if not navigation:
					if tool == "draw":
						begin_stroke(event.position)
					elif tool == "erase":
						eraser.begin(event.position)
					elif tool == "select":
						if selection_mode == "tap":
							edit_at(event.position)
						else:
							selection_overlay.begin_selection(event.position)
			else:
				if tool == "select" and selection_mode != "tap" and selection_overlay.active:
					apply_area_selection(selection_overlay.end_selection())
				else:
					guides.finish_preview()
					finish_stroke()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT and not navigation:
		var hovered := get_viewport().gui_get_hovered_control()
		var over_ui := hovered != null and hovered != selection_overlay
		if not over_ui:
			if tool == "draw":
				extend_stroke(event.position)
			elif tool == "erase":
				eraser.extend(event.position)
			elif tool == "select" and selection_mode != "tap" and selection_overlay.active:
				selection_overlay.update_selection(event.position)
			get_viewport().set_input_as_handled()
			return
	# Capture only gestures that started on the canvas, even across a menu panel.
	if event is InputEventScreenDrag and touches.has(event.index):
		drag_touch(event)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if event.canceled or not event.pressed:
			if touches.has(event.index):
				end_touch(event)
				get_viewport().set_input_as_handled()
			return
		if not touches.is_empty():
			begin_touch(event)
			get_viewport().set_input_as_handled()
			return
	# Releases must reach us even when a drag ends over a UI panel.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		guides.finish_preview()
		finish_stroke()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.ctrl_pressed and event.keycode == KEY_S:
			request_save(event.shift_pressed)
		elif event.ctrl_pressed and event.keycode == KEY_O:
			open_dialog.popup_centered_ratio(0.75)
		elif event.ctrl_pressed and event.keycode == KEY_Z:
			if event.shift_pressed:
				redo()
			else:
				undo()
		elif event.keycode == KEY_B:
			set_navigation(false)
		elif event.keycode == KEY_N:
			set_navigation(true)
		elif event.keycode == KEY_G:
			guides.start_placing()
		elif event.keycode == KEY_U and not event.ctrl_pressed and not event.alt_pressed and not event.meta_pressed:
			toggle_menu()
		elif event.keycode == KEY_ESCAPE:
			if sequence_playing:
				stop_sequence_playback()
			guides.close_active()
		elif event.keycode == KEY_V:
			set_tool("select")
		elif event.ctrl_pressed and event.keycode == KEY_D:
			duplicate_selected()
		elif event.keycode == KEY_E:
			set_tool("erase")
		elif event.keycode in [KEY_DELETE, KEY_BACKSPACE]:
			delete_selected()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom(0.9)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom(1.1)
		elif event.button_index == MOUSE_BUTTON_LEFT and not navigation:
			if tool == "draw":
				begin_stroke(event.position)
			elif tool == "erase":
				eraser.begin(event.position)
			elif tool == "select":
				if selection_mode == "tap":
					edit_at(event.position)
				else:
					selection_overlay.begin_selection(event.position)
			else:
				edit_at(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if tool == "select" and selection_mode != "tap" and selection_overlay.active:
			apply_area_selection(selection_overlay.end_selection())
		else:
			finish_stroke()
	elif event is InputEventMouseMotion:
		if tool == "erase":
			eraser.move_cursor(event.position)
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			pan(event.relative)
		elif event.button_mask & MOUSE_BUTTON_MASK_RIGHT or (navigation and event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			orbit(event.relative)
		elif event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			if tool == "erase":
				eraser.extend(event.position)
			elif tool == "select" and selection_mode != "tap" and selection_overlay.active:
				selection_overlay.update_selection(event.position)
			else:
				extend_stroke(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		begin_touch(event)
	elif event is InputEventScreenDrag and touches.has(event.index):
		drag_touch(event)

func set_navigation(value: bool) -> void:
	set_tool("navigate" if value else "draw")

func set_tool(value: String) -> void:
	if liquify_active and value != "select":
		liquify_cancel()
	if not touches.is_empty():
		discard_touch_drawing()
		touch_blocked = true
	if value != "draw":
		guides.cancel_placing()
	finish_stroke()
	tool = value
	eraser.cursor_visible = false
	eraser.queue_redraw()
	eraser_controls.visible = value == "erase"
	navigation = value == "navigate"
	draw_button.button_pressed = value == "draw"
	nav_button.button_pressed = navigation
	select_button.button_pressed = value == "select"
	erase_button.button_pressed = value == "erase"
	transform_joystick_button.visible = value == "select"
	if value == "select":
		transform_joystick.set_mode("move")
	if compact_draw_button != null:
		compact_draw_button.button_pressed = value == "draw"
		compact_nav_button.button_pressed = navigation
		compact_select_button.button_pressed = value == "select"
		compact_erase_button.button_pressed = value == "erase"
	update_status()

func liquify_start() -> void:
	finish_stroke()
	if selected_strokes.is_empty():
		status.text = Localization.translate("Pilih minimal satu goresan sebelum Liquify.")
		return
	liquify_baseline.clear()
	liquify_compare_preview.clear()
	for stroke in selected_strokes:
		if is_instance_valid(stroke):
			liquify_baseline[stroke] = stroke.points.duplicate()
	liquify_active = true
	liquify_changed = false
	liquify_compare = false
	liquify_dragging = false
	selection_overlay.cancel_selection()
	transform_joystick.queue_redraw()
	status.text = Localization.translate("Liquify active: %s. Drag on strokes, then Apply.") % liquify_type.capitalize()

func liquify_begin_drag(position: Vector2) -> void:
	if not liquify_active:
		return
	liquify_dragging = true
	liquify_update_cursor(position)
	liquify_last_position = position

func liquify_update_cursor(position: Vector2) -> void:
	if not liquify_active:
		return
	selection_overlay.set_liquify_preview(true, position, liquify_screen_radius(position), liquify_range)

func liquify_screen_radius(_position: Vector2) -> float:
	var depth := distance
	if not selected_strokes.is_empty() and is_instance_valid(selected_strokes[0]) and not selected_strokes[0].points.is_empty():
		depth = maxf(-camera.to_local(selected_strokes[0].points[0]).z, 0.01)
	return liquify_size * get_viewport().get_visible_rect().size.y / view_height(depth)

func liquify_drag(position: Vector2) -> void:
	if not liquify_active or not liquify_dragging:
		return
	var delta := position - liquify_last_position
	liquify_last_position = position
	if delta.length_squared() < 0.01:
		return
	for stroke in selected_strokes:
		if is_instance_valid(stroke):
			liquify_stroke(stroke, position, delta)
	liquify_changed = true
	changed()

func liquify_stroke(stroke: MeshInstance3D, center: Vector2, delta: Vector2) -> void:
	for i in stroke.points.size():
		var point: Vector3 = stroke.points[i]
		if camera.is_position_behind(point):
			continue
		var screen := camera.unproject_position(point)
		var distance_px := screen.distance_to(center)
		var point_radius := liquify_size * get_viewport().get_visible_rect().size.y / view_height(maxf(-camera.to_local(point).z, 0.01))
		if distance_px > point_radius:
			continue
		var normalized_distance := distance_px / maxf(point_radius, 1.0)
		var inner := clampf(liquify_range, 0.05, 1.0)
		var falloff := 1.0 if normalized_distance <= inner else 1.0 - smoothstep(inner, 1.0, normalized_distance)
		falloff *= clampf(liquify_strength, 0.01, 1.0)
		var scale_factor := view_height(maxf(-camera.to_local(point).z, 0.01)) / get_viewport().get_visible_rect().size.y
		var world_delta := (camera.basis.x * delta.x - camera.basis.y * delta.y) * scale_factor
		match liquify_type:
			"push":
				stroke.points[i] += world_delta * falloff
			"pinch":
				var direction := (center - screen).normalized()
				stroke.points[i] += (camera.basis.x * direction.x - camera.basis.y * direction.y) * scale_factor * delta.length() * falloff
			"comb":
				stroke.points[i] += world_delta * falloff * 0.45
		stroke.points[i] += stroke.plane_normal * 0.0001
	stroke.rebuild()

func liquify_restore_baseline() -> void:
	for stroke in liquify_baseline:
		if is_instance_valid(stroke):
			stroke.points = liquify_baseline[stroke].duplicate()
			stroke.rebuild()
	liquify_changed = false
	changed()

func liquify_undo_all() -> void:
	if not liquify_active:
		return
	liquify_restore_baseline()
	status.text = Localization.translate("Perubahan Liquify dibatalkan.")

func liquify_compare_toggle() -> void:
	if not liquify_active:
		return
	liquify_compare = not liquify_compare
	if liquify_compare:
		liquify_compare_preview.clear()
		for stroke in selected_strokes:
			if is_instance_valid(stroke):
				liquify_compare_preview[stroke] = stroke.points.duplicate()
		liquify_restore_baseline()
	else:
		for stroke in liquify_compare_preview:
			if is_instance_valid(stroke):
				stroke.points = liquify_compare_preview[stroke].duplicate()
				stroke.rebuild()
		liquify_compare_preview.clear()
	status.text = Localization.translate("Compare: before Liquify.") if liquify_compare else Localization.translate("Compare: Liquify result.")

func liquify_apply() -> void:
	if not liquify_active:
		return
	if liquify_compare:
		for stroke in liquify_compare_preview:
			if is_instance_valid(stroke):
				stroke.points = liquify_compare_preview[stroke].duplicate()
				stroke.rebuild()
		liquify_compare = false
	if liquify_changed:
		checkpoint()
	changed()
	liquify_active = false
	liquify_dragging = false
	liquify_baseline.clear()
	liquify_compare_preview.clear()
	selection_overlay.set_liquify_preview(false)
	transform_joystick.queue_redraw()
	status.text = Localization.translate("Liquify diterapkan.")

func liquify_cancel() -> void:
	if not liquify_active:
		return
	liquify_restore_baseline()
	liquify_active = false
	liquify_dragging = false
	liquify_baseline.clear()
	liquify_compare_preview.clear()
	selection_overlay.set_liquify_preview(false)
	transform_joystick.queue_redraw()

func toggle_mirror_menu() -> void:
	var enabled: bool = mirror_axes["x"] or mirror_axes["y"] or mirror_axes["z"]
	mirror_button.button_pressed = enabled
	compact_mirror_button.button_pressed = enabled
	for id in 3:
		var key: String = ["x", "y", "z"][id]
		mirror_menu.set_item_checked(id, mirror_axes[key])
	var source_button := compact_mirror_button if not menu_visible else mirror_button
	mirror_menu.position = Vector2i(source_button.global_position + Vector2(0, source_button.size.y))
	mirror_menu.popup()

func toggle_mirror_axis(id: int) -> void:
	var names := ["x", "y", "z"]
	var axis_name: String = names[id]
	mirror_axes[axis_name] = not mirror_axes[axis_name]
	mirror_menu.set_item_checked(id, mirror_axes[axis_name])
	var enabled: bool = mirror_axes["x"] or mirror_axes["y"] or mirror_axes["z"]
	mirror_button.button_pressed = enabled
	compact_mirror_button.button_pressed = enabled
	status.text = Localization.translate("Mirror active: ") + axis_name.to_upper() if enabled else Localization.translate("Mirror inactive")

func face_guide() -> void:
	var surface: MeshInstance3D = guides.current()
	if surface == null:
		return
	finish_stroke()
	target = surface.center()
	var normal: Vector3 = surface.surface_normal()
	if normal.dot(camera.position - target) < 0:
		normal = -normal
	yaw = atan2(normal.x, normal.z)
	pitch = clampf(asin(normal.y), -1.45, 1.45)
	update_camera()

func update_status() -> void:
	if status == null:
		return
	var title := current_path.get_file() if not current_path.is_empty() else Localization.translate("Proyek baru")
	var modes := {"draw": "Gambar", "navigate": "Navigasi", "select": "Seleksi", "erase": "Hapus"}
	status.text = "%s%s   /   %d %s   /   %s" % [title, " *" if dirty else "", strokes.size(), Localization.translate("goresan"), Localization.translate(modes[tool])]
	status.text += "   /   " + Localization.translate("Membuat guide" if guides.placing else ("Guide actif" if guides.current() != null else "Tanpa guide"))
	if dirty and not autosave_time.is_empty():
		status.text += "   /   Autosave " + autosave_time
	undo_button.disabled = history.is_empty()
	redo_button.disabled = future.is_empty()
	if compact_undo_button != null:
		compact_undo_button.disabled = undo_button.disabled
		compact_redo_button.disabled = redo_button.disabled
	if selection_label != null:
		selection_label.text = "%d goresan dipilih" % selected_strokes.size() if not selected_strokes.is_empty() else "Belum ada seleksi"

func style(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(12)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box

func label_in(parent: Node, text: String, size: int = 16) -> Label:
	var label := Label.new()
	label.set_meta("locale_key", text)
	label.text = Localization.translate(text)
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label

func refresh_language(node: Node = self) -> void:
	for child in node.get_children():
		if child.has_meta("locale_key"):
			var key: String = child.get_meta("locale_key")
			if child is Label:
				child.text = Localization.translate(key)
			elif child is Button and child.icon == null and not child.has_meta("icon_button"):
				child.text = Localization.translate(key)
		if child is OptionButton and child.has_meta("locale_items"):
			var items: Array = child.get_meta("locale_items")
			for index in items.size():
				child.set_item_text(index, Localization.translate(items[index]))
		if child is PopupMenu and child.has_meta("locale_items"):
			var items: Array = child.get_meta("locale_items")
			for index in items.size():
				child.set_item_text(index, Localization.translate(items[index]))
		refresh_language(child)

func set_language(value: String) -> void:
	Localization.set_language(value)
	refresh_language()
	if language_picker != null:
		language_picker.set_item_text(0, Localization.translate("English (US)"))
		language_picker.set_item_text(1, Localization.translate("Bahasa Indonesia"))
	if icon_help != null and icon_help.has_method("refresh_language"):
		icon_help.refresh_language()
	status.text = Localization.translate("Language") + ": " + Localization.translate(value)

func button_in(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.set_meta("locale_key", text)
	button.text = Localization.translate(text)
	button.custom_minimum_size.y = 44
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	parent.add_child(button)
	Icons.apply(button, text)
	button.tooltip_text = Localization.translate(button.tooltip_text)
	return button

func show_icon_help() -> void:
	cancel_input()
	var viewport_size := get_viewport().get_visible_rect().size
	icon_help.popup_centered(Vector2i(minf(760, viewport_size.x * 0.9), minf(600, viewport_size.y * 0.85)))

func set_brush_color(value: Color) -> void:
	# Existing strokes retain their material; the chosen color applies to new ink.
	ink = Color(value.r, value.g, value.b, 1.0)
	brush_picker.color = ink
	if compact_color_button != null:
		compact_color_button.color = ink
	ink_label.text = Localization.translate("Warna") + "  #" + ink.to_html(false).to_upper()

func loft_selected() -> void:
	finish_stroke()
	var profiles: Array[PackedVector3Array] = []
	for stroke in selected_strokes:
		if is_instance_valid(stroke) and stroke.points.size() >= 2:
			profiles.append(stroke.points.duplicate())
	if profiles.size() < 2:
		status.text = Localization.translate("Pilih minimal dua stroke untuk Loft.")
		return
	guides.create_loft(profiles)

func show_compact_popup(popup: PopupPanel, source: Control) -> void:
	popup.position = Vector2i(source.global_position + Vector2(0, source.size.y + 6))
	popup.popup()

func build_compact_value_popup(title_key: String, value_text: String, minimum: float, maximum: float, step: float, value: float, changed: Callable) -> PopupPanel:
	var popup := PopupPanel.new()
	popup.add_theme_stylebox_override("panel", style(Color("18232d")))
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(220, 0)
	column.add_theme_constant_override("separation", 8)
	popup.add_child(column)
	var label := label_in(column, title_key, 14)
	label.text = value_text
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(200, 36)
	slider.value_changed.connect(func(new_value: float):
		changed.call(new_value)
	)
	column.add_child(slider)
	compact_toolbar.get_parent().add_child(popup)
	return popup

func toggle_menu() -> void:
	finish_stroke()
	menu_visible = not menu_visible
	brush_picker.get_popup().hide()
	if compact_color_button != null:
		compact_color_button.get_popup().hide()
	compact_guide_menu.hide()
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null:
		focused.release_focus()
	for panel in menu_panels:
		panel.visible = menu_visible
	show_menu_button.visible = true
	show_menu_button.tooltip_text = Localization.translate("Sembunyikan semua menu") if menu_visible else Localization.translate("Tampilkan kembali semua menu (U)")
	compact_finger_button.visible = not menu_visible
	compact_help_button.visible = not menu_visible
	compact_toolbar.visible = not menu_visible
	if menu_visible:
		view_controls.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		view_controls.offset_left = -148
		view_controls.offset_right = 148
		view_controls.offset_top = 20
	else:
		view_controls.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		view_controls.offset_left = -390
		view_controls.offset_right = -92
		view_controls.offset_top = 20

func show_compact_shape_menu() -> void:
	compact_shape_menu.position = Vector2i(compact_shape_button.global_position + Vector2(0, compact_shape_button.size.y + 6))
	compact_shape_menu.popup()

func select_compact_shape(index: int) -> void:
	if shape_picker == null or index < 0 or index >= shape_picker.item_count:
		return
	shape_picker.select(index)
	finish_stroke()
	shape_assist.mode = ["off", "auto", "line", "circle", "ellipse", "curve"][index]

func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var theme := Theme.new()
	theme.default_font_size = 16
	theme.set_stylebox("normal", "Button", style(Color("24333e")))
	theme.set_stylebox("hover", "Button", style(Color("354956")))
	theme.set_stylebox("pressed", "Button", style(Color("286454")))
	theme.set_stylebox("disabled", "Button", style(Color("18232b")))
	root.theme = theme
	selection_overlay = SelectionOverlay.new()
	selection_overlay.setup(self)
	root.add_child(selection_overlay)
	sequence_overlay = SequenceOverlay.new()
	sequence_overlay.setup(self)
	root.add_child(sequence_overlay)
	icon_help = preload("res://scripts/icon_help.gd").new()
	root.add_child(icon_help)
	var header := PanelContainer.new()
	menu_panels.append(header)
	root.add_child(header)
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 20
	header.offset_right = -20
	header.offset_top = 18
	header.add_theme_stylebox_override("panel", style(Color("18232d")))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	header.add_child(row)
	label_in(row, "W /  WOLFDRAW", 22)
	var subtitle := label_in(row, "GUIDE / DRAW", 13)
	subtitle.modulate = Color("8da4b1")
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	draw_button = button_in(row, "Gambar  B", set_navigation.bind(false))
	draw_button.toggle_mode = true
	draw_button.button_pressed = true
	nav_button = button_in(row, "Navigasi  N", set_navigation.bind(true))
	nav_button.toggle_mode = true
	select_button = button_in(row, "Pilih V", set_tool.bind("select"))
	select_button.toggle_mode = true
	select_button.button_down.connect(start_select_mode_hold)
	select_button.button_up.connect(end_select_mode_hold)
	erase_button = button_in(row, "Hapus E", set_tool.bind("erase"))
	erase_button.toggle_mode = true
	erase_button.tooltip_text = Localization.translate("Sapu untuk menghapus sebagian goresan. Goresan bertumpuk di area layar yang sama ikut terpotong; grup tersembunyi dilindungi.")
	undo_button = button_in(row, "Undo", undo)
	redo_button = button_in(row, "Redo", redo)
	mirror_button = button_in(row, "Mirror", toggle_mirror_menu)
	mirror_button.toggle_mode = true
	button_in(row, "Sembunyikan U", toggle_menu)
	button_in(row, "Panduan ikon", show_icon_help)
	var sidebar := PanelContainer.new()
	menu_panels.append(sidebar)
	root.add_child(sidebar)
	sidebar.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	sidebar.offset_left = 20
	sidebar.offset_right = 270
	sidebar.offset_top = 112
	sidebar.offset_bottom = -112
	sidebar.add_theme_stylebox_override("panel", style(Color("18232d")))
	var left_scroll := ScrollContainer.new()
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sidebar.add_child(left_scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 10)
	left_scroll.add_child(column)
	label_in(column, "BRUSH", 13).modulate = Color("8da4b1")
	finger_button = button_in(column, "Jari: putar", func(): set_finger_drawing(not finger_drawing))
	finger_button.toggle_mode = true
	finger_button.tooltip_text = Localization.translate("Putar: satu jari untuk orbit. Gambar: satu jari memakai alat aktif. Dua jari selalu pan dan cubit untuk zoom.")
	label_in(column, "Pilih warna brush", 14)
	brush_picker = ColorPickerButton.new()
	brush_picker.color = ink
	brush_picker.edit_alpha = false
	brush_picker.custom_minimum_size.y = 40
	brush_picker.tooltip_text = Localization.translate("Klik untuk memilih warna atau memasukkan kode HEX.")
	brush_picker.color_changed.connect(set_brush_color)
	column.add_child(brush_picker)
	brush_picker.get_popup().add_theme_stylebox_override("panel", style(Color("18232d")))
	ink_label = label_in(column, "Warna", 14)
	ink_label.text = Localization.translate("Warna") + "  #" + ink.to_html(false).to_upper()
	size_label = label_in(column, "Radius", 14)
	size_label.text = Localization.translate("Radius") + "  %.3f" % brush_radius
	var radius_slider := HSlider.new()
	radius_slider.min_value = 0.015
	radius_slider.max_value = 0.12
	radius_slider.step = 0.005
	radius_slider.value = brush_radius
	radius_slider.custom_minimum_size.y = 32
	radius_slider.value_changed.connect(func(value: float): brush_radius = value; size_label.text = Localization.translate("Radius") + "  %.3f" % value)
	column.add_child(radius_slider)
	var brush_picker_type := OptionButton.new()
	brush_picker_type.custom_minimum_size.y = 44
	var brush_items := ["Pena", "Pensil tekstur", "Kuas tekstur", "Tube 3D (lama)", "Lasso Fill", "Rectangle Fill"]
	for title in brush_items:
		brush_picker_type.add_item(Localization.translate(title))
	brush_picker_type.set_meta("locale_items", brush_items)
	brush_picker_type.item_selected.connect(func(index: int): brush_kind = ["pen", "pencil", "brush", "tube", "lasso_fill", "rectangle_fill"][index])
	column.add_child(brush_picker_type)
	brush_picker_type.get_popup().add_theme_constant_override("v_separation", 22)
	var opacity_label := label_in(column, "Opacity brush: 100%", 14)
	var brush_alpha := HSlider.new()
	brush_alpha.min_value = 0.05
	brush_alpha.max_value = 1.0
	brush_alpha.step = 0.05
	brush_alpha.value = 1.0
	brush_alpha.custom_minimum_size.y = 32
	brush_alpha.value_changed.connect(func(value: float): brush_opacity = value; opacity_label.text = "Opacity brush: %d%%" % roundi(value * 100))
	column.add_child(brush_alpha)
	var brush_toggles := HBoxContainer.new()
	column.add_child(brush_toggles)
	var taper_toggle := button_in(brush_toggles, "Ujung meruncing", func(): pass)
	taper_toggle.toggle_mode = true
	taper_toggle.button_pressed = true
	taper_toggle.toggled.connect(func(value: bool): brush_taper = 0.15 if value else 0.0)
	shape_picker = OptionButton.new()
	shape_picker.custom_minimum_size.y = 44
	for title in ["Draw Shape: mati", "Draw Shape: otomatis", "Bentuk: garis", "Bentuk: lingkaran", "Bentuk: elips", "Bentuk: kurva"]:
		shape_picker.add_item(Localization.translate(title))
	shape_picker.set_meta("locale_items", ["Draw Shape: mati", "Draw Shape: otomatis", "Bentuk: garis", "Bentuk: lingkaran", "Bentuk: elips", "Bentuk: kurva"])
	shape_picker.item_selected.connect(func(index: int): finish_stroke(); shape_assist.mode = ["off", "auto", "line", "circle", "ellipse", "curve"][index])
	shape_picker.tooltip_text = Localization.translate("Gambar bebas, tahan ujung sekitar 1 detik untuk merapikan, lalu geser tanpa melepas. Lepas sebelum ditahan untuk tetap bebas.")
	column.add_child(shape_picker)
	shape_picker.get_popup().add_theme_constant_override("v_separation", 22)
	brush_picker_type.item_selected.connect(func(index: int): brush_alpha.editable = index != 3 and index < 4; taper_toggle.disabled = index >= 3)
	eraser_controls = VBoxContainer.new()
	column.add_child(eraser_controls)
	var eraser_label := label_in(eraser_controls, "Radius eraser", 14)
	eraser_label.text = Localization.translate("Radius eraser") + ": 24 px"
	var eraser_slider := HSlider.new()
	eraser_slider.min_value = 4
	eraser_slider.max_value = 100
	eraser_slider.step = 1
	eraser_slider.value = eraser.radius
	eraser_slider.custom_minimum_size.y = 32
	eraser_slider.value_changed.connect(func(value: float): eraser.radius = value; eraser_label.text = Localization.translate("Radius eraser") + ": %d px" % value; eraser.queue_redraw())
	eraser_controls.add_child(eraser_slider)
	eraser_controls.hide()
	var smooth_toggle := button_in(brush_toggles, "Haluskan goresan", func(): pass)
	smooth_toggle.toggle_mode = true
	smooth_toggle.button_pressed = true
	smooth_toggle.toggled.connect(func(value: bool): smoothing = value)
	column.add_child(HSeparator.new())
	guides.build_controls(column)
	build_edit_panel(root)
	build_transform_joystick(root)
	var footer := PanelContainer.new()
	menu_panels.append(footer)
	root.add_child(footer)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 20
	footer.offset_right = -20
	footer.offset_top = -98
	footer.offset_bottom = -18
	footer.add_theme_stylebox_override("panel", style(Color("18232d")))
	var foot_column := VBoxContainer.new()
	footer.add_child(foot_column)
	status = label_in(foot_column, "")
	label_in(foot_column, "1 jari: putar / gambar   •   2 jari: pan / zoom   •   ? Panduan ikon", 14).modulate = Color("8da4b1")
	show_menu_button = button_in(root, "Menu  U", toggle_menu)
	show_menu_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	show_menu_button.offset_left = -82
	show_menu_button.offset_right = -20
	show_menu_button.offset_top = 20
	show_menu_button.offset_bottom = 68
	show_menu_button.text = ""
	show_menu_button.custom_minimum_size.x = 48
	show_menu_button.custom_minimum_size.y = 48
	show_menu_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	show_menu_button.add_theme_constant_override("icon_max_width", 24)
	show_menu_button.set_meta("icon_button", true)
	show_menu_button.z_index = 100
	Icons.apply(show_menu_button, "Menu U")
	show_menu_button.tooltip_text = Localization.translate("Open color, groups, sequence, and project tools")
	show_menu_button.tooltip_text = Localization.translate("Tampilkan kembali semua menu (U)")
	sequence_exit_button = button_in(root, "Stop Playback", stop_sequence_playback)
	sequence_exit_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	sequence_exit_button.offset_left = -190
	sequence_exit_button.offset_right = -20
	sequence_exit_button.offset_top = 20
	sequence_exit_button.offset_bottom = 68
	sequence_exit_button.hide()
	compact_toolbar = HBoxContainer.new()
	root.add_child(compact_toolbar)
	compact_toolbar.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	compact_toolbar.offset_left = 20
	compact_toolbar.offset_top = 20
	compact_toolbar.add_theme_constant_override("separation", 8)
	compact_toolbar.show()
	compact_draw_button = button_in(compact_toolbar, "Gambar B", set_navigation.bind(false))
	compact_guide_button = button_in(compact_toolbar, "Buat bidang: tarik area", compact_guide_pressed)
	compact_guide_button.button_down.connect(start_compact_guide_hold)
	compact_guide_button.button_up.connect(end_compact_guide_hold)
	compact_nav_button = button_in(compact_toolbar, "Navigasi N", set_navigation.bind(true))
	compact_select_button = button_in(compact_toolbar, "Pilih V", set_tool.bind("select"))
	compact_select_button.button_down.connect(start_select_mode_hold)
	compact_select_button.button_up.connect(end_select_mode_hold)
	compact_duplicate_button = button_in(compact_toolbar, "Duplikat", duplicate_selected)
	compact_loft_button = button_in(compact_toolbar, "Loft", loft_selected)
	compact_erase_button = button_in(compact_toolbar, "Hapus E", set_tool.bind("erase"))
	compact_undo_button = button_in(compact_toolbar, "Undo", undo)
	compact_redo_button = button_in(compact_toolbar, "Redo", redo)
	compact_mirror_button = button_in(compact_toolbar, "Mirror", toggle_mirror_menu)
	compact_mirror_button.toggle_mode = true
	compact_brush_button = button_in(compact_toolbar, "Pena", set_tool.bind("draw"))
	compact_brush_button.button_down.connect(start_brush_tool_hold)
	compact_brush_button.button_up.connect(end_brush_tool_hold)
	compact_brush_button.custom_minimum_size.x = 48
	compact_brush_button.text = ""
	compact_brush_button.icon = Icons.texture("pen")
	compact_brush_button.tooltip_text = Localization.translate("Pilih jenis brush")
	compact_toolbar.move_child(compact_guide_button, 0)
	compact_toolbar.move_child(compact_brush_button, 1)
	compact_toolbar.move_child(compact_duplicate_button, 5)
	compact_toolbar.move_child(compact_loft_button, 6)
	for tool_button in [compact_guide_button, compact_brush_button, compact_draw_button, compact_nav_button, compact_select_button, compact_duplicate_button, compact_loft_button, compact_erase_button]:
		tool_button.custom_minimum_size = Vector2(48, 48)
		tool_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tool_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tool_button.expand_icon = false
		tool_button.add_theme_constant_override("icon_max_width", 24)
		tool_button.set_meta("icon_button", true)
	for icon_button in [compact_guide_button, compact_draw_button, compact_nav_button, compact_select_button, compact_duplicate_button, compact_loft_button, compact_erase_button]:
		icon_button.text = ""
	compact_undo_button.text = ""
	compact_redo_button.text = ""
	compact_mirror_button.text = ""
	Icons.apply(compact_undo_button, "Undo")
	Icons.apply(compact_redo_button, "Redo")
	Icons.apply(compact_mirror_button, "Mirror")
	Icons.apply(compact_duplicate_button, "Duplikat")
	Icons.apply(compact_loft_button, "Loft")
	compact_color_button = ColorPickerButton.new()
	compact_color_button.color = ink
	compact_color_button.edit_alpha = false
	compact_color_button.custom_minimum_size = Vector2(48, 44)
	compact_color_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	compact_color_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	compact_color_button.tooltip_text = Localization.translate("Pilih warna brush")
	compact_color_button.color_changed.connect(set_brush_color)
	compact_toolbar.add_child(compact_color_button)
	compact_toolbar.move_child(compact_color_button, 2)
	compact_radius_button = button_in(compact_toolbar, "Radius", func(): show_compact_popup(compact_radius_popup, compact_radius_button))
	compact_opacity_button = button_in(compact_toolbar, "Opacity brush", func(): show_compact_popup(compact_opacity_popup, compact_opacity_button))
	compact_shape_button = button_in(compact_toolbar, "Draw Shape", show_compact_shape_menu)
	for setting_button in [compact_radius_button, compact_opacity_button, compact_shape_button]:
		setting_button.custom_minimum_size = Vector2(48, 48)
		setting_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		setting_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		setting_button.expand_icon = false
		setting_button.add_theme_constant_override("icon_max_width", 24)
		setting_button.text = ""
		setting_button.set_meta("icon_button", true)
	compact_toolbar.move_child(compact_radius_button, 3)
	compact_toolbar.move_child(compact_opacity_button, 4)
	compact_toolbar.move_child(compact_shape_button, 5)
	compact_radius_popup = build_compact_value_popup("Radius", Localization.translate("Radius") + "  %.3f" % brush_radius, 0.015, 0.12, 0.005, brush_radius, func(value: float):
		brush_radius = value
		size_label.text = Localization.translate("Radius") + "  %.3f" % value
	)
	compact_opacity_popup = build_compact_value_popup("Opacity brush", Localization.translate("Opacity brush") + ": %d%%" % roundi(brush_opacity * 100.0), 0.05, 1.0, 0.05, brush_opacity, func(value: float):
		brush_opacity = value
	)
	compact_shape_menu = PopupMenu.new()
	var compact_shape_items := ["Draw Shape: mati", "Draw Shape: otomatis", "Bentuk: garis", "Bentuk: lingkaran", "Bentuk: elips", "Bentuk: kurva"]
	for index in compact_shape_items.size():
		compact_shape_menu.add_item(Localization.translate(compact_shape_items[index]), index)
	compact_shape_menu.set_meta("locale_items", compact_shape_items)
	compact_shape_menu.id_pressed.connect(select_compact_shape)
	compact_toolbar.get_parent().add_child(compact_shape_menu)
	Icons.apply(compact_radius_button, "Radius")
	Icons.apply(compact_opacity_button, "Opacity brush")
	Icons.apply(compact_shape_button, "Draw Shape")
	for setting_button in [compact_radius_button, compact_opacity_button, compact_shape_button]:
		setting_button.expand_icon = false
	select_mode_menu = PopupMenu.new()
	var select_mode_items := ["Tap: tambah/hapus", "Rectangle", "Lasso"]
	for item in select_mode_items:
		select_mode_menu.add_check_item(item)
	select_mode_menu.set_meta("locale_items", select_mode_items)
	select_mode_menu.id_pressed.connect(select_mode_pressed)
	root.add_child(select_mode_menu)
	select_mode_timer = Timer.new()
	select_mode_timer.one_shot = true
	select_mode_timer.wait_time = 0.35
	select_mode_timer.timeout.connect(show_select_mode_menu)
	root.add_child(select_mode_timer)
	for compact_button in [compact_draw_button, compact_nav_button, compact_select_button, compact_erase_button]:
		compact_button.toggle_mode = true
	compact_draw_button.button_pressed = true
	mirror_menu = PopupMenu.new()
	mirror_menu.add_check_item("Sumbu X", 0)
	mirror_menu.add_check_item("Sumbu Y", 1)
	mirror_menu.add_check_item("Sumbu Z", 2)
	mirror_menu.id_pressed.connect(toggle_mirror_axis)
	root.add_child(mirror_menu)
	compact_guide_hold_timer = Timer.new()
	compact_guide_hold_timer.one_shot = true
	compact_guide_hold_timer.wait_time = 0.35
	compact_guide_hold_timer.timeout.connect(show_compact_guide_menu)
	root.add_child(compact_guide_hold_timer)
	compact_guide_menu = PopupMenu.new()
	var compact_guide_items := ["Bidang: tarik area", "Bidang ukuran otomatis", "Draw: profil bebas", "Bend: gambar arah baru"]
	for item in compact_guide_items:
		compact_guide_menu.add_item(Localization.translate(item))
	compact_guide_menu.set_meta("locale_items", compact_guide_items)
	compact_guide_menu.id_pressed.connect(select_compact_guide)
	root.add_child(compact_guide_menu)
	compact_finger_button = button_in(root, "Jari: putar", func(): set_finger_drawing(not finger_drawing))
	compact_finger_button.toggle_mode = true
	compact_finger_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	compact_finger_button.offset_left = -210
	compact_finger_button.offset_right = -162
	compact_finger_button.offset_top = 20
	compact_finger_button.offset_bottom = 68
	compact_finger_button.text = "☝"
	compact_finger_button.set_meta("icon_button", true)
	compact_finger_button.hide()
	compact_help_button = button_in(root, "Panduan ikon", show_icon_help)
	compact_help_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	compact_help_button.offset_left = -154
	compact_help_button.offset_right = -106
	compact_help_button.offset_top = 20
	compact_help_button.offset_bottom = 68
	compact_help_button.text = "?"
	compact_help_button.set_meta("icon_button", true)
	compact_help_button.tooltip_text = Localization.translate("Panduan ikon")
	compact_help_button.hide()
	brush_tool_menu = PopupMenu.new()
	var brush_tool_items := ["Pena", "Pensil tekstur", "Kuas tekstur", "Tube 3D (lama)", "Lasso Fill", "Rectangle Fill"]
	for item in brush_tool_items:
		brush_tool_menu.add_item(Localization.translate(item))
	brush_tool_menu.set_meta("locale_items", brush_tool_items)
	brush_tool_menu.id_pressed.connect(select_brush_tool)
	root.add_child(brush_tool_menu)
	brush_tool_timer = Timer.new()
	brush_tool_timer.one_shot = true
	brush_tool_timer.wait_time = 0.35
	brush_tool_timer.timeout.connect(show_brush_tool_menu)
	root.add_child(brush_tool_timer)
	# Keep direct axis views accessible even with the main panels hidden.
	view_controls = HBoxContainer.new()
	root.add_child(view_controls)
	view_controls.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	view_controls.offset_left = -390
	view_controls.offset_right = -92
	view_controls.offset_top = 20
	view_controls.z_index = 90
	view_controls.add_theme_constant_override("separation", 12)
	view_menu = MenuButton.new()
	view_menu.flat = false
	view_menu.focus_mode = Control.FOCUS_NONE
	view_menu.custom_minimum_size = Vector2(48, 48)
	view_menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	view_controls.add_child(view_menu)
	Icons.apply(view_menu, "Tampak")
	var views := ["X+ Kanan", "Y+ Atas", "Z+ Depan", "X- Kiri", "Y- Bawah", "Z- Belakang"]
	for title in views:
		view_menu.get_popup().add_item(title)
	view_menu.get_popup().add_theme_constant_override("v_separation", 22)
	view_menu.get_popup().id_pressed.connect(func(index: int): snap_view(VIEW_AXES[index]))
	projection_picker = OptionButton.new()
	projection_picker.custom_minimum_size = Vector2(48, 48)
	projection_picker.focus_mode = Control.FOCUS_NONE
	projection_picker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	projection_picker.add_item(Localization.translate("Perspective"))
	projection_picker.add_item(Localization.translate("Orthographic"))
	projection_picker.set_meta("locale_items", ["Perspective", "Orthographic"])
	projection_picker.item_selected.connect(set_projection)
	view_controls.add_child(projection_picker)
	projection_picker.get_popup().add_theme_constant_override("v_separation", 22)
	update_projection_icon()
	var reset_camera_button := button_in(view_controls, "Reset kamera", func(): target = Vector3.ZERO; distance = 12; yaw = 0; pitch = 0; update_camera())
	reset_camera_button.text = ""
	Icons.apply(reset_camera_button, "Reset kamera")
	reset_camera_button.custom_minimum_size = Vector2(48, 48)
	reset_camera_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	reset_camera_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reset_camera_button.expand_icon = false
	reset_camera_button.add_theme_constant_override("icon_max_width", 24)
	root.add_child(eraser)
	eraser.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toggle_menu()

func start_compact_guide_hold() -> void:
	compact_guide_long_pressed = false
	compact_guide_hold_timer.start()

func end_compact_guide_hold() -> void:
	if not compact_guide_long_pressed:
		compact_guide_hold_timer.stop()

func compact_guide_pressed() -> void:
	if compact_guide_long_pressed:
		compact_guide_long_pressed = false
		return
	guides.start_placing()

func start_brush_tool_hold() -> void:
	brush_tool_long_pressed = false
	brush_tool_timer.start()

func end_brush_tool_hold() -> void:
	if not brush_tool_long_pressed:
		brush_tool_timer.stop()
		set_tool("draw")

func show_brush_tool_menu() -> void:
	brush_tool_long_pressed = true
	refresh_popup_language(brush_tool_menu)
	brush_tool_menu.position = Vector2i(compact_brush_button.global_position + Vector2(0, compact_brush_button.size.y))
	brush_tool_menu.popup()

func select_brush_tool(id: int) -> void:
	var kinds := ["pen", "pencil", "brush", "tube", "lasso_fill", "rectangle_fill"]
	var icons := ["pen", "pencil", "brush", "tube", "lasso_fill", "rectangle_fill"]
	if id < 0 or id >= kinds.size():
		return
	brush_kind = kinds[id]
	compact_brush_button.text = ""
	compact_brush_button.icon = Icons.texture(icons[id])
	brush_tool_long_pressed = false
	set_tool("draw")
	status.text = Localization.translate("Brush") + ": " + Localization.translate(["Pena", "Pensil tekstur", "Kuas tekstur", "Tube 3D (lama)", "Lasso Fill", "Rectangle Fill"][id])

func show_compact_guide_menu() -> void:
	compact_guide_long_pressed = true
	refresh_popup_language(compact_guide_menu)
	compact_guide_menu.position = Vector2i(compact_guide_button.global_position + Vector2(0, compact_guide_button.size.y))
	compact_guide_menu.popup()

func select_compact_guide(id: int) -> void:
	match id:
		0:
			guides.start_placing()
		1:
			guides.quick_plane()
		2:
			guides.start_profile()
		3:
			guides.start_bend()

func smoke_test() -> void:
	get_tree().create_timer(20).timeout.connect(func(): push_error("TEST TIMEOUT / assertion failure"); get_tree().quit(1))
	await get_tree().process_frame
	if "--ui-touch-test" in OS.get_cmdline_user_args():
		assert(await preload("res://tests/popup_touch_test.gd").new().run(self))
		get_tree().quit()
		return
	await preload("res://tests/guide_test.gd").new().run(self)
	assert(await preload("res://tests/sequence_test.gd").new().run(self))

func connect_popup_input(node: Node) -> void:
	if node is Window and node != get_window():
		node.about_to_popup.connect(cancel_input)
	for child in node.get_children():
		connect_popup_input(child)

func document() -> Dictionary:
	var data := []
	for stroke in strokes:
		data.append(stroke.serialize())
	return {"format": Store.FORMAT, "version": Store.VERSION, "groups": groups.duplicate(true),
		"active_group": active_group, "strokes": data, "guides": guides.serialize(), "active_guide": guides.active_id,
		"sequence": sequence.duplicate(true)}

func sample_count() -> int:
	var count := 0
	for stroke in strokes:
		count += stroke.points.size()
	return count

func checkpoint() -> void:
	history.append(document())
	if history.size() > 40:
		history.pop_front()
	future.clear()

func changed() -> void:
	dirty = Store.encode(document()) != saved_state
	update_status()

func restore_document(data: Dictionary) -> void:
	choose_stroke(null)
	guides.restore(data)
	for stroke in strokes:
		remove_child(stroke)
		stroke.queue_free()
	strokes.clear()
	groups = data.groups.duplicate(true)
	active_group = int(data.active_group)
	for entry in data.strokes:
		var stroke := Stroke.new()
		stroke.restore(entry)
		add_child(stroke)
		strokes.append(stroke)
	sequence = data.get("sequence", []).duplicate(true)
	sequence_next_id = 0
	for shot in sequence:
		sequence_next_id = maxi(sequence_next_id, int(shot.id) + 1)
	sequence_selected_id = -1
	sequence_selected_ids.clear()
	refresh_groups()
	refresh_sequence()

func group_data(id: int) -> Dictionary:
	for group in groups:
		if int(group.id) == id:
			return group
	return groups[0]

func refresh_groups() -> void:
	group_picker.clear()
	for group in groups:
		group_picker.add_item(group.name, int(group.id))
	group_picker.select(group_picker.get_item_index(active_group))
	group_name.text = group_data(active_group).name
	group_visible.set_pressed_no_signal(group_data(active_group).visible)
	for stroke in strokes:
		stroke.visible = bool(group_data(stroke.group_id).visible) and (group_isolation_id < 0 or stroke.group_id == group_isolation_id)
	if is_instance_valid(selected) and not selected.visible:
		clear_selection()
	if group_list != null:
		for child in group_list.get_children():
			child.queue_free()
		for group in groups:
			var id := int(group.id)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 4)
			group_list.add_child(row)
			var group_button := Button.new()
			group_button.text = ("● " if group_selected_ids.has(id) else "") + str(group.name)
			group_button.toggle_mode = true
			group_button.button_pressed = id == active_group
			group_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			group_button.tooltip_text = Localization.translate("Klik: grup aktif. Tekan-tahan belum diperlukan; gunakan Ctrl di PC atau tombol Multi.")
			group_button.pressed.connect(select_group.bind(id))
			row.add_child(group_button)
			var select_group_button := Button.new()
			select_group_button.text = "✓" if group_selected_ids.has(id) else "+"
			select_group_button.toggle_mode = true
			select_group_button.button_pressed = group_selected_ids.has(id)
			select_group_button.custom_minimum_size.x = 40
			select_group_button.tooltip_text = Localization.translate("Pilih atau lepas grup untuk operasi multi-grup.")
			select_group_button.pressed.connect(toggle_group_selection.bind(id))
			row.add_child(select_group_button)
			var visibility := Button.new()
			visibility.text = "◉" if bool(group.visible) else "○"
			visibility.custom_minimum_size.x = 40
			visibility.pressed.connect(toggle_group_id.bind(id))
			row.add_child(visibility)
			var isolate := Button.new()
			isolate.text = "I"
			isolate.custom_minimum_size.x = 40
			isolate.pressed.connect(isolate_group.bind(id))
			row.add_child(isolate)

func add_group() -> void:
	finish_stroke()
	if groups.size() >= 1000:
		show_message(Localization.translate("Batas 1.000 grup tercapai."))
		return
	checkpoint()
	var id := 0
	for group in groups:
		id = maxi(id, int(group.id) + 1)
	groups.append({"id": id, "name": "Grup %d" % (id + 1), "visible": true})
	active_group = id
	refresh_groups()
	changed()

func select_group(id: int) -> void:
	finish_stroke()
	active_group = id
	clear_selection()
	var group := group_data(id)
	if bool(group.visible):
		for stroke in strokes:
			if stroke.group_id == id and stroke.visible:
				selected_strokes.append(stroke)
				stroke.set_selected(true)
	selected = selected_strokes.back() if not selected_strokes.is_empty() else null
	refresh_groups()
	status.text = Localization.translate("%d strokes in group '%s' selected.") % [selected_strokes.size(), str(group.name)]
	changed()

func toggle_group_id(id: int) -> void:
	finish_stroke()
	checkpoint()
	var group := group_data(id)
	group.visible = not bool(group.visible)
	refresh_groups()
	changed()

func isolate_group(id: int) -> void:
	finish_stroke()
	checkpoint()
	group_isolation_id = -1 if group_isolation_id == id else id
	refresh_groups()
	changed()

func toggle_group_selection(id: int) -> void:
	if group_selected_ids.has(id):
		group_selected_ids.erase(id)
	else:
		group_selected_ids.append(id)
	refresh_groups()

func delete_selected_groups() -> void:
	if group_selected_ids.is_empty():
		group_selected_ids.append(active_group)
	if groups.size() - group_selected_ids.size() < 1:
		show_message(Localization.translate("Minimal satu grup harus dipertahankan."))
		return
	finish_stroke()
	checkpoint()
	var deleted := group_selected_ids.duplicate()
	var fallback := -1
	for group in groups:
		if not deleted.has(int(group.id)):
			fallback = int(group.id)
			break
	var deleted_strokes: Array[MeshInstance3D] = []
	for stroke in strokes:
		if deleted.has(stroke.group_id):
			deleted_strokes.append(stroke)
	for stroke in deleted_strokes:
		strokes.erase(stroke)
		remove_child(stroke)
		stroke.queue_free()
	for i in range(groups.size() - 1, -1, -1):
		if deleted.has(int(groups[i].id)):
			groups.remove_at(i)
	group_selected_ids.clear()
	group_isolation_id = -1
	active_group = fallback
	refresh_groups()
	changed()

func duplicate_selected_group() -> void:
	if group_selected_ids.is_empty():
		group_selected_ids.append(active_group)
	var source_id := group_selected_ids[0]
	var source_group := group_data(source_id)
	if groups.size() >= 1000:
		show_message(Localization.translate("Batas 1.000 grup tercapai."))
		return
	var source_strokes: Array[MeshInstance3D] = []
	for stroke in strokes:
		if stroke.group_id == source_id:
			source_strokes.append(stroke)
	if strokes.size() + source_strokes.size() > 10000 or sample_count() + total_points(source_strokes) > Store.MAX_POINTS:
		show_message(Localization.translate("Batas ukuran proyek tercapai."))
		return
	finish_stroke()
	checkpoint()
	var new_id := 0
	for group in groups:
		new_id = maxi(new_id, int(group.id) + 1)
	groups.append({"id": new_id, "name": str(source_group.name) + " Copy", "visible": true})
	for source in source_strokes:
		var copy := Stroke.new()
		copy.restore(source.serialize())
		copy.group_id = new_id
		add_child(copy)
		strokes.append(copy)
	active_group = new_id
	group_selected_ids = [new_id]
	refresh_groups()
	changed()

func merge_selected_groups() -> void:
	if group_selected_ids.size() < 2:
		show_message(Localization.translate("Pilih minimal dua grup untuk digabung."))
		return
	finish_stroke()
	checkpoint()
	var target_id := group_selected_ids[0]
	for stroke in strokes:
		if group_selected_ids.has(stroke.group_id):
			stroke.group_id = target_id
	for i in range(groups.size() - 1, -1, -1):
		var id := int(groups[i].id)
		if group_selected_ids.has(id) and id != target_id:
			groups.remove_at(i)
	active_group = target_id
	group_selected_ids = [target_id]
	refresh_groups()
	changed()

func total_points(items: Array[MeshInstance3D]) -> int:
	var total := 0
	for stroke in items:
		total += stroke.points.size()
	return total

func rename_group() -> void:
	var title := group_name.text.strip_edges().left(80)
	if title.is_empty() or title == group_data(active_group).name:
		return
	finish_stroke()
	checkpoint()
	group_data(active_group).name = title
	refresh_groups()
	changed()

func toggle_group(value: bool) -> void:
	finish_stroke()
	checkpoint()
	group_data(active_group).visible = value
	refresh_groups()
	changed()

func choose_stroke(stroke: MeshInstance3D) -> void:
	if is_instance_valid(stroke):
		if selected_strokes.has(stroke):
			selected_strokes.erase(stroke)
			stroke.set_selected(false)
		else:
			selected_strokes.append(stroke)
			stroke.set_selected(true)
	else:
		clear_selection()
	selected = selected_strokes.back() if not selected_strokes.is_empty() else null
	update_status()

func clear_selection() -> void:
	for stroke in selected_strokes:
		if is_instance_valid(stroke):
			stroke.set_selected(false)
	selected_strokes.clear()
	selected = null

func set_selection_mode(value: String) -> void:
	selection_mode = value
	if is_instance_valid(selection_overlay):
		selection_overlay.mode = value
		selection_overlay.cancel_selection()
	if select_mode_menu != null:
		for id in 3:
			select_mode_menu.set_item_checked(id, ["tap", "rectangle", "lasso"][id] == value)
	if status != null:
		status.text = Localization.translate({"tap": "Seleksi tap: ketuk untuk tambah/hapus", "rectangle": "Seleksi rectangle", "lasso": "Seleksi lasso"}.get(value, "Seleksi"))

func start_select_mode_hold() -> void:
	select_mode_long_pressed = false
	select_mode_timer.start()

func end_select_mode_hold() -> void:
	if select_mode_timer.time_left > 0 and not select_mode_long_pressed:
		set_tool("select")
	select_mode_timer.stop()

func show_select_mode_menu() -> void:
	select_mode_long_pressed = true
	refresh_popup_language(select_mode_menu)
	var source := compact_select_button if not menu_visible else select_button
	select_mode_menu.position = Vector2i(source.global_position + Vector2(0, source.size.y))
	select_mode_menu.popup()

func refresh_popup_language(popup: PopupMenu) -> void:
	if popup == null or not popup.has_meta("locale_items"):
		return
	var items: Array = popup.get_meta("locale_items")
	for index in items.size():
		popup.set_item_text(index, Localization.translate(items[index]))

func select_mode_pressed(id: int) -> void:
	set_selection_mode(["tap", "rectangle", "lasso"][id])

func apply_area_selection(points: PackedVector2Array) -> void:
	if points.size() < 2:
		return
	var rectangle := selection_mode == "rectangle"
	var bounds := Rect2(points[0], points[1] - points[0]).abs() if rectangle else Rect2()
	for stroke in strokes:
		if not stroke.visible or stroke.points.is_empty():
			continue
		for point in stroke.points:
			if camera.is_position_behind(point):
				continue
			var screen := camera.unproject_position(point)
			var inside := bounds.has_point(screen) if rectangle else Geometry2D.is_point_in_polygon(screen, points)
			if inside:
				if not selected_strokes.has(stroke):
					selected_strokes.append(stroke)
					stroke.set_selected(true)
				break
	selected = selected_strokes.back() if not selected_strokes.is_empty() else null
	update_status()

func pick_stroke(screen: Vector2) -> MeshInstance3D:
	var best: MeshInstance3D
	var best_depth := INF
	for stroke in strokes:
		if not stroke.visible:
			continue
		for i in range(1, stroke.points.size()):
			var a: Vector3 = stroke.points[i - 1]
			var b: Vector3 = stroke.points[i]
			if camera.is_position_behind(a) or camera.is_position_behind(b):
				continue
			var pa := camera.unproject_position(a)
			var pb := camera.unproject_position(b)
			var closest := Geometry2D.get_closest_point_to_segment(screen, pa, pb)
			var fraction := clampf((closest - pa).dot(pb - pa) / maxf(pa.distance_squared_to(pb), 0.0001), 0, 1)
			# Perspective-correct interpolation for the nearest depth at this pixel.
			var za := -camera.to_local(a).z
			var zb := -camera.to_local(b).z
			var z := 1.0 / lerpf(1.0 / maxf(za, 0.001), 1.0 / maxf(zb, 0.001), fraction)
			if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
				z = lerpf(za, zb, fraction)
			var pixels: float = stroke.radius * get_viewport().get_visible_rect().size.y / view_height(maxf(z, 0.01))
			if screen.distance_to(closest) <= maxf(10, pixels + 5) and z < best_depth:
				best = stroke
				best_depth = z
	return best

func edit_at(screen: Vector2) -> void:
	if tool == "erase":
		eraser.begin(screen)
		eraser.finish()
	else:
		choose_stroke(pick_stroke(screen))

func delete_selected() -> void:
	finish_stroke()
	if selected_strokes.is_empty():
		return
	checkpoint()
	var old_strokes := selected_strokes.duplicate()
	clear_selection()
	for old in old_strokes:
		strokes.erase(old)
		remove_child(old)
		old.queue_free()
	changed()

func duplicate_selected() -> void:
	finish_stroke()
	if selected_strokes.is_empty():
		return
	var total_points := 0
	for stroke in selected_strokes:
		total_points += stroke.points.size()
	if strokes.size() + selected_strokes.size() > 10000 or sample_count() + total_points > Store.MAX_POINTS:
		status.text = Localization.translate("Batas ukuran proyek tercapai. Hapus goresan sebelum menduplikasi.")
		return
	checkpoint()
	var copies: Array[MeshInstance3D] = []
	for source in selected_strokes:
		if not bool(group_data(source.group_id).visible):
			continue
		var copy := Stroke.new()
		copy.restore(source.serialize())
		var offset := camera.basis.x * 0.25
		for i in copy.points.size():
			copy.points[i] += offset
		copy.rebuild()
		add_child(copy)
		strokes.append(copy)
		copies.append(copy)
	clear_selection()
	for copy in copies:
		selected_strokes.append(copy)
		copy.set_selected(true)
	selected = selected_strokes.back() if not selected_strokes.is_empty() else null
	changed()
	status.text = Localization.translate("%d duplicates created and selected.") % copies.size()

func move_selected_to_group() -> void:
	if selected_strokes.is_empty():
		return
	checkpoint()
	for stroke in selected_strokes:
		stroke.group_id = active_group
	refresh_groups()
	changed()

func transform_group(offset: Vector3, angle: float = 0.0, factor: float = 1.0, rotation_axis: Vector3 = Vector3.ZERO, record_history: bool = true, selected_only: bool = false) -> void:
	finish_stroke()
	var members: Array[MeshInstance3D] = []
	var center := Vector3.ZERO
	var count := 0
	for stroke in strokes:
		if (selected_only and selected_strokes.has(stroke)) or (not selected_only and stroke.group_id == active_group):
			members.append(stroke)
			for point in stroke.points:
				center += point
				count += 1
	if count == 0:
		return
	center /= count
	var axis: Vector3 = rotation_axis if rotation_axis.length_squared() > 0.01 else (guides.current().surface_normal() if guides.current() != null else camera.basis.z)
	var rotation_basis := Basis(axis, deg_to_rad(angle))
	# Respect the same limits as the file format before changing any geometry.
	for stroke in members:
		if stroke.radius * factor < 0.001 or stroke.radius * factor > 10:
			return
		for point in stroke.points:
			var result: Vector3 = center + rotation_basis * (point - center) * factor + offset
			if maxf(absf(result.x), maxf(absf(result.y), absf(result.z))) > 100000:
				return
	if record_history:
		checkpoint()
	for stroke in members:
		for i in stroke.points.size():
			stroke.points[i] = center + rotation_basis * (stroke.points[i] - center) * factor + offset
		stroke.plane_normal = (rotation_basis * stroke.plane_normal).normalized()
		for i in stroke.sample_normals.size():
			stroke.sample_normals[i] = (rotation_basis * stroke.sample_normals[i]).normalized()
		stroke.radius *= factor
		stroke.rebuild()
	changed()

func build_edit_panel(root: Control) -> void:
	var panel := PanelContainer.new()
	menu_panels.append(panel)
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -320
	panel.offset_right = -20
	panel.offset_top = 112
	panel.offset_bottom = -112
	panel.add_theme_stylebox_override("panel", style(Color("18232d")))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 9)
	scroll.add_child(column)
	label_in(column, "PROYEK", 13).modulate = Color("8da4b1")
	language_picker = OptionButton.new()
	language_picker.set_meta("locale_key", "Bahasa / Language")
	language_picker.add_item(Localization.translate("English (US)"))
	language_picker.add_item(Localization.translate("Bahasa Indonesia"))
	language_picker.select(0 if Localization.language == "en-US" else 1)
	language_picker.item_selected.connect(func(index: int): set_language("en-US" if index == 0 else "id"))
	column.add_child(language_picker)
	var files := HBoxContainer.new()
	column.add_child(files)
	button_in(files, "Simpan", func(): request_save())
	button_in(files, "Buka", func(): open_dialog.popup_centered_ratio(0.75))
	button_in(files, "Simpan sebagai...", request_save.bind(true))
	column.add_child(HSeparator.new())
	var sequence_title := label_in(column, "SEQUENCE", 13)
	sequence_title.modulate = Color("8da4b1")
	var sequence_add := button_in(column, "Add Shot", add_sequence_shot)
	sequence_add.custom_minimum_size.y = 38
	var gif_export := button_in(column, "Export 360 GIF", request_gif_export)
	gif_export.custom_minimum_size.y = 38
	var sequence_playback := GridContainer.new()
	sequence_playback.columns = 2
	sequence_playback.add_theme_constant_override("h_separation", 4)
	column.add_child(sequence_playback)
	sequence_play_button = button_in(sequence_playback, "Play", toggle_sequence_playback)
	var sequence_previous := button_in(sequence_playback, "Previous", sequence_previous_shot)
	var sequence_next := button_in(sequence_playback, "Next", sequence_next_shot)
	for control in [sequence_play_button, sequence_previous, sequence_next]:
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sequence_speed_picker = OptionButton.new()
	sequence_speed_picker.custom_minimum_size.x = 72
	for title in ["0.5x", "1x", "2x"]:
		sequence_speed_picker.add_item(title)
	sequence_speed_picker.item_selected.connect(func(index: int): sequence_speed = [0.5, 1.0, 2.0][index])
	sequence_playback.add_child(sequence_speed_picker)
	sequence_mode_picker = OptionButton.new()
	sequence_mode_picker.custom_minimum_size.x = 88
	for title in ["Once", "Loop", "Swing"]:
		sequence_mode_picker.add_item(title)
	sequence_mode_picker.item_selected.connect(func(index: int): sequence_mode = ["once", "loop", "swing"][index])
	sequence_playback.add_child(sequence_mode_picker)
	sequence_timeline = HSlider.new()
	sequence_timeline.min_value = 0.0
	sequence_timeline.max_value = 1.0
	sequence_timeline.step = 0.001
	sequence_timeline.custom_minimum_size.y = 28
	sequence_timeline.value_changed.connect(scrub_sequence)
	column.add_child(sequence_timeline)
	var sequence_options := VBoxContainer.new()
	column.add_child(sequence_options)
	var always_on := CheckButton.new()
	always_on.text = Localization.translate("UI Always On")
	always_on.toggled.connect(func(value: bool): sequence_ui_always_on = value)
	sequence_options.add_child(always_on)
	var thirds := CheckButton.new()
	thirds.text = Localization.translate("Thirds Grid")
	thirds.toggled.connect(func(value: bool): sequence_overlay.set_thirds(value))
	sequence_options.add_child(thirds)
	var camera_info := CheckButton.new()
	camera_info.text = Localization.translate("Camera Info")
	camera_info.toggled.connect(func(value: bool): sequence_overlay.set_info(value); sequence_info_label.visible = value)
	sequence_options.add_child(camera_info)
	sequence_info_label = label_in(column, "Camera Info", 12)
	sequence_info_label.visible = false
	var sequence_order := HBoxContainer.new()
	column.add_child(sequence_order)
	var sequence_left := button_in(sequence_order, "Move Left", move_sequence_left)
	var sequence_right := button_in(sequence_order, "Move Right", move_sequence_right)
	sequence_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sequence_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sequence_list = VBoxContainer.new()
	sequence_list.add_theme_constant_override("separation", 4)
	column.add_child(sequence_list)
	column.add_child(HSeparator.new())
	label_in(column, "GRUP AKTIF", 13).modulate = Color("8da4b1")
	var group_row := HBoxContainer.new()
	column.add_child(group_row)
	group_picker = OptionButton.new()
	group_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group_picker.custom_minimum_size.x = 132
	group_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group_picker.clip_text = true
	group_picker.item_selected.connect(func(index: int): finish_stroke(); active_group = group_picker.get_item_id(index); refresh_groups(); changed())
	group_row.add_child(group_picker)
	var add_group_button := button_in(group_row, "+", add_group)
	add_group_button.custom_minimum_size.x = 40
	var group_actions := GridContainer.new()
	group_actions.columns = 2
	column.add_child(group_actions)
	var delete_group_button := button_in(group_actions, "Hapus", delete_selected_groups)
	var duplicate_group_button := button_in(group_actions, "Duplikat", duplicate_selected_group)
	var merge_group_button := button_in(group_actions, "Gabung", merge_selected_groups)
	delete_group_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	duplicate_group_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	merge_group_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	delete_group_button.custom_minimum_size.x = 0
	duplicate_group_button.custom_minimum_size.x = 0
	merge_group_button.custom_minimum_size.x = 0
	group_list = VBoxContainer.new()
	group_list.add_theme_constant_override("separation", 4)
	column.add_child(group_list)
	group_name = LineEdit.new()
	group_name.max_length = 80
	group_name.placeholder_text = "Nama grup"
	group_name.text_submitted.connect(func(_text: String): rename_group(); group_name.release_focus())
	var rename_row := HBoxContainer.new()
	column.add_child(rename_row)
	group_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	group_name.custom_minimum_size.x = 110
	rename_row.add_child(group_name)
	var rename_button := button_in(rename_row, "Ubah", rename_group)
	rename_button.custom_minimum_size.x = 54
	var edit_row := HBoxContainer.new()
	column.add_child(edit_row)
	group_visible = button_in(edit_row, "Tampilkan grup", func(): pass)
	group_visible.toggle_mode = true
	group_visible.toggled.connect(toggle_group)
	selection_label = label_in(column, "Belum ada seleksi", 14)
	button_in(edit_row, "Pindah ke grup aktif", move_selected_to_group)
	button_in(edit_row, "Duplikat", duplicate_selected)
	button_in(edit_row, "Loft", loft_selected)
	button_in(edit_row, "Hapus pilihan", delete_selected)
	column.add_child(HSeparator.new())
	var liquify_title := label_in(column, "LIQUIFY", 13)
	liquify_title.modulate = Color("8da4b1")
	liquify_button = button_in(column, "Mulai Liquify", liquify_start)
	liquify_type_picker = OptionButton.new()
	liquify_type_picker.custom_minimum_size.y = 40
	for title in ["Push", "Pinch", "Comb"]:
		liquify_type_picker.add_item(title)
	liquify_type_picker.item_selected.connect(func(index: int): liquify_type = ["push", "pinch", "comb"][index])
	column.add_child(liquify_type_picker)
	liquify_size_slider = liquify_slider(column, "Ukuran", 0.25, 5.0, liquify_size, func(value: float): liquify_size = value)
	liquify_range_slider = liquify_slider(column, "Range", 0.05, 1.0, liquify_range, func(value: float): liquify_range = value)
	liquify_strength_slider = liquify_slider(column, "Strength", 0.01, 1.0, liquify_strength, func(value: float): liquify_strength = value)
	var liquify_actions := HBoxContainer.new()
	column.add_child(liquify_actions)
	button_in(liquify_actions, "Undo All", liquify_undo_all)
	button_in(liquify_actions, "Compare", liquify_compare_toggle)
	button_in(liquify_actions, "Apply", liquify_apply)
	refresh_groups()
	refresh_sequence()

func liquify_slider(parent: Node, title: String, minimum: float, maximum: float, value: float, action: Callable) -> HSlider:
	var label := label_in(parent, title, 13)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = 0.01
	slider.value = value
	slider.custom_minimum_size.y = 28
	slider.value_changed.connect(func(next: float): action.call(next); label.text = "%s  %.2f" % [Localization.translate(title), next])
	parent.add_child(slider)
	return slider

func camera_vector(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

func add_sequence_shot() -> void:
	var shot := {
		"id": sequence_next_id,
		"name": "Shot %d" % (sequence.size() + 1),
		"target": camera_vector(target),
		"position": camera_vector(camera.position),
		"distance": distance,
		"yaw": yaw,
		"pitch": pitch,
		"fov": camera.fov,
		"projection": int(camera.projection)
	}
	sequence_next_id += 1
	sequence.append(shot)
	sequence_selected_id = int(shot.id)
	sequence_selected_ids = [int(shot.id)]
	changed()
	refresh_sequence()

func apply_sequence_shot(shot: Dictionary) -> void:
	finish_stroke()
	target = Vector3(shot.target[0], shot.target[1], shot.target[2])
	distance = float(shot.distance)
	yaw = float(shot.yaw)
	pitch = clampf(float(shot.pitch), -PI / 2, PI / 2)
	camera.fov = float(shot.fov)
	camera.projection = int(shot.projection)
	if projection_picker != null:
		projection_picker.select(int(shot.projection))
		update_projection_icon()
	update_camera()

func select_sequence_shot(id: int) -> void:
	sequence_playing = false
	update_sequence_play_button()
	for shot in sequence:
		if int(shot.id) == id:
			sequence_selected_id = id
			sequence_selected_ids = [id]
			apply_sequence_shot(shot)
			refresh_sequence()
			return

func toggle_sequence_playback() -> void:
	if sequence.size() < 2:
		return
	if not sequence_playing:
		sequence_playback_index = maxi(sequence_index(sequence_selected_id), 0)
		if sequence_playback_index >= sequence.size() - 1:
			sequence_playback_index = 0
		sequence_playback_progress = 0.0
		sequence_playing = true
	else:
		stop_sequence_playback()
	update_sequence_play_button()
	if not sequence_ui_always_on:
		for panel in menu_panels:
			panel.visible = not sequence_playing
	if sequence_exit_button != null:
		sequence_exit_button.visible = sequence_playing and not sequence_ui_always_on

func stop_sequence_playback() -> void:
	sequence_playing = false
	update_sequence_play_button()
	if not sequence_ui_always_on:
		for panel in menu_panels:
			panel.visible = true
	if sequence_exit_button != null:
		sequence_exit_button.hide()

func update_sequence_play_button() -> void:
	if sequence_play_button != null:
		sequence_play_button.text = Localization.translate("Pause") if sequence_playing else Localization.translate("Play")
	if sequence_info_label != null and sequence_info_label.visible:
		sequence_info_label.text = "Position %.2f, %.2f, %.2f | Target %.2f, %.2f, %.2f | FOV %.1f | %s" % [
			camera.position.x, camera.position.y, camera.position.z, target.x, target.y, target.z, camera.fov,
			"Orthographic" if camera.projection == Camera3D.PROJECTION_ORTHOGONAL else "Perspective"]

func advance_sequence(delta: float) -> void:
	if sequence_playback_index >= sequence.size() - 1:
		stop_sequence_playback()
		return
	sequence_playback_progress += delta * sequence_speed / sequence_playback_duration
	var from: Dictionary = sequence[sequence_playback_index]
	var to: Dictionary = sequence[sequence_playback_index + 1]
	var amount := clampf(sequence_playback_progress, 0.0, 1.0)
	interpolate_sequence_shot(from, to, amount)
	if amount >= 1.0:
		sequence_playback_index += 1
		sequence_playback_progress = 0.0
		sequence_selected_id = int(to.id)
		if sequence_playback_index >= sequence.size() - 1:
			match sequence_mode:
				"loop":
					sequence_playback_index = 0
					sequence_selected_id = int(sequence[0].id)
				"swing":
					sequence_playback_index = maxi(sequence.size() - 2, 0)
					sequence_selected_id = int(sequence[sequence_playback_index].id)
					sequence_playback_progress = 1.0
				_:
					stop_sequence_playback()
		refresh_sequence()
	sequence_timeline.set_value_no_signal(sequence_progress_value())

func interpolate_sequence_shot(from: Dictionary, to: Dictionary, amount: float) -> void:
	target = Vector3(from.target[0], from.target[1], from.target[2]).lerp(Vector3(to.target[0], to.target[1], to.target[2]), amount)
	distance = lerpf(float(from.distance), float(to.distance), amount)
	yaw = lerp_angle(float(from.yaw), float(to.yaw), amount)
	pitch = lerpf(float(from.pitch), float(to.pitch), amount)
	camera.fov = lerpf(float(from.fov), float(to.fov), amount)
	camera.projection = int(from.projection) if amount < 0.5 else int(to.projection)
	if projection_picker != null:
		projection_picker.select(int(camera.projection))
		update_projection_icon()
	update_camera()

func sequence_previous_shot() -> void:
	if sequence.is_empty():
		return
	sequence_playing = false
	var index := maxi(sequence_index(sequence_selected_id) - 1, 0)
	sequence_selected_id = int(sequence[index].id)
	apply_sequence_shot(sequence[index])
	update_sequence_play_button()
	refresh_sequence()

func scrub_sequence(value: float) -> void:
	if sequence.size() < 2:
		return
	sequence_playing = false
	var scaled := value * float(sequence.size() - 1)
	var index := mini(int(floor(scaled)), sequence.size() - 2)
	var amount := scaled - float(index)
	sequence_playback_index = index
	sequence_playback_progress = amount
	sequence_selected_id = int(sequence[index].id)
	interpolate_sequence_shot(sequence[index], sequence[index + 1], amount)
	update_sequence_play_button()
	refresh_sequence()

func sequence_progress_value() -> float:
	if sequence.size() < 2:
		return 0.0
	return clampf((float(sequence_playback_index) + sequence_playback_progress) / float(sequence.size() - 1), 0.0, 1.0)

func sequence_next_shot() -> void:
	if sequence.is_empty():
		return
	sequence_playing = false
	var index := mini(sequence_index(sequence_selected_id) + 1, sequence.size() - 1)
	sequence_selected_id = int(sequence[index].id)
	apply_sequence_shot(sequence[index])
	update_sequence_play_button()
	refresh_sequence()

func delete_sequence_shot(id: int) -> void:
	for index in sequence.size():
		if int(sequence[index].id) == id:
			sequence.remove_at(index)
			break
	sequence_selected_id = -1
	sequence_selected_ids.erase(id)
	changed()
	refresh_sequence()

func move_sequence_left() -> void:
	var ids := sequence_selected_ids if not sequence_selected_ids.is_empty() else [sequence_selected_id]
	var indices: Array[int] = []
	for id in ids:
		var selected_index := sequence_index(id)
		if selected_index >= 0:
			indices.append(selected_index)
	indices.sort()
	var index := indices[0] if not indices.is_empty() else -1
	if index <= 0:
		return
	for selected_index in indices:
		var shot = sequence[selected_index]
		sequence[selected_index] = sequence[selected_index - 1]
		sequence[selected_index - 1] = shot
	changed()
	refresh_sequence()

func move_sequence_right() -> void:
	var ids := sequence_selected_ids if not sequence_selected_ids.is_empty() else [sequence_selected_id]
	var indices: Array[int] = []
	for id in ids:
		var selected_index := sequence_index(id)
		if selected_index >= 0:
			indices.append(selected_index)
	indices.sort()
	if indices.is_empty() or indices.back() >= sequence.size() - 1:
		return
	for reverse_index in range(indices.size() - 1, -1, -1):
		var selected_index: int = indices[reverse_index]
		var shot = sequence[selected_index]
		sequence[selected_index] = sequence[selected_index + 1]
		sequence[selected_index + 1] = shot
	changed()
	refresh_sequence()

func toggle_sequence_selection(id: int) -> void:
	if sequence_selected_ids.has(id):
		sequence_selected_ids.erase(id)
	else:
		sequence_selected_ids.append(id)
	sequence_selected_id = id
	refresh_sequence()

func rename_sequence_shot(id: int, name: String) -> void:
	var clean_name := name.strip_edges()
	if clean_name.is_empty():
		return
	for shot in sequence:
		if int(shot.id) == id:
			shot.name = clean_name.left(80)
			break
	changed()
	refresh_sequence()

func sequence_index(id: int) -> int:
	for index in sequence.size():
		if int(sequence[index].id) == id:
			return index
	return -1

func refresh_sequence() -> void:
	if sequence_list == null:
		return
	for child in sequence_list.get_children():
		child.queue_free()
	for shot in sequence:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		var shot_controls := HBoxContainer.new()
		row.add_child(shot_controls)
		var button := Button.new()
		button.text = str(shot.name)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = int(shot.id) == sequence_selected_id
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(select_sequence_shot.bind(int(shot.id)))
		shot_controls.add_child(button)
		var select := CheckButton.new()
		select.button_pressed = sequence_selected_ids.has(int(shot.id))
		select.tooltip_text = Localization.translate("Select shot for ordering")
		select.toggled.connect(func(_value: bool): toggle_sequence_selection(int(shot.id)))
		shot_controls.add_child(select)
		var rename := LineEdit.new()
		rename.text = str(shot.name)
		rename.custom_minimum_size.x = 90
		rename.max_length = 80
		rename.text_submitted.connect(func(value: String): rename_sequence_shot(int(shot.id), value))
		var remove := Button.new()
		remove.text = "×"
		remove.custom_minimum_size.x = 38
		remove.pressed.connect(delete_sequence_shot.bind(int(shot.id)))
		shot_controls.add_child(remove)
		row.add_child(rename)
		sequence_list.add_child(row)
	update_sequence_play_button()

func build_transform_joystick(root: Control) -> void:
	var joystick := TransformJoystick.new()
	joystick.setup(self)
	transform_joystick = joystick
	root.add_child(joystick)
	transform_joystick_button = button_in(root, "Joystick transformasi", toggle_transform_joystick)
	transform_joystick_button.toggle_mode = true
	transform_joystick_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	transform_joystick_button.offset_left = -76
	transform_joystick_button.offset_right = -20
	transform_joystick_button.offset_top = -102
	transform_joystick_button.offset_bottom = -46
	transform_joystick_button.z_index = 100
	transform_joystick_button.tooltip_text = Localization.translate("Menampilkan atau menyembunyikan joystick transformasi grup.")
	transform_mode_timer = Timer.new()
	transform_mode_timer.one_shot = true
	transform_mode_timer.wait_time = 0.35
	transform_mode_timer.timeout.connect(show_transform_mode_menu)
	root.add_child(transform_mode_timer)
	transform_joystick_button.button_down.connect(start_transform_mode_hold)
	transform_joystick_button.button_up.connect(end_transform_mode_hold)
	transform_mode_menu = PopupMenu.new()
	transform_mode_menu.add_item("Move", 0)
	transform_mode_menu.add_item("Rotate", 1)
	transform_mode_menu.add_item("Scale", 2)
	transform_mode_menu.id_pressed.connect(select_transform_mode)
	root.add_child(transform_mode_menu)

func toggle_transform_joystick() -> void:
	if transform_joystick == null or transform_mode_long_pressed:
		transform_mode_long_pressed = false
		return
	transform_joystick.set_mode("move")
	transform_joystick_button.button_pressed = true
	transform_joystick.queue_redraw()

func start_transform_mode_hold() -> void:
	transform_mode_long_pressed = false
	transform_mode_timer.start()

func end_transform_mode_hold() -> void:
	if not transform_mode_long_pressed:
		transform_mode_timer.stop()

func show_transform_mode_menu() -> void:
	transform_mode_long_pressed = true
	transform_mode_menu.position = Vector2i(transform_joystick_button.global_position + Vector2(0, -transform_mode_menu.size.y))
	transform_mode_menu.popup()

func select_transform_mode(id: int) -> void:
	var modes := ["move", "rotate", "scale"]
	transform_joystick.set_mode(modes[id])
	transform_joystick_button.button_pressed = true

func build_file_dialogs() -> void:
	message_dialog = AcceptDialog.new()
	message_dialog.title = "WolfDraw3D"
	add_child(message_dialog)
	save_dialog = FileDialog.new()
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	save_dialog.filters = PackedStringArray(["*.wolf3d ; Proyek WolfDraw3D"])
	save_dialog.current_file = "Sketsa.wolf3d"
	save_dialog.file_selected.connect(save_to)
	add_child(save_dialog)
	open_dialog = FileDialog.new()
	open_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	open_dialog.access = FileDialog.ACCESS_FILESYSTEM
	open_dialog.filters = save_dialog.filters
	if OS.has_feature("android"):
		# The regular file dialog cannot write Android shared storage paths.
		# Keep project/temp/backup files together in the app's writable sandbox.
		save_dialog.access = FileDialog.ACCESS_USERDATA
		open_dialog.access = FileDialog.ACCESS_USERDATA
		save_dialog.current_dir = "user://"
		open_dialog.current_dir = "user://"
	open_dialog.file_selected.connect(request_open)
	add_child(open_dialog)
	gif_dialog = FileDialog.new()
	gif_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	gif_dialog.access = FileDialog.ACCESS_FILESYSTEM
	gif_dialog.filters = PackedStringArray(["*.gif ; Animated GIF"])
	gif_dialog.current_file = "turntable.gif"
	if OS.has_feature("android"):
		gif_dialog.access = FileDialog.ACCESS_USERDATA
		gif_dialog.current_dir = "user://"
	gif_dialog.file_selected.connect(export_360_gif)
	add_child(gif_dialog)

func show_message(text: String) -> void:
	if testing:
		print(text)
		return
	var translated_lines := PackedStringArray()
	for line in text.split("\n"):
		translated_lines.append(Localization.translate(line))
	message_dialog.dialog_text = "\n".join(translated_lines)
	message_dialog.popup_centered(Vector2i(520, 180))

func request_gif_export() -> void:
	if gif_dialog != null:
		gif_dialog.popup_centered_ratio(0.75)

func export_360_gif(path: String) -> void:
	if not path.to_lower().ends_with(".gif"):
		path += ".gif"
	var original_yaw := yaw
	var original_panel_states := {}
	for panel in menu_panels:
		original_panel_states[panel] = panel.visible
		panel.hide()
	var original_view_controls_visible := view_controls.visible
	var original_compact_toolbar_visible := compact_toolbar.visible
	var original_compact_finger_visible := compact_finger_button.visible
	var original_compact_help_visible := compact_help_button.visible
	var original_sequence_overlay_visible := sequence_overlay.visible
	view_controls.hide()
	compact_toolbar.hide()
	compact_finger_button.hide()
	compact_help_button.hide()
	sequence_overlay.hide()
	var frames: Array[Image] = []
	for index in gif_frame_count:
		yaw = original_yaw + TAU * float(index) / float(gif_frame_count)
		update_camera()
		await get_tree().process_frame
		var frame := get_viewport().get_texture().get_image()
		frame.resize(gif_resolution, gif_resolution, Image.INTERPOLATE_BILINEAR)
		frames.append(frame)
	yaw = original_yaw
	update_camera()
	for panel in menu_panels:
		panel.visible = original_panel_states[panel]
	view_controls.visible = original_view_controls_visible
	compact_toolbar.visible = original_compact_toolbar_visible
	compact_finger_button.visible = original_compact_finger_visible
	compact_help_button.visible = original_compact_help_visible
	sequence_overlay.visible = original_sequence_overlay_visible
	var encoded := GifEncoder.encode(frames, int(round(100.0 / float(gif_fps))))
	if encoded.is_empty():
		show_message("GIF export failed.")
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		show_message("GIF export failed.")
		return
	file.store_buffer(encoded)
	file.close()
	show_message("360 GIF exported.")

func request_save(save_as: bool = false) -> void:
	finish_stroke()
	if save_as or current_path.is_empty():
		save_dialog.popup_centered_ratio(0.75)
	else:
		save_to(current_path)

func save_to(path: String) -> bool:
	finish_stroke()
	if not path.ends_with(".wolf3d"):
		path += ".wolf3d"
	var data := document()
	var result := Store.save_project(path, data)
	if result != OK:
		show_message("Gagal menyimpan. Proyek tetap terbuka.\n" + error_string(result))
		return false
	current_path = path
	recovery_pending = false
	saved_state = Store.encode(data)
	dirty = false
	clear_autosave()
	update_status()
	return true

func request_open(path: String) -> void:
	finish_stroke()
	if not dirty:
		load_from(path)
		return
	var confirm := ConfirmationDialog.new()
	confirm.title = Localization.translate("Buka proyek lain?")
	confirm.dialog_text = Localization.translate("Perubahan belum disimpan ke file proyek.\nSimpan terlebih dahulu jika ingin mempertahankannya.")
	confirm.ok_button_text = Localization.translate("Buka tanpa menyimpan")
	add_child(confirm)
	confirm.confirmed.connect(func(): load_from(path); confirm.queue_free())
	confirm.canceled.connect(confirm.queue_free)
	confirm.popup_centered(Vector2i(540, 160))

func load_from(path: String, recovery: bool = false) -> bool:
	# No scene mutation until every field has passed validation.
	var result := Store.load_project(path)
	if not result.error.is_empty():
		show_message(result.error + "\nProyek yang sedang dibuka tidak diubah.")
		return false
	finish_stroke()
	restore_document(result.data)
	recovery_pending = false
	history.clear()
	future.clear()
	current_path = "" if recovery else path
	saved_state = "" if recovery or result.recovered else Store.encode(document())
	autosaved_state = ""
	autosave_time = ""
	if not recovery and not result.recovered:
		clear_autosave()
	changed()
	if result.recovered:
		show_message("File utama tidak terbaca. Proyek dipulihkan dari cadangan .bak; simpan sebagai file baru.")
		current_path = ""
		update_status()
	return true

func autosave() -> bool:
	if active != null or guides.preview != null or eraser.dragging or recovery_pending:
		return true
	if not dirty:
		clear_autosave()
		return true
	var state := Store.encode(document())
	if state == autosaved_state:
		return true
	var result := Store.save_project(autosave_path, document())
	if result != OK:
		status.text = Localization.translate("Autosave failed: ") + error_string(result) + ". " + Localization.translate("Gunakan Simpan.")
		return false
	autosaved_state = state
	autosave_time = Time.get_time_string_from_system()
	update_status()
	return true

func clear_autosave() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(autosave_path + suffix):
			DirAccess.remove_absolute(autosave_path + suffix)
	autosaved_state = ""
	autosave_time = ""

func offer_recovery() -> void:
	var confirm := ConfirmationDialog.new()
	confirm.title = Localization.translate("Pulihkan sesi sebelumnya?")
	confirm.dialog_text = Localization.translate("Ada autosave dari sesi sebelumnya.\nPulihkan untuk melanjutkan gambar yang belum disimpan.")
	confirm.ok_button_text = Localization.translate("Pulihkan")
	confirm.cancel_button_text = Localization.translate("Mulai kosong")
	add_child(confirm)
	confirm.confirmed.connect(func(): recovery_pending = not load_from(autosave_path, true); confirm.queue_free())
	confirm.canceled.connect(func(): recovery_pending = false; clear_autosave(); confirm.queue_free())
	confirm.popup_centered(Vector2i(520, 160))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		guides.cancel_preview()
		finish_stroke()
		if autosave():
			get_tree().quit()
		else:
			show_message("Autosave gagal. Simpan proyek ke lokasi lain sebelum menutup aplikasi.")
	elif what == NOTIFICATION_APPLICATION_PAUSED and is_node_ready():
		cancel_input()
		autosave()
