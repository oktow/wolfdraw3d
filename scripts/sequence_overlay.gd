extends Control

var thirds_enabled := false
var info_enabled := false
var app: Node

func setup(owner: Node) -> void:
	app = owner
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()

func _draw() -> void:
	if thirds_enabled:
		var size := get_viewport_rect().size
		var color := Color(0.2, 0.35, 0.4, 0.45)
		draw_line(Vector2(size.x / 3.0, 0), Vector2(size.x / 3.0, size.y), color, 1.0)
		draw_line(Vector2(size.x * 2.0 / 3.0, 0), Vector2(size.x * 2.0 / 3.0, size.y), color, 1.0)
		draw_line(Vector2(0, size.y / 3.0), Vector2(size.x, size.y / 3.0), color, 1.0)
		draw_line(Vector2(0, size.y * 2.0 / 3.0), Vector2(size.x, size.y * 2.0 / 3.0), color, 1.0)

func set_thirds(value: bool) -> void:
	thirds_enabled = value
	queue_redraw()

func set_info(value: bool) -> void:
	info_enabled = value
	queue_redraw()

func _process(_delta: float) -> void:
	if info_enabled and app != null:
		queue_redraw()

