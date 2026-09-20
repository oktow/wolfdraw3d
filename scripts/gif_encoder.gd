extends RefCounted

static func encode(images: Array[Image], delay_cs: int, loop: bool = true) -> PackedByteArray:
	if images.is_empty():
		return PackedByteArray()
	var first: Image = images[0]
	var width := first.get_width()
	var height := first.get_height()
	var output := PackedByteArray()
	output.append_array("GIF89a".to_ascii_buffer())
	append_u16(output, width)
	append_u16(output, height)
	output.append(0xF7)
	output.append(0)
	output.append(0)
	for index in 256:
		output.append(index & 0xE0)
		output.append((index & 0x1C) << 3)
		output.append((index & 0x03) << 6)
	output.append(0x21)
	output.append(0xFF)
	output.append(11)
	output.append_array("NETSCAPE2.0".to_ascii_buffer())
	output.append(3)
	output.append(1)
	append_u16(output, 0 if loop else 1)
	output.append(0)
	for image in images:
		var indexed := quantize(image, width, height)
		output.append(0x21)
		output.append(0xF9)
		output.append(4)
		output.append(0)
		append_u16(output, maxi(delay_cs, 1))
		output.append(0)
		output.append(0)
		output.append(0x2C)
		append_u16(output, 0)
		append_u16(output, 0)
		append_u16(output, width)
		append_u16(output, height)
		output.append(0)
		var compressed := lzw(indexed)
		output.append(8)
		append_sub_blocks(output, compressed)
	output.append(0x3B)
	return output

static func append_u16(output: PackedByteArray, value: int) -> void:
	output.append(value & 0xFF)
	output.append((value >> 8) & 0xFF)

static func append_sub_blocks(output: PackedByteArray, data: PackedByteArray) -> void:
	var offset := 0
	while offset < data.size():
		var count := mini(255, data.size() - offset)
		output.append(count)
		for index in count:
			output.append(data[offset + index])
		offset += count
	output.append(0)

static func quantize(image: Image, width: int, height: int) -> PackedByteArray:
	var source := image
	if source.get_width() != width or source.get_height() != height:
		source = image.duplicate()
		source.resize(width, height, Image.INTERPOLATE_BILINEAR)
	var indexed := PackedByteArray()
	indexed.resize(width * height)
	for y in height:
		for x in width:
			var color := source.get_pixel(x, y)
			var red := int(round(clampf(color.r, 0.0, 1.0) * 7.0))
			var green := int(round(clampf(color.g, 0.0, 1.0) * 7.0))
			var blue := int(round(clampf(color.b, 0.0, 1.0) * 3.0))
			indexed[y * width + x] = (red << 5) | (green << 2) | blue
	return indexed

static func lzw(indexed: PackedByteArray) -> PackedByteArray:
	var clear := 256
	var end := 257
	var code_size := 9
	var output := PackedByteArray()
	var codes := PackedInt32Array([clear])
	for index in indexed.size():
		if index > 0 and index % 200 == 0:
			codes.append(clear)
		var value := indexed[index]
		codes.append(value)
	codes.append(end)
	var bits := 0
	var bit_count := 0
	for code in codes:
		bits |= code << bit_count
		bit_count += code_size
		while bit_count >= 8:
			output.append(bits & 0xFF)
			bits >>= 8
			bit_count -= 8
	if bit_count > 0:
		output.append(bits & 0xFF)
	return output
