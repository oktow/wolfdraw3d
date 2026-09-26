extends RefCounted
const Localization = preload("res://scripts/localization.gd")
## Original SVG line icons. One catalog supplies buttons, tooltips and the in-app legend.
static var cache: Dictionary = {}
const PATHS = {
	"pen": '<path d="m4 20 4-1 12-12-3-3L5 16Z M14 7l3 3 M4 20l1-4"/>',
	"pencil": '<path d="m4 20 4-1 12-12-3-3L5 16Z M14 7l3 3 M4 20l1-4"/>',
	"brush": '<path d="M5 19q-2-2 0-4l9-9 4 4-9 9q-2 2-4 0Z M14 6l2-2q2-2 4 0l1 1q2 2 0 4l-2 2"/>',
	"tube": '<path d="M7 4h10v4H7z M8 8v9q0 4 4 4t4-4V8 M10 12h4"/>',
	"marker": '<path d="M4 20 12 12 M11 3l8 8-5 5-8-8Z M11 3l3-1 6 6-1 3"/>',
	"flat": '<path d="M3 21h18 M5 21V9h14v12 M5 13h14"/>',
	"props": '<path d="M4 7h16 M4 12h16 M4 17h16"/><circle cx="15" cy="7" r="2.4"/><circle cx="9" cy="12" r="2.4"/><circle cx="17" cy="17" r="2.4"/>',
	"lasso_fill": '<path d="M5 7q7-6 14 0t-7 8q-7 2-7-3t7-2q5 1 3 5 M8 18h8"/>',
	"rectangle_fill": '<rect x="4" y="5" width="16" height="14" rx="1"/><path d="M4 9h16 M4 15h16 M9 5v14 M15 5v14"/>',
	"paint": '<path d="M4 20 11 13 M10 4l9 9-6 6-9-9Z M15 3l3-1 3 3-1 3 M4 20l1-4"/>',
	"radius": '<circle cx="12" cy="12" r="7"/><circle cx="12" cy="12" r="2"/>',
	"opacity": '<circle cx="12" cy="12" r="8"/><path d="M4 12h16"/>',
	"draw_shape": '<path d="M4 18 9 5l4 8 7-2-5 7Z"/><circle cx="9" cy="5" r="1"/>',
	"loft": '<path d="M4 5h16 M4 12h16 M4 19h16 M7 5v14 M12 5v14 M17 5v14"/>',
	"orbit": '<ellipse cx="12" cy="12" rx="10" ry="5"/><ellipse cx="12" cy="12" rx="5" ry="10"/><circle cx="12" cy="12" r="1"/>',
	"select": '<path d="m5 3 14 9-7 1-3 7Z"/>',
	"erase": '<path d="m3 14 10-10 8 8-8 9H9Z M8 9l8 8 M12 21h9"/>',
	"undo": '<path d="m8 4-5 5 5 5 M3 9h10a7 7 0 0 1 0 14" transform="translate(0 -2)"/>',
	"redo": '<path d="m16 2 5 5-5 5 M21 7h-10a7 7 0 0 0 0 14"/>',
	"hide": '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M8 4v16 m8-12-4 4 4 4"/>',
	"menu": '<path d="M4 6h16 M4 12h16 M4 18h16"/>',
	"finger": '<path d="M8 12V5a2 2 0 0 1 4 0v7-4a2 2 0 0 1 4 0v4-2a2 2 0 0 1 4 0v5q0 6-6 6h-2q-3 0-5-3l-4-5q-1-3 2-2l3 3"/>',
	"finger_pen": '<path d="M5 13v-8a2 2 0 0 1 4 0v6 M9 9q7-2 7 4v3q0 5-6 5L4 16"/><path d="m15 10 5-7 2 2-5 7-3 2Z"/>',
	"save": '<path d="M4 3h13l4 4v14H3V3Z M7 3v6h10V3 M7 21v-8h10v8"/>',
	"open": '<path d="M3 19V5h7l3 3h8v3 M3 19l3-8h16l-3 8Z"/>',
	"save_as": '<path d="M10 21H3V3h14l4 4v5 M7 3v6h10V3 M7 18v-5h5 m2 7 6-6 2 2-6 6-3 1Z"/>',
	"add": '<path d="M12 4v16 M4 12h16"/>',
	"rename": '<path d="M3 8V4h14v4 M10 4v14 M6 18h7 m2 1 5-5 2 2-5 5-3 1Z"/>',
	"eye": '<path d="M2 12q10-15 20 0-10 15-20 0Z"/><circle cx="12" cy="12" r="3"/>',
	"move_group": '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/><path d="M14 5h4v6 m-3-3 3 3 3-3 M5 14v4h6"/>',
	"delete": '<path d="M3 6h18 M9 6V3h6v3 M5 6l1 15h12l1-15 M10 10v7 M14 10v7"/>',
	"profile": '<path d="M3 9q4-10 8 0t10 0 M3 9v10q4-10 8 0t10 0V9 M11 9v10"/>',
	"bend": '<path d="M4 20V7q0-4 4-4h12 M9 20V8h11 m-4-3 4 3-4 3"/>',
	"plane": '<path d="m3 17 5-11 13 1-5 11Z M4 3v5 M2 5h5"/>',
	"quick_plane": '<path d="m2 18 5-10 11 1-5 10Z m16-17-5 7h5l-5 7"/>',
	"cancel": '<path d="m6 6 12 12 M18 6 6 18"/>',
	"save_guide": '<path d="m2 10 7-7 12 4-7 7Z M3 15l6 4 4-3 M17 14v8 m-4-3 4 3 4-3"/>',
	"face": '<rect x="6" y="6" width="12" height="12" rx="1"/><path d="M8 2H2v6 M16 2h6v6 M2 16v6h6 M22 16v6h-6"/>',
	"activate": '<path d="m3 8 7-5 11 4-7 6Z M3 8v11l11 2V13 M9 13l4 3-4 3Z"/>',
	"reset": '<path d="M4 10a8 8 0 1 1 1 8 M4 4v6h6"/><circle cx="12" cy="12" r="2"/>',
	"cube": '<path d="m12 2 9 5v10l-9 5-9-5V7Z M3 7l9 5 9-5 M12 12v10"/>',
	"global_axis": '<path d="M3 12h18 M18 8l3 4-3 4" stroke="#f18cae"/><path d="M12 21V3 M8 6l4-4 4 4" stroke="#73e6bb"/><path d="M6 18l9-9 M13 9h4v4" stroke="#8eb9ff"/>',
	"cursor3d": '<circle cx="12" cy="12" r="6"/><path d="M12 1v5 M12 18v5 M1 12h5 M18 12h5"/>',
	"vertex_edit": '<circle cx="5" cy="5" r="1.8"/><circle cx="12" cy="5" r="1.8"/><circle cx="19" cy="5" r="1.8"/><circle cx="5" cy="12" r="1.8"/><circle cx="12" cy="12" r="1.8"/><circle cx="19" cy="12" r="1.8"/><circle cx="5" cy="19" r="1.8"/><circle cx="12" cy="19" r="1.8"/><circle cx="19" cy="19" r="1.8"/>',
	"edge_edit": '<path d="M4 20 20 4"/><circle cx="4" cy="20" r="2.2"/><circle cx="20" cy="4" r="2.2"/>',
	"face_edit": '<path d="M12 4 21 20 H3 Z"/><circle cx="12" cy="4" r="1.8"/><circle cx="21" cy="20" r="1.8"/><circle cx="3" cy="20" r="1.8"/>',
	"extrude": '<rect x="4" y="13" width="10" height="7" rx="1"/><rect x="4" y="4" width="10" height="7" rx="1" opacity=".4"/><path d="M18 14V5 M15.5 7.5 18 5l2.5 2.5"/>',
	"line": '<path d="M4 20 20 4"/><circle cx="4" cy="20" r="1.6"/><circle cx="20" cy="4" r="1.6"/>',
	"polyline": '<circle cx="4" cy="18" r="1.6"/><circle cx="12" cy="8" r="1.6"/><circle cx="20" cy="14" r="1.6"/><path d="M5 17l6-8 8 5"/>',
	"curve": '<path d="M3 18q6-12 9-6t9-6"/><circle cx="3" cy="18" r="1.4"/><circle cx="21" cy="6" r="1.4"/>',
	"help": '<circle cx="12" cy="12" r="9"/><path d="M9 8a3 3 0 0 1 6 0c0 3-3 2-3 5 M12 17h.01"/>',
	"taper": '<path d="m2 12 20-7v14Z"/>',
	"smooth": '<path d="m2 16 4-8 4 8 4-8 4 8 4-8" opacity=".3"/><path d="M2 13q5-9 10 0t10 0"/>',
	"rotate_left": '<path d="M4 10a8 8 0 1 1 1 8 M4 4v6h6"/>',
	"rotate_right": '<path d="M20 10a8 8 0 1 0-1 8 M20 4v6h-6"/>',
	"scale_down": '<path d="M3 9h6V3 M21 15h-6v6 M9 9 3 3 M15 15l6 6"/>',
	"scale_up": '<path d="M3 9V3h6 M21 15v6h-6 M3 3l6 6 M21 21l-6-6"/>',
	"joystick": '<circle cx="12" cy="12" r="3"/><path d="M12 9V3 M9 12H3 M15 12h6 M12 15v6 M12 3l-2 3h4Z M3 12l3-2v4Z M21 12l-3-2v4Z M12 21l-2-3h4Z"/>',
	"mode_move": '<path d="M12 2v20 M2 12h20 M9 5l3-3 3 3 M9 19l3 3 3-3 M5 9l-3 3 3 3 M19 9l3 3-3 3"/>',
	"mode_rotate": '<path d="M20 12a8 8 0 1 1-2.3-5.6 M18 2v5h-5"/>',
	"mode_scale": '<path d="M9 3H3v6 M15 3h6v6 M9 21H3v-6 M15 21h6v-6"/>',
	"duplicate": '<rect x="7" y="7" width="12" height="12" rx="1"/><path d="M5 17H4V4h13v1 M12 10v6 M9 13h6"/>',
	"mirror": '<path d="M12 3v18 M5 6l-3 3 3 3 M19 6l3 3-3 3 M5 15l-3 3 3 3 M19 15l3 3-3 3"/>',
	"perspective": '<path d="M3 5h18v14H3Z M3 5l9 7 9-7 M3 19l9-7 9 7"/>',
	"orthographic": '<rect x="4" y="5" width="16" height="14" rx="1"/><path d="M8 5v14 M16 5v14 M4 9h16 M4 15h16"/>'
}
const ACTIONS = {
	"Gambar B": ["pen", "Menggambar pada guide aktif. Pintasan B."],
	"Navigasi N": ["orbit", "Memutar kamera. Satu jari orbit; dua jari pan/cubit zoom. Pintasan N."],
	"Pilih V": ["select", "Memilih satu goresan untuk diedit. Pintasan V."],
	"Hapus E": ["erase", "Menghapus bagian goresan dalam sapuan eraser. Pintasan E."],
	"Undo": ["undo", "Membatalkan satu perubahan. Ctrl+Z."],
	"Redo": ["redo", "Mengulangi perubahan yang dibatalkan. Ctrl+Shift+Z."],
	"Sembunyikan U": ["hide", "Menyembunyikan panel untuk memperluas kanvas. Pintasan U."],
	"Menu U": ["menu", "Menampilkan kembali panel. Pintasan U."],
	"Jari: putar": ["finger", "Satu jari memutar kamera. Ketuk untuk beralih ke jari menggambar."],
	"Jari: gambar": ["finger_pen", "Satu jari memakai alat aktif. Ketuk untuk kembali memutar. Dua jari selalu navigasi."],
	"Simpan": ["save", "Menyimpan proyek ke file. Ctrl+S."],
	"Buka": ["open", "Membuka file proyek. Ctrl+O."],
	"Simpan sebagai...": ["save_as", "Menyimpan proyek ke file baru. Ctrl+Shift+S."],
	"+": ["add", "Membuat grup baru."],
	"Ubah nama": ["rename", "Menerapkan nama grup dari kolom di sebelah ikon."],
	"Tampilkan grup": ["eye", "Menampilkan atau menyembunyikan grup aktif. Hijau berarti tampil."],
	"Pindah ke grup aktif": ["move_group", "Memindahkan goresan terpilih ke grup aktif."],
	"Hapus pilihan": ["delete", "Menghapus seluruh goresan terpilih. Delete/Backspace."],
	"Draw: profil bebas": ["profile", "Membuat guide dari profil bebas yang ditarik pada kanvas."],
	"Bend: gambar arah baru": ["bend", "Mengubah bentangan guide dengan garis baru, dimulai dari sisi oranye."],
	"Buat bidang: tarik area": ["plane", "Menarik area untuk membuat guide datar. Pintasan G."],
	"Bidang ukuran otomatis": ["quick_plane", "Langsung membuat guide datar di depan kamera."],
	"Batal membuat guide": ["cancel", "Membatalkan pembuatan atau Bend guide."],
	"Simpan guide": ["save_guide", "Menyimpan guide sebagai resource dan melepas target gambar. Simpan proyek untuk menulis ke disk."],
	"Tutup": ["cancel", "Menutup guide aktif tanpa menghapus tinta. Pintasan Esc."],
	"Hadap guide": ["face", "Mengarahkan kamera ke guide aktif."],
	"Aktifkan guide": ["activate", "Memakai guide tersimpan yang dipilih sebagai target gambar."],
	"Tampil / sembunyi": ["eye", "Mengubah visibilitas guide tersimpan yang dipilih."],
	"Hapus guide tersimpan": ["delete", "Menghapus guide tersimpan, tinta tetap ada."],
	"Hapus guide aktif": ["delete", "Menghapus guide aktif, tinta tetap ada."],
	"Reset kamera": ["reset", "Mengembalikan posisi, pusat, dan jarak kamera ke awal."],
	"Tampak": ["cube", "Membuka pilihan tampak depan, belakang, atas, bawah, kanan, dan kiri."],
	"Panduan ikon": ["help", "Membuka arti ikon dan panduan gestur."],
	"Ujung meruncing": ["taper", "Mengaktifkan taper untuk sapuan baru. Hijau berarti aktif."],
	"Haluskan goresan": ["smooth", "Menghaluskan goresan pada guide datar. Hijau berarti aktif."],
	"Putar -15": ["rotate_left", "Memutar grup -15 derajat terhadap normal guide."],
	"+15": ["rotate_right", "Memutar grup +15 derajat terhadap normal guide."],
	"Skala -": ["scale_down", "Memperkecil grup aktif."],
	"Skala +": ["scale_up", "Memperbesar grup aktif."],
	"Joystick transformasi": ["joystick", "Menampilkan atau menyembunyikan joystick transformasi grup."],
	"Duplikat": ["duplicate", "Menyalin goresan terpilih sebagai goresan baru."],
	"Mirror": ["mirror", "Mencerminkan sapuan baru pada sumbu X, Y, atau Z melalui kursor 3D."]
	,"Radius": ["radius", "Mengatur radius brush untuk sapuan baru."]
	,"Opacity brush": ["opacity", "Mengatur opacity brush untuk sapuan baru."]
	,"Draw Shape": ["draw_shape", "Memilih mode Draw Shape untuk merapikan garis, lingkaran, elips, atau kurva."]
	,"Loft": ["loft", "Menghubungkan minimal dua stroke terpilih menjadi guide surface baru."]
	,"Cube": ["cube", "Membuat guide kotak menghadap kamera."]
	,"Tube": ["tube", "Membuat guide tabung menjauhi kamera."]
	,"Line": ["line", "Membuat guide strip tipis sebagai penggaris."]
	,"Spidol datar": ["marker", "Pena mata pipih; lebar goresan mengikuti arah tarikan terhadap sudut nib."]
	,"Kuas warna": ["paint", "Coretan bebas tertutup menjadi satu warna; warna sama pada bidang yang sama menyatu."]
	,"Pena pipih": ["flat", "Ribbon datar solid; lebar konstan dan opak penuh."]
	,"Properti": ["props", "Warna, opacity, dan radius brush dalam satu popup."]
	,"Buat guide": ["add", "Membuka pilihan tipe guide baru."]
	,"Poligonal: klik titik": ["polyline", "Klik titik-titik sudut guide satu per satu."]
	,"Kurva bebas": ["curve", "Gambar garis bebas yang dihaluskan otomatis."]
	,"Pilih grup aktif": ["add", "Memilih seluruh goresan terlihat pada grup aktif."]
	,"Pilih semua": ["eye", "Memilih seluruh goresan terlihat dari semua grup."]
	,"Kosongkan pilihan": ["cancel", "Mengosongkan seleksi tanpa menghapus."]
	,"Mirror seleksi": ["mirror", "Mencerminkan seleksi di tempat terhadap bidang kursor 3D."]
	,"Geser": ["mode_move", "Gizmo geser sepanjang sumbu."]
	,"Putar": ["mode_rotate", "Gizmo putar mengelilingi sumbu."]
	,"Skala": ["mode_scale", "Gizmo skala seragam dari pusat."]
	,"Radius eraser": ["radius", "Mengatur radius lingkaran eraser."]
	,"Sumbu global": ["global_axis", "Menampilkan atau menyembunyikan sumbu global XYZ."]
	,"Kursor 3D": ["cursor3d", "Menaruh kursor 3D sebagai acuan lahir guide; ketuk atau seret kanvas."]
	,"Vertex objek": ["vertex_edit", "Memilih dan menggeser titik vertex guide aktif."]
	,"Edge objek": ["edge_edit", "Memilih dan menggeser rusuk guide aktif."]
	,"Face objek": ["face_edit", "Memilih dan menggeser sisi segitiga guide aktif."]
	,"Extrude tepi": ["extrude", "Menambah baris grid baru dari tepi terpilih."]
	,"Joystick 2D": ["joystick", "Pad geser/putar/skala pada bidang pandang untuk seleksi."]
	,"Transformasi guide": ["joystick", "Beralih ke gizmo viewport untuk menggeser, memutar, atau menskala guide aktif. Tinta tetap di tempat."]
	,"Putar 90°": ["mode_rotate", "Putar guide aktif 90 derajat; pilih sumbu dunia."]
}

static func normalized(title: String) -> String:
	return title.strip_edges().replace("  ", " ")

static func texture(key: String, pixel_scale := 2.0) -> Texture2D:
	var cache_key := key + "@" + str(pixel_scale)
	if cache.has(cache_key):
		return cache[cache_key]
	var paths: String = PATHS.get(key, PATHS.help)
	if key.begins_with("axis_"):
		var letter := key.substr(5, 1)
		var glyph: String = {"X": "M3 5l6 10 M9 5 3 15", "Y": "M3 5l3 5 3-5 M6 10v5", "Z": "M3 5h6l-6 10h6"}[letter]
		paths = '<path d="' + glyph + ' M14 12h8'
		if key.ends_with("+"):
			paths += ' M18 8v8'
		paths += '"/>'
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><g fill="none" stroke="#e8eff2" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">' + paths + '</g></svg>'
	var image := Image.new()
	image.load_svg_from_string(svg, pixel_scale)
	cache[cache_key] = ImageTexture.create_from_image(image)
	return cache[cache_key]

static func apply(button: Button, title: String) -> void:
	var name := normalized(title)
	var key := ""
	var description := ""
	if ACTIONS.has(name):
		key = ACTIONS[name][0]
		description = ACTIONS[name][1]
	elif name in ["X+", "X-", "Y+", "Y-", "Z+", "Z-"]:
		key = "axis_" + name
		description = "Geser grup aktif 0,25 unit pada sumbu " + name
	else:
		return
	button.text = ""
	button.icon = texture(key)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 24)
	button.custom_minimum_size = Vector2(48,48)
	button.tooltip_text = Localization.translate(name) + "\n" + Localization.translate(description)
	button.set_meta("action_title", name)
	for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		var box := button.get_theme_stylebox(state).duplicate() as StyleBox
		box.content_margin_left = 10
		box.content_margin_right = 10
		box.content_margin_top = 10
		box.content_margin_bottom = 10
		button.add_theme_stylebox_override(state, box)
