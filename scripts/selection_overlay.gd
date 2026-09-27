extends Control

var app: Node
var mode := "rectangle"
var active := false
var start := Vector2.ZERO
var current := Vector2.ZERO
var lasso: PackedVector2Array = []
var fill_preview := false
var fill_color := Color("55c2a0")
var liquify_preview := false
var liquify_position := Vector2.ZERO
var liquify_radius := 0.0
var liquify_range := 0.65

func setup(app_node: Node) -> void:
	app = app_node
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 90

func begin_selection(position: Vector2) -> void:
	active = true
	start = position
	current = position
	lasso = PackedVector2Array([position])
	queue_redraw()

func set_fill_preview(value: bool, color: Color = Color("55c2a0")) -> void:
	fill_preview = value
	fill_color = Color(color.r, color.g, color.b, 0.35)
	queue_redraw()

func set_liquify_preview(value: bool, position: Vector2 = Vector2.ZERO, radius: float = 0.0, range_value: float = 0.65) -> void:
	liquify_preview = value
	liquify_position = position
	liquify_radius = radius
	liquify_range = clampf(range_value, 0.05, 1.0)
	queue_redraw()

func update_selection(position: Vector2) -> void:
	if not active:
		return
	current = position
	if (mode == "lasso" or mode == "brush") and (lasso.is_empty() or lasso[-1].distance_to(position) >= 4):
		lasso.append(position)
	queue_redraw()

func end_selection() -> PackedVector2Array:
	if not active:
		return PackedVector2Array()
	active = false
	queue_redraw()
	if mode == "lasso" or mode == "brush":
		return lasso
	return PackedVector2Array([start, current])

func cancel_selection() -> void:
	active = false
	lasso.clear()
	fill_preview = false
	liquify_preview = false
	queue_redraw()

func _draw() -> void:
	if liquify_preview and liquify_radius > 1:
		draw_circle(liquify_position, liquify_radius, Color(0.2, 0.75, 0.65, 0.10))
		draw_arc(liquify_position, liquify_radius, 0, TAU, 64, Color("39a88e"), 2.5, true)
		draw_arc(liquify_position, liquify_radius * liquify_range, 0, TAU, 64, Color("f2c879"), 2.0, true)
		draw_line(liquify_position - Vector2(8, 0), liquify_position + Vector2(8, 0), Color("f2c879"), 1.5, true)
		draw_line(liquify_position - Vector2(0, 8), liquify_position + Vector2(0, 8), Color("f2c879"), 1.5, true)
	if not active:
		return
	if mode == "lasso" or mode == "brush":
		if lasso.size() > 1:
			if fill_preview and lasso.size() > 2:
				draw_colored_polygon(lasso, fill_color)
			var outline := lasso.duplicate()
			if fill_preview and outline.size() > 2:
				outline.append(outline[0])
			draw_polyline(outline, fill_color.darkened(0.2) if fill_preview else Color("55c2a0"), 3, true)
	else:
		var rect := Rect2(start, current - start).abs()
		var color := fill_color if fill_preview else Color(0.25, 0.75, 0.62, 0.14)
		draw_rect(rect, color, true)
		draw_rect(rect, color.darkened(0.2) if fill_preview else Color("55c2a0"), false, 3)
