extends RefCounted
const Localization = preload("res://scripts/localization.gd")
const HOLD_SECONDS := 0.9
## Screen-space fitting, followed by transactional projection back onto the guide.
var app: Node3D
var mode := "off"
var drawing := false
var guide_target := false
var locked := false
var idle := 0.0
var anchor := Vector2.ZERO
var pointer := Vector2.ZERO
var held_at := Vector2.ZERO
var raw := PackedVector2Array()
var model: Dictionary = {}
var corrected := false

func _init(app_node: Node3D) -> void:
	app = app_node

func begin(screen: Vector2, on_guide: bool) -> void:
	cancel()
	# Guide creation always arms the hold gesture; ink strokes obey the mode.
	if mode == "off" and not on_guide:
		return
	drawing = true
	guide_target = on_guide
	raw = PackedVector2Array([screen])
	anchor = screen
	pointer = screen

func cancel() -> void:
	drawing = false
	locked = false
	idle = 0
	corrected = false
	model = {}

func move(screen: Vector2) -> bool:
	if not drawing:
		return false
	pointer = screen
	if locked:
		var adjusted := model.duplicate(true)
		var delta := screen - held_at
		if model.kind == "line":
			adjusted.end = screen
		elif model.kind == "curve":
			var points: PackedVector2Array = model.path.duplicate()
			for i in points.size():
				points[i] += delta * sin(PI * i / (points.size() - 1)) * 1.5
			adjusted.path = points
		elif model.get("from_center", false):
			adjusted.radii = Vector2.ONE * maxf(2, screen.distance_to(model.center))
		else:
			var local := delta.rotated(-model.angle)
			if model.kind == "circle":
				var radius_delta: float = screen.distance_to(model.center) - held_at.distance_to(model.center)
				adjusted.radii = Vector2.ONE * maxf(2, model.radii.x + radius_delta)
			else:
				adjusted.radii = Vector2(maxf(2, model.radii.x + local.x), maxf(2, model.radii.y + local.y))
		apply_path(sample(adjusted))
		return true
	if screen.distance_to(anchor) > 5:
		anchor = screen
		idle = 0
	if raw[-1].distance_to(screen) >= 2:
		raw.append(screen)
		if raw.size() > 1024:
			raw = resample(raw, 512)
	return false

func tick(delta: float) -> void:
	if not drawing or locked:
		return
	idle += delta
	if idle < HOLD_SECONDS:
		return
	if raw.size() < 3 and raw[0].distance_to(pointer) < 8 and not guide_target:
		model = {"kind": "circle", "center": raw[0], "radii": Vector2(2,2), "angle": 0.0, "from_center": true}
	else:
		# A held guide creation auto-fits like ink: straight lines, curves,
		# and near-closed loops each keep their natural shape.
		var requested := "auto" if guide_target and mode == "off" else mode
		model = fit(raw, requested)
	if model.is_empty():
		return
	held_at = pointer
	locked = true
	if apply_path(sample(model)):
		app.status.text = Localization.translate("Draw Shape: tahan aktif — geser untuk mengatur bentuk, lepas untuk selesai.")

func finalize() -> void:
	if not drawing:
		return
	# Releasing early leaves the freehand stroke intact. Only holding triggers fitting.
	drawing = false

func apply_path(path: PackedVector2Array) -> bool:
	if path.size() < 2:
		return false
	var world := PackedVector3Array()
	var normals := PackedVector3Array()
	for screen in path:
		var hit: Variant = app.guides.plane_hit(screen) if guide_target else app.hit_point(screen)
		if hit == null:
			app.status.text = Localization.translate("Koreksi keluar batas guide; bentuk sebelumnya dipertahankan.")
			return false
		world.append(hit)
		if not guide_target:
			normals.append(app.guides.current().hit_normal)
	var length := 0.0
	for i in range(1, world.size()):
		length += world[i - 1].distance_to(world[i])
	if length < 0.0001:
		app.status.text = Localization.translate("Bentuk terlalu kecil; goresan sebelumnya dipertahankan.")
		return false
	if guide_target:
		var preview = app.guides.preview
		if preview == null:
			return false
		# Bend is capped at 64 rows by the project format.
		if app.guides.creation_mode == "bend":
			preview.configure_bend(app.guides.current(), world)
		else:
			var centered: bool = app.guides.creation_mode == "profile" or app.guides.creation_mode == "curve"
			preview.configure_profile(world, -app.guides.creation_frame.basis.z * app.guides.sweep_length, centered)
		preview.show()
		app.guides.profile = world
	else:
		if app.active == null or app.sample_count() + world.size() > app.Store.MAX_POINTS:
			return false
		app.active.points = world
		app.active.sample_normals = normals
		app.active.path_uv.clear()
		app.active.uv_length = 0
		for i in world.size():
			if i > 0:
				app.active.uv_length += world[i - 1].distance_to(world[i]) / (app.active.radius * 2)
			app.active.path_uv.append(app.active.uv_length)
		# A closed shape has no free endpoints to taper.
		if world[0].distance_to(world[-1]) < 0.001:
			app.active.taper = 0
		app.active.rebuild()
	corrected = true
	return true

static func resample(points: PackedVector2Array, count: int) -> PackedVector2Array:
	var lengths := PackedFloat32Array([0.0])
	for i in range(1, points.size()):
		lengths.append(lengths[-1] + points[i - 1].distance_to(points[i]))
	var result := PackedVector2Array()
	var segment := 0
	for i in count:
		var distance := lengths[-1] * i / (count - 1)
		while segment < points.size() - 2 and lengths[segment + 1] < distance:
			segment += 1
		var t := (distance - lengths[segment]) / maxf(0.00001, lengths[segment + 1] - lengths[segment])
		result.append(points[segment].lerp(points[segment + 1], t))
	return result

static func fit(points: PackedVector2Array, requested: String = "auto") -> Dictionary:
	if points.size() < 2:
		return {}
	var start := points[0]
	var end := points[-1]
	var length := 0.0
	var deviation := 0.0
	for i in range(1, points.size()):
		length += points[i - 1].distance_to(points[i])
		deviation = maxf(deviation, points[i].distance_to(Geometry2D.get_closest_point_to_segment(points[i], start, end)))
	if length < 8:
		return {}
	if requested == "line" or (requested == "auto" and length < start.distance_to(end) * 1.6 and deviation < maxf(4, start.distance_to(end) * 0.12)):
		return {"kind": "line", "start": start, "end": end}
	var uniform := resample(points, 64)
	var mean := Vector2.ZERO
	for point in uniform:
		mean += point
	mean /= uniform.size()
	var xx := 0.0
	var yy := 0.0
	var xy := 0.0
	for point in uniform:
		var d := point - mean
		xx += d.x * d.x
		yy += d.y * d.y
		xy += d.x * d.y
	var angle := 0.5 * atan2(2 * xy, xx - yy)
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for point in uniform:
		var p := (point - mean).rotated(-angle)
		low = low.min(p)
		high = high.max(p)
	var radii := (high - low) / 2
	var center := mean + ((high + low) / 2).rotated(angle)
	if requested in ["circle", "ellipse"]:
		if requested == "circle" and minf(radii.x, radii.y) <= 3:
			radii = Vector2.ONE * maxf(radii.x, radii.y)
		radii = radii.max(Vector2(4,4))
	var error := 0.0
	var winding := 0.0
	var previous_angle := 0.0
	if minf(radii.x, radii.y) > 3:
		for i in uniform.size():
			var local := (uniform[i] - center).rotated(-angle) / radii
			error += absf(local.length() - 1)
			if i > 0:
				winding += wrapf(local.angle() - previous_angle, -PI, PI)
			previous_angle = local.angle()
		var closed := start.distance_to(end) < maxf(15, radii.length() * 0.5)
		if requested in ["circle", "ellipse"] or (requested == "auto" and closed and error / 64 < 0.18 and absf(winding) > 5):
			var kind := "circle" if requested == "circle" or (requested == "auto" and maxf(radii.x, radii.y) / minf(radii.x, radii.y) < 1.5) else "ellipse"
			if kind == "circle":
				radii = Vector2.ONE * (radii.x + radii.y) / 2
			return {"kind": kind, "center": center, "radii": radii, "angle": angle}
	# Least-squares quadratic curve with fixed endpoints; preserve more complex paths.
	var control := Vector2.ZERO
	var denominator := 0.0
	for i in range(1, 63):
		var t := i / 63.0
		var weight := 2 * (1 - t) * t
		control += (uniform[i] - start * pow(1 - t, 2) - end * t * t) * weight
		denominator += weight * weight
	control /= maxf(denominator, 0.0001)
	var path := PackedVector2Array()
	var curve_error := 0.0
	for i in 64:
		var t := i / 63.0
		var point := start * pow(1 - t, 2) + control * 2 * (1 - t) * t + end * t * t
		path.append(point)
		curve_error = maxf(curve_error, point.distance_to(uniform[i]))
	if curve_error > maxf(10, length * 0.1):
		path = uniform.duplicate()
		for pass_index in 3:
			var smoothed := path.duplicate()
			for i in range(1, 63):
				smoothed[i] = path[i - 1] * 0.25 + path[i] * 0.5 + path[i + 1] * 0.25
			path = smoothed
	return {"kind": "curve", "path": path}

static func sample(shape: Dictionary) -> PackedVector2Array:
	if shape.kind == "curve":
		return shape.path
	var result := PackedVector2Array()
	for i in 64:
		var t := i / 63.0
		if shape.kind == "line":
			result.append(shape.start.lerp(shape.end, t))
		else:
			var angle := TAU * t
			result.append(shape.center + (Vector2(cos(angle), sin(angle)) * shape.radii).rotated(shape.angle))
	return result
