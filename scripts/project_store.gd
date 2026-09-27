extends RefCounted
## Versioned, data-only project files. Validate fully before touching the scene.

const FORMAT := "wolfdraw3d"
const VERSION := 8
const MAX_POINTS := 200000
const MAX_BYTES := 32 * 1024 * 1024
const MAX_BG_IMAGE_CHARS := 5600000

static func default_environment() -> Dictionary:
	return {"axis": false, "grid": true, "fog": false, "shadow": false,
		"glow": false, "grain": false, "pixel": false,
		"bg_color": [1.0, 1.0, 1.0], "bg_image": "",
		"light_alt": 35.0, "light_az": -25.0, "light_color": [1.0, 1.0, 1.0],
		"light_energy": 1.0, "glow_amount": 0.8, "grain_amount": 0.3, "pixel_scale": 1.0}

static func encode(data: Dictionary) -> String:
	return JSON.stringify(data, "", true, true)

static func valid_number(value: Variant, limit: float = 100000.0) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and absf(float(value)) <= limit

static func valid_vector(value: Variant) -> bool:
	return value is Array and value.size() == 3 and valid_number(value[0]) and valid_number(value[1]) and valid_number(value[2])

static func validate(data: Variant) -> String:
	if not data is Dictionary or data.get("format") != FORMAT or (data.get("version") != 1 and data.get("version") != 2 and data.get("version") != 3 and data.get("version") != 4 and data.get("version") != 5 and data.get("version") != 6 and data.get("version") != 7 and data.get("version") != VERSION):
		return "Format atau versi proyek tidak didukung."
	var groups: Variant = data.get("groups")
	var strokes: Variant = data.get("strokes")
	if not groups is Array or groups.is_empty() or groups.size() > 1000 or not strokes is Array or strokes.size() > 10000:
		return "Daftar grup atau goresan tidak valid."
	var ids := {}
	for group in groups:
		if not group is Dictionary:
			return "Data grup tidak valid."
		var id: Variant = group.get("id")
		if not valid_number(id) or float(id) != floor(float(id)) or id < 0 or ids.has(int(id)):
			return "ID grup tidak valid atau duplikat."
		if not group.get("name") is String or group.name.length() > 80 or not group.get("visible") is bool:
			return "Nama atau visibilitas grup tidak valid."
		ids[int(id)] = true
	if not valid_number(data.get("active_group")) or float(data.active_group) != floor(float(data.active_group)) or not ids.has(int(data.active_group)):
		return "Grup aktif tidak ditemukan."
	var total := 0
	for stroke in strokes:
		if not stroke is Dictionary or not valid_number(stroke.get("group")) or float(stroke.group) != floor(float(stroke.group)) or not ids.has(int(stroke.group)):
			return "Grup goresan tidak ditemukan."
		var points: Variant = stroke.get("points")
		if not points is Array or points.size() < 2:
			return "Titik goresan tidak valid."
		total += points.size()
		if total > MAX_POINTS:
			return "Proyek melebihi batas 200.000 titik."
		for point in points:
			if not valid_vector(point):
				return "Koordinat goresan tidak valid."
		if not valid_vector(stroke.get("normal")):
			return "Normal goresan tidak valid."
		var normal := Vector3(stroke.normal[0], stroke.normal[1], stroke.normal[2])
		if normal.length() < 0.99 or normal.length() > 1.01:
			return "Normal goresan harus berupa vektor satuan."
		if not valid_number(stroke.get("radius"), 10) or stroke.radius < 0.001:
			return "Ukuran brush tidak valid."
		var color: Variant = stroke.get("color")
		if not color is Array or color.size() != 4:
			return "Warna goresan tidak valid."
		for channel in color:
			if not valid_number(channel, 1) or channel < 0:
				return "Nilai warna tidak valid."
		if stroke.has("brush"):
			if stroke.brush not in ["pen", "pencil", "brush", "marker", "flat", "paint", "lasso_fill", "rectangle_fill"]:
				return "Jenis brush tidak valid."
			if stroke.brush == "marker" and not valid_number(stroke.get("nib")):
				return "Sudut nib tidak valid."
			if stroke.brush == "paint":
				if not valid_number(stroke.get("opacity"), 1) or stroke.opacity < 0:
					return "Opacity brush tidak valid."
				var polys: Variant = stroke.get("paint")
				if not polys is Array or polys.is_empty():
					return "Poligon kuas warna tidak valid."
				for poly in polys:
					if not poly is Array or poly.size() < 3:
						return "Poligon kuas warna tidak valid."
					for point in poly:
						if not valid_vector(point):
							return "Koordinat kuas warna tidak valid."
				continue
			if stroke.brush == "lasso_fill" or stroke.brush == "rectangle_fill":
				if not valid_number(stroke.get("opacity"), 1) or stroke.opacity < 0:
					return "Opacity brush tidak valid."
				continue
			if not valid_number(stroke.get("opacity"), 1) or stroke.opacity < 0 or not valid_number(stroke.get("taper"), 0.5) or stroke.taper < 0:
				return "Opacity/taper brush tidak valid."
			if stroke.has("thickness") and (not valid_number(stroke.get("thickness"), 1) or stroke.thickness < 0):
				return "Ketebalan brush tidak valid."
			if not stroke.get("normals") is Array or stroke.normals.size() != points.size() or not stroke.get("uv") is Array or stroke.uv.size() != points.size():
				return "Atribut titik brush tidak lengkap."
			if not valid_number(stroke.get("uv_length"), 1e12) or stroke.uv_length <= 0:
				return "Panjang tekstur brush tidak valid."
			var previous := -1.0
			for i in points.size():
				if not valid_vector(stroke.normals[i]):
					return "Normal brush tidak valid."
				var n := Vector3(stroke.normals[i][0], stroke.normals[i][1], stroke.normals[i][2])
				if absf(n.length() - 1.0) > 0.01:
					return "Normal brush harus satuan."
				var u: Variant = stroke.uv[i]
				if not valid_number(u, 1e12) or u < 0 or u < previous or u > stroke.uv_length + maxf(0.001, stroke.uv_length * 0.00001):
					return "Koordinat tekstur brush tidak valid."
				previous = u
	if data.version >= 2:
		var guide_issue := validate_guides(data)
		if not guide_issue.is_empty():
			return guide_issue
	if data.version >= 5:
		var sequence_issue := validate_sequence(data)
		if not sequence_issue.is_empty():
			return sequence_issue
	if data.version >= 6:
		return validate_environment(data)
	return ""

static func valid_color(value: Variant) -> bool:
	return value is Array and value.size() == 3 and valid_number(value[0], 1) and valid_number(value[1], 1) and valid_number(value[2], 1) and value[0] >= 0 and value[1] >= 0 and value[2] >= 0

static func validate_environment(data: Dictionary) -> String:
	var env: Variant = data.get("environment")
	if not env is Dictionary:
		return "Data environment tidak valid."
	for key in ["axis", "grid", "fog", "shadow", "glow", "grain", "pixel"]:
		if not env.get(key) is bool:
			return "Toggle environment tidak valid."
	if not valid_color(env.get("bg_color")) or not valid_color(env.get("light_color")):
		return "Warna environment tidak valid."
	var image: Variant = env.get("bg_image")
	if not image is String or image.length() > MAX_BG_IMAGE_CHARS:
		return "Gambar latar environment tidak valid."
	if not image.is_empty() and Marshalls.base64_to_raw(image).is_empty():
		return "Gambar latar environment tidak valid."
	if not valid_number(env.get("light_alt"), 90) or env.light_alt < -90 or env.light_alt > 90:
		return "Arah cahaya tidak valid."
	if not valid_number(env.get("light_az"), 360) or env.light_az < -360 or env.light_az > 360:
		return "Arah cahaya tidak valid."
	if not valid_number(env.get("light_energy"), 4) or env.light_energy < 0:
		return "Kekuatan cahaya tidak valid."
	if not valid_number(env.get("glow_amount"), 2) or env.glow_amount < 0:
		return "Kekuatan glow tidak valid."
	if not valid_number(env.get("grain_amount"), 1) or env.grain_amount < 0:
		return "Kekuatan grain tidak valid."
	if not valid_number(env.get("pixel_scale"), 1) or env.pixel_scale < 0.25 or env.pixel_scale > 1:
		return "Skala pixel tidak valid."
	return ""

static func validate_sequence(data: Dictionary) -> String:
	var sequence: Variant = data.get("sequence")
	if not sequence is Array or sequence.size() > 200:
		return "Sequence data is invalid."
	var ids := {}
	for shot in sequence:
		if not shot is Dictionary:
			return "Sequence shot is invalid."
		var id: Variant = shot.get("id")
		if not valid_number(id) or float(id) != floor(float(id)) or id < 0 or ids.has(int(id)):
			return "Sequence shot ID is invalid or duplicated."
		if not shot.get("name") is String or shot.name.length() > 80:
			return "Sequence shot name is invalid."
		for key in ["target", "position"]:
			if not valid_vector(shot.get(key)):
				return "Sequence camera position is invalid."
		if not valid_number(shot.get("distance"), 100000.0) or shot.distance < 0.01:
			return "Sequence camera distance is invalid."
		if not valid_number(shot.get("yaw"), 1000.0) or not valid_number(shot.get("pitch"), 1000.0):
			return "Sequence camera rotation is invalid."
		if not valid_number(shot.get("fov"), 179.0) or shot.fov <= 0 or shot.fov >= 180:
			return "Sequence camera FOV is invalid."
		if shot.get("projection") not in [0, 1]:
			return "Sequence camera projection is invalid."
		ids[int(id)] = true
	return ""

static func validate_guides(data: Dictionary) -> String:
	var surfaces: Variant = data.get("guides")
	if not surfaces is Array or surfaces.size() > 100:
		return "Daftar guide tidak valid."
	var ids := {}
	var vertex_total := 0
	for surface in surfaces:
		if not surface is Dictionary or surface.get("kind") not in ["plane", "mesh"] or (data.version == 2 and surface.get("kind") != "plane"):
			return "Jenis guide tidak didukung."
		var id: Variant = surface.get("id")
		if not valid_number(id) or float(id) != floor(float(id)) or id < 0 or ids.has(int(id)):
			return "ID guide tidak valid atau duplikat."
		if not surface.get("name") is String or surface.name.length() > 80:
			return "Nama guide tidak valid."
		if not surface.get("saved") is bool or not surface.get("visible") is bool:
			return "Status guide tidak valid."
		if not valid_number(surface.get("opacity"), 0.7) or surface.opacity < 0:
			return "Opacity guide tidak valid."
		if surface.kind == "mesh":
			var issue := validate_mesh(surface)
			if not issue.is_empty():
				return issue
			vertex_total += surface.vertices.size()
			if vertex_total > 200000:
				return "Proyek melebihi 200.000 vertex guide."
			ids[int(id)] = surface
			continue
		var corners: Variant = surface.get("corners")
		if not corners is Array or corners.size() != 4:
			return "Sudut guide tidak valid."
		var points: Array[Vector3] = []
		for point in corners:
			if not valid_vector(point):
				return "Koordinat guide tidak valid."
			points.append(Vector3(point[0], point[1], point[2]))
		var u := points[1] - points[0]
		var v := points[3] - points[0]
		if u.length() < 0.049 or v.length() < 0.049 or absf(u.normalized().dot(v.normalized())) > 0.001:
			return "Bidang guide terlalu kecil atau bukan persegi panjang."
		if points[2].distance_to(points[0] + u + v) > maxf(0.001, (u.length() + v.length()) * 0.0001):
			return "Sudut guide tidak membentuk bidang datar."
		ids[int(id)] = surface
	var active: Variant = data.get("active_guide")
	if not valid_number(active) or float(active) != floor(float(active)) or int(active) < -1:
		return "ID guide aktif tidak valid."
	if int(active) != -1 and (not ids.has(int(active)) or not ids[int(active)].visible):
		return "Guide aktif tidak ditemukan atau tersembunyi."
	for id in ids:
		if not ids[id].saved and id != int(active):
			return "Guide sementara harus aktif."
	return ""

static func validate_mesh(surface: Dictionary) -> String:
	var columns: Variant = surface.get("columns")
	var rows: Variant = surface.get("rows")
	if not valid_number(columns, 256) or columns < 2 or float(columns) != floor(float(columns)) or not valid_number(rows, 64) or rows < 2 or float(rows) != floor(float(rows)):
		return "Ukuran mesh guide tidak valid."
	var vertices: Variant = surface.get("vertices")
	if not vertices is Array or vertices.size() != int(columns) * int(rows):
		return "Jumlah vertex guide tidak valid."
	var points: Array[Vector3] = []
	for point in vertices:
		if not valid_vector(point):
			return "Koordinat mesh guide tidak valid."
		points.append(Vector3(point[0], point[1], point[2]))
	var area := 0.0
	for row in range(int(rows) - 1):
		for col in range(int(columns) - 1):
			var a := row * int(columns) + col
			var u := points[a + 1] - points[a]
			var v := points[a + int(columns)] - points[a]
			area += u.cross(v).length()
	if area < 0.0001:
		return "Garis belum membentuk permukaan guide."
	return ""

static func save_project(path: String, data: Dictionary) -> Error:
	if not validate(data).is_empty():
		return ERR_INVALID_DATA
	var text := encode(data)
	if text.to_utf8_buffer().size() > MAX_BYTES:
		return ERR_OUT_OF_MEMORY
	# Write and close a sibling temporary file before rotating the old file.
	var temporary := path + ".tmp"
	var backup := path + ".bak"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(text)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	var had_original := FileAccess.file_exists(path)
	if had_original:
		if FileAccess.file_exists(backup):
			error = DirAccess.remove_absolute(backup)
			if error != OK:
				return error
		error = DirAccess.rename_absolute(path, backup)
		if error != OK:
			return error
	error = DirAccess.rename_absolute(temporary, path)
	if error != OK and had_original:
		DirAccess.rename_absolute(backup, path)
	return error

static func read_one(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": "File tidak dapat dibuka: " + error_string(FileAccess.get_open_error())}
	if file.get_length() > MAX_BYTES:
		file.close()
		return {"error": "Ukuran proyek melebihi 32 MB."}
	var json := JSON.new()
	var result := json.parse(file.get_as_text())
	file.close()
	if result != OK:
		return {"error": "Isi JSON proyek rusak."}
	var issue := validate(json.data)
	if not issue.is_empty():
		return {"error": issue}
	# JSON has only a number type; normalize IDs before using them as keys.
	if int(json.data.version) == 1:
		json.data.guides = []
		json.data.active_guide = -1
	if not json.data.has("sequence"):
		json.data.sequence = []
	if not json.data.has("environment"):
		json.data.environment = default_environment()
	json.data.version = VERSION
	json.data.active_guide = int(json.data.active_guide)
	for surface in json.data.guides:
		surface.id = int(surface.id)
	json.data.active_group = int(json.data.active_group)
	for group in json.data.groups:
		group.id = int(group.id)
	for stroke in json.data.strokes:
		stroke.group = int(stroke.group)
	return {"error": "", "data": json.data, "recovered": false}

static func load_project(path: String) -> Dictionary:
	var result := read_one(path)
	if result.error.is_empty():
		return result
	if FileAccess.file_exists(path + ".bak"):
		var backup := read_one(path + ".bak")
		if backup.error.is_empty():
			backup.recovered = true
			return backup
	return result
