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
var bounds := AABB()
var selected_verts: Array[int] = []
var selected_edges: Array = []
var selected_faces: Array[int] = []
var highlight_offset := Vector3.ZERO
# Uniform-grid spatial index for dense meshes (built in rebuild, used by
# intersect_ray). Small meshes keep the plain linear scan.
const GRID_TRI_THRESHOLD := 1500
var grid_cells := {}
var grid_origin := Vector3.ZERO
var grid_step := Vector3.ONE
var grid_dims := Vector3i.ONE

func configure_profile(profile: PackedVector3Array, depth: Vector3, centered := false) -> void:
	kind = "mesh"
	columns = profile.size()
	rows = 2
	# Centered: the drawn line sits mid-surface (cursor = median).
	var shift := -depth / 2.0 if centered else Vector3.ZERO
	vertices.clear()
	for point in profile:
		vertices.append(point + shift)
	for point in profile:
		vertices.append(point + shift + depth)
	rebuild()

func configure_loft(profiles: Array[PackedVector3Array], tension: float = 0.5) -> void:
	kind = "mesh"
	rows = profiles.size()
	columns = 0
	for profile in profiles:
		columns = maxi(columns, profile.size())
	columns = clampi(columns, 2, 256)
	var sampled_profiles: Array[PackedVector3Array] = []
	for profile in profiles:
		sampled_profiles.append(_resample_profile(profile, columns))
	vertices.clear()
	for row in profiles.size():
		var sampled: PackedVector3Array = sampled_profiles[row]
		for index in sampled.size():
			var point: Vector3 = sampled[index]
			if tension > 0.0 and profiles.size() > 2:
				if row > 0 and row < profiles.size() - 1:
					var before := sampled_profiles[row - 1][index]
					var after := sampled_profiles[row + 1][index]
					point = point.lerp((before + point + after) / 3.0, clampf(tension, 0.0, 1.0) * 0.35)
			vertices.append(point)
	rebuild()

func _resample_profile(profile: PackedVector3Array, count: int) -> PackedVector3Array:
	if profile.size() <= 2:
		return profile
	var lengths := PackedFloat32Array()
	lengths.resize(profile.size())
	var total := 0.0
	for index in range(1, profile.size()):
		total += profile[index - 1].distance_to(profile[index])
		lengths[index] = total
	var result := PackedVector3Array()
	var segment := 1
	for target_index in count:
		var target := total * float(target_index) / float(count - 1)
		while segment < lengths.size() - 1 and lengths[segment] < target:
			segment += 1
		var span := lengths[segment] - lengths[segment - 1]
		var amount := 0.0 if span <= 0.00001 else (target - lengths[segment - 1]) / span
		result.append(profile[segment - 1].lerp(profile[segment], amount))
	return result

func edge_points() -> PackedVector3Array:
	if kind == "plane":
		return PackedVector3Array([corners[0], corners[1]])
	return vertices.slice(0, columns)

func configure_cube(center: Vector3, basis: Basis, edge: float) -> void:
	# Camera-facing box stored as a 5x4 grid: cap fans use repeated apex
	# vertices (degenerate half-quads) so existing grid triangulation,
	# validation, and save/load keep working unchanged.
	kind = "mesh"
	columns = 5
	rows = 4
	var h := edge / 2.0
	var x: Vector3 = basis.x.normalized() * h
	var y: Vector3 = basis.y.normalized() * h
	var z: Vector3 = basis.z.normalized() * h
	var front := center + z
	var back := center - z
	var t := [front - x - y, front + x - y, front + x + y, front - x + y]
	var b := [back - x - y, back + x - y, back + x + y, back - x + y]
	vertices.clear()
	for i in 5:
		vertices.append(front)
	for point in t:
		vertices.append(point)
	vertices.append(t[0])
	for point in b:
		vertices.append(point)
	vertices.append(b[0])
	for i in 5:
		vertices.append(back)
	rebuild()

func configure_tube(center: Vector3, axis: Vector3, radius: float, length: float, radial_segments: int = 12, length_segments: int = 8) -> void:
	# Closed cylinder with a duplicated seam column so the grid wraps around.
	kind = "mesh"
	var w: Vector3 = axis.normalized()
	var up := Vector3.UP
	if absf(w.dot(up)) > 0.95:
		up = Vector3.RIGHT
	var u: Vector3 = w.cross(up).normalized()
	var v: Vector3 = w.cross(u).normalized()
	columns = clampi(radial_segments + 1, 3, 256)
	rows = clampi(length_segments + 1, 2, 64)
	vertices.clear()
	for row in rows:
		var along: Vector3 = center - w * (length / 2.0) + w * (length * float(row) / float(rows - 1))
		for col in columns:
			var angle := TAU * float(col) / float(columns - 1)
			vertices.append(along + (u * cos(angle) + v * sin(angle)) * radius)
	rebuild()

func configure_line(center: Vector3, basis: Basis, length: float, width: float) -> void:
	# Thin camera-facing strip (ruler edge) that stays drawable.
	kind = "mesh"
	columns = 2
	rows = 2
	var x: Vector3 = basis.x.normalized() * (length / 2.0)
	var y: Vector3 = basis.y.normalized() * (width / 2.0)
	vertices = PackedVector3Array([
		center - x - y, center + x - y,
		center - x + y, center + x + y])
	rebuild()

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

func apply_transform(center: Vector3, rotation: Basis, factor: float, offset: Vector3) -> void:
	if kind == "plane":
		for i in corners.size():
			corners[i] = center + rotation * ((corners[i] - center) * factor) + offset
	else:
		for i in vertices.size():
			vertices[i] = center + rotation * ((vertices[i] - center) * factor) + offset
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
var face_grid := MeshInstance3D.new()
var face_material := StandardMaterial3D.new()
var material := StandardMaterial3D.new()

func _init() -> void:
	add_child(grid)
	add_child(face_grid)
	face_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	face_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	face_material.albedo_color = Color(1.0, 0.77, 0.35, 0.4)
	face_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	face_material.no_depth_test = true
	face_grid.material_override = face_material
	face_grid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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

func ray_hits_bounds(origin: Vector3, direction: Vector3) -> bool:
	if not bounds.has_volume():
		return true
	if bounds.has_point(origin):
		return true
	var tmin := 0.0
	var tmax := INF
	for axis in 3:
		var o := origin[axis]
		var d := direction[axis]
		var lo := bounds.position[axis]
		var hi := lo + bounds.size[axis]
		if absf(d) < 0.0000001:
			if o < lo or o > hi:
				return false
		else:
			var t1 := (lo - o) / d
			var t2 := (hi - o) / d
			tmin = maxf(tmin, minf(t1, t2))
			tmax = minf(tmax, maxf(t1, t2))
			if tmin > tmax:
				return false
	return true

func build_spatial_index() -> void:
	grid_cells.clear()
	if kind != "mesh":
		return
	var tri_count := index_cache.size() / 3
	if tri_count <= GRID_TRI_THRESHOLD:
		return
	var size := bounds.size
	var longest := maxf(size.x, maxf(size.y, size.z))
	if longest < 0.0001:
		return
	var cell := longest / 16.0
	grid_step = Vector3(cell, cell, cell)
	grid_origin = bounds.position
	grid_dims = Vector3i(maxi(1, int(size.x / cell) + 1), maxi(1, int(size.y / cell) + 1), maxi(1, int(size.z / cell) + 1))
	for base in range(0, index_cache.size(), 3):
		var tri_min := vertices[index_cache[base]]
		var tri_max := tri_min
		for k in [1, 2]:
			var vertex: Vector3 = vertices[index_cache[base + k]]
			tri_min = tri_min.min(vertex)
			tri_max = tri_max.max(vertex)
		var cell_min := cell_of(tri_min)
		var cell_max := cell_of(tri_max)
		for x in range(cell_min.x, cell_max.x + 1):
			for y in range(cell_min.y, cell_max.y + 1):
				for z in range(cell_min.z, cell_max.z + 1):
					var key := Vector3i(x, y, z)
					if grid_cells.has(key):
						grid_cells[key].append(base)
					else:
						grid_cells[key] = PackedInt32Array([base])

func cell_of(point: Vector3) -> Vector3i:
	return Vector3i(clampi(int(floor((point.x - grid_origin.x) / grid_step.x)), 0, grid_dims.x - 1), clampi(int(floor((point.y - grid_origin.y) / grid_step.y)), 0, grid_dims.y - 1), clampi(int(floor((point.z - grid_origin.z) / grid_step.z)), 0, grid_dims.z - 1))

func slab_interval(origin: Vector3, direction: Vector3) -> Vector2:
	# Entry/exit distances of the ray through bounds, or (-1, -1) on a miss.
	var tmin := 0.0
	var tmax := INF
	for axis in 3:
		var o := origin[axis]
		var d := direction[axis]
		var lo := bounds.position[axis]
		var hi := lo + bounds.size[axis]
		if absf(d) < 0.0000001:
			if o < lo or o > hi:
				return Vector2(-1, -1)
		else:
			var t1 := (lo - o) / d
			var t2 := (hi - o) / d
			tmin = maxf(tmin, minf(t1, t2))
			tmax = minf(tmax, maxf(t1, t2))
			if tmin > tmax:
				return Vector2(-1, -1)
	return Vector2(tmin, tmax)

func intersect_ray_grid(origin: Vector3, direction: Vector3) -> Array:
	# Ordered voxel walk (Amanatides-Woo): cells nearest the ray origin are
	# tested first, and the walk stops once cells lie beyond the best hit.
	var interval := slab_interval(origin, direction)
	if interval.x < 0.0:
		return [null, -1]
	var point: Vector3 = origin + direction * interval.x
	var cell := cell_of(point)
	var step := Vector3i(1 if direction.x > 0 else -1, 1 if direction.y > 0 else -1, 1 if direction.z > 0 else -1)
	var boundary := Vector3(
		grid_origin.x + (float(cell.x + (1 if step.x > 0 else 0))) * grid_step.x,
		grid_origin.y + (float(cell.y + (1 if step.y > 0 else 0))) * grid_step.y,
		grid_origin.z + (float(cell.z + (1 if step.z > 0 else 0))) * grid_step.z)
	var advance := Vector3(INF, INF, INF)
	var delta := Vector3(INF, INF, INF)
	for axis in 3:
		var d := direction[axis]
		if absf(d) > 0.0000001:
			advance[axis] = (boundary[axis] - point[axis]) / d
			delta[axis] = absf(grid_step[axis] / d)
	var closest: Variant = null
	var best := INF
	var best_base := -1
	var dir_scale := direction.length_squared()
	var guard := 0
	while guard < 4096:
		guard += 1
		if grid_cells.has(cell):
			for base in grid_cells[cell]:
				var b := int(base)
				var candidate: Variant = Geometry3D.ray_intersects_triangle(origin, direction, vertices[index_cache[b]], vertices[index_cache[b + 1]], vertices[index_cache[b + 2]])
				if candidate != null:
					var dist := origin.distance_squared_to(candidate)
					if dist < best:
						closest = candidate
						best = dist
						best_base = b
						hit_normal = (vertices[index_cache[b + 1]] - vertices[index_cache[b]]).cross(vertices[index_cache[b + 2]] - vertices[index_cache[b]]).normalized()
		var next := minf(advance.x, minf(advance.y, advance.z))
		if next > interval.y or (best < INF and next * next * dir_scale > best):
			break
		if advance.x <= advance.y and advance.x <= advance.z:
			cell.x += step.x
			advance.x += delta.x
		elif advance.y <= advance.z:
			cell.y += step.y
			advance.y += delta.y
		else:
			cell.z += step.z
			advance.z += delta.z
		if cell.x < 0 or cell.y < 0 or cell.z < 0 or cell.x >= grid_dims.x or cell.y >= grid_dims.y or cell.z >= grid_dims.z:
			break
	return [closest, best_base]

func intersect_ray_full(origin: Vector3, direction: Vector3) -> Array:
	# [hit point or null, triangle base index into index_cache (mesh) or
	# 0/1 (plane), -1 on a miss]. Powers sub-object picking.
	if kind == "mesh":
		if grid_cells.is_empty():
			if not ray_hits_bounds(origin, direction):
				return [null, -1]
			var indices := index_cache
			var closest: Variant = null
			var best := INF
			var best_base := -1
			for i in range(0, indices.size(), 3):
				var candidate: Variant = Geometry3D.ray_intersects_triangle(origin, direction, vertices[indices[i]], vertices[indices[i + 1]], vertices[indices[i + 2]])
				if candidate != null:
					var dist := origin.distance_squared_to(candidate)
					if dist < best:
						closest = candidate
						best = dist
						best_base = i
						hit_normal = (vertices[indices[i + 1]] - vertices[indices[i]]).cross(vertices[indices[i + 2]] - vertices[indices[i]]).normalized()
			return [closest, best_base]
		return intersect_ray_grid(origin, direction)
	# Query the actual triangles, including their back faces and finite bounds.
	hit_normal = surface_normal()
	if absf(surface_normal().dot(direction)) < 0.0001:
		return [null, -1]
	var hit: Variant = Geometry3D.ray_intersects_triangle(origin, direction, corners[0], corners[1], corners[2])
	if hit != null:
		return [hit, 0]
	hit = Geometry3D.ray_intersects_triangle(origin, direction, corners[0], corners[2], corners[3])
	return [hit, 1 if hit != null else -1]

func intersect_ray(origin: Vector3, direction: Vector3) -> Variant:
	return intersect_ray_full(origin, direction)[0]

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
	bounds = mesh_data.get_aabb()
	build_spatial_index()
	rebuild_grid_lines()
	set_opacity(opacity)

func set_selected_vertices(indices: Array) -> void:
	set_subobj_selection(indices, [], [])

func set_subobj_selection(verts: Array, edges: Array, faces: Array) -> void:
	var clean: Array[int] = []
	var count := vertices.size() if kind == "mesh" else 4
	for i in verts:
		var idx := int(i)
		if idx >= 0 and idx < count and not clean.has(idx):
			clean.append(idx)
	selected_verts = clean
	var clean_edges := []
	for e in edges:
		var pair := Vector2i(e)
		var a := mini(pair.x, pair.y)
		var b := maxi(pair.x, pair.y)
		if a >= 0 and b < count and a != b:
			var key := Vector2i(a, b)
			if not clean_edges.has(key):
				clean_edges.append(key)
	selected_edges = clean_edges
	var clean_faces: Array[int] = []
	var tri_count := (index_cache.size() / 3) if kind == "mesh" else 2
	for f in faces:
		var base := int(f)
		if kind == "mesh":
			if base >= 0 and base % 3 == 0 and base < index_cache.size() and not clean_faces.has(base):
				clean_faces.append(base)
		elif (base == 0 or base == 1) and not clean_faces.has(base):
			clean_faces.append(base)
	selected_faces = clean_faces
	rebuild_grid_lines()

func guide_points() -> PackedVector3Array:
	return vertices if kind == "mesh" else corners

func rebuild_grid_lines() -> void:
	var selected := {}
	for idx in selected_verts:
		selected[idx] = true
	var lines := ImmediateMesh.new()
	var line_material := StandardMaterial3D.new()
	line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_material.vertex_color_use_as_albedo = true
	lines.surface_begin(Mesh.PRIMITIVE_LINES, line_material)
	if kind == "mesh":
		# Sparse cross-lines keep long freehand profiles readable.
		for row in rows:
			for column in range(columns - 1):
				var a := row * columns + column
				lines.surface_set_color(Color("ffc570") if selected.has(a) or selected.has(a + 1) else (Color("ffb76c") if row == 0 else Color("496771")))
				lines.surface_add_vertex(vertices[a])
				lines.surface_add_vertex(vertices[a + 1])
		for column in range(0, columns, maxi(1, columns / 12)):
			for row in range(rows - 1):
				var a := row * columns + column
				lines.surface_set_color(Color("ffc570") if selected.has(a) or selected.has(a + columns) else Color("496771"))
				lines.surface_add_vertex(vertices[a])
				lines.surface_add_vertex(vertices[a + columns])
	else:
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
		for corner in selected:
			var first: Vector3 = corners[corner]
			for neighbor in [(corner + 1) % 4, (corner + 3) % 4]:
				lines.surface_set_color(Color("ffc570"))
				lines.surface_add_vertex(first)
				lines.surface_add_vertex(first.lerp(corners[neighbor], 0.18))
	var points: PackedVector3Array = vertices if kind == "mesh" else corners
	for e in selected_edges:
		var pair := Vector2i(e)
		if pair.y < points.size():
			lines.surface_set_color(Color("ffc570"))
			lines.surface_add_vertex(points[pair.x] + highlight_offset)
			lines.surface_add_vertex(points[pair.y] + highlight_offset)
	lines.surface_end()
	grid.mesh = lines
	rebuild_face_overlay(points)

func rebuild_face_overlay(points: PackedVector3Array) -> void:
	if selected_faces.is_empty():
		face_grid.mesh = null
		face_grid.visible = false
		return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var tris := PackedVector3Array()
	for base in selected_faces:
		var trio: Array[int] = []
		if kind == "mesh":
			trio.assign([index_cache[base], index_cache[base + 1], index_cache[base + 2]])
		else:
			trio.assign([0, 1, 2] if base == 0 else [0, 2, 3])
		for idx in trio:
			if idx >= 0 and idx < points.size():
				tris.append(points[idx] + highlight_offset)
	arrays[Mesh.ARRAY_VERTEX] = tris
	var overlay := ArrayMesh.new()
	overlay.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	face_grid.mesh = overlay
	face_grid.visible = true

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
	selected_verts = []
	selected_edges = []
	selected_faces = []
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
