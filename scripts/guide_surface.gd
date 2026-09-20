extends MeshInstance3D
## Independent world-space drawing surface. Camera changes never edit its mesh.

var guide_id := 0
var title := "Guide"
var saved := false
var opacity := 0.22
var corners := PackedVector3Array()
var kind := "plane"
var vertices := PackedVector3Array()
var columns := 2
var rows := 2
var index_cache := PackedInt32Array()
var hit_normal := Vector3.BACK

func configure_profile(profile: PackedVector3Array, depth: Vector3) -> void:
	kind = "mesh"
	columns = profile.size()
	rows = 2
	vertices = profile.duplicate()
	for point in profile:
		vertices.append(point + depth)
	rebuild()

func edge_points() -> PackedVector3Array:
	if kind == "plane":
		return PackedVector3Array([corners[0], corners[1]])
	return vertices.slice(0, columns)

func configure_bend(source: MeshInstance3D, path: PackedVector3Array) -> void:
	# Sweep the starting edge along the drawn path; keep that edge fixed.
	var edge: PackedVector3Array = source.edge_points()
	kind = "mesh"
	columns = edge.size()
	rows = path.size()
	vertices.clear()
	for point in path:
		for start in edge:
			vertices.append(start + (point - path[0]))
	rebuild()

func triangle_indices() -> PackedInt32Array:
	if kind == "plane":
		return PackedInt32Array([0, 1, 2, 0, 2, 3])
	var result := PackedInt32Array()
	for row in range(rows - 1):
		for column in range(columns - 1):
			var a := row * columns + column
			var b := a + columns
			result.append_array(PackedInt32Array([a, a + 1, b + 1, a, b + 1, b]))
	return result
var grid := MeshInstance3D.new()
var material := StandardMaterial3D.new()

func _init() -> void:
	add_child(grid)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = false
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	grid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func configure(frame: Transform3D, size: Vector2) -> void:
	kind = "plane"
	corners = PackedVector3Array([
		frame * Vector3(-size.x / 2, -size.y / 2, 0),
		frame * Vector3(size.x / 2, -size.y / 2, 0),
		frame * Vector3(size.x / 2, size.y / 2, 0),
		frame * Vector3(-size.x / 2, size.y / 2, 0)])
	rebuild()

func surface_normal() -> Vector3:
	if kind == "mesh":
		var indices := index_cache
		for i in range(0, indices.size(), 3):
			var normal := (vertices[indices[i + 1]] - vertices[indices[i]]).cross(vertices[indices[i + 2]] - vertices[indices[i]])
			if normal.length_squared() > 0.00000001:
				return normal.normalized()
		return Vector3.UP
	return (corners[1] - corners[0]).cross(corners[3] - corners[0]).normalized()

func center() -> Vector3:
	if kind == "mesh":
		var sum := Vector3.ZERO
		for point in vertices:
			sum += point
		return sum / maxi(1, vertices.size())
	return (corners[0] + corners[1] + corners[2] + corners[3]) / 4

func intersect_ray(origin: Vector3, direction: Vector3) -> Variant:
	if kind == "mesh":
		var indices := index_cache
		var closest: Variant = null
		var best := INF
		for i in range(0, indices.size(), 3):
			var candidate: Variant = Geometry3D.ray_intersects_triangle(origin, direction, vertices[indices[i]], vertices[indices[i + 1]], vertices[indices[i + 2]])
			if candidate != null and origin.distance_squared_to(candidate) < best:
				best = origin.distance_squared_to(candidate)
				closest = candidate
				hit_normal = (vertices[indices[i + 1]] - vertices[indices[i]]).cross(vertices[indices[i + 2]] - vertices[indices[i]]).normalized()
		return closest
	# Query the actual triangles, including their back faces and finite bounds.
	hit_normal = surface_normal()
	if absf(surface_normal().dot(direction)) < 0.0001:
		return null
	var hit: Variant = Geometry3D.ray_intersects_triangle(origin, direction, corners[0], corners[1], corners[2])
	if hit == null:
		hit = Geometry3D.ray_intersects_triangle(origin, direction, corners[0], corners[2], corners[3])
	return hit

func set_opacity(value: float) -> void:
	opacity = clampf(value, 0, 0.7)
	material.albedo_color = Color(0.43, 0.7, 0.77, opacity)
	grid.visible = opacity > 0.001

func rebuild() -> void:
	index_cache = triangle_indices()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices if kind == "mesh" else corners
	arrays[Mesh.ARRAY_INDEX] = index_cache
	var mesh_data := ArrayMesh.new()
	mesh_data.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = mesh_data
	var lines := ImmediateMesh.new()
	var line_material := StandardMaterial3D.new()
	line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_material.vertex_color_use_as_albedo = true
	lines.surface_begin(Mesh.PRIMITIVE_LINES, line_material)
	if kind == "mesh":
		# Sparse cross-lines keep long freehand profiles readable.
		for row in rows:
			lines.surface_set_color(Color("ffb76c") if row == 0 else Color("496771"))
			for column in range(columns - 1):
				lines.surface_add_vertex(vertices[row * columns + column])
				lines.surface_add_vertex(vertices[row * columns + column + 1])
		lines.surface_set_color(Color("496771"))
		for column in range(0, columns, maxi(1, columns / 12)):
			for row in range(rows - 1):
				lines.surface_add_vertex(vertices[row * columns + column])
				lines.surface_add_vertex(vertices[(row + 1) * columns + column])
		lines.surface_end()
		grid.mesh = lines
		set_opacity(opacity)
		return
	for i in range(9):
		var fraction := float(i) / 8
		lines.surface_set_color(Color("496771"))
		lines.surface_add_vertex(corners[0].lerp(corners[1], fraction))
		lines.surface_add_vertex(corners[3].lerp(corners[2], fraction))
		lines.surface_add_vertex(corners[0].lerp(corners[3], fraction))
		lines.surface_add_vertex(corners[1].lerp(corners[2], fraction))
	lines.surface_set_color(Color("ffb76c"))
	lines.surface_add_vertex(corners[0])
	lines.surface_add_vertex(corners[1])
	lines.surface_end()
	grid.mesh = lines
	set_opacity(opacity)

func serialize() -> Dictionary:
	var points := []
	for point in (vertices if kind == "mesh" else corners):
		points.append([point.x, point.y, point.z])
	if kind == "mesh":
		return {"id": guide_id, "name": title, "kind": kind, "vertices": points, "columns": columns, "rows": rows,
			"saved": saved, "visible": visible, "opacity": opacity}
	return {"id": guide_id, "name": title, "kind": "plane", "corners": points,
		"saved": saved, "visible": visible, "opacity": opacity}

func restore(data: Dictionary) -> void:
	guide_id = int(data.id)
	title = data.name
	saved = data.saved
	visible = data.visible
	opacity = data.opacity
	kind = data.kind
	if kind == "mesh":
		columns = int(data.columns)
		rows = int(data.rows)
		vertices.clear()
		for point in data.vertices:
			vertices.append(Vector3(point[0], point[1], point[2]))
		rebuild()
		return
	corners.clear()
	for point in data.corners:
		corners.append(Vector3(point[0], point[1], point[2]))
	rebuild()
