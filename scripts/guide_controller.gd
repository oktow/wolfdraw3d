extends RefCounted
const Localization = preload("res://scripts/localization.gd")
## Owns guide lifecycle and creation preview, separate from ink and camera.

const Surface = preload("res://scripts/guide_surface.gd")
var app: Node3D
var surfaces: Array[MeshInstance3D] = []
var active_id := -1
var placing := false
var preview: MeshInstance3D
var drag_origin := Vector2.ZERO
var creation_frame := Transform3D.IDENTITY
var creation_depth := 0.0
var opacity_before := -1.0
var opacity_checkpointed := false
var state_label: Label

var save_button: Button
var close_button: Button
var cancel_button: Button
var picker: OptionButton
var guide_name_field: LineEdit
var activate_button: Button
var visibility_button: Button
var opacity_slider: HSlider
var depth_slider: HSlider
var delete_button: Button
var depth_label: Label
var opacity_label: Label
var action_row: HBoxContainer
var face_button: Button
var subobj_row: HBoxContainer
var vertex_mode_button: Button
var edge_mode_button: Button
var face_mode_button: Button
var extrude_button: Button
var profile_button: Button
var poly_button: Button
var bend_button: Button
const POLY_IDLE_MS := 2000
var poly_last_msec := -1
var cube_button: Button
var tube_button: Button
var primitive_row: HBoxContainer
var length_slider: HSlider
var length_label: Label
var creation_mode := "plane"
var profile := PackedVector3Array()
var last_screen := Vector2.ZERO
var sweep_length := 4.0
var loft_tension := 0.5
var loft_tension_slider: HSlider
var loft_tension_label: Label

func start_profile() -> void:
	if current() != null:
		return
	start_placing()
	if placing:
		creation_mode = "profile"
		app.set_finger_drawing(true)
		refresh()

func start_plane_taps() -> void:
	if current() != null:
		return
	start_placing()
	if placing:
		creation_mode = "plane_taps"
		app.set_finger_drawing(true)
		refresh()

func start_polyline() -> void:
	if current() != null:
		return
	start_placing()
	if placing:
		creation_mode = "polyline"
		app.set_finger_drawing(true)
		refresh()

func start_curve() -> void:
	if current() != null:
		return
	start_placing()
	if placing:
		creation_mode = "curve"
		app.set_finger_drawing(true)
		refresh()

func simplify_profile(points: PackedVector3Array, limit: int) -> PackedVector3Array:
	while points.size() > limit:
		var least := INF
		var remove_index := 1
		for i in range(1, points.size() - 1):
			var error := points[i].distance_squared_to(Geometry3D.get_closest_point_to_segment(points[i], points[i - 1], points[i + 1]))
			if error < least:
				least = error
				remove_index = i
		points.remove_at(remove_index)
	return points

func smooth_chaikin(points: PackedVector3Array) -> PackedVector3Array:
	# Two Chaikin passes with fixed endpoints, capped for the mesh format.
	if points.size() < 3:
		return points
	var result := points
	for iteration in 2:
		var refined := PackedVector3Array([result[0]])
		for i in range(result.size() - 1):
			var a := result[i]
			var b := result[i + 1]
			refined.append(a.lerp(b, 0.25))
			refined.append(a.lerp(b, 0.75))
		refined.append(result[result.size() - 1])
		result = refined
	return simplify_profile(result, 256)

func start_cube() -> void:
	if current() != null:
		return
	start_placing()
	if placing:
		creation_mode = "cube"
		app.set_finger_drawing(true)
		refresh()

func start_tube() -> void:
	if current() != null:
		return
	start_placing()
	if placing:
		creation_mode = "tube"
		app.set_finger_drawing(true)
		refresh()

func start_bend() -> void:
	if current() == null:
		return
	app.finish_stroke()
	cancel_preview()
	creation_mode = "bend"
	placing = true
	app.set_tool("draw")
	app.set_finger_drawing(true)
	refresh()

func _init(app_node: Node3D) -> void:
	app = app_node

func current() -> MeshInstance3D:
	for surface in surfaces:
		if surface.guide_id == active_id:
			return surface
	return null

func picked() -> MeshInstance3D:
	if picker.selected < 0:
		return null
	var id := picker.get_selected_id()
	for surface in surfaces:
		if surface.guide_id == id:
			return surface
	return null

func ray_hit(screen: Vector2) -> Variant:
	var surface := current()
	if surface == null:
		return null
	return surface.intersect_ray(app.camera.project_ray_origin(screen), app.camera.project_ray_normal(screen))

func start_placing() -> void:
	app.finish_stroke()
	if current() != null:
		app.status.text = Localization.translate("Tutup atau simpan guide aktif sebelum membuat guide baru.")
		return
	if surfaces.size() >= 100:
		app.show_message(Localization.translate("Batas 100 guide tercapai."))
		return
	cancel_preview()
	creation_mode = "plane"
	placing = true
	app.set_tool("draw")
	refresh()

func plane_hit(screen: Vector2) -> Variant:
	var normal := creation_frame.basis.z
	var plane := Plane(normal, normal.dot(creation_frame.origin))
	return plane.intersects_ray(app.camera.project_ray_origin(screen), app.camera.project_ray_normal(screen))

func begin_preview(screen: Vector2) -> void:
	if not placing:
		return
	if creation_mode == "polyline" and preview != null:
		# Every click appends a vertex; release never commits (see finish_preview).
		var extra: Variant = plane_hit(screen)
		if extra == null or screen.distance_to(last_screen) < 3:
			return
		profile.append(extra)
		profile = simplify_profile(profile, 256)
		last_screen = screen
		poly_last_msec = Time.get_ticks_msec()
		preview.configure_profile(profile, -creation_frame.basis.z * sweep_length, true)
		preview.show()
		return
	if creation_mode == "plane_taps" and not profile.is_empty():
		commit_tap_corner(screen)
		return
	cancel_preview()
	creation_frame = Transform3D(app.camera.global_basis, app.cursor_pos + app.camera.global_basis.z * minf(creation_depth, app.distance - 0.5))
	var hit: Variant = plane_hit(screen)
	if hit == null:
		return
	var local: Vector3 = creation_frame.affine_inverse() * hit
	drag_origin = Vector2(local.x, local.y)
	profile = PackedVector3Array([hit])
	last_screen = screen
	preview = Surface.new()
	preview.title = "Pratinjau"
	app.add_child(preview)
	preview.hide()

func preview_rubber(screen: Vector2) -> void:
	# Mouse hover shows the pending polyline segment without adding a vertex.
	if preview == null or creation_mode != "polyline" or profile.is_empty():
		return
	var hit: Variant = plane_hit(screen)
	if hit == null:
		return
	var rubber := profile.duplicate()
	rubber.append(hit)
	preview.configure_profile(rubber, -creation_frame.basis.z * sweep_length, true)
	preview.show()

func extend_preview(screen: Vector2) -> void:
	if preview == null:
		return
	var hit: Variant = plane_hit(screen)
	if hit == null:
		return
	if creation_mode == "cube":
		var local_cube: Vector3 = creation_frame.affine_inverse() * hit
		var end_cube := Vector2(local_cube.x, local_cube.y)
		var drag_size := (end_cube - drag_origin).abs()
		var edge := maxf(drag_size.x, drag_size.y)
		if edge < 0.05:
			preview.hide()
			return
		var middle := (end_cube + drag_origin) / 2
		var cube_center: Vector3 = creation_frame * Vector3(middle.x, middle.y, 0)
		preview.configure_cube(cube_center, creation_frame.basis, edge)
		preview.show()
		return
	if creation_mode == "tube":
		if profile.is_empty():
			return
		# Touch point is the cap center; drag distance outward is the radius.
		var tube_radius: float = hit.distance_to(profile[0])
		if tube_radius < 0.05:
			preview.hide()
			return
		tube_radius = minf(tube_radius, 3.0)
		var tube_axis: Vector3 = -creation_frame.basis.z.normalized()
		preview.configure_tube(profile[0], tube_axis, tube_radius, sweep_length)
		preview.show()
		return
	if creation_mode != "plane" and creation_mode != "plane_taps":
		if screen.distance_to(last_screen) < 3:
			return
		profile.append(hit)
		# Preserve endpoints and the strongest corners when the sample cap is reached.
		profile = simplify_profile(profile, 64 if creation_mode == "bend" else 256)
		if creation_mode == "polyline":
			poly_last_msec = Time.get_ticks_msec()
		last_screen = screen
		if creation_mode == "bend":
			if current() == null:
				cancel_preview()
				return
			preview.configure_bend(current(), profile)
		else:
			var surface_profile := profile
			if creation_mode == "curve":
				surface_profile = smooth_chaikin(profile)
			preview.configure_profile(surface_profile, -creation_frame.basis.z * sweep_length, true)
		preview.show()
		return
	var local: Vector3 = creation_frame.affine_inverse() * hit
	var end := Vector2(local.x, local.y)
	var size := (end - drag_origin).abs()
	if minf(size.x, size.y) < 0.05:
		preview.hide()
		return
	var frame := creation_frame
	var middle := (end + drag_origin) / 2
	frame.origin = creation_frame * Vector3(middle.x, middle.y, 0)
	preview.configure(frame, size)
	preview.show()

func tick_polyline_idle() -> void:
	# No new vertices for a while: the polyline finishes itself.
	if not placing or creation_mode != "polyline" or poly_last_msec < 0:
		return
	if profile.size() >= 3 and Time.get_ticks_msec() - poly_last_msec >= POLY_IDLE_MS:
		poly_last_msec = -1
		finish_preview(true)

func finish_preview(force := false) -> void:
	app.shape_assist.finalize()
	if preview == null:
		return
	if creation_mode == "polyline" and not force:
		# Clicks only append vertices; commit via the Done button or double-tap.
		return
	if creation_mode == "polyline" and profile.size() < 3:
		# Two points make a straight edge whose extrusion ends up edge-on to
		# the viewer; a polygon needs at least three corners. Stay in mode.
		app.status.text = Localization.translate("Poligonal butuh minimal 3 titik.")
		return
	if creation_mode == "plane_taps" and not force:
		# Taps only set corners; the second tap commits through begin_preview.
		return
	if not preview.visible:
		if creation_mode == "polyline":
			app.status.text = Localization.translate("Tambahkan minimal dua titik.")
			cancel_placing()
		else:
			cancel_preview()
		return
	if preview.kind == "mesh":
		var candidate: Dictionary = preview.serialize()
		var issue: String = app.Store.validate_mesh(candidate)
		if not issue.is_empty():
			cancel_preview()
			app.status.text = issue + " " + Localization.translate("Coba garis dengan arah atau bentangan berbeda.")
			return
		var total: int = preview.vertices.size()
		for surface in surfaces:
			if surface.kind == "mesh" and not (creation_mode == "bend" and surface == current()):
				total += surface.vertices.size()
		if total > 200000:
			cancel_preview()
			app.show_message(Localization.translate("Batas 200.000 vertex guide tercapai."))
			return
	if creation_mode == "bend" and current() != null:
		app.checkpoint()
		var original: Dictionary = current().serialize()
		var bent: Dictionary = preview.serialize()
		for key in ["id", "name", "saved", "visible", "opacity"]:
			bent[key] = original[key]
		current().restore(bent)
		cancel_preview()
		placing = false
		refresh()
		app.changed()
		return
	app.checkpoint()
	var id := 0
	for surface in surfaces:
		id = maxi(id, surface.guide_id + 1)
	preview.guide_id = id
	preview.title = "Guide %d" % (id + 1)
	surfaces.append(preview)
	active_id = id
	preview = null
	placing = false
	refresh()
	app.changed()

func create_plane(frame: Transform3D, size: Vector2) -> void:
	# Shared by the full-size button and tests; same commit path as dragging.
	if current() != null or surfaces.size() >= 100 or minf(size.x, size.y) < 0.05:
		return
	app.finish_stroke()
	cancel_preview()
	creation_mode = "plane"
	preview = Surface.new()
	app.add_child(preview)
	preview.configure(frame, size)
	finish_preview()

func create_loft(profiles: Array[PackedVector3Array]) -> void:
	if profiles.size() < 2 or current() != null or surfaces.size() >= 100:
		return
	var column_count := 2
	for profile in profiles:
		column_count = maxi(column_count, mini(profile.size(), 256))
	if profiles.size() * column_count > 200000:
		app.show_message(Localization.translate("Batas 200.000 vertex guide tercapai."))
		return
	app.finish_stroke()
	cancel_preview()
	creation_mode = "loft"
	preview = Surface.new()
	app.add_child(preview)
	preview.configure_loft(profiles, loft_tension)
	finish_preview()

func primitive_frame() -> Transform3D:
	return Transform3D(app.camera.global_basis, app.cursor_pos + app.camera.global_basis.z * minf(creation_depth, app.distance - 0.5))

func create_cube() -> void:
	if current() != null or surfaces.size() >= 100:
		return
	app.finish_stroke()
	cancel_preview()
	creation_mode = "primitive"
	var frame := primitive_frame()
	preview = Surface.new()
	app.add_child(preview)
	preview.configure_cube(frame.origin, frame.basis, clampf(sweep_length * 0.5, 0.25, 6.0))
	finish_preview()

func create_tube() -> void:
	if current() != null or surfaces.size() >= 100:
		return
	app.finish_stroke()
	cancel_preview()
	creation_mode = "primitive"
	var frame := primitive_frame()
	preview = Surface.new()
	app.add_child(preview)
	preview.configure_tube(frame.origin, -frame.basis.z.normalized(),
		clampf(sweep_length * 0.06, 0.05, 0.8), sweep_length)
	finish_preview()

func create_line() -> void:
	if current() != null or surfaces.size() >= 100:
		return
	app.finish_stroke()
	cancel_preview()
	creation_mode = "primitive"
	var frame := primitive_frame()
	var depth: float = app.distance - minf(creation_depth, app.distance - 0.5)
	preview = Surface.new()
	app.add_child(preview)
	preview.configure_line(frame.origin, frame.basis, sweep_length,
		clampf(app.view_height(depth) * 0.015, 0.03, 0.25))
	finish_preview()

func quick_plane() -> void:
	var frame := Transform3D(app.camera.global_basis, app.cursor_pos + app.camera.global_basis.z * minf(creation_depth, app.distance - 0.5))
	var height: float = app.view_height(app.distance - minf(creation_depth, app.distance - 0.5)) * 0.6
	create_plane(frame, Vector2(height * 1.3, height))
	app.set_tool("draw")

func commit_tap_corner(screen: Vector2) -> void:
	# Second tap of plane_taps: opposite rectangle corner commits at once.
	var hit: Variant = plane_hit(screen)
	if hit == null:
		return
	var local: Vector3 = creation_frame.affine_inverse() * hit
	var end := Vector2(local.x, local.y)
	var size := (end - drag_origin).abs()
	if minf(size.x, size.y) < 0.05:
		app.status.text = Localization.translate("Ketuk lebih jauh untuk ukuran bidang.")
		return
	var frame := creation_frame
	var middle := (end + drag_origin) / 2
	frame.origin = creation_frame * Vector3(middle.x, middle.y, 0)
	preview.configure(frame, size)
	preview.show()
	finish_preview(true)

func cancel_preview() -> void:
	if app.shape_assist != null and app.shape_assist.guide_target:
		app.shape_assist.cancel()
	profile = PackedVector3Array()
	if preview != null:
		app.remove_child(preview)
		preview.queue_free()
		preview = null

func cancel_placing() -> void:
	cancel_preview()
	placing = false
	refresh()

func save_active() -> void:
	app.finish_stroke()
	var surface := current()
	if surface == null:
		return
	app.checkpoint()
	surface.saved = true
	# Saving releases the drawing target, allowing another guide to be created.
	active_id = -1
	refresh()
	app.changed()

func close_active() -> void:
	app.finish_stroke()
	var surface := current()
	if surface == null:
		cancel_placing()
		return
	app.checkpoint()
	active_id = -1
	app.clear_vertex_selection()
	if surface.saved:
		surface.hide()
	else:
		surfaces.erase(surface)
		app.remove_child(surface)
		surface.queue_free()
	refresh()
	app.changed()

func activate_picked() -> void:
	var surface := picked()
	if surface == null or current() != null:
		return
	app.finish_stroke()
	cancel_preview()
	app.checkpoint()
	app.clear_vertex_selection()
	surface.show()
	active_id = surface.guide_id
	refresh()
	app.set_tool("draw")
	app.changed()

func toggle_visibility() -> void:
	var surface := picked()
	if surface == null:
		return
	app.finish_stroke()
	app.checkpoint()
	surface.visible = not surface.visible
	if not surface.visible and surface.guide_id == active_id:
		active_id = -1
	refresh()
	app.changed()

func rename_target(title: String) -> void:
	var clean := title.strip_edges().left(80)
	if clean.is_empty():
		return
	var surface := current()
	if surface == null:
		surface = picked()
	if surface == null:
		return
	app.finish_stroke()
	app.checkpoint()
	surface.title = clean
	refresh()
	app.changed()

func delete_picked() -> void:
	var surface := picked()
	if surface == null:
		return
	app.finish_stroke()
	app.checkpoint()
	if surface.guide_id == active_id:
		active_id = -1
	app.clear_vertex_selection()
	surfaces.erase(surface)
	app.remove_child(surface)
	surface.queue_free()
	refresh()
	app.changed()

func delete_active() -> void:
	var surface := current()
	if surface == null:
		return
	app.finish_stroke()
	app.checkpoint()
	active_id = -1
	surfaces.erase(surface)
	app.remove_child(surface)
	surface.queue_free()
	refresh()
	app.changed()

func begin_opacity() -> void:
	app.finish_stroke()
	if current() != null:
		opacity_before = current().opacity
		opacity_checkpointed = false

func change_opacity(value: float) -> void:
	if current() == null:
		return
	if is_equal_approx(current().opacity, value):
		return
	# Keyboard/wheel changes are discrete edits; a drag is one history entry.
	if opacity_before < 0 or not opacity_checkpointed:
		app.checkpoint()
		opacity_checkpointed = true
	current().set_opacity(value)
	app.changed()

func end_opacity(_changed: bool) -> void:
	opacity_before = -1
	opacity_checkpointed = false

func serialize() -> Array:
	var result := []
	for surface in surfaces:
		result.append(surface.serialize())
	return result

func restore(data: Dictionary) -> void:
	cancel_preview()
	placing = false
	opacity_before = -1
	for surface in surfaces:
		app.remove_child(surface)
		surface.queue_free()
	surfaces.clear()
	for entry in data.get("guides", []):
		var surface := Surface.new()
		surface.restore(entry)
		app.add_child(surface)
		surfaces.append(surface)
	active_id = int(data.get("active_guide", -1))
	refresh()

func refresh() -> void:
	if state_label == null:
		return
	var surface := current()
	if placing:
		var placing_text := Localization.translate("Tarik area di kanvas")
		if creation_mode == "bend":
			placing_text = Localization.translate("Gambar garis Bend")
		elif creation_mode == "profile":
			placing_text = Localization.translate("Gambar profil bebas")
		elif creation_mode == "polyline":
			placing_text = Localization.translate("Klik titik poligonal")
		elif creation_mode == "curve":
			placing_text = Localization.translate("Gambar kurva bebas")
		elif creation_mode == "cube":
			placing_text = Localization.translate("Tarik area untuk ukuran cube")
		elif creation_mode == "tube":
			placing_text = Localization.translate("Tarik keluar untuk radius tube")
		elif creation_mode == "plane_taps":
			placing_text = Localization.translate("Ketuk sudut seberang bidang") if not profile.is_empty() else Localization.translate("Ketuk sudut pertama bidang")
		state_label.text = placing_text
	elif surface != null:
		state_label.text = surface.title + " " + Localization.translate("aktif")
	else:
		state_label.text = Localization.translate("Belum ada guide aktif")
	profile_button.visible = surface == null
	poly_button.visible = surface == null
	bend_button.visible = surface != null
	length_slider.visible = surface == null
	length_label.visible = surface == null
	loft_tension_slider.visible = surface == null
	loft_tension_label.visible = surface == null
	primitive_row.visible = surface == null
	cube_button.disabled = surface != null
	tube_button.disabled = surface != null
	depth_label.visible = surface == null
	depth_slider.visible = surface == null
	opacity_label.visible = surface != null
	opacity_slider.visible = surface != null
	action_row.visible = surface != null
	face_button.visible = surface != null
	save_button.disabled = surface == null
	close_button.disabled = surface == null
	cancel_button.visible = placing
	depth_slider.editable = surface == null
	opacity_slider.editable = surface != null
	opacity_slider.set_value_no_signal(surface.opacity if surface != null else 0.22)
	var old_id := picker.get_selected_id() if picker.selected >= 0 else -1
	picker.clear()
	for item in surfaces:
		if item.saved:
			picker.add_item(item.title + ("" if item.visible else " (sembunyi)"), item.guide_id)
	if picker.get_item_index(old_id) >= 0:
		picker.select(picker.get_item_index(old_id))
	activate_button.disabled = picker.item_count == 0 or surface != null
	visibility_button.disabled = picker.item_count == 0
	delete_button.disabled = picker.item_count == 0
	var named := surface if surface != null else picked()
	if named != null and guide_name_field != null and not guide_name_field.has_focus():
		guide_name_field.text = named.title
	if subobj_row != null:
		subobj_row.visible = surface != null
		vertex_mode_button.set_pressed_no_signal(app.mesh_select_mode == "vertex")
		edge_mode_button.set_pressed_no_signal(app.mesh_select_mode == "edge")
		face_mode_button.set_pressed_no_signal(app.mesh_select_mode == "face")
		extrude_button.disabled = false
	app.update_status()

func build_controls(column: VBoxContainer) -> void:
	app.label_in(column, "3D GUIDE", 13).modulate = Color("8da4b1")
	state_label = app.label_in(column, "Belum ada guide aktif", 14)
	var creation_actions := HBoxContainer.new()
	column.add_child(creation_actions)
	profile_button = app.button_in(creation_actions, "Draw: profil bebas", start_profile)
	profile_button.tooltip_text = Localization.translate("Gambar satu garis bebas di tengah bentangan guide, lalu orbit untuk melihat permukaannya.")
	var free_row := HBoxContainer.new()
	column.add_child(free_row)
	poly_button = app.button_in(free_row, "Poligonal: klik titik", start_polyline)
	poly_button.tooltip_text = Localization.translate("Klik titik-titik sudut, lalu Selesai atau ketuk dua kali.")

	length_label = app.label_in(column, "Bentangan profil: 4.0", 14)
	length_slider = HSlider.new()
	length_slider.min_value = 0.25
	length_slider.max_value = 12
	length_slider.step = 0.25
	length_slider.value = sweep_length
	length_slider.custom_minimum_size.y = 32
	length_slider.value_changed.connect(func(value: float): sweep_length = value; length_label.text = Localization.translate("Bentangan profil") + ": %.2f" % value)
	column.add_child(length_slider)
	loft_tension_label = app.label_in(column, "Loft tension: 50%", 14)
	loft_tension_slider = HSlider.new()
	loft_tension_slider.min_value = 0.0
	loft_tension_slider.max_value = 1.0
	loft_tension_slider.step = 0.05
	loft_tension_slider.value = loft_tension
	loft_tension_slider.custom_minimum_size.y = 32
	loft_tension_slider.value_changed.connect(func(value: float):
		loft_tension = value
		loft_tension_label.text = Localization.translate("Loft tension") + ": %d%%" % roundi(value * 100.0)
	)
	column.add_child(loft_tension_slider)
	bend_button = app.button_in(column, "Bend: gambar arah baru", start_bend)
	bend_button.tooltip_text = Localization.translate("Garis baru mengganti arah bentangan dari tepi oranye. Tinta yang sudah ada tetap di tempat.")
	primitive_row = HBoxContainer.new()
	column.add_child(primitive_row)
	cube_button = app.button_in(primitive_row, "Cube", start_cube)
	tube_button = app.button_in(primitive_row, "Tube", start_tube)
	cube_button.tooltip_text = Localization.translate("Klik-drag pada kanvas untuk mengatur ukuran cube; tengah tepat di area tarikan.")
	tube_button.tooltip_text = Localization.translate("Sentuh titik pusat, tarik keluar untuk radius tube. Panjang mengikuti Bentangan profil.")
	cancel_button = app.button_in(column, "Batal membuat guide", cancel_placing)
	depth_label = app.label_in(column, "Kedalaman guide baru", 14)
	depth_slider = HSlider.new()
	depth_slider.min_value = -4
	depth_slider.max_value = 4
	depth_slider.step = 0.25
	depth_slider.custom_minimum_size.y = 28
	depth_slider.value_changed.connect(func(value: float):
		creation_depth = value
		depth_label.text = Localization.translate("Kedalaman guide baru") + ": %+.2f" % value)
	depth_label.text = Localization.translate("Kedalaman guide baru") + ": %+.2f" % creation_depth
	column.add_child(depth_slider)
	opacity_label = app.label_in(column, "Opacity guide", 14)
	opacity_slider = HSlider.new()
	opacity_slider.min_value = 0
	opacity_slider.max_value = 0.7
	opacity_slider.step = 0.01
	opacity_slider.custom_minimum_size.y = 28
	opacity_slider.drag_started.connect(begin_opacity)
	opacity_slider.value_changed.connect(change_opacity)
	opacity_slider.drag_ended.connect(end_opacity)
	column.add_child(opacity_slider)
	action_row = HBoxContainer.new()
	column.add_child(action_row)
	save_button = app.button_in(action_row, "Simpan guide", save_active)
	close_button = app.button_in(action_row, "Tutup", close_active)
	save_button.tooltip_text = Localization.translate("Simpan sebagai resource dan nonaktifkan. Goresan tetap ada. Gunakan Simpan proyek untuk menulis ke disk.")
	face_button = app.button_in(action_row, "Hadap guide", app.face_guide)
	app.label_in(column, "GUIDE TERSIMPAN", 13).modulate = Color("8da4b1")
	picker = OptionButton.new()
	picker.custom_minimum_size = Vector2(180, 40)
	picker.clip_text = true
	column.add_child(picker)
	var resource_actions := HBoxContainer.new()
	column.add_child(resource_actions)
	activate_button = app.button_in(resource_actions, "Aktifkan guide", activate_picked)
	visibility_button = app.button_in(resource_actions, "Tampil / sembunyi", toggle_visibility)
	delete_button = app.button_in(resource_actions, "Hapus guide tersimpan", delete_picked)
	var rename_row := HBoxContainer.new()
	column.add_child(rename_row)
	guide_name_field = LineEdit.new()
	guide_name_field.custom_minimum_size = Vector2(140, 40)
	guide_name_field.max_length = 80
	rename_row.add_child(guide_name_field)
	var rename_button: Button = app.button_in(rename_row, "Ubah nama", func(): rename_target(guide_name_field.text))
	rename_button.tooltip_text = Localization.translate("Menerapkan nama objek pada guide aktif atau terpilih.")
	guide_name_field.text_submitted.connect(func(_text: String): rename_target(guide_name_field.text))
	subobj_row = HBoxContainer.new()
	column.add_child(subobj_row)
	vertex_mode_button = app.button_in(subobj_row, "Vertex", func(): app.set_mesh_select_mode("vertex"))
	edge_mode_button = app.button_in(subobj_row, "Edge", func(): app.set_mesh_select_mode("edge"))
	face_mode_button = app.button_in(subobj_row, "Face", func(): app.set_mesh_select_mode("face"))
	vertex_mode_button.toggle_mode = true
	edge_mode_button.toggle_mode = true
	face_mode_button.toggle_mode = true
	vertex_mode_button.tooltip_text = Localization.translate("Memilih dan menggeser titik vertex guide aktif.")
	edge_mode_button.tooltip_text = Localization.translate("Memilih dan menggeser rusuk guide aktif.")
	face_mode_button.tooltip_text = Localization.translate("Memilih dan menggeser sisi segitiga guide aktif.")
	extrude_button = app.button_in(subobj_row, "Extrude", func(): app.extrude_mesh_boundary())
	extrude_button.tooltip_text = Localization.translate("Menambah baris grid baru dari tepi terpilih.")
	refresh()
