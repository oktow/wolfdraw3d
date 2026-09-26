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
const PadJoystick = preload("res://scripts/pad_joystick.gd")
const APP_VERSION := "0.2.7"
var mirror_axes := {"x": false, "y": false, "z": false}
var mirror_button: Button
var compact_mirror_button: Button
var compact_axis_button: Button
var compact_pad_button: Button
var compact_cursor_button: Button
var cursor_button: Button
var cursor_pos := Vector3.ZERO
var vertex_edit := false
var vertex_drag_live := false
var mesh_select_mode := "vertex"
var selected_guide_vertices: Array[int] = []
var selected_guide_edges: Array = []
var selected_guide_faces: Array[int] = []
var pad_rail: VBoxContainer
var pad_stick: Control
var pad_visible := false
var mirror_menu: PopupMenu
var icon_help: AcceptDialog
var compact_help_button: Button
var compact_toolbar: HBoxContainer
var compact_draw_button: Button
var compact_guide_button: Button
var guide_type_menu: PopupMenu
var rail_guide_new_button: Button
var last_guide_type := "profile"
var context_rail: VBoxContainer
var rail_guide_save_button: Button
var rail_guide_close_button: Button
var rail_guide_face_button: Button
var rail_guide_delete_button: Button
var rail_guide_transform_button: Button
var rail_vertex_button: Button
var rail_edge_button: Button
var rail_face_button: Button
var rail_extrude_button: Button
var rail_guide_rot_button: Button
var rail_rotate_menu: PopupMenu
var rail_draw_brush_button: Button
var rail_draw_props_button: Button
var rail_props_popup: PopupPanel
var rail_props_color: ColorPickerButton
var rail_props_radius_slider: HSlider
var rail_props_radius_label: Label
var rail_props_opacity_slider: HSlider
var rail_props_opacity_label: Label
var rail_draw_taper_button: Button
var rail_draw_shape_button: Button
var rail_select_mode_button: Button
var rail_select_group_button: Button
var rail_select_all_button: Button
var rail_select_clear_button: Button
var rail_select_duplicate_button: Button
var rail_select_mirror_button: Button
var rail_select_delete_button: Button
var rail_erase_radius_button: Button
var rail_erase_radius_popup: PopupPanel
var eraser_radius_slider: HSlider
var eraser_radius_label: Label
var taper_toggle_button: Button

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
var brush_tool_menu: PopupMenu
var compact_shape_menu: PopupMenu

var transform_joystick: Control
var rail_mode_move_button: Button
var rail_mode_rotate_button: Button
var rail_mode_scale_button: Button
var shape_assist: RefCounted
var shape_picker: OptionButton
var eraser: Control
var eraser_controls: VBoxContainer
var camera := Camera3D.new()
var reference_grid := Node3D.new()
var cursor_gizmo := MeshInstance3D.new()
var env_settings: Dictionary = Store.default_environment()
var env: Environment
var sun: DirectionalLight3D
var axis_gizmo := MeshInstance3D.new()
var bg_quad := MeshInstance3D.new()
var bg_dialog: FileDialog
var grain_layer := CanvasLayer.new()
var grain_rect := ColorRect.new()
var env_slider_active := false
var env_axis_button: Button
var env_grid_button: Button
var env_fog_button: Button
var env_shadow_button: Button
var env_glow_button: Button
var env_grain_button: Button
var env_pixel_button: Button
var env_bg_color: ColorPickerButton
var env_light_color: ColorPickerButton
var env_light_alt_slider: HSlider
var env_light_alt_label: Label
var env_light_az_slider: HSlider
var env_light_az_label: Label
var env_light_energy_slider: HSlider
var env_light_energy_label: Label
var env_glow_slider: HSlider
var env_grain_slider: HSlider
var env_pixel_slider: HSlider
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
var nib_angle := deg_to_rad(45.0)
var nib_label: Label
var nib_slider: HSlider
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
# Feather-style gesture state (single-finger tap/hold, three-finger taps/FOV).
const DOUBLE_TAP_MS := 350
const TAP_TRAVEL_PX := 18.0
const DOUBLE_TAP_DIST_PX := 28.0
const HOLD_MS := 500
const HOLD_TRAVEL_PX := 12.0
const THREE_TAP_MS := 400
const THREE_DOUBLE_MS := 450
const THREE_TRAVEL_PX := 12.0
const FOV_MIN := 15.0
const FOV_MAX := 100.0
var touch_press_msec := -1
var touch_drew := false
var last_tap_msec := -1
var last_tap_pos := Vector2.ZERO
var hold_fired := false
var three_start_msec := -1
var three_start_centroid := Vector2.ZERO
var three_last_centroid := Vector2.ZERO
var three_moved := false
var three_start_fov := 45.0
var last_three_tap_msec := -1
var status: Label
var draw_button: Button
var nav_button: Button
var undo_button: Button
var redo_button: Button
var doc_revision := 0
var autosaved_revision := -1
var gif_frame_count := 36
var gif_fps := 12
var gif_resolution := 512

func _ready() -> void:
	testing = "--smoke-test" in OS.get_cmdline_user_args()
	add_child(camera)
	camera.fov = 45
	camera.far = 2000.0
	camera.current = true
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	env = environment.environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.WHITE
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.65
	add_child(environment)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -25, 0)
	add_child(sun)
	add_child(reference_grid)
	reference_grid.rotation.x = -PI / 2
	reference_grid.position.y = -2.5
	add_child(cursor_gizmo)
	cursor_gizmo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(axis_gizmo)
	axis_gizmo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	axis_gizmo.hide()
	add_child(bg_quad)
	bg_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bg_quad.hide()
	grain_layer.layer = 0
	add_child(grain_layer)
	grain_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grain_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var grain_material := ShaderMaterial.new()
	var grain_shader := Shader.new()
	grain_shader.code = "shader_type canvas_item;\nrender_mode blend_add;\nuniform float amount : hint_range(0.0, 1.0) = 0.0;\nfloat hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }\nvoid fragment() { float g = hash(UV * vec2(1920.0, 1080.0) + fract(TIME * 7.0) * 91.0) - 0.5; COLOR = vec4(vec3(g * amount * 0.6), 1.0); }\n"
	grain_material.shader = grain_shader
	grain_rect.material = grain_material
	grain_rect.hide()
	grain_layer.add_child(grain_rect)
	get_viewport().size_changed.connect(update_bg_quad)
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

var cursor_lines: ImmediateMesh
var cursor_material: StandardMaterial3D

func update_cursor_gizmo() -> void:
	# Blender-style 3D cursor: crosshair + view-facing ring pinned at the
	# cursor position, i.e. the reference point new guides are born from.
	# Constant on-screen size, always drawn on top. Mesh and material are
	# reused so navigation never reallocates per tick.
	if cursor_lines == null:
		cursor_lines = ImmediateMesh.new()
		cursor_material = StandardMaterial3D.new()
		cursor_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cursor_material.vertex_color_use_as_albedo = true
		cursor_material.no_depth_test = true
		cursor_gizmo.mesh = cursor_lines
	var arm := view_height() / get_viewport().get_visible_rect().size.y * 14.0
	var radius := arm * 0.8
	var lines := cursor_lines
	lines.clear_surfaces()
	lines.surface_begin(Mesh.PRIMITIVE_LINES, cursor_material)
	var right := camera.basis.x.normalized()
	var up := camera.basis.y.normalized()
	for axis in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
		lines.surface_set_color(Color("e58aa5") if axis == Vector3.RIGHT else (Color("8fce8f") if axis == Vector3.UP else Color("7fa8d9")))
		lines.surface_add_vertex(cursor_pos - axis * arm)
		lines.surface_add_vertex(cursor_pos + axis * arm)
	lines.surface_set_color(Color("f2f5f6"))
	var previous := cursor_pos + (right + up).normalized() * radius
	for i in range(1, 25):
		var angle := TAU * float(i) / 24.0
		var point := cursor_pos + (right * cos(angle) + up * sin(angle)) * radius
		lines.surface_add_vertex(previous)
		lines.surface_add_vertex(point)
		previous = point
	lines.surface_end()

func env_color(key: String) -> Color:
	var channels: Array = env_settings.get(key, [1.0, 1.0, 1.0])
	return Color(float(channels[0]), float(channels[1]), float(channels[2]))

func apply_environment(data: Dictionary) -> void:
	var full: Dictionary = Store.default_environment()
	for key in data:
		if full.has(key):
			full[key] = data[key]
	env_settings = full
	apply_axis()
	apply_grid()
	apply_background()
	apply_fog()
	apply_light()
	apply_glow()
	apply_grain()
	apply_pixel()
	refresh_env_ui()

func apply_axis() -> void:
	if axis_gizmo.mesh == null:
		var lines := ImmediateMesh.new()
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.vertex_color_use_as_albedo = true
		material.no_depth_test = true
		lines.surface_begin(Mesh.PRIMITIVE_LINES, material)
		for entry in [[Vector3.RIGHT, Color("f18cae")], [Vector3.UP, Color("73e6bb")], [Vector3.BACK, Color("8eb9ff")]]:
			lines.surface_set_color(entry[1])
			lines.surface_add_vertex(-entry[0] * 2.0)
			lines.surface_add_vertex(entry[0] * 2.0)
		lines.surface_end()
		axis_gizmo.mesh = lines
	axis_gizmo.visible = bool(env_settings.get("axis", false))

func apply_grid() -> void:
	reference_grid.visible = bool(env_settings.get("grid", true))

func apply_background() -> void:
	var bg := env_color("bg_color")
	env.background_color = bg
	env.fog_light_color = bg
	refresh_bg_quad()

func apply_fog() -> void:
	env.fog_enabled = bool(env_settings.get("fog", false))
	env.fog_light_color = env_color("bg_color")
	env.fog_density = 0.015

func apply_light() -> void:
	sun.rotation_degrees = Vector3(-float(env_settings.get("light_alt", 35.0)), float(env_settings.get("light_az", -25.0)), 0)
	sun.light_color = env_color("light_color")
	sun.light_energy = float(env_settings.get("light_energy", 1.0))
	sun.shadow_enabled = bool(env_settings.get("shadow", false))

func apply_glow() -> void:
	env.glow_enabled = bool(env_settings.get("glow", false))
	env.glow_intensity = float(env_settings.get("glow_amount", 0.8))

func apply_grain() -> void:
	grain_rect.visible = bool(env_settings.get("grain", false))
	(grain_rect.material as ShaderMaterial).set_shader_parameter("amount", float(env_settings.get("grain_amount", 0.3)))

func apply_pixel() -> void:
	var pixel_scale: float = clampf(float(env_settings.get("pixel_scale", 1.0)), 0.25, 1.0)
	get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	get_viewport().scaling_3d_scale = pixel_scale

func refresh_bg_quad() -> void:
	# Decode the stored image once; per-frame work stays in layout_bg_quad.
	var raw: String = str(env_settings.get("bg_image", ""))
	if raw.is_empty():
		bg_quad.hide()
		return
	if bg_quad.mesh == null:
		var quad := QuadMesh.new()
		var material := ShaderMaterial.new()
		var shader := Shader.new()
		shader.code = "shader_type spatial;\nrender_mode unshaded, fog_disabled;\nuniform sampler2D image_tex;\nvoid fragment() { ALBEDO = texture(image_tex, UV).rgb; }\n"
		material.shader = shader
		quad.material = material
		bg_quad.mesh = quad
	var image := Image.new()
	if image.load_png_from_buffer(Marshalls.base64_to_raw(raw)) != OK:
		bg_quad.hide()
		return
	((bg_quad.mesh as QuadMesh).material as ShaderMaterial).set_shader_parameter("image_tex", ImageTexture.create_from_image(image))
	bg_quad.show()
	layout_bg_quad()

func layout_bg_quad() -> void:
	if not bg_quad.visible:
		return
	var depth := distance + 100.0
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect: float = viewport_size.x / maxf(1.0, viewport_size.y)
	var height: float = 2.0 * depth * tan(deg_to_rad(camera.fov / 2.0)) * 1.02
	(bg_quad.mesh as QuadMesh).size = Vector2(height * aspect, height)
	var view_dir: Vector3 = -camera.global_transform.basis.z.normalized()
	bg_quad.global_transform = Transform3D(camera.global_transform.basis, camera.global_position + view_dir * depth)

func update_bg_quad() -> void:
	layout_bg_quad()

func set_bg_image(image: Image) -> void:
	var copy := image.duplicate() as Image
	if maxi(copy.get_width(), copy.get_height()) > 1024:
		var factor := 1024.0 / float(maxi(copy.get_width(), copy.get_height()))
		copy.resize(int(copy.get_width() * factor), int(copy.get_height() * factor), Image.INTERPOLATE_BILINEAR)
	checkpoint()
	env_settings["bg_image"] = Marshalls.raw_to_base64(copy.save_png_to_buffer())
	refresh_bg_quad()
	changed()

func clear_bg_image() -> void:
	if str(env_settings.get("bg_image", "")).is_empty():
		return
	checkpoint()
	env_settings["bg_image"] = ""
	refresh_bg_quad()
	changed()

func import_bg_image(path: String) -> void:
	var image := Image.new()
	if image.load(path) != OK:
		show_message("Gambar latar tidak dapat dibuka.")
		return
	set_bg_image(image)
	status.text = Localization.translate("Gambar latar dipasang.")

func env_set_toggle(key: String, value: bool) -> void:
	checkpoint()
	env_settings[key] = value
	apply_environment(env_settings)
	changed()

func env_begin_slider() -> void:
	if not env_slider_active:
		checkpoint()
		env_slider_active = true

func env_end_slider(_changed: bool) -> void:
	env_slider_active = false
	changed()

func refresh_env_ui() -> void:
	if env_axis_button == null:
		return
	env_axis_button.set_pressed_no_signal(bool(env_settings.get("axis", false)))
	if compact_axis_button != null:
		compact_axis_button.set_pressed_no_signal(bool(env_settings.get("axis", false)))
	env_grid_button.set_pressed_no_signal(bool(env_settings.get("grid", true)))
	env_fog_button.set_pressed_no_signal(bool(env_settings.get("fog", false)))
	env_shadow_button.set_pressed_no_signal(bool(env_settings.get("shadow", false)))
	env_glow_button.set_pressed_no_signal(bool(env_settings.get("glow", false)))
	env_grain_button.set_pressed_no_signal(bool(env_settings.get("grain", false)))
	env_pixel_button.set_pressed_no_signal(float(env_settings.get("pixel_scale", 1.0)) < 1.0)
	env_bg_color.color = env_color("bg_color")
	env_light_color.color = env_color("light_color")
	env_light_alt_slider.set_value_no_signal(float(env_settings.get("light_alt", 35.0)))
	env_light_alt_label.text = Localization.translate("Ketinggian cahaya") + ": %d°" % roundi(float(env_settings.get("light_alt", 35.0)))
	env_light_az_slider.set_value_no_signal(float(env_settings.get("light_az", -25.0)))
	env_light_az_label.text = Localization.translate("Arah cahaya") + ": %d°" % roundi(float(env_settings.get("light_az", -25.0)))
	env_light_energy_slider.set_value_no_signal(float(env_settings.get("light_energy", 1.0)))
	env_light_energy_label.text = Localization.translate("Kekuatan cahaya") + ": %d%%" % roundi(float(env_settings.get("light_energy", 1.0)) * 100.0)
	env_glow_slider.set_value_no_signal(float(env_settings.get("glow_amount", 0.8)))
	env_grain_slider.set_value_no_signal(float(env_settings.get("grain_amount", 0.3)))
	env_pixel_slider.set_value_no_signal(float(env_settings.get("pixel_scale", 1.0)))

func update_camera() -> void:
	finish_stroke()
	guides.cancel_preview()
	camera.size = 2.0 * distance * tan(deg_to_rad(camera.fov / 2))
	var back := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	# An explicit basis stays valid at the exact top/bottom poles.
	camera.transform = Transform3D(Basis(right, back.cross(right).normalized(), back.normalized()), target + back * distance)
	update_cursor_gizmo()
	update_bg_quad()

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

func place_cursor(screen: Vector2) -> void:
	# Touch anywhere becomes the 3D cursor: ink first, then guide, then the
	# floor grid, else a point at the current view distance along the ray.
	finish_stroke()
	var point: Variant = nearest_stroke_point(screen)
	if point == null:
		point = hit_point(screen)
	if point == null:
		var origin := camera.project_ray_origin(screen)
		var direction := camera.project_ray_normal(screen)
		var grid_hit: Variant = Plane(Vector3.UP, -2.5).intersects_ray(origin, direction)
		if grid_hit != null and absf(grid_hit.x) <= 6.0 and absf(grid_hit.z) <= 6.0:
			point = grid_hit
	if point == null:
		point = camera.project_ray_origin(screen) + camera.project_ray_normal(screen) * distance
	cursor_pos = point
	update_cursor_gizmo()
	status.text = Localization.translate("Kursor 3D") + ": (%.2f, %.2f, %.2f)" % [cursor_pos.x, cursor_pos.y, cursor_pos.z]

func reset_view() -> void:
	target = Vector3.ZERO
	distance = 12
	yaw = 0
	pitch = 0
	update_camera()

func snap_to_nearest_view() -> void:
	# Feather-style double-tap: settle on the closest standard view.
	var back: Vector3 = camera.basis.z.normalized()
	var best: Vector3 = VIEW_AXES[0]
	var best_dot := -2.0
	for axis in VIEW_AXES:
		var amount := back.dot(axis)
		if amount > best_dot:
			best_dot = amount
			best = axis
	snap_view(best)
	status.text = Localization.translate("Snap ke tampak standar.")

func nearest_stroke_point(screen: Vector2) -> Variant:
	var best := Vector3.ZERO
	var best_depth := INF
	var found := false
	for stroke in strokes:
		if not stroke.visible or not is_instance_valid(stroke):
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
			var pixels: float = stroke.radius * get_viewport().get_visible_rect().size.y / view_height(12.0)
			if screen.distance_to(closest) > maxf(10, pixels + 5):
				continue
			var za := -camera.to_local(a).z
			var zb := -camera.to_local(b).z
			var z: float = lerpf(za, zb, fraction) if camera.projection == Camera3D.PROJECTION_ORTHOGONAL else 1.0 / lerpf(1.0 / maxf(za, 0.001), 1.0 / maxf(zb, 0.001), fraction)
			if z < best_depth:
				best_depth = z
				best = a.lerp(b, fraction)
				found = true
	if not found:
		return null
	return best

func stroke_covers_rect(stroke: MeshInstance3D, rect: Rect2) -> bool:
	# Broad-phase prune so per-motion tools skip untouched strokes without
	# scanning every segment. Unknown or behind-camera bounds never skip.
	var box: AABB = stroke.bounds
	if not box.has_volume():
		return true
	var screen_box := Rect2()
	var started := false
	for i in 8:
		var corner := box.position + Vector3(
			box.size.x if (i & 1) != 0 else 0.0,
			box.size.y if (i & 2) != 0 else 0.0,
			box.size.z if (i & 4) != 0 else 0.0)
		if camera.is_position_behind(corner):
			return true
		var flat := camera.unproject_position(corner)
		if started:
			screen_box = screen_box.expand(flat)
		else:
			screen_box = Rect2(flat, Vector2.ZERO)
			started = true
	return screen_box.intersects(rect)

func ink_near(screen: Vector2, radius_px: float) -> bool:
	for stroke in strokes:
		if not stroke.visible or not is_instance_valid(stroke):
			continue
		for i in range(1, stroke.points.size()):
			var a: Vector3 = stroke.points[i - 1]
			var b: Vector3 = stroke.points[i]
			if camera.is_position_behind(a) or camera.is_position_behind(b):
				continue
			var pa := camera.unproject_position(a)
			var pb := camera.unproject_position(b)
			if Geometry2D.get_closest_point_to_segment(screen, pa, pb).distance_to(screen) <= radius_px:
				return true
	return false

func do_orbit_hold(screen: Vector2) -> void:
	# Feather-style tap-and-hold: pin the orbit point on a stroke, guide, or
	# the floor grid; holding on empty space resets the view.
	finish_stroke()
	var point: Variant = nearest_stroke_point(screen)
	if point != null:
		target = point
		update_camera()
		status.text = Localization.translate("Pusat orbit: goresan.")
		return
	var hit: Variant = hit_point(screen)
	if hit != null:
		target = hit
		update_camera()
		status.text = Localization.translate("Pusat orbit: guide.")
		return
	var grid_hit: Variant = Plane(Vector3.UP, -2.5).intersects_ray(camera.project_ray_origin(screen), camera.project_ray_normal(screen))
	if grid_hit != null and absf(grid_hit.x) <= 6.0 and absf(grid_hit.z) <= 6.0:
		target = grid_hit
		update_camera()
		status.text = Localization.translate("Pusat orbit: lantai.")
		return
	reset_view()
	status.text = Localization.translate("Tampilan direset.")

func hit_point(screen: Vector2) -> Variant:
	return guides.ray_hit(screen)

func begin_stroke(screen: Vector2) -> void:
	if guides.placing and (guides.creation_mode == "polyline" or guides.creation_mode == "plane_taps"):
		guides.begin_preview(screen)
		return
	if active != null or fill_active or guides.preview != null:
		return
	if guides.placing:
		guides.begin_preview(screen)
		if guides.preview != null and (guides.creation_mode == "profile" or guides.creation_mode == "bend" or guides.creation_mode == "curve"):
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
	if brush_kind == "flat":
		# Pena pipih solid: lebar konstan dan opak penuh, apa pun slider-nya.
		active.opacity = 1.0
		active.taper = 0.0
	else:
		active.opacity = brush_opacity
		active.taper = brush_taper
	active.nib_angle = nib_angle
	active.plane_normal = guides.current().surface_normal()
	active.group_id = active_group
	active.defer_rebuild = true
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
		active.defer_rebuild = false
		active.rebuild()
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
		# Mirror across the planes through the 3D cursor, not the origin.
		for i in copy.points.size():
			copy.points[i] = cursor_pos + (copy.points[i] - cursor_pos) * reflection
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
		doc_revision += 1
	sync_dirty()

func redo() -> void:
	guides.cancel_placing()
	finish_stroke()
	if not future.is_empty():
		history.append(document())
		restore_document(future.pop_back())
		doc_revision += 1
	sync_dirty()

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
	touch_press_msec = -1
	touch_drew = false
	last_tap_msec = -1
	hold_fired = false
	three_start_msec = -1
	three_moved = false
	last_three_tap_msec = -1
	update_status()

func _process(delta: float) -> void:
	flush_touch_navigation()
	tick_touch_hold()
	guides.tick_polyline_idle()
	shape_assist.tick(delta)
	if sequence_playing:
		advance_sequence(delta)

func tick_touch_hold() -> void:
	# Feather-style tap-and-hold: one stationary finger in orbit mode pins the
	# orbit point after HOLD_MS; further movement just orbits from there.
	if hold_fired or liquify_active or touch_blocked or touch_action != "orbit":
		return
	if touches.size() != 1 or touch_press_msec < 0 or touch_travel > HOLD_TRAVEL_PX:
		return
	if Time.get_ticks_msec() - touch_press_msec < HOLD_MS:
		return
	hold_fired = true
	do_orbit_hold(touches.values()[0])

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
		if touches.size() == 3:
			var positions := touches.values()
			three_start_centroid = (positions[0] + positions[1] + positions[2]) / 3
			three_last_centroid = three_start_centroid
			three_start_msec = Time.get_ticks_msec()
			three_moved = false
			three_start_fov = camera.fov
		else:
			three_start_msec = -1
	else:
		touch_travel = 0
		pending_touch = event.position
		touch_press_msec = Time.get_ticks_msec()
		touch_drew = false
		hold_fired = false
		touch_action = "cursor" if tool == "cursor" else ("edit" if finger_drawing and not navigation else "orbit")
		if not touch_blocked and touch_action == "cursor":
			place_cursor(event.position)
			return
		if liquify_active and not touch_blocked:
			liquify_update_cursor(event.position)
			liquify_begin_drag(event.position)
			return
		if not touch_blocked and touch_action == "edit" and tool == "draw":
			begin_stroke(event.position)
			touch_drew = active != null or guides.preview != null
		elif not touch_blocked and touch_action == "edit" and tool == "erase":
			eraser.begin(event.position)
			touch_drew = true
			# Pressing far from any ink orbits instead, so rotating never
			# needs a mode toggle. begin() above keeps tap-to-deselect and
			# commits nothing when the sweep touches no ink.
			if not ink_near(event.position, eraser.radius + 8.0):
				touch_action = "orbit"
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
	elif touches.size() == 3 and three_start_msec >= 0:
		# Feather-style three-finger vertical swipe adjusts the field of view.
		var positions := touches.values()
		var centroid: Vector2 = (positions[0] + positions[1] + positions[2]) / 3
		if centroid.distance_to(three_start_centroid) > THREE_TRAVEL_PX:
			three_moved = true
		camera.fov = clampf(three_start_fov - (centroid.y - three_start_centroid.y) * 0.05, FOV_MIN, FOV_MAX)
		three_last_centroid = centroid
		update_camera()
		status.text = "FOV: %d°" % roundi(camera.fov)
	elif touches.size() == 1 and not touch_blocked:
		touch_travel += delta.length()
		if liquify_active:
			liquify_update_cursor(event.position)
			liquify_drag(event.position)
			return
		if touch_action == "orbit":
			orbit(delta * 800.0 / maxf(get_viewport().get_visible_rect().size.y, 1))
		elif touch_action == "cursor":
			place_cursor(event.position)
			return
		elif tool == "draw":
			# Draw-mode drag on empty space (no ink, no fill, no guide preview)
			# orbits, so rotating never needs a finger-mode toggle. Decided
			# on drag, never on press, so holds and taps keep their old
			# meaning. Fill tools join in: outside a guide they orbit, inside
			# they fill as before.
			if not touch_drew and active == null and not fill_active and guides.preview == null and not guides.placing and brush_kind in ["pen", "pencil", "brush", "marker", "flat", "tube", "lasso_fill", "rectangle_fill"] and touch_travel > TAP_TRAVEL_PX:
				touch_action = "orbit"
				touch_drew = true
				update_status()
				orbit(delta * 800.0 / maxf(get_viewport().get_visible_rect().size.y, 1))
				return
			extend_stroke(event.position)
		elif tool == "erase":
			eraser.extend(event.position)
		elif tool == "select" and selection_mode == "tap":
			# Tap mode uses only taps; any real drag orbits without a toggle.
			# Rectangle/lasso below keep their drag for the selection area.
			if touch_travel > TAP_TRAVEL_PX:
				touch_action = "orbit"
				update_status()
				orbit(delta * 800.0 / maxf(get_viewport().get_visible_rect().size.y, 1))
				return
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
	var was_three := touches.size() == 3
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
				if tool == "select" and touch_travel < TAP_TRAVEL_PX and event.position.distance_to(pending_touch) < TAP_TRAVEL_PX:
					if selection_mode == "tap":
						edit_at(event.position)
					elif selection_overlay.active:
						apply_area_selection(selection_overlay.end_selection())
				elif guides.placing and guides.creation_mode == "polyline" and touch_travel < TAP_TRAVEL_PX and event.position.distance_to(pending_touch) < TAP_TRAVEL_PX:
					# Double-tap commits the clicked vertices.
					var tap_ms: int = Time.get_ticks_msec() - touch_press_msec if touch_press_msec >= 0 else DOUBLE_TAP_MS + 1
					if tap_ms <= DOUBLE_TAP_MS:
						var tap_now := Time.get_ticks_msec()
						if last_tap_msec >= 0 and tap_now - last_tap_msec <= DOUBLE_TAP_MS and event.position.distance_to(last_tap_pos) <= DOUBLE_TAP_DIST_PX:
							last_tap_msec = -1
							guides.finish_preview(true)
						else:
							last_tap_msec = tap_now
							last_tap_pos = event.position
				guides.finish_preview()
				finish_stroke()
			elif touches.size() == 1 and not touch_blocked and touch_action == "orbit":
				# Feather-style double-tap settles on the nearest standard view.
				var press_ms: int = Time.get_ticks_msec() - touch_press_msec if touch_press_msec >= 0 else DOUBLE_TAP_MS + 1
				if touch_travel < TAP_TRAVEL_PX and event.position.distance_to(pending_touch) < TAP_TRAVEL_PX and press_ms <= DOUBLE_TAP_MS:
					var now_ms := Time.get_ticks_msec()
					if last_tap_msec >= 0 and now_ms - last_tap_msec <= DOUBLE_TAP_MS and event.position.distance_to(last_tap_pos) <= DOUBLE_TAP_DIST_PX:
						last_tap_msec = -1
						snap_to_nearest_view()
					else:
						last_tap_msec = now_ms
						last_tap_pos = event.position
			# Feather-style three-finger double-tap toggles the projection.
			if was_three and three_start_msec >= 0 and not three_moved and Time.get_ticks_msec() - three_start_msec <= THREE_TAP_MS:
				var now_ms := Time.get_ticks_msec()
				if last_three_tap_msec >= 0 and now_ms - last_three_tap_msec <= THREE_DOUBLE_MS:
					last_three_tap_msec = -1
					three_start_msec = -1
					touches.erase(event.index)
					reset_touch_pair()
					if touches.is_empty():
						touch_blocked = false
						touch_action = ""
					set_projection(0 if camera.projection == Camera3D.PROJECTION_ORTHOGONAL else 1)
					status.text = Localization.translate("Proyeksi: Perspektif." if camera.projection == Camera3D.PROJECTION_PERSPECTIVE else "Proyeksi: Ortografis.")
					return
				else:
					last_three_tap_msec = now_ms
	touches.erase(event.index)
	reset_touch_pair()
	if touches.is_empty():
		touch_blocked = false
		touch_action = ""
		touch_drew = false

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
			if tool == "cursor":
				place_cursor(event.position)
			elif tool == "draw":
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
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		var hovered := get_viewport().gui_get_hovered_control()
		if hovered != null and hovered != selection_overlay:
			return
		if guides.placing and guides.creation_mode == "polyline":
			guides.finish_preview(true)
			get_viewport().set_input_as_handled()
			return
		if navigation:
			snap_to_nearest_view()
	elif event is InputEventMouseMotion:
		if tool == "erase":
			eraser.move_cursor(event.position)
		if event.button_mask == 0 and guides.placing and guides.creation_mode == "polyline" and tool == "draw":
			guides.preview_rubber(event.position)
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			pan(event.relative)
		elif event.button_mask & MOUSE_BUTTON_MASK_RIGHT or (navigation and event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			orbit(event.relative)
		elif event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			if tool == "cursor":
				place_cursor(event.position)
			elif tool == "erase":
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
	if cursor_button != null:
		cursor_button.button_pressed = value == "cursor"
	if value == "select":
		transform_joystick.set_mode("move")
	if compact_draw_button != null:
		compact_draw_button.button_pressed = value == "draw"
		compact_nav_button.button_pressed = navigation
		compact_select_button.button_pressed = value == "select"
		compact_erase_button.button_pressed = value == "erase"
	if compact_cursor_button != null:
		compact_cursor_button.button_pressed = value == "cursor"
	if compact_pad_button != null:
		compact_pad_button.disabled = value != "select"
		if value != "select" and pad_visible:
			pad_visible = false
			compact_pad_button.set_pressed_no_signal(false)
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

func liquify_begin_drag(screen_pos: Vector2) -> void:
	if not liquify_active:
		return
	liquify_dragging = true
	liquify_update_cursor(screen_pos)
	liquify_last_position = screen_pos

func liquify_update_cursor(screen_pos: Vector2) -> void:
	if not liquify_active:
		return
	selection_overlay.set_liquify_preview(true, screen_pos, liquify_screen_radius(screen_pos), liquify_range)

func liquify_screen_radius(_position: Vector2) -> float:
	var depth := distance
	if not selected_strokes.is_empty() and is_instance_valid(selected_strokes[0]) and not selected_strokes[0].points.is_empty():
		depth = maxf(-camera.to_local(selected_strokes[0].points[0]).z, 0.01)
	return liquify_size * get_viewport().get_visible_rect().size.y / view_height(depth)

func liquify_drag(screen_pos: Vector2) -> void:
	if not liquify_active or not liquify_dragging:
		return
	var delta := screen_pos - liquify_last_position
	liquify_last_position = screen_pos
	if delta.length_squared() < 0.01:
		return
	for stroke in selected_strokes:
		if is_instance_valid(stroke):
			liquify_stroke(stroke, screen_pos, delta)
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
	var modes := {"draw": "Gambar", "navigate": "Navigasi", "select": "Seleksi", "erase": "Hapus", "cursor": "Kursor"}
	status.text = "%s%s   /   %d %s   /   %s" % [title, " *" if dirty else "", strokes.size(), Localization.translate("goresan"), Localization.translate(modes[tool])]
	status.text += "   /   " + Localization.translate("Membuat guide" if guides.placing else ("Guide actif" if guides.current() != null else "Tanpa guide"))
	status.text += "   /   " + Localization.translate("Kursor 3D") + ": (%.2f, %.2f, %.2f)" % [cursor_pos.x, cursor_pos.y, cursor_pos.z]
	if dirty and not autosave_time.is_empty():
		status.text += "   /   Autosave " + autosave_time
	undo_button.disabled = history.is_empty()
	redo_button.disabled = future.is_empty()
	if compact_undo_button != null:
		compact_undo_button.disabled = undo_button.disabled
		compact_redo_button.disabled = redo_button.disabled
	refresh_context_rail()
	if selection_label != null:
		if not selected_strokes.is_empty():
			selection_label.text = "%d goresan dipilih" % selected_strokes.size()
		elif not selected_guide_faces.is_empty():
			selection_label.text = "%d face dipilih" % selected_guide_faces.size()
		elif not selected_guide_edges.is_empty():
			selection_label.text = "%d edge dipilih" % selected_guide_edges.size()
		elif not selected_guide_vertices.is_empty():
			selection_label.text = "%d vertex dipilih" % selected_guide_vertices.size()
		elif tool == "select" and guides != null and guides.current() != null:
			selection_label.text = Localization.translate("Gizmo: guide aktif")
		elif tool == "select":
			selection_label.text = Localization.translate("Gizmo: kursor 3D")
		else:
			selection_label.text = Localization.translate("Belum ada seleksi")

func layout_context_rail() -> void:
	# Keep the rail clear of the left sidebar when panels are shown. Both
	# horizontal edges are set: without offset_right the container width goes
	# negative and the buttons slide inside the panel.
	if context_rail == null:
		return
	context_rail.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	var rail_left := 292.0 if menu_visible else 20.0
	context_rail.offset_left = rail_left
	context_rail.offset_right = rail_left + 56.0
	if pad_rail != null:
		var pad_right := -336.0 if menu_visible else -20.0
		pad_rail.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
		pad_rail.offset_right = pad_right
		pad_rail.offset_left = pad_right - 178.0
		pad_rail.offset_top = -105
		pad_rail.offset_bottom = 105
	# Height follows the visible button count so stacked sections never clip.
	var shown := 0
	for button in [rail_guide_save_button, rail_guide_close_button, rail_guide_face_button, rail_guide_delete_button, rail_guide_transform_button, rail_guide_rot_button, rail_vertex_button, rail_edge_button, rail_face_button, rail_extrude_button, rail_draw_brush_button, rail_draw_props_button, rail_draw_taper_button, rail_draw_shape_button, rail_guide_new_button, rail_select_mode_button, rail_select_group_button, rail_select_all_button, rail_select_clear_button, rail_mode_move_button, rail_mode_rotate_button, rail_mode_scale_button, rail_select_duplicate_button, rail_select_mirror_button, rail_select_delete_button, rail_erase_radius_button]:
		if button != null and button.visible:
			shown += 1
	var half := clampf(shown * 28.0 + 8.0, 60.0, get_viewport().get_visible_rect().size.y / 2.0 - 90.0)
	context_rail.offset_top = -half
	context_rail.offset_bottom = half

func rail_brush_icon() -> Texture2D:
	var icons := {"pen": "pen", "pencil": "pencil", "brush": "brush", "marker": "marker", "flat": "flat", "tube": "tube", "lasso_fill": "lasso_fill", "rectangle_fill": "rectangle_fill"}
	return Icons.texture(icons.get(brush_kind, "pen"))

func refresh_rail_draw_icons() -> void:
	if rail_draw_brush_button == null:
		return
	rail_draw_brush_button.text = ""
	rail_draw_brush_button.icon = rail_brush_icon()
	rail_draw_brush_button.tooltip_text = Localization.translate("Pilih jenis brush")
	if rail_draw_taper_button != null:
		rail_draw_taper_button.set_pressed_no_signal(brush_taper > 0.0)

func refresh_context_rail() -> void:
	if context_rail == null:
		return
	# Guide and Draw stack when drawing on a guide; Select/Erase yield to
	# the guide section. Without a guide, the rail follows the tool. The
	# creation section shows on top-guide-icon toggle.
	var guide_active := guides != null and guides.current() != null
	var draw_active := tool == "draw"
	var select_active := tool == "select" and not guide_active
	var erase_active := tool == "erase" and not guide_active
	for button in [rail_guide_save_button, rail_guide_close_button, rail_guide_face_button, rail_guide_delete_button, rail_guide_transform_button, rail_guide_rot_button, rail_vertex_button, rail_edge_button, rail_face_button, rail_extrude_button]:
		if button != null:
			button.visible = guide_active
	if rail_vertex_button != null:
		rail_vertex_button.set_pressed_no_signal(vertex_edit and mesh_select_mode == "vertex")
		rail_edge_button.set_pressed_no_signal(vertex_edit and mesh_select_mode == "edge")
		rail_face_button.set_pressed_no_signal(vertex_edit and mesh_select_mode == "face")
		rail_extrude_button.disabled = not can_extrude()
	for button in [rail_draw_brush_button, rail_draw_props_button, rail_draw_taper_button, rail_draw_shape_button]:
		if button != null:
			button.visible = draw_active
	for button in [rail_select_mode_button, rail_select_group_button, rail_select_all_button, rail_select_clear_button, rail_mode_move_button, rail_mode_rotate_button, rail_mode_scale_button, rail_select_duplicate_button, rail_select_mirror_button, rail_select_delete_button]:
		if button != null:
			button.visible = select_active
	if select_active:
		refresh_rail_transform_modes()
	if rail_erase_radius_button != null:
		rail_erase_radius_button.visible = erase_active
	if draw_active:
		refresh_rail_draw_icons()
	refresh_top_guide_icon()
	# The rail is a hidden-menu quick bar; it never covers the open panels.
	# Guide and Draw sections stack when a guide is active while drawing.
	# The single creation button is always at hand in hidden-menu mode.
	if rail_guide_new_button != null:
		rail_guide_new_button.visible = true
	context_rail.visible = not menu_visible
	if pad_rail != null:
		pad_rail.visible = pad_visible and tool == "select" and not menu_visible
		if not pad_rail.visible and pad_stick != null and not pad_stick.dragging.is_empty():
			# Finish, don't strand: hiding mid-drag commits the partial move.
			pad_stick.end_gesture()
	layout_context_rail()

func edit_guide_transform() -> void:
	# Jump to the viewport gizmo with the active guide as its target.
	if guides == null or guides.current() == null:
		return
	finish_stroke()
	clear_selection()
	set_tool("select")

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
	icon_help.popup_centered(Vector2i(int(minf(760, viewport_size.x * 0.9)), int(minf(600, viewport_size.y * 0.85))))

func refresh_nib_ui() -> void:
	if nib_slider == null:
		return
	var enabled := brush_kind == "marker"
	nib_slider.editable = enabled
	nib_slider.modulate = Color(1, 1, 1, 1) if enabled else Color(1, 1, 1, 0.35)
	nib_label.modulate = Color(1, 1, 1, 1) if enabled else Color(1, 1, 1, 0.35)

func set_eraser_radius(value: float) -> void:
	eraser.radius = value
	if eraser_radius_label != null:
		eraser_radius_label.text = Localization.translate("Radius eraser") + ": %d px" % value
	if eraser_radius_slider != null:
		eraser_radius_slider.set_value_no_signal(value)
	eraser.queue_redraw()

var last_color_checkpoint_msec := -100000

func set_brush_color(value: Color) -> void:
	# The chosen color applies to new ink; with an active selection it also
	# repaints the selected strokes as one undoable step (checkpoint coalesced
	# so picker drags don't flood the history).
	ink = Color(value.r, value.g, value.b, 1.0)
	brush_picker.color = ink
	if rail_props_color != null:
		rail_props_color.color = ink
	ink_label.text = Localization.translate("Warna") + "  #" + ink.to_html(false).to_upper()
	if selected_strokes.is_empty():
		return
	if Time.get_ticks_msec() - last_color_checkpoint_msec > 1500:
		checkpoint()
		last_color_checkpoint_msec = Time.get_ticks_msec()
	for stroke in selected_strokes:
		if is_instance_valid(stroke):
			stroke.apply_ink(ink)
	changed()
	status.text = Localization.translate("Warna seleksi diubah.")

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

func build_compact_value_popup(title_key: String, minimum: float, maximum: float, step: float, value: float, on_change: Callable, format_value: Callable) -> PopupPanel:
	var popup := PopupPanel.new()
	popup.add_theme_stylebox_override("panel", style(Color("18232d")))
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(220, 0)
	column.add_theme_constant_override("separation", 8)
	popup.add_child(column)
	var label := label_in(column, title_key, 14)
	label.text = Localization.translate(title_key) + str(format_value.call(value))
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(200, 36)
	slider.value_changed.connect(func(new_value: float):
		label.text = Localization.translate(title_key) + str(format_value.call(new_value))
		on_change.call(new_value)
	)
	column.add_child(slider)
	popup.set_meta("slider", slider)
	popup.set_meta("label", label)
	popup.set_meta("title_key", title_key)
	popup.set_meta("format", format_value)
	compact_toolbar.get_parent().add_child(popup)
	return popup

func show_synced_popup(popup: PopupPanel, source: Control, value: float) -> void:
	# Rail buttons share the compact popups; resync the slider so panel-side
	# edits never show stale values.
	(popup.get_meta("slider") as HSlider).set_value_no_signal(value)
	(popup.get_meta("label") as Label).text = Localization.translate(popup.get_meta("title_key")) + str((popup.get_meta("format") as Callable).call(value))
	show_compact_popup(popup, source)

func toggle_menu() -> void:
	finish_stroke()
	menu_visible = not menu_visible
	brush_picker.get_popup().hide()
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
	layout_context_rail()
	refresh_context_rail()
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

func select_compact_shape(index: int) -> void:
	if shape_picker == null or index < 0 or index >= shape_picker.item_count:
		return
	shape_picker.select(index)
	finish_stroke()
	shape_assist.mode = ["off", "auto"][index]

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
	var subtitle := label_in(row, "GUIDE / DRAW • v" + APP_VERSION, 13)
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
	cursor_button = button_in(row, "Kursor 3D", set_tool.bind("cursor"))
	cursor_button.toggle_mode = true
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
	radius_slider.min_value = 0.005
	radius_slider.max_value = 0.5
	radius_slider.step = 0.005
	radius_slider.value = brush_radius
	radius_slider.custom_minimum_size.y = 32
	radius_slider.value_changed.connect(func(value: float): brush_radius = value; size_label.text = Localization.translate("Radius") + "  %.3f" % value)
	column.add_child(radius_slider)
	var brush_picker_type := OptionButton.new()
	brush_picker_type.custom_minimum_size.y = 44
	var brush_items := ["Pena", "Pensil tekstur", "Kuas tekstur", "Spidol datar", "Pena pipih", "Tube 3D (lama)", "Lasso Fill", "Rectangle Fill"]
	for title in brush_items:
		brush_picker_type.add_item(Localization.translate(title))
	brush_picker_type.set_meta("locale_items", brush_items)
	brush_picker_type.item_selected.connect(func(index: int): brush_kind = ["pen", "pencil", "brush", "marker", "flat", "tube", "lasso_fill", "rectangle_fill"][index]; refresh_nib_ui(); refresh_rail_draw_icons())
	brush_picker_type.select(0)
	column.add_child(brush_picker_type)
	nib_label = label_in(column, "Sudut nib", 14)
	nib_slider = HSlider.new()
	nib_slider.min_value = 0
	nib_slider.max_value = 180
	nib_slider.step = 1
	nib_slider.value = 45
	nib_slider.custom_minimum_size.y = 32
	nib_slider.value_changed.connect(func(value: float): nib_angle = deg_to_rad(value); nib_label.text = Localization.translate("Sudut nib") + ": %d°" % roundi(value))
	column.add_child(nib_slider)
	refresh_nib_ui()
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
	taper_toggle_button = button_in(brush_toggles, "Ujung meruncing", func(): pass)
	taper_toggle_button.toggle_mode = true
	taper_toggle_button.button_pressed = true
	taper_toggle_button.toggled.connect(func(value: bool):
		brush_taper = 0.15 if value else 0.0
		if rail_draw_taper_button != null:
			rail_draw_taper_button.set_pressed_no_signal(value))
	shape_picker = OptionButton.new()
	shape_picker.custom_minimum_size.y = 44
	for title in ["Draw Shape: mati", "Draw Shape: otomatis"]:
		shape_picker.add_item(Localization.translate(title))
	shape_picker.set_meta("locale_items", ["Draw Shape: mati", "Draw Shape: otomatis"])
	shape_picker.item_selected.connect(func(index: int): finish_stroke(); shape_assist.mode = ["off", "auto"][index])
	shape_picker.tooltip_text = Localization.translate("Gambar bebas, tahan ujung sekitar 1 detik untuk merapikan, lalu geser tanpa melepas. Lepas sebelum ditahan untuk tetap bebas.")
	column.add_child(shape_picker)
	shape_picker.get_popup().add_theme_constant_override("v_separation", 22)
	brush_picker_type.item_selected.connect(func(index: int): brush_alpha.editable = index < 5; taper_toggle_button.disabled = index >= 5)
	eraser_controls = VBoxContainer.new()
	column.add_child(eraser_controls)
	eraser_radius_label = label_in(eraser_controls, "Radius eraser", 14)
	eraser_radius_label.text = Localization.translate("Radius eraser") + ": 24 px"
	eraser_radius_slider = HSlider.new()
	eraser_radius_slider.min_value = 4
	eraser_radius_slider.max_value = 100
	eraser_radius_slider.step = 1
	eraser_radius_slider.value = eraser.radius
	eraser_radius_slider.custom_minimum_size.y = 32
	eraser_radius_slider.value_changed.connect(func(value: float): set_eraser_radius(value))
	eraser_controls.add_child(eraser_radius_slider)
	eraser_controls.hide()
	var smooth_toggle := button_in(brush_toggles, "Haluskan goresan", func(): pass)
	smooth_toggle.toggle_mode = true
	smooth_toggle.button_pressed = true
	smooth_toggle.toggled.connect(func(value: bool): smoothing = value)
	column.add_child(HSeparator.new())
	guides.build_controls(column)
	build_environment_panel(column)
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
	compact_guide_button = button_in(compact_toolbar, "Buat guide", toggle_guide_create)
	compact_guide_button.toggle_mode = true
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
	compact_cursor_button = button_in(compact_toolbar, "Kursor 3D", set_tool.bind("cursor"))
	compact_axis_button = button_in(compact_toolbar, "Sumbu global", func(): pass)
	compact_axis_button.toggle_mode = true
	compact_axis_button.set_pressed_no_signal(bool(env_settings.get("axis", false)))
	compact_axis_button.toggled.connect(func(value: bool): env_set_toggle("axis", value))
	compact_pad_button = button_in(compact_toolbar, "Joystick 2D", func(): pass)
	compact_pad_button.toggle_mode = true
	compact_pad_button.toggled.connect(func(value: bool):
		pad_visible = value
		refresh_context_rail())
	compact_toolbar.move_child(compact_guide_button, 0)
	compact_toolbar.move_child(compact_duplicate_button, 5)
	compact_toolbar.move_child(compact_loft_button, 6)
	for tool_button in [compact_guide_button, compact_draw_button, compact_nav_button, compact_select_button, compact_duplicate_button, compact_loft_button, compact_erase_button, compact_pad_button, compact_axis_button, compact_cursor_button]:
		tool_button.custom_minimum_size = Vector2(48, 48)
		tool_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tool_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tool_button.expand_icon = false
		tool_button.add_theme_constant_override("icon_max_width", 24)
		tool_button.set_meta("icon_button", true)
	for icon_button in [compact_guide_button, compact_draw_button, compact_nav_button, compact_select_button, compact_duplicate_button, compact_loft_button, compact_erase_button, compact_pad_button, compact_axis_button, compact_cursor_button]:
		icon_button.text = ""
	compact_undo_button.text = ""
	compact_redo_button.text = ""
	compact_mirror_button.text = ""
	Icons.apply(compact_undo_button, "Undo")
	Icons.apply(compact_redo_button, "Redo")
	Icons.apply(compact_mirror_button, "Mirror")
	Icons.apply(compact_duplicate_button, "Duplikat")
	Icons.apply(compact_loft_button, "Loft")
	compact_shape_menu = PopupMenu.new()
	var compact_shape_items := ["Draw Shape: mati", "Draw Shape: otomatis"]
	for index in compact_shape_items.size():
		compact_shape_menu.add_check_item(Localization.translate(compact_shape_items[index]), index)
	compact_shape_menu.set_meta("locale_items", compact_shape_items)
	compact_shape_menu.id_pressed.connect(select_compact_shape)
	compact_toolbar.get_parent().add_child(compact_shape_menu)
	# Contextual vertical rail on the left: shows icons related to whatever
	# top-level function is active (first section: active guide).
	context_rail = VBoxContainer.new()
	root.add_child(context_rail)
	context_rail.add_theme_constant_override("separation", 8)
	rail_guide_save_button = button_in(context_rail, "Simpan guide", guides.save_active)
	rail_guide_close_button = button_in(context_rail, "Tutup", guides.close_active)
	rail_guide_face_button = button_in(context_rail, "Hadap guide", face_guide)
	rail_guide_delete_button = button_in(context_rail, "Hapus guide aktif", guides.delete_active)
	rail_guide_transform_button = button_in(context_rail, "Transformasi guide", edit_guide_transform)
	rail_vertex_button = button_in(context_rail, "Vertex objek", func(): toggle_mesh_mode("vertex"))
	rail_vertex_button.toggle_mode = true
	rail_edge_button = button_in(context_rail, "Edge objek", func(): toggle_mesh_mode("edge"))
	rail_edge_button.toggle_mode = true
	rail_face_button = button_in(context_rail, "Face objek", func(): toggle_mesh_mode("face"))
	rail_face_button.toggle_mode = true
	rail_extrude_button = button_in(context_rail, "Extrude tepi", extrude_mesh_boundary)
	rail_guide_rot_button = button_in(context_rail, "Putar 90°", show_rail_rotate_menu)
	rail_rotate_menu = PopupMenu.new()
	for axis_name in ["Sumbu X", "Sumbu Y", "Sumbu Z"]:
		rail_rotate_menu.add_item(Localization.translate(axis_name))
	rail_rotate_menu.set_meta("locale_items", ["Sumbu X", "Sumbu Y", "Sumbu Z"])
	rail_rotate_menu.id_pressed.connect(select_rail_rotate_axis)
	root.add_child(rail_rotate_menu)
	rail_draw_brush_button = button_in(context_rail, "Pena", show_rail_brush_menu)
	rail_draw_props_button = button_in(context_rail, "Properti", show_rail_props_menu)
	rail_props_popup = PopupPanel.new()
	rail_props_popup.add_theme_stylebox_override("panel", style(Color("18232d")))
	var props_column := VBoxContainer.new()
	props_column.custom_minimum_size = Vector2(240, 0)
	props_column.add_theme_constant_override("separation", 8)
	rail_props_popup.add_child(props_column)
	label_in(props_column, "Warna brush", 14)
	rail_props_color = ColorPickerButton.new()
	rail_props_color.color = ink
	rail_props_color.edit_alpha = false
	rail_props_color.custom_minimum_size.y = 40
	rail_props_color.color_changed.connect(set_brush_color)
	props_column.add_child(rail_props_color)
	rail_props_radius_label = label_in(props_column, "Radius", 14)
	rail_props_radius_slider = HSlider.new()
	rail_props_radius_slider.min_value = 0.005
	rail_props_radius_slider.max_value = 0.5
	rail_props_radius_slider.step = 0.005
	rail_props_radius_slider.value = brush_radius
	rail_props_radius_slider.custom_minimum_size = Vector2(220, 36)
	rail_props_radius_slider.value_changed.connect(func(value: float):
		brush_radius = value
		rail_props_radius_label.text = Localization.translate("Radius") + "  %.3f" % value
		size_label.text = Localization.translate("Radius") + "  %.3f" % value)
	props_column.add_child(rail_props_radius_slider)
	rail_props_opacity_label = label_in(props_column, "Opacity brush", 14)
	rail_props_opacity_slider = HSlider.new()
	rail_props_opacity_slider.min_value = 0.05
	rail_props_opacity_slider.max_value = 1.0
	rail_props_opacity_slider.step = 0.05
	rail_props_opacity_slider.value = brush_opacity
	rail_props_opacity_slider.custom_minimum_size = Vector2(220, 36)
	rail_props_opacity_slider.value_changed.connect(func(value: float):
		brush_opacity = value
		rail_props_opacity_label.text = Localization.translate("Opacity brush") + ": %d%%" % roundi(value * 100.0))
	props_column.add_child(rail_props_opacity_slider)
	compact_toolbar.get_parent().add_child(rail_props_popup)
	rail_draw_taper_button = button_in(context_rail, "Ujung meruncing", func(): pass)
	rail_draw_taper_button.toggle_mode = true
	rail_draw_taper_button.button_pressed = brush_taper > 0.0
	rail_draw_taper_button.toggled.connect(func(value: bool):
		brush_taper = 0.15 if value else 0.0
		if taper_toggle_button != null:
			taper_toggle_button.set_pressed_no_signal(value)
		refresh_rail_draw_icons())
	rail_draw_shape_button = button_in(context_rail, "Draw Shape", show_rail_shape_menu)
	rail_guide_new_button = button_in(context_rail, "Buat guide", func(): show_guide_type_menu(rail_guide_new_button))
	guide_type_menu = PopupMenu.new()
	for index in guide_type_items().size():
		guide_type_menu.add_item(Localization.translate(guide_type_items()[index]), index)
	guide_type_menu.set_meta("locale_items", guide_type_items())
	guide_type_menu.id_pressed.connect(select_guide_type)
	root.add_child(guide_type_menu)
	rail_select_mode_button = button_in(context_rail, "Pilih V", show_rail_select_mode)
	rail_mode_move_button = button_in(context_rail, "Geser", set_rail_transform_mode.bind("move"))
	rail_mode_rotate_button = button_in(context_rail, "Putar", set_rail_transform_mode.bind("rotate"))
	rail_mode_scale_button = button_in(context_rail, "Skala", set_rail_transform_mode.bind("scale"))
	rail_mode_move_button.toggle_mode = true
	rail_mode_rotate_button.toggle_mode = true
	rail_mode_scale_button.toggle_mode = true
	rail_select_group_button = button_in(context_rail, "Pilih grup aktif", func(): select_group(active_group))
	rail_select_all_button = button_in(context_rail, "Pilih semua", select_all_visible)
	rail_select_clear_button = button_in(context_rail, "Kosongkan pilihan", deselect_all)
	rail_select_duplicate_button = button_in(context_rail, "Duplikat", duplicate_selected)
	rail_select_mirror_button = button_in(context_rail, "Mirror seleksi", mirror_selected)
	rail_select_delete_button = button_in(context_rail, "Hapus pilihan", delete_selected)
	rail_erase_radius_button = button_in(context_rail, "Radius eraser", func(): show_synced_popup(rail_erase_radius_popup, rail_erase_radius_button, eraser.radius))
	rail_erase_radius_popup = build_compact_value_popup("Radius eraser", 4.0, 100.0, 1.0, eraser.radius, func(value: float):
		set_eraser_radius(value)
	, func(value: float): return ": %d px" % roundi(value))
	for rail_button in [rail_guide_save_button, rail_guide_close_button, rail_guide_face_button, rail_guide_delete_button, rail_guide_transform_button, rail_guide_rot_button, rail_vertex_button, rail_edge_button, rail_face_button, rail_extrude_button, rail_draw_brush_button, rail_draw_props_button, rail_draw_taper_button, rail_draw_shape_button, rail_guide_new_button, rail_select_mode_button, rail_select_group_button, rail_select_all_button, rail_select_clear_button, rail_mode_move_button, rail_mode_rotate_button, rail_mode_scale_button, rail_select_duplicate_button, rail_select_mirror_button, rail_select_delete_button, rail_erase_radius_button]:
		rail_button.custom_minimum_size = Vector2(48, 48)
		rail_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		rail_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rail_button.expand_icon = false
		rail_button.add_theme_constant_override("icon_max_width", 24)
		rail_button.text = ""
		rail_button.set_meta("icon_button", true)
	refresh_rail_draw_icons()
	# Right rail: Feather-style 2D joystick pad, only while toggled.
	pad_rail = VBoxContainer.new()
	root.add_child(pad_rail)
	pad_rail.add_theme_constant_override("separation", 8)
	pad_stick = PadJoystick.new()
	pad_stick.setup(self)
	pad_rail.add_child(pad_stick)
	layout_context_rail()
	refresh_context_rail()
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
	for compact_button in [compact_draw_button, compact_nav_button, compact_select_button, compact_erase_button, compact_cursor_button]:
		compact_button.toggle_mode = true
	compact_draw_button.button_pressed = true
	mirror_menu = PopupMenu.new()
	mirror_menu.add_check_item("Sumbu X", 0)
	mirror_menu.add_check_item("Sumbu Y", 1)
	mirror_menu.add_check_item("Sumbu Z", 2)
	mirror_menu.id_pressed.connect(toggle_mirror_axis)
	root.add_child(mirror_menu)
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
	var brush_tool_items := ["Pena", "Pensil tekstur", "Kuas tekstur", "Spidol datar", "Pena pipih", "Tube 3D (lama)", "Lasso Fill", "Rectangle Fill"]
	for item in brush_tool_items:
		brush_tool_menu.add_check_item(Localization.translate(item))
	brush_tool_menu.set_meta("locale_items", brush_tool_items)
	brush_tool_menu.id_pressed.connect(select_brush_tool)
	root.add_child(brush_tool_menu)
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
	var reset_camera_button := button_in(view_controls, "Reset kamera", reset_view)
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

func guide_type_items() -> Array:
	return ["Draw: profil bebas", "Poligonal: klik titik", "Bend: gambar arah baru", "Cube", "Tube"]

func guide_type_icons() -> Array:
	return ["profile", "polyline", "bend", "cube", "tube"]

func refresh_guide_type_menu() -> void:
	refresh_popup_language(guide_type_menu)
	var has_active := guides != null and guides.current() != null
	var bend_index := guide_type_kinds().find("bend")
	for index in guide_type_menu.item_count:
		guide_type_menu.set_item_icon(index, Icons.texture(guide_type_icons()[index], 1.0))
		# Bend needs a guide to reshape; the rest need a free slot.
		guide_type_menu.set_item_disabled(index, (not has_active) if index == bend_index else has_active)

func show_guide_type_menu(source: Control) -> void:
	refresh_guide_type_menu()
	guide_type_menu.position = Vector2i(source.global_position + Vector2(source.size.x + 6, 0))
	guide_type_menu.popup()

func guide_type_kinds() -> Array:
	return ["profile", "polyline", "bend", "cube", "tube"]

func start_guide_kind(kind: String) -> void:
	match kind:
		"profile":
			guides.start_profile()
		"polyline":
			guides.start_polyline()
		"bend":
			guides.start_bend()
		"cube":
			guides.start_cube()
		"tube":
			guides.start_tube()
		_:
			guides.start_profile()

func toggle_guide_create() -> void:
	# Top icon only toggles: cancel while placing, else start the default
	# (plane) or the last type picked from the rail, no popup, no hold.
	if guides.placing:
		guides.cancel_placing()
	else:
		start_guide_kind(last_guide_type)
	refresh_context_rail()

func refresh_top_guide_icon() -> void:
	if compact_guide_button == null:
		return
	var icons := {"plane": "plane", "quick": "quick_plane", "profile": "profile", "polyline": "polyline", "curve": "curve", "bend": "bend", "cube": "cube", "tube": "tube", "line": "line"}
	compact_guide_button.text = ""
	compact_guide_button.icon = Icons.texture(icons.get(last_guide_type, "plane"))
	compact_guide_button.set_pressed_no_signal(guides != null and guides.placing)

func select_guide_type(id: int) -> void:
	var kinds := guide_type_kinds()
	if id < 0 or id >= kinds.size():
		return
	# Rail choice both starts the mode and becomes the remembered default.
	last_guide_type = kinds[id]
	start_guide_kind(last_guide_type)
	refresh_top_guide_icon()

func brush_kind_index() -> int:
	var kinds := ["pen", "pencil", "brush", "marker", "flat", "tube", "lasso_fill", "rectangle_fill"]
	return maxi(0, kinds.find(brush_kind))

func refresh_brush_menu_checks() -> void:
	for index in brush_tool_menu.item_count:
		brush_tool_menu.set_item_checked(index, index == brush_kind_index())

func refresh_shape_menu_checks() -> void:
	var modes := ["off", "auto"]
	for index in compact_shape_menu.item_count:
		compact_shape_menu.set_item_checked(index, shape_assist.mode == modes[index])

func sync_rail_props() -> void:
	rail_props_color.color = ink
	rail_props_radius_slider.set_value_no_signal(brush_radius)
	rail_props_radius_label.text = Localization.translate("Radius") + "  %.3f" % brush_radius
	rail_props_opacity_slider.set_value_no_signal(brush_opacity)
	rail_props_opacity_label.text = Localization.translate("Opacity brush") + ": %d%%" % roundi(brush_opacity * 100.0)

func show_rail_props_menu() -> void:
	sync_rail_props()
	rail_props_popup.position = Vector2i(rail_draw_props_button.global_position + Vector2(rail_draw_props_button.size.x + 6, 0))
	rail_props_popup.popup()

func show_rail_brush_menu() -> void:
	refresh_popup_language(brush_tool_menu)
	refresh_brush_menu_checks()
	brush_tool_menu.position = Vector2i(rail_draw_brush_button.global_position + Vector2(rail_draw_brush_button.size.x + 6, 0))
	brush_tool_menu.popup()

func show_rail_shape_menu() -> void:
	refresh_popup_language(compact_shape_menu)
	refresh_shape_menu_checks()
	compact_shape_menu.position = Vector2i(rail_draw_shape_button.global_position + Vector2(rail_draw_shape_button.size.x + 6, 0))
	compact_shape_menu.popup()

func show_rail_rotate_menu() -> void:
	refresh_popup_language(rail_rotate_menu)
	for index in rail_rotate_menu.item_count:
		rail_rotate_menu.set_item_icon(index, Icons.texture(["axis_X+", "axis_Y+", "axis_Z+"][index], 1.0))
	rail_rotate_menu.position = Vector2i(rail_guide_rot_button.global_position + Vector2(rail_guide_rot_button.size.x + 6, 0))
	rail_rotate_menu.popup()

func select_rail_rotate_axis(id: int) -> void:
	var axes := [Vector3.RIGHT, Vector3.UP, Vector3.BACK]
	if id < 0 or id >= axes.size():
		return
	transform_guide(Vector3.ZERO, 90.0, 1.0, axes[id])

func show_rail_select_mode() -> void:
	refresh_popup_language(select_mode_menu)
	for id in 3:
		select_mode_menu.set_item_checked(id, ["tap", "rectangle", "lasso"][id] == selection_mode)
	select_mode_menu.position = Vector2i(rail_select_mode_button.global_position + Vector2(rail_select_mode_button.size.x + 6, 0))
	select_mode_menu.popup()

func select_brush_tool(id: int) -> void:
	var kinds := ["pen", "pencil", "brush", "marker", "flat", "tube", "lasso_fill", "rectangle_fill"]
	if id < 0 or id >= kinds.size():
		return
	brush_kind = kinds[id]
	set_tool("draw")
	refresh_nib_ui()
	refresh_rail_draw_icons()
	status.text = Localization.translate("Brush") + ": " + Localization.translate(["Pena", "Pensil tekstur", "Kuas tekstur", "Spidol datar", "Pena pipih", "Tube 3D (lama)", "Lasso Fill", "Rectangle Fill"][id])

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
		"sequence": sequence.duplicate(true), "environment": env_settings.duplicate(true)}

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
	# Mutations always mark dirty; the O(document) encode only runs where an
	# honest answer is required (undo/redo/open), never per input tick.
	dirty = true
	doc_revision += 1
	update_status()

func sync_dirty() -> void:
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
	apply_environment(data.get("environment", Store.default_environment()))
	selected_guide_vertices.clear()
	selected_guide_edges.clear()
	selected_guide_faces.clear()
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

func select_all_visible() -> void:
	finish_stroke()
	clear_selection()
	for stroke in strokes:
		if stroke.visible and is_instance_valid(stroke):
			selected_strokes.append(stroke)
			stroke.set_selected(true)
	selected = selected_strokes.back() if not selected_strokes.is_empty() else null
	update_status()

func deselect_all() -> void:
	finish_stroke()
	clear_selection()
	update_status()

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
	elif vertex_edit and tool == "select":
		# Sub-object mode is modal: taps only touch guide parts, never ink.
		var surface: MeshInstance3D = guides.current()
		if surface == null:
			clear_vertex_selection()
			return
		if mesh_select_mode == "edge":
			var picked_edge := pick_guide_edge(screen)
			if picked_edge.x < 0:
				clear_vertex_selection()
				return
			if selected_guide_edges.has(picked_edge):
				selected_guide_edges.erase(picked_edge)
			else:
				selected_guide_edges.append(picked_edge)
		elif mesh_select_mode == "face":
			var picked_face := pick_guide_face(screen)
			if picked_face < 0:
				clear_vertex_selection()
				return
			if selected_guide_faces.has(picked_face):
				selected_guide_faces.erase(picked_face)
			else:
				selected_guide_faces.append(picked_face)
		else:
			var picked := pick_guide_vertex(screen)
			if picked < 0:
				clear_vertex_selection()
				return
			if selected_guide_vertices.has(picked):
				selected_guide_vertices.erase(picked)
			else:
				selected_guide_vertices.append(picked)
		push_subobj_selection()
		update_status()
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
	if strokes.size() + selected_strokes.size() > 10000 or sample_count() + total_points(selected_strokes) > Store.MAX_POINTS:
		status.text = Localization.translate("Batas ukuran proyek tercapai. Hapus goresan sebelum menduplikasi.")
		return
	checkpoint()
	var copies: Array[MeshInstance3D] = []
	for source in selected_strokes:
		if not bool(group_data(source.group_id).visible):
			continue
		var copy := Stroke.new()
		copy.restore(source.serialize())
		# Duplicates stay exactly in place; the new copies end up selected.
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

func mirror_selected() -> void:
	finish_stroke()
	if selected_strokes.is_empty():
		return
	var axes := []
	if mirror_axes["x"]:
		axes.append(Vector3.RIGHT)
	if mirror_axes["y"]:
		axes.append(Vector3.UP)
	if mirror_axes["z"]:
		axes.append(Vector3.BACK)
	if axes.is_empty():
		status.text = Localization.translate("Aktifkan sumbu Mirror dulu.")
		return
	checkpoint()
	var reflection := Vector3.ONE
	for axis in axes:
		reflection -= axis * 2.0
	for stroke in selected_strokes:
		if not is_instance_valid(stroke):
			continue
		for i in stroke.points.size():
			stroke.points[i] = cursor_pos + (stroke.points[i] - cursor_pos) * reflection
		stroke.plane_normal = (stroke.plane_normal * reflection).normalized()
		for i in stroke.sample_normals.size():
			stroke.sample_normals[i] = (stroke.sample_normals[i] * reflection).normalized()
		stroke.rebuild()
	changed()
	status.text = Localization.translate("Seleksi dicerminkan.")

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
	for stroke in strokes:
		if (selected_only and selected_strokes.has(stroke)) or (not selected_only and stroke.group_id == active_group):
			members.append(stroke)
	if members.is_empty():
		return
	# Rotate/scale pivot is the 3D cursor, like mirror. Pure moves are unaffected.
	var center := cursor_pos
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

func transform_guide(offset: Vector3, angle: float = 0.0, factor: float = 1.0, rotation_axis: Vector3 = Vector3.ZERO, record_history: bool = true) -> void:
	# Move/rotate/scale the ACTIVE guide (fresh or loaded from storage).
	# Ink is intentionally left in place: strokes are not linked to guides.
	# Rotate/scale pivot is the 3D cursor, like mirror and ink.
	finish_stroke()
	var surface: MeshInstance3D = guides.current()
	if surface == null:
		return
	var center := cursor_pos
	var axis: Vector3 = rotation_axis if rotation_axis.length_squared() > 0.01 else camera.basis.z
	var rotation_basis := Basis(axis.normalized(), deg_to_rad(angle))
	var source: PackedVector3Array = surface.corners if surface.kind == "plane" else surface.vertices
	var moved: Array[Vector3] = []
	for point in source:
		var result: Vector3 = center + rotation_basis * ((point - center) * factor) + offset
		if not result.is_finite() or maxf(absf(result.x), maxf(absf(result.y), absf(result.z))) > 100000:
			return
		moved.append(result)
	if surface.kind == "mesh":
		var candidate: Dictionary = surface.serialize()
		var encoded := []
		for point in moved:
			encoded.append([point.x, point.y, point.z])
		candidate["vertices"] = encoded
		if not Store.validate_mesh(candidate).is_empty():
			return
	else:
		var u := moved[1] - moved[0]
		var v := moved[3] - moved[0]
		if u.length() < 0.049 or v.length() < 0.049:
			return
	if record_history:
		checkpoint()
	surface.apply_transform(center, rotation_basis, factor, offset)
	changed()

func transform_guide_vertices(offset: Vector3, angle: float = 0.0, factor: float = 1.0, rotation_axis: Vector3 = Vector3.ZERO, record_history: bool = true, live: bool = false) -> void:
	# Move/rotate/scale a subset of the active guide's vertices about their
	# own center. Stays inside the grid topology, so the file format is untouched.
	# Live drag ticks skip validation, history, and highlight rebuilds; the
	# matching finish_vertex_drag() call validates and finalizes instead.
	finish_stroke()
	if not vertex_edit:
		return
	var surface: MeshInstance3D = guides.current()
	if surface == null:
		return
	var points: PackedVector3Array = surface.corners if surface.kind == "plane" else surface.vertices
	var indices: Array[int] = []
	var center := Vector3.ZERO
	for i in selected_mesh_indices():
		var idx := int(i)
		if idx < 0 or idx >= points.size():
			continue
		indices.append(idx)
		center += points[idx]
	if indices.is_empty():
		return
	center /= float(indices.size())
	var axis: Vector3 = rotation_axis if rotation_axis.length_squared() > 0.01 else camera.basis.z
	var rotation_basis := Basis(axis.normalized(), deg_to_rad(angle))
	var moved: PackedVector3Array = points.duplicate()
	for idx in indices:
		var result: Vector3 = center + rotation_basis * ((points[idx] - center) * factor) + offset
		if not result.is_finite() or maxf(absf(result.x), maxf(absf(result.y), absf(result.z))) > 100000:
			return
		moved[idx] = result
	if live:
		vertex_drag_live = true
		if surface.kind == "plane":
			surface.kind = "mesh"
			surface.columns = 2
			surface.rows = 2
			surface.corners = PackedVector3Array()
		surface.vertices = moved
		surface.rebuild_mesh()
		surface.rebuild_face_overlay(surface.vertices)
		return
	# A plane cannot bend one corner and stay a rectangle (format rule), so
	# the first vertex edit promotes it to an equivalent 2x2 mesh.
	var candidate: Dictionary = surface.serialize()
	var encoded := []
	for point in moved:
		encoded.append([point.x, point.y, point.z])
	candidate["kind"] = "mesh"
	candidate["vertices"] = encoded
	if surface.kind == "plane":
		candidate["columns"] = 2
		candidate["rows"] = 2
	candidate.erase("corners")
	if not Store.validate_mesh(candidate).is_empty():
		return
	if record_history:
		checkpoint()
	if surface.kind == "plane":
		surface.kind = "mesh"
		surface.columns = 2
		surface.rows = 2
		surface.corners = PackedVector3Array()
	surface.vertices = moved
	surface.rebuild()
	changed()

func finish_vertex_drag() -> void:
	# End of a live vertex drag: validate once, rebuild highlights, or roll
	# back to the drag-start checkpoint when the result is degenerate.
	if not vertex_drag_live:
		return
	vertex_drag_live = false
	var surface: MeshInstance3D = guides.current() if guides != null else null
	if surface == null or surface.kind != "mesh":
		return
	if not Store.validate_mesh(surface.serialize()).is_empty():
		undo()
	else:
		surface.rebuild_grid_lines()

func set_vertex_edit(value: bool) -> void:
	vertex_drag_live = false
	vertex_edit = value
	if value:
		finish_stroke()
		clear_selection()
	else:
		clear_vertex_selection()
	update_status()

func clear_vertex_selection() -> void:
	selected_guide_vertices.clear()
	selected_guide_edges.clear()
	selected_guide_faces.clear()
	push_subobj_selection()
	update_status()

func push_subobj_selection() -> void:
	if guides == null:
		return
	var surface: MeshInstance3D = guides.current()
	if surface == null or not is_instance_valid(surface):
		return
	if camera != null:
		var to_cam: Vector3 = camera.global_position - surface.center()
		surface.highlight_offset = to_cam.normalized() * 0.004 if to_cam.length() > 0.001 else Vector3.ZERO
	surface.set_subobj_selection(selected_guide_vertices, selected_guide_edges, selected_guide_faces)

func selected_mesh_indices() -> Array[int]:
	# Union of every selected sub-object part as mesh/corner indices.
	var out: Array[int] = []
	var surface: MeshInstance3D = guides.current() if guides != null else null
	for i in selected_guide_vertices:
		_add_mesh_index(out, int(i))
	for e in selected_guide_edges:
		var pair := Vector2i(e)
		_add_mesh_index(out, pair.x)
		_add_mesh_index(out, pair.y)
	if surface != null and surface.kind == "mesh":
		for f in selected_guide_faces:
			var base := int(f)
			if base >= 0 and base + 2 < surface.index_cache.size():
				_add_mesh_index(out, surface.index_cache[base])
				_add_mesh_index(out, surface.index_cache[base + 1])
				_add_mesh_index(out, surface.index_cache[base + 2])
	else:
		for f in selected_guide_faces:
			for idx in ([0, 1, 2] if int(f) == 0 else [0, 2, 3]):
				_add_mesh_index(out, idx)
	var count := 0
	if surface != null:
		count = surface.vertices.size() if surface.kind == "mesh" else 4
	var clean: Array[int] = []
	for idx in out:
		if idx >= 0 and idx < count and not clean.has(idx):
			clean.append(idx)
	return clean

func _add_mesh_index(out: Array[int], idx: int) -> void:
	if not out.has(idx):
		out.append(idx)

func toggle_mesh_mode(mode: String) -> void:
	# Rail radio: pressing the active mode turns sub-object editing off.
	if vertex_edit and mesh_select_mode == mode:
		set_vertex_edit(false)
	else:
		set_mesh_select_mode(mode)

func set_mesh_select_mode(mode: String) -> void:
	if mode not in ["vertex", "edge", "face"]:
		return
	mesh_select_mode = mode
	if not vertex_edit:
		set_vertex_edit(true)
	else:
		clear_vertex_selection()
	if guides != null:
		guides.refresh()
	update_status()

func pick_guide_vertex(screen: Vector2) -> int:
	var surface: MeshInstance3D = guides.current()
	if surface == null or not surface.visible:
		return -1
	var result: Array = surface.intersect_ray_full(camera.project_ray_origin(screen), camera.project_ray_normal(screen))
	if result[0] == null:
		return -1
	var candidates: Array[int] = []
	if surface.kind == "plane":
		candidates.assign([0, 1, 2] if int(result[1]) == 0 else [0, 2, 3])
	else:
		var base := int(result[1])
		candidates.assign([surface.index_cache[base], surface.index_cache[base + 1], surface.index_cache[base + 2]])
	var points: PackedVector3Array = surface.corners if surface.kind == "plane" else surface.vertices
	var best := -1
	var best_px := 28.0
	for i in candidates:
		var idx := int(i)
		if idx < 0 or idx >= points.size():
			continue
		var distance_px: float = camera.unproject_position(points[idx]).distance_to(screen)
		if distance_px < best_px:
			best_px = distance_px
			best = idx
	return best

func _screen_segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	var span := b - a
	var length_squared := span.length_squared()
	if length_squared < 0.000001:
		return point.distance_to(a)
	var amount := clampf((point - a).dot(span) / length_squared, 0.0, 1.0)
	return point.distance_to(a + span * amount)

func pick_guide_edge(screen: Vector2) -> Vector2i:
	var miss := Vector2i(-1, -1)
	var surface: MeshInstance3D = guides.current()
	if surface == null or not surface.visible:
		return miss
	var result: Array = surface.intersect_ray_full(camera.project_ray_origin(screen), camera.project_ray_normal(screen))
	if result[0] == null:
		return miss
	var points: PackedVector3Array = surface.corners if surface.kind == "plane" else surface.vertices
	var trio: Array[int] = []
	if surface.kind == "mesh":
		var base := int(result[1])
		if base < 0 or base + 2 >= surface.index_cache.size():
			return miss
		trio.assign([surface.index_cache[base], surface.index_cache[base + 1], surface.index_cache[base + 2]])
	else:
		trio.assign([0, 1, 2] if int(result[1]) == 0 else [0, 2, 3])
	var best := miss
	var best_px := 16.0
	for pair in [[trio[0], trio[1]], [trio[1], trio[2]], [trio[2], trio[0]]]:
		var a := int(pair[0])
		var b := int(pair[1])
		if a < 0 or b < 0 or a >= points.size() or b >= points.size():
			continue
		var distance_px := _screen_segment_distance(screen, camera.unproject_position(points[a]), camera.unproject_position(points[b]))
		if distance_px < best_px:
			best_px = distance_px
			best = Vector2i(mini(a, b), maxi(a, b))
	return best

func pick_guide_face(screen: Vector2) -> int:
	var surface: MeshInstance3D = guides.current()
	if surface == null or not surface.visible:
		return -1
	var result: Array = surface.intersect_ray_full(camera.project_ray_origin(screen), camera.project_ray_normal(screen))
	if result[0] == null:
		return -1
	return int(result[1])

func _boundary_target() -> Array:
	# ["row", index] or ["col", index] when the selected edges cover one
	# full boundary row/column of the active mesh (plane counts as 2x2).
	var surface: MeshInstance3D = guides.current()
	if surface == null:
		return []
	var columns := 2
	var rows := 2
	if surface.kind == "mesh":
		columns = surface.columns
		rows = surface.rows
	elif surface.kind != "plane":
		return []
	var edge_set := {}
	for e in selected_guide_edges:
		edge_set[Vector2i(e)] = true
	for r in [0, rows - 1]:
		var full := true
		for c in range(columns - 1):
			if not edge_set.has(Vector2i(r * columns + c, r * columns + c + 1)):
				full = false
				break
		if full:
			return ["row", r]
	for c in [0, columns - 1]:
		var full_col := true
		for r in range(rows - 1):
			if not edge_set.has(Vector2i(r * columns + c, (r + 1) * columns + c)):
				full_col = false
				break
		if full_col:
			return ["col", c]
	return []

func can_extrude() -> bool:
	return not _boundary_target().is_empty()

func extrude_mesh_boundary() -> void:
	# Grow the grid by one row/column from a fully selected boundary edge.
	# The new strip continues the sweep direction by one edge-length step.
	finish_stroke()
	if not vertex_edit:
		return
	var surface: MeshInstance3D = guides.current()
	if surface == null or not surface.visible:
		return
	var target := _boundary_target()
	if target.is_empty():
		status.text = Localization.translate("Pilih satu baris tepi penuh untuk Extrude.")
		return
	if surface.kind == "plane":
		checkpoint()
		surface.kind = "mesh"
		surface.columns = 2
		surface.rows = 2
		surface.vertices = surface.corners.duplicate()
		surface.corners = PackedVector3Array()
		surface.rebuild()
	var columns: int = surface.columns
	var rows: int = surface.rows
	var points: PackedVector3Array = surface.vertices
	var boundary: PackedVector3Array = PackedVector3Array()
	var neighbor: PackedVector3Array = PackedVector3Array()
	if String(target[0]) == "row":
		var r := int(target[1])
		var n := r - 1 if r == rows - 1 else r + 1
		for c in range(columns):
			boundary.append(points[r * columns + c])
			neighbor.append(points[n * columns + c])
	else:
		var c := int(target[1])
		var n2 := c - 1 if c == columns - 1 else c + 1
		for r in range(rows):
			boundary.append(points[r * columns + c])
			neighbor.append(points[r * columns + n2])
	var spread := 0.0
	for a in boundary:
		for b in boundary:
			spread = maxf(spread, a.distance_to(b))
	if spread < 0.001:
		return
	var direction := Vector3.ZERO
	var step := 0.0
	for i in boundary.size():
		direction += boundary[i] - neighbor[i]
		if i > 0:
			step += boundary[i - 1].distance_to(boundary[i])
	if direction.length() < 0.000001:
		return
	step = maxf(0.05, step / maxf(1.0, float(boundary.size() - 1)))
	var grown: PackedVector3Array = PackedVector3Array()
	var push: Vector3 = direction.normalized() * step
	for point in boundary:
		grown.append(point + push)
	var grown_vertices := PackedVector3Array()
	var grown_columns := columns
	var grown_rows := rows
	if String(target[0]) == "row":
		if rows + 1 > 64:
			return
		grown_rows = rows + 1
		if int(target[1]) == 0:
			grown_vertices.append_array(grown)
			grown_vertices.append_array(points)
		else:
			grown_vertices.append_array(points)
			grown_vertices.append_array(grown)
	else:
		if columns + 1 > 256:
			return
		grown_columns = columns + 1
		var at_end := int(target[1]) == columns - 1
		for r in range(rows):
			if not at_end:
				grown_vertices.append(grown[r])
			for c in range(columns):
				grown_vertices.append(points[r * columns + c])
			if at_end:
				grown_vertices.append(grown[r])
	var candidate: Dictionary = surface.serialize()
	var encoded := []
	for point in grown_vertices:
		encoded.append([point.x, point.y, point.z])
	candidate["vertices"] = encoded
	candidate["columns"] = grown_columns
	candidate["rows"] = grown_rows
	if not Store.validate_mesh(candidate).is_empty():
		return
	checkpoint()
	surface.columns = grown_columns
	surface.rows = grown_rows
	surface.vertices = grown_vertices
	selected_guide_vertices.clear()
	selected_guide_edges.clear()
	selected_guide_faces.clear()
	surface.rebuild()
	push_subobj_selection()
	changed()
	status.text = Localization.translate("Tepi diekstrusi.")
	if guides != null:
		guides.refresh()

func move_cursor(offset: Vector3) -> void:
	# Session-only nudge of the 3D cursor: no history, no document change.
	cursor_pos += offset
	update_cursor_gizmo()
	update_status()

func env_toggle_in(parent: Node, text: String, key: String) -> Button:
	var toggle := button_in(parent, text, func(): pass)
	toggle.toggle_mode = true
	toggle.set_pressed_no_signal(bool(env_settings.get(key, false)))
	toggle.toggled.connect(func(value: bool): env_set_toggle(key, value))
	return toggle

func env_slider_in(column: VBoxContainer, text: String, initial: float, minimum: float, maximum: float, step: float, apply: Callable) -> Array:
	var slider_label := label_in(column, text, 14)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = initial
	slider.custom_minimum_size.y = 32
	slider.drag_started.connect(env_begin_slider)
	slider.drag_ended.connect(env_end_slider)
	slider.value_changed.connect(apply)
	column.add_child(slider)
	return [slider, slider_label]

func align_sun_to_view() -> void:
	checkpoint()
	sun.global_transform = Transform3D(camera.global_transform.basis, sun.global_position)
	env_settings["light_alt"] = -sun.rotation_degrees.x
	env_settings["light_az"] = fposmod(sun.rotation_degrees.y + 180.0, 360.0) - 180.0
	apply_light()
	refresh_env_ui()
	changed()

func build_environment_panel(column: VBoxContainer) -> void:
	column.add_child(HSeparator.new())
	label_in(column, "ENVIRONMENT", 13).modulate = Color("8da4b1")
	var overlay_row := HBoxContainer.new()
	column.add_child(overlay_row)
	env_axis_button = env_toggle_in(overlay_row, "Sumbu global", "axis")
	env_grid_button = env_toggle_in(overlay_row, "Grid", "grid")
	env_grid_button.set_pressed_no_signal(bool(env_settings.get("grid", true)))
	var world_row := HBoxContainer.new()
	column.add_child(world_row)
	env_fog_button = env_toggle_in(world_row, "Fog", "fog")
	env_shadow_button = env_toggle_in(world_row, "Bayangan", "shadow")
	label_in(column, "Warna background", 14)
	env_bg_color = ColorPickerButton.new()
	env_bg_color.color = env_color("bg_color")
	env_bg_color.edit_alpha = false
	env_bg_color.custom_minimum_size.y = 40
	env_bg_color.color_changed.connect(func(value: Color):
		env_settings["bg_color"] = [value.r, value.g, value.b]
		apply_background()
		changed())
	env_bg_color.get_popup().about_to_popup.connect(func(): checkpoint())
	column.add_child(env_bg_color)
	var image_row := HBoxContainer.new()
	column.add_child(image_row)
	button_in(image_row, "Gambar latar...", func(): bg_dialog.popup_centered_ratio(0.75))
	button_in(image_row, "Hapus gambar", clear_bg_image)
	var light_parts := env_slider_in(column, "Ketinggian cahaya", float(env_settings.get("light_alt", 35.0)), -90.0, 90.0, 1.0, func(value: float):
		env_settings["light_alt"] = value
		apply_light()
		env_light_alt_label.text = Localization.translate("Ketinggian cahaya") + ": %d°" % roundi(value))
	env_light_alt_slider = light_parts[0]
	env_light_alt_label = light_parts[1]
	env_light_alt_label.text = Localization.translate("Ketinggian cahaya") + ": %d°" % roundi(float(env_settings.get("light_alt", 35.0)))
	var az_parts := env_slider_in(column, "Arah cahaya", float(env_settings.get("light_az", -25.0)), -180.0, 180.0, 1.0, func(value: float):
		env_settings["light_az"] = value
		apply_light()
		env_light_az_label.text = Localization.translate("Arah cahaya") + ": %d°" % roundi(value))
	env_light_az_slider = az_parts[0]
	env_light_az_label = az_parts[1]
	env_light_az_label.text = Localization.translate("Arah cahaya") + ": %d°" % roundi(float(env_settings.get("light_az", -25.0)))
	button_in(column, "Sejajarkan tampilan", align_sun_to_view)
	label_in(column, "Warna cahaya", 14)
	env_light_color = ColorPickerButton.new()
	env_light_color.color = env_color("light_color")
	env_light_color.edit_alpha = false
	env_light_color.custom_minimum_size.y = 40
	env_light_color.color_changed.connect(func(value: Color):
		env_settings["light_color"] = [value.r, value.g, value.b]
		apply_light()
		changed())
	env_light_color.get_popup().about_to_popup.connect(func(): checkpoint())
	column.add_child(env_light_color)
	var energy_parts := env_slider_in(column, "Kekuatan cahaya", float(env_settings.get("light_energy", 1.0)), 0.0, 2.0, 0.05, func(value: float):
		env_settings["light_energy"] = value
		apply_light()
		env_light_energy_label.text = Localization.translate("Kekuatan cahaya") + ": %d%%" % roundi(value * 100.0))
	env_light_energy_slider = energy_parts[0]
	env_light_energy_label = energy_parts[1]
	env_light_energy_label.text = Localization.translate("Kekuatan cahaya") + ": %d%%" % roundi(float(env_settings.get("light_energy", 1.0)) * 100.0)
	var glow_row := HBoxContainer.new()
	column.add_child(glow_row)
	env_glow_button = env_toggle_in(glow_row, "Glow", "glow")
	var glow_parts := env_slider_in(column, "Kekuatan glow", float(env_settings.get("glow_amount", 0.8)), 0.0, 2.0, 0.05, func(value: float):
		env_settings["glow_amount"] = value
		apply_glow())
	env_glow_slider = glow_parts[0]
	var grain_row := HBoxContainer.new()
	column.add_child(grain_row)
	env_grain_button = env_toggle_in(grain_row, "Grain", "grain")
	var grain_parts := env_slider_in(column, "Kekuatan grain", float(env_settings.get("grain_amount", 0.3)), 0.0, 1.0, 0.05, func(value: float):
		env_settings["grain_amount"] = value
		apply_grain())
	env_grain_slider = grain_parts[0]
	var pixel_row := HBoxContainer.new()
	column.add_child(pixel_row)
	env_pixel_button = button_in(pixel_row, "Pixelasi", func(): pass)
	env_pixel_button.toggle_mode = true
	env_pixel_button.set_pressed_no_signal(float(env_settings.get("pixel_scale", 1.0)) < 1.0)
	env_pixel_button.toggled.connect(func(value: bool):
		checkpoint()
		env_settings["pixel_scale"] = 0.5 if value else 1.0
		apply_pixel()
		env_pixel_slider.set_value_no_signal(float(env_settings.get("pixel_scale")))
		changed())
	var pixel_parts := env_slider_in(column, "Skala pixel", float(env_settings.get("pixel_scale", 1.0)), 0.25, 1.0, 0.05, func(value: float):
		env_settings["pixel_scale"] = value
		apply_pixel()
		env_pixel_button.set_pressed_no_signal(value < 1.0))
	env_pixel_slider = pixel_parts[0]

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
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL if int(shot.projection) == 1 else Camera3D.PROJECTION_PERSPECTIVE
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
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL if (int(to.projection) if amount >= 0.5 else int(from.projection)) == 1 else Camera3D.PROJECTION_PERSPECTIVE
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

func rename_sequence_shot(id: int, new_name: String) -> void:
	var clean_name := new_name.strip_edges()
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
func set_rail_transform_mode(mode: String) -> void:
	transform_joystick.set_mode(mode)
	refresh_rail_transform_modes()

func refresh_rail_transform_modes() -> void:
	if rail_mode_move_button == null or transform_joystick == null:
		return
	rail_mode_move_button.set_pressed_no_signal(transform_joystick.mode == "move")
	rail_mode_rotate_button.set_pressed_no_signal(transform_joystick.mode == "rotate")
	rail_mode_scale_button.set_pressed_no_signal(transform_joystick.mode == "scale")
	# Rotate/scale are meaningless for the point cursor; disable instead of
	# silently ignoring so the gizmo state never surprises.
	var cursor_only: bool = transform_joystick.cursor_active()
	rail_mode_rotate_button.disabled = cursor_only
	rail_mode_scale_button.disabled = cursor_only
	var note := ""
	if cursor_only:
		note = " " + Localization.translate("Tidak berlaku untuk kursor 3D.")
	rail_mode_rotate_button.tooltip_text = Localization.translate("Gizmo putar mengelilingi sumbu.") + note
	rail_mode_scale_button.tooltip_text = Localization.translate("Gizmo skala seragam dari pusat.") + note

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
	bg_dialog = FileDialog.new()
	bg_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	bg_dialog.access = FileDialog.ACCESS_FILESYSTEM
	bg_dialog.filters = PackedStringArray(["*.png ; PNG image", "*.jpg,*.jpeg ; JPEG image"])
	if OS.has_feature("android"):
		bg_dialog.access = FileDialog.ACCESS_USERDATA
		bg_dialog.current_dir = "user://"
	bg_dialog.file_selected.connect(import_bg_image)
	add_child(bg_dialog)

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
	var original_context_rail_visible := context_rail.visible if context_rail != null else false
	var original_pad_rail_visible := pad_rail.visible if pad_rail != null else false
	view_controls.hide()
	compact_toolbar.hide()
	compact_finger_button.hide()
	compact_help_button.hide()
	sequence_overlay.hide()
	cursor_gizmo.hide()
	var original_axis_visible := axis_gizmo.visible
	axis_gizmo.hide()
	if context_rail != null:
		context_rail.hide()
	if pad_rail != null:
		pad_rail.hide()
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
	cursor_gizmo.visible = true
	axis_gizmo.visible = original_axis_visible
	if context_rail != null:
		context_rail.visible = original_context_rail_visible
	if pad_rail != null:
		pad_rail.visible = original_pad_rail_visible
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
	autosaved_revision = -1
	autosave_time = ""
	if not recovery and not result.recovered:
		clear_autosave()
	sync_dirty()
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
	if autosaved_revision == doc_revision:
		return true
	var result := Store.save_project(autosave_path, document())
	if result != OK:
		status.text = Localization.translate("Autosave failed: ") + error_string(result) + ". " + Localization.translate("Gunakan Simpan.")
		return false
	autosaved_revision = doc_revision
	autosave_time = Time.get_time_string_from_system()
	update_status()
	return true

func clear_autosave() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(autosave_path + suffix):
			DirAccess.remove_absolute(autosave_path + suffix)
	autosaved_revision = -1
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
