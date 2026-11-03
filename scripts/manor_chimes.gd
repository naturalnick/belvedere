class_name ManorChimes
extends AudioStreamPlayer

func play_completion(count: int = 1) -> void:
	var rate := 22050
	var length := 1.0 + count * 0.18
	var bytes := PackedByteArray()
	bytes.resize(int(length * rate) * 2)
	for sample_index in int(length * rate):
		var t := float(sample_index) / rate
		var value := 0.0
		for note in count:
			var age := t - note * 0.18
			if age < 0:
				continue
			var frequency := 440.0 * pow(2.0, float([0, 4, 7, 12, 16, 19, 24][note % 7]) / 12.0)
			value += (sin(TAU * frequency * age) + 0.22 * sin(TAU * frequency * 2.01 * age)) * exp(-age * 5.0) * minf(age * 120, 1) * 0.18
		bytes.encode_s16(sample_index * 2, int(clampf(value, -1, 1) * 32767))
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = rate
	sound.data = bytes
	stream = sound
	volume_db = -10
	play()
