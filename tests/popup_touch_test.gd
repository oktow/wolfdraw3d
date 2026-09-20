extends RefCounted

func tap(app: Node, point: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.position = point
	press.pressed = true
	Input.parse_input_event(press)
	await app.get_tree().create_timer(0.15).timeout
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.position = point
	release.pressed = false
	Input.parse_input_event(release)
	await app.get_tree().create_timer(0.15).timeout

func run(app: Node) -> bool:
	app.get_viewport().gui_embed_subwindows = true
	assert(Input.emulate_mouse_from_touch)
	var before: Dictionary = app.document()
	await tap(app, app.projection_picker.get_global_rect().get_center())
	var popup: PopupMenu = app.projection_picker.get_popup()
	assert(popup.visible, "Touch opens projection popup")
	await tap(app, Vector2(popup.position) + Vector2(popup.size.x * 0.5, popup.size.y * 0.75))
	assert(not popup.visible and app.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Touch selects ortho and dismisses popup")
	await tap(app, app.projection_picker.get_global_rect().get_center())
	await tap(app, Vector2(popup.position) + Vector2(popup.size.x * 0.5, popup.size.y * 0.25))
	assert(not popup.visible and app.camera.projection == Camera3D.PROJECTION_PERSPECTIVE)
	await tap(app, app.view_menu.get_global_rect().get_center())
	popup = app.view_menu.get_popup()
	assert(popup.visible)
	await tap(app, Vector2(popup.position) + Vector2(popup.size.x * 0.5, popup.size.y * 0.25))
	assert(not popup.visible and app.camera.basis.z.is_equal_approx(Vector3.UP))
	assert(app.touches.is_empty() and app.document() == before)
	# Raw touch still navigates exactly once when mouse emulation is enabled.
	var yaw_before: float = app.yaw
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.position = Vector2(640, 400)
	press.pressed = true
	Input.parse_input_event(press)
	await app.get_tree().create_timer(0.1).timeout
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(680, 400)
	drag.relative = Vector2(40, 0)
	Input.parse_input_event(drag)
	await app.get_tree().create_timer(0.1).timeout
	press.pressed = false
	press.position = drag.position
	Input.parse_input_event(press)
	await app.get_tree().create_timer(0.1).timeout
	assert(is_equal_approx(app.yaw, yaw_before - 40 * 0.007))
	assert(app.touches.is_empty() and app.document() == before)
	# Emulated mouse cannot start or commit an extra canvas operation.
	app.set_tool("erase")
	var event := InputEventMouseButton.new()
	event.device = InputEvent.DEVICE_ID_EMULATION
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = Vector2(640, 400)
	app._unhandled_input(event)
	assert(not app.eraser.dragging)
	print("POPUP TOUCH PASS: real input pipeline opens/selects ortho, perspective, snap; no stuck touches or emulated canvas edits")
	return true
