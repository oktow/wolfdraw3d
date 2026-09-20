extends RefCounted

const Store = preload("res://scripts/project_store.gd")
const GifEncoder = preload("res://scripts/gif_encoder.gd")

func reset(app: Node) -> void:
	app.restore_document({
		"format": Store.FORMAT,
		"version": 5,
		"groups": [{"id": 0, "name": "Grup 1", "visible": true}],
		"active_group": 0,
		"strokes": [],
		"guides": [],
		"active_guide": -1,
		"sequence": []
	})
	app.history.clear()
	app.future.clear()
	app.target = Vector3.ZERO
	app.distance = 12.0
	app.yaw = 0.0
	app.pitch = 0.0
	app.camera.fov = 45.0
	app.camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	app.update_camera()
	app.saved_state = Store.encode(app.document())

func run(app: Node) -> bool:
	reset(app)
	app.add_sequence_shot()
	app.yaw = 0.5
	app.update_camera()
	app.add_sequence_shot()
	app.yaw = 1.0
	app.update_camera()
	app.add_sequence_shot()
	assert(app.sequence.size() == 3, "Sequence must add three shots")
	var first_id: int = app.sequence[0].id
	var second_id: int = app.sequence[1].id
	var third_id: int = app.sequence[2].id
	app.rename_sequence_shot(second_id, "Hero angle")
	assert(app.sequence[1].name == "Hero angle")
	app.toggle_sequence_selection(third_id)
	app.toggle_sequence_selection(second_id)
	app.toggle_sequence_selection(third_id)
	app.set("sequence_selected_id", second_id)
	app.move_sequence_left()
	assert(int(app.sequence[0].id) == second_id and int(app.sequence[1].id) == third_id and int(app.sequence[2].id) == first_id)
	app.move_sequence_right()
	assert(int(app.sequence[0].id) == first_id and int(app.sequence[1].id) == second_id and int(app.sequence[2].id) == third_id)
	var saved: Dictionary = app.document()
	assert(Store.validate(saved).is_empty(), "Sequence document must validate")
	app.sequence.clear()
	app.restore_document(saved)
	assert(app.sequence.size() == 3 and app.sequence[1].name == "Hero angle")
	app.select_sequence_shot(second_id)
	assert(app.sequence_selected_id == second_id)
	app.sequence_playback_index = 0
	app.sequence_playback_progress = 0.5
	app.interpolate_sequence_shot(app.sequence[0], app.sequence[1], 0.5)
	assert(is_equal_approx(app.yaw, 0.25), "Sequence interpolation must update camera")
	app.delete_sequence_shot(second_id)
	assert(app.sequence.size() == 2)
	var sample := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	sample.fill(Color("286454"))
	var gif := GifEncoder.encode([sample, sample], 8)
	assert(gif.size() > 800 and gif.slice(0, 6).get_string_from_ascii() == "GIF89a", "GIF encoder must produce a GIF89a stream")
	var gif_path := "user://sequence-test-%d.gif" % Time.get_ticks_usec()
	var gif_file := FileAccess.open(gif_path, FileAccess.WRITE)
	gif_file.store_buffer(gif)
	gif_file.close()
	assert(gif[gif.size() - 1] == 0x3B, "Encoded GIF must end with a trailer")
	DirAccess.remove_absolute(gif_path)
	print("SEQUENCE PASS: shots, rename, multi-select reorder, persistence, interpolation, deletion")
	return true
