extends RefCounted

const Store = preload("res://scripts/project_store.gd")

func run(app: Node) -> bool:
	var before: Dictionary = app.document()
	var defaults: Dictionary = Store.default_environment()
	assert(defaults.get("axis") == false and defaults.get("grid") == true)
	assert(defaults.get("fog") == false and defaults.get("pixel_scale") == 1.0)
	assert(app.document().get("version") == Store.VERSION)
	assert(Store.validate(app.document()).is_empty())
	# Version 5 files without environment stay valid and merge to defaults.
	var legacy: Dictionary = before.duplicate(true)
	legacy.erase("environment")
	legacy["version"] = 5
	assert(Store.validate(legacy).is_empty())
	app.apply_environment({})
	assert(app.env_settings.get("grid") == true and app.reference_grid.visible)
	assert(not app.axis_gizmo.visible)
	app.env_set_toggle("axis", true)
	assert(app.axis_gizmo.visible and app.axis_gizmo.mesh.get_surface_count() == 1)
	assert(app.compact_axis_button.button_pressed)
	app.compact_axis_button.button_pressed = false
	app.compact_axis_button.pressed.emit()
	assert(not app.axis_gizmo.visible and not app.env_axis_button.button_pressed)
	app.compact_axis_button.button_pressed = true
	app.compact_axis_button.pressed.emit()
	assert(app.axis_gizmo.visible)
	app.env_set_toggle("grid", false)
	assert(not app.reference_grid.visible)
	app.env_set_toggle("fog", true)
	assert(app.env.fog_enabled and app.env.fog_light_color.is_equal_approx(Color.WHITE))
	app.env_set_toggle("shadow", true)
	assert(app.sun.shadow_enabled)
	app.env_set_toggle("glow", true)
	assert(app.env.glow_enabled)
	app.env_set_toggle("grain", true)
	assert(app.grain_rect.visible)
	app.env_settings["bg_color"] = [0.1, 0.2, 0.3]
	app.apply_background()
	assert(app.env.background_color.is_equal_approx(Color(0.1, 0.2, 0.3)))
	app.env_settings["light_alt"] = 10.0
	app.env_settings["light_az"] = 40.0
	app.apply_light()
	assert(is_equal_approx(app.sun.rotation_degrees.x, -10.0))
	assert(is_equal_approx(app.sun.rotation_degrees.y, 40.0))
	app.env_settings["light_energy"] = 1.5
	app.apply_light()
	assert(is_equal_approx(app.sun.light_energy, 1.5))
	app.env_settings["glow_amount"] = 1.5
	app.apply_glow()
	assert(is_equal_approx(app.env.glow_intensity, 1.5))
	app.env_settings["pixel_scale"] = 0.5
	app.apply_pixel()
	assert(is_equal_approx(app.get_viewport().scaling_3d_scale, 0.5))
	var image := Image.create(4, 4, false, Image.FORMAT_RGB8)
	image.fill(Color.RED)
	app.set_bg_image(image)
	assert(app.bg_quad.visible)
	assert(not str(app.env_settings.get("bg_image")).is_empty())
	assert(Store.validate(app.document()).is_empty())
	app.restore_document(before)
	assert(app.document() == before)
	assert(not app.axis_gizmo.visible and app.reference_grid.visible)
	assert(not app.env.fog_enabled and not app.env.glow_enabled)
	assert(not app.sun.shadow_enabled and not app.grain_rect.visible)
	assert(not app.bg_quad.visible)
	assert(is_equal_approx(app.get_viewport().scaling_3d_scale, 1.0))
	print("ENV PASS: defaults/migration, overlays, background, light, effects, undo restore")
	return true
