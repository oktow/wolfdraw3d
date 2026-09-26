extends MeshInstance3D
## A stroke retains world-space samples; changing the guide never moves old ink.

var points := PackedVector3Array()
var radius := 0.035
var ink := Color("73e6bb")
var plane_normal := Vector3.BACK
var group_id := 0
var brush_kind := "tube"
var opacity := 1.0
var taper := 0.15
var sample_normals := PackedVector3Array()
var path_uv := PackedFloat32Array()
var uv_length := 0.0
var nib_angle := deg_to_rad(45.0)
const NIB_THIN := 0.15
# Coloring brush: one merged fill made of 2D-projected polygons. `points`
# stays a copy of the first polygon boundary for bounds/selection helpers.
var paint_polys: Array = []
var bounds := AABB()
var defer_rebuild := false
var last_rebuild_msec := -100000

func copy_brush(source: MeshInstance3D, samples: PackedFloat32Array) -> void:
	if source.brush_kind == "paint":
		brush_kind = "paint"
		paint_polys = source.paint_polys.duplicate(true)
		opacity = source.opacity
		return
	brush_kind = source.brush_kind
	opacity = source.opacity
	taper = source.taper
	uv_length = source.uv_length
	nib_angle = source.nib_angle
	if brush_kind == "tube":
		return
	for sample in samples:
		var a := mini(int(floor(sample)), source.points.size() - 2)
		var t := clampf(sample - a, 0, 1)
		var normal: Vector3 = source.sample_normals[a].lerp(source.sample_normals[a + 1], t)
		sample_normals.append(normal.normalized() if normal.length_squared() > 0.001 else source.sample_normals[a])
		path_uv.append(lerpf(source.path_uv[a], source.path_uv[a + 1], t))

func rebuild_ink() -> void:
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var previous_side := Vector3.ZERO
	for i in points.size():
		var tangent := (points[mini(i + 1, points.size() - 1)] - points[maxi(0, i - 1)]).normalized()
		var normal := sample_normals[i]
		var side := tangent.cross(normal).normalized()
		if side.length_squared() < 0.01:
			side = previous_side if previous_side.length_squared() > 0.01 else normal.cross(Vector3.RIGHT).normalized()
		if previous_side.length_squared() > 0 and side.dot(previous_side) < 0:
			side = -side
		previous_side = side
		var fraction := path_uv[i] / maxf(uv_length, 0.0001)
		var width := 1.0 if taper <= 0 or brush_kind == "flat" else clampf(minf(fraction, 1.0 - fraction) / taper, 0.08, 1.0)
		if brush_kind == "marker":
			# Flat calligraphy nib: full width when moving across the nib
			# edge, thin when moving along it. Nib lives in the guide plane
			# so orbiting never changes the baked shape.
			var up_ref := Vector3.UP if absf(plane_normal.y) < 0.9 else Vector3.RIGHT
			var bx := plane_normal.cross(up_ref).normalized()
			var by := bx.cross(plane_normal).normalized()
			var nib := bx * cos(nib_angle) + by * sin(nib_angle)
			var across: float = tangent.cross(nib).length()
			width *= NIB_THIN + (1.0 - NIB_THIN) * clampf(across, 0.0, 1.0)
		# Local guide normals orient the strip; a tiny lift avoids coplanar flicker.
		var center := points[i] + normal * 0.001
		verts.append(center - side * radius * width)
		verts.append(center + side * radius * width)
		uvs.append(Vector2(path_uv[i], 0))
		uvs.append(Vector2(path_uv[i], 1))
		if i > 0:
			var a := (i - 1) * 2
			indices.append_array(PackedInt32Array([a,a+1,a+2,a+1,a+3,a+2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = result
	if not material_override is ShaderMaterial:
		var material := ShaderMaterial.new()
		material.shader = preload("res://scripts/ink.gdshader")
		material_override = material
	material_override.set_shader_parameter("ink_color", ink)
	material_override.set_shader_parameter("opacity", opacity)
	material_override.set_shader_parameter("brush_mode", 1 if brush_kind == "pencil" else (2 if brush_kind == "brush" else 0))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func rebuild_fill() -> void:
	if points.size() < 3:
		return
	var center := Vector3.ZERO
	for point in points:
		center += point
	center /= float(points.size())
	var normal := plane_normal.normalized() if plane_normal.length_squared() > 0.01 else Vector3.BACK
	var basis_x := normal.cross(Vector3.UP)
	if basis_x.length_squared() < 0.01:
		basis_x = normal.cross(Vector3.RIGHT)
	basis_x = basis_x.normalized()
	var basis_y := normal.cross(basis_x).normalized()
	var polygon := PackedVector2Array()
	for point in points:
		var delta := point - center
		polygon.append(Vector2(delta.dot(basis_x), delta.dot(basis_y)))
	var triangles := Geometry2D.triangulate_polygon(polygon)
	if triangles.is_empty():
		return
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for point in points:
		vertices.append(point + normal * 0.001)
		normals.append(normal)
		uvs.append(Vector2(0.5, 0.5))
	for index in triangles:
		indices.append(int(index))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = result
	if not material_override is ShaderMaterial:
		var material := ShaderMaterial.new()
		material.shader = preload("res://scripts/ink.gdshader")
		material_override = material
	material_override.set_shader_parameter("ink_color", ink)
	material_override.set_shader_parameter("opacity", opacity)
	material_override.set_shader_parameter("brush_mode", 0)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func smooth_points() -> void:
	# One conservative pass, preserving endpoints and staying on the same plane.
	if points.size() < 3:
		return
	var result := points.duplicate()
	for i in range(1, points.size() - 1):
		result[i] = points[i - 1] * 0.15 + points[i] * 0.7 + points[i + 1] * 0.15
	points = result
	rebuild()

func apply_ink(rgb: Color) -> void:
	ink = Color(rgb.r, rgb.g, rgb.b, ink.a)
	if material_override is ShaderMaterial:
		material_override.set_shader_parameter("ink_color", ink)
	elif material_override is StandardMaterial3D:
		var fixed: Color = material_override.albedo_color
		material_override.albedo_color = Color(rgb.r, rgb.g, rgb.b, fixed.a)

func set_selected(selected: bool) -> void:
	if material_override is ShaderMaterial:
		material_override.set_shader_parameter("selected", selected)
		return
	if material_override != null:
		material_override.emission_enabled = selected
		material_override.emission = Color("ffc570")
		material_override.emission_energy_multiplier = 0.65

func serialize() -> Dictionary:
	var samples := []
	for point in points:
		samples.append([point.x, point.y, point.z])
	var data := {"points": samples, "radius": radius, "color": [ink.r, ink.g, ink.b, ink.a],
		"normal": [plane_normal.x, plane_normal.y, plane_normal.z], "group": group_id}
	if brush_kind == "paint":
		var polys := []
		for poly in paint_polys:
			var ring := []
			for point in poly:
				ring.append([point.x, point.y, point.z])
			polys.append(ring)
		data.merge({"brush": "paint", "opacity": opacity, "paint": polys})
		return data
	if brush_kind != "tube":
		var normals := []
		for normal in sample_normals:
			normals.append([normal.x, normal.y, normal.z])
		data.merge({"brush": brush_kind, "opacity": opacity, "taper": taper, "normals": normals, "uv": Array(path_uv), "uv_length": uv_length})
		if brush_kind == "marker":
			data["nib"] = nib_angle
	return data

func restore(data: Dictionary) -> void:
	points.clear()
	for point in data.points:
		points.append(Vector3(point[0], point[1], point[2]))
	radius = data.radius
	ink = Color(data.color[0], data.color[1], data.color[2], data.color[3])
	plane_normal = Vector3(data.normal[0], data.normal[1], data.normal[2])
	group_id = int(data.group)
	brush_kind = data.get("brush", "tube")
	if brush_kind == "paint":
		paint_polys.clear()
		for poly in data.get("paint", []):
			var ring := PackedVector3Array()
			for point in poly:
				ring.append(Vector3(point[0], point[1], point[2]))
			if ring.size() >= 3:
				paint_polys.append(ring)
	nib_angle = float(data.get("nib", deg_to_rad(45.0)))
	opacity = data.get("opacity", 1.0)
	taper = data.get("taper", 0.15)
	uv_length = data.get("uv_length", 0.0)
	path_uv = PackedFloat32Array(data.get("uv", []))
	sample_normals.clear()
	for normal in data.get("normals", []):
		sample_normals.append(Vector3(normal[0], normal[1], normal[2]))
	rebuild()

func add_point(point: Vector3, normal: Vector3 = Vector3.ZERO) -> void:
	if not points.is_empty() and points[-1].distance_to(point) < radius * 0.35:
		return
	if brush_kind != "tube":
		if not points.is_empty():
			uv_length += points[-1].distance_to(point) / (radius * 2)
		path_uv.append(uv_length)
		sample_normals.append(normal.normalized() if normal.length_squared() > 0.1 else plane_normal)
	points.append(point)
	# Live strokes accumulate dozens of samples per frame; rebuilding the
	# whole mesh for each is O(N^2) per stroke. While drawing, at most one
	# rebuild per frame (~33ms); finish paths rebuild explicitly.
	if defer_rebuild and Time.get_ticks_msec() - last_rebuild_msec < 33:
		return
	rebuild()

func rebuild_paint() -> void:
	# One flat mesh for every merged polygon; same lift as fills so stacked
	# same-color paint never shows per-stroke seams.
	if paint_polys.is_empty():
		return
	var normal := plane_normal.normalized() if plane_normal.length_squared() > 0.01 else Vector3.BACK
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for poly in paint_polys:
		var ring: PackedVector3Array = poly
		if ring.size() < 3:
			continue
		var basis_x := normal.cross(Vector3.UP)
		if basis_x.length_squared() < 0.01:
			basis_x = normal.cross(Vector3.RIGHT)
		basis_x = basis_x.normalized()
		var basis_y := normal.cross(basis_x).normalized()
		var flat := PackedVector2Array()
		for point in ring:
			flat.append(Vector2((point - ring[0]).dot(basis_x), (point - ring[0]).dot(basis_y)))
		var triangles := Geometry2D.triangulate_polygon(flat)
		if triangles.is_empty():
			continue
		var base := vertices.size()
		for point in ring:
			vertices.append(point + normal * 0.001)
			normals.append(normal)
			uvs.append(Vector2(0.5, 0.5))
		for index in triangles:
			indices.append(base + int(index))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = result
	if not material_override is ShaderMaterial:
		var material := ShaderMaterial.new()
		material.shader = preload("res://scripts/ink.gdshader")
		material_override = material
	material_override.set_shader_parameter("ink_color", ink)
	material_override.set_shader_parameter("opacity", opacity)
	material_override.set_shader_parameter("brush_mode", 0)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func rebuild() -> void:
	last_rebuild_msec = Time.get_ticks_msec()
	if brush_kind == "paint":
		rebuild_paint()
		bounds = mesh.get_aabb() if mesh != null else AABB()
		return
	if points.size() < 2:
		bounds = AABB()
		return
	if brush_kind == "lasso_fill" or brush_kind == "rectangle_fill":
		rebuild_fill()
		bounds = mesh.get_aabb() if mesh != null else AABB()
		return
	if brush_kind != "tube":
		rebuild_ink()
		bounds = mesh.get_aabb() if mesh != null else AABB()
		return
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	const SIDES := 8
	for i in points.size():
		var tangent: Vector3
		if i == 0:
			tangent = (points[1] - points[0]).normalized()
		elif i == points.size() - 1:
			tangent = (points[i] - points[i - 1]).normalized()
		else:
			tangent = (points[i + 1] - points[i - 1]).normalized()
		if tangent.length_squared() < 0.1:
			tangent = (points[i] - points[maxi(i - 1, 0)]).normalized()
		var reference := plane_normal
		if absf(tangent.dot(reference)) > 0.95:
			reference = Vector3.UP if absf(tangent.y) < 0.9 else Vector3.RIGHT
		var side := tangent.cross(reference).normalized()
		var ring_normal := side.cross(tangent).normalized()
		for j in SIDES:
			var angle := TAU * j / SIDES
			var normal := side * cos(angle) + ring_normal * sin(angle)
			vertices.append(points[i] + normal * radius)
			normals.append(normal)
			if i > 0:
				var a := (i - 1) * SIDES + j
				var b := (i - 1) * SIDES + (j + 1) % SIDES
				var c := i * SIDES + j
				var d := i * SIDES + (j + 1) % SIDES
				indices.append_array(PackedInt32Array([a, c, b, b, c, d]))
	# Close both ends so strokes remain solid when viewed along their direction.
	for end in 2:
		var sample := 0 if end == 0 else points.size() - 1
		var center := vertices.size()
		vertices.append(points[sample])
		normals.append((points[0] - points[1]).normalized() if end == 0 else (points[-1] - points[-2]).normalized())
		for j in SIDES:
			indices.append_array(PackedInt32Array([center, sample * SIDES + j, sample * SIDES + (j + 1) % SIDES]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = result
	bounds = mesh.get_aabb()
	if material_override == null:
		var material := StandardMaterial3D.new()
		material.albedo_color = ink
		material.roughness = 0.65
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material_override = material
