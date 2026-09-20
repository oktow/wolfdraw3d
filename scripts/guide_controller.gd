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
var create_button: Button
var quick_button: Button
var save_button: Button
var close_button: Button
var cancel_button: Button
var picker: OptionButton
var activate_button: Button
var visibility_button: Button
var opacity_slider: HSlider
var depth_slider: HSlider
var delete_button: Button
var depth_label: Label
var opacity_label: Label
var action_row: HBoxContainer
var face_button: Button
var profile_button: Button
var bend_button: Button
var length_slider: HSlider
var length_label: Label
var creation_mode := "plane"
var profile := PackedVector3Array()
var last_screen := Vector2.ZERO
var sweep_length := 4.0

func start_profile() -> void:
	if current() != null:
		return
	start_placing()
	if placing:
		creation_mode = "profile"
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
	cancel_preview()
	creation_frame = Transform3D(app.camera.global_basis, app.target + app.camera.global_basis.z * minf(creation_depth, app.distance - 0.5))
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

func extend_preview(screen: Vector2) -> void:
	if preview == null:
		return
	var hit: Variant = plane_hit(screen)
	if hit == null:
		return
	if creation_mode != "plane":
		if screen.distance_to(last_screen) < 3:
			return
		profile.append(hit)
		# Preserve endpoints and the strongest corners when the sample cap is reached.
		var limit := 64 if creation_mode == "bend" else 256
		if profile.size() > limit:
			var least := INF
			var remove_index := 1
			for i in range(1, profile.size() - 1):
				var error := profile[i].distance_squared_to(Geometry3D.get_closest_point_to_segment(profile[i], profile[i - 1], profile[i + 1]))
				if error < least:
					least = error
					remove_index = i
			profile.remove_at(remove_index)
		last_screen = screen
		if creation_mode == "bend":
			if current() == null:
				cancel_preview()
				return
			preview.configure_bend(current(), profile)
		else:
			preview.configure_profile(profile, -creation_frame.basis.z * sweep_length)
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

func finish_preview() -> void:
	app.shape_assist.finalize()
	if preview == null:
		return
	if not preview.visible:
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

func quick_plane() -> void:
	var frame := Transform3D(app.camera.global_basis, app.target + app.camera.global_basis.z * minf(creation_depth, app.distance - 0.5))
	var height: float = app.view_height(app.distance - minf(creation_depth, app.distance - 0.5)) * 0.6
	create_plane(frame, Vector2(height * 1.3, height))
	app.set_tool("draw")

func cancel_preview() -> void:
	if app.shape_assist != null and app.shape_assist.guide_target:
		app.shape_assist.cancel()
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
	cancel_placing()
	app.checkpoint()
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

func delete_picked() -> void:
	var surface := picked()
	if surface == null:
		return
	app.finish_stroke()
	app.checkpoint()
	if surface.guide_id == active_id:
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
	state_label.text = (Localization.translate("Gambar garis Bend") if creation_mode == "bend" else (Localization.translate("Gambar profil bebas") if creation_mode == "profile" else Localization.translate("Tarik area di kanvas"))) if placing else ((surface.title + " " + Localization.translate("aktif")) if surface != null else Localization.translate("Belum ada guide aktif"))
	profile_button.visible = surface == null
	bend_button.visible = surface != null
	length_slider.visible = surface == null
	length_label.visible = surface == null
	create_button.disabled = surface != null
	quick_button.disabled = surface != null
	create_button.visible = surface == null
	quick_button.visible = surface == null
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
	app.update_status()

func build_controls(column: VBoxContainer) -> void:
	app.label_in(column, "3D GUIDE", 13).modulate = Color("8da4b1")
	state_label = app.label_in(column, "Belum ada guide aktif", 14)
	var creation_actions := HBoxContainer.new()
	column.add_child(creation_actions)
	profile_button = app.button_in(creation_actions, "Draw: profil bebas", start_profile)
	profile_button.tooltip_text = Localization.translate("Gambar satu garis bebas sebagai tepi awal guide, lalu orbit untuk melihat permukaannya.")
	length_label = app.label_in(column, "Bentangan profil: 4.0", 14)
	length_slider = HSlider.new()
	length_slider.min_value = 0.25
	length_slider.max_value = 12
	length_slider.step = 0.25
	length_slider.value = sweep_length
	length_slider.custom_minimum_size.y = 32
	length_slider.value_changed.connect(func(value: float): sweep_length = value; length_label.text = Localization.translate("Bentangan profil") + ": %.2f" % value)
	column.add_child(length_slider)
	bend_button = app.button_in(column, "Bend: gambar arah baru", start_bend)
	bend_button.tooltip_text = Localization.translate("Garis baru mengganti arah bentangan dari tepi oranye. Tinta yang sudah ada tetap di tempat.")
	create_button = app.button_in(creation_actions, "Buat bidang: tarik area", start_placing)
	quick_button = app.button_in(creation_actions, "Bidang ukuran otomatis", quick_plane)
	cancel_button = app.button_in(column, "Batal membuat guide", cancel_placing)
	depth_label = app.label_in(column, "Kedalaman guide baru", 14)
	depth_slider = HSlider.new()
	depth_slider.min_value = -4
	depth_slider.max_value = 4
	depth_slider.step = 0.25
	depth_slider.custom_minimum_size.y = 28
	depth_slider.value_changed.connect(func(value: float): creation_depth = value)
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
	refresh()
