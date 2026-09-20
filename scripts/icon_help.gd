extends AcceptDialog
const Icons = preload("res://scripts/ui_icons.gd")
const Localization = preload("res://scripts/localization.gd")

func _init() -> void:
	title = Localization.translate("Panduan ikon • WolfDraw3D")
	ok_button_text = Localization.translate("Tutup panduan")
	min_size = Vector2i(460, 350)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(420, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 16)
	scroll.add_child(column)
	var introduction := Label.new()
	introduction.set_meta("locale_key", "icon_help_introduction")
	introduction.text = Localization.translate("Arahkan mouse ke ikon untuk tooltip. Di layar sentuh, buka panduan ini lewat ikon tanda tanya.\nHijau = aktif • Redup = belum tersedia.\n\nSatu jari: putar atau gambar sesuai ikon tangan.\nDua jari: geser untuk pan, cubit/renggangkan untuk zoom.\nDraw Shape: tahan ujung sekitar 1 detik, atur bentuk, lalu lepaskan.")
	introduction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(introduction)
	for title_text in Icons.ACTIONS:
		add_entry(column, Icons.ACTIONS[title_text][0], title_text, Icons.ACTIONS[title_text][1])
	for axis in ["X+", "X-", "Y+", "Y-", "Z+", "Z-"]:
		add_entry(column, "axis_" + axis, "Geser " + axis, "Memindahkan grup 0,25 unit pada sumbu " + axis + ".")

func add_entry(column: VBoxContainer, key: String, title_text: String, description: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	column.add_child(row)
	var icon := TextureRect.new()
	icon.texture = Icons.texture(key)
	icon.custom_minimum_size = Vector2(32,32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var text := Label.new()
	text.set_meta("locale_title", title_text)
	text.set_meta("locale_description", description)
	text.text = Localization.translate(title_text) + "\n" + Localization.translate(description)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)

func refresh_language() -> void:
	title = Localization.translate("Panduan ikon • WolfDraw3D")
	ok_button_text = Localization.translate("Tutup panduan")
	for node in find_children("*", "Label", true, false):
		if node.has_meta("locale_key"):
			node.text = Localization.translate("Arahkan mouse ke ikon untuk tooltip. Di layar sentuh, buka panduan ini lewat ikon tanda tanya.\nHijau = aktif • Redup = belum tersedia.\n\nSatu jari: putar atau gambar sesuai ikon tangan.\nDua jari: geser untuk pan, cubit/renggangkan untuk zoom.\nDraw Shape: tahan ujung sekitar 1 detik, atur bentuk, lalu lepaskan.")
		elif node.has_meta("locale_title"):
			node.text = Localization.translate(node.get_meta("locale_title")) + "\n" + Localization.translate(node.get_meta("locale_description"))
