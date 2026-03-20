extends Node

# Audio Manager - 音效管理系统
# 支持多种音效类型和背景音乐

# 音量控制 (0.0 - 1.0)
var master_volume: float = 0.7
var sfx_volume: float = 0.8
var music_volume: float = 0.5

# 音乐播放器
var music_player: AudioStreamPlayer
var current_music: String = ""

# 音效播放器池 (避免音效重叠)
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_players: int = 8

# 保存路径
var config_file_path = "user://audio_config.json"

# 音效类型枚举
enum SFXType {
	CLICK,          # 按钮点击
	SUCCESS,        # 成功
	FAILURE,        # 失败
	COIN,           # 金币
	PURCHASE,       # 购买
	NOTIFICATION,   # 通知
	ACHIEVEMENT,    # 成就解锁
	MENU_OPEN,      # 菜单打开
	MENU_CLOSE,     # 菜单关闭
	DAILY_START,    # 新一天开始
	EVENT_TRIGGER,  # 随机事件
	STRESS,         # 压力增加
	RELIEF,         # 压力减轻
	EVOLUTION,      # 进化
	WARNING,        # 警告
}

func _ready():
	# 初始化音乐播放器
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Master"
	music_player.volume_db = linear_to_db(music_volume * master_volume)
	music_player.playing = false
	add_child(music_player)
	
	# 初始化音效播放器池
	_init_sfx_pool()
	
	# 加载音量设置
	_load_config()
	
	print("Audio Manager initialized")

func _init_sfx_pool():
	for i in range(max_sfx_players):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer_%d" % i
		player.bus = "Master"
		player.volume_db = linear_to_db(sfx_volume * master_volume)
		add_child(player)
		sfx_players.append(player)

# 播放音效
func play_sfx(type: SFXType):
	var player = _get_available_player()
	if player == null:
		return
	
	# 生成并播放合成音效
	var stream = _generate_sfx(type)
	if stream:
		player.stream = stream
		player.volume_db = linear_to_db(sfx_volume * master_volume)
		player.play()

# 获取可用的音效播放器
func _get_available_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	# 如果所有播放器都在使用，返回第一个
	return sfx_players[0]

# 生成合成音效 (使用内置功能)
func _generate_sfx(type: SFXType) -> AudioStream:
	match type:
		SFXType.CLICK:
			return _create_tone(800, 0.05, 0.3)
		SFXType.SUCCESS:
			return _create_success_fanfare()
		SFXType.FAILURE:
			return _create_failure_sound()
		SFXType.COIN:
			return _create_coin_sound()
		SFXType.PURCHASE:
			return _create_purchase_sound()
		SFXType.NOTIFICATION:
			return _create_notification_sound()
		SFXType.ACHIEVEMENT:
			return _create_achievement_sound()
		SFXType.MENU_OPEN:
			return _create_menu_sound(true)
		SFXType.MENU_CLOSE:
			return _create_menu_sound(false)
		SFXType.DAILY_START:
			return _create_daily_start_sound()
		SFXType.EVENT_TRIGGER:
			return _create_event_sound()
		SFXType.STRESS:
			return _create_stress_sound()
		SFXType.RELIEF:
			return _create_relief_sound()
		SFXType.EVOLUTION:
			return _create_evolution_sound()
		SFXType.WARNING:
			return _create_warning_sound()
	
	return _create_tone(440, 0.1, 0.3)

# 创建单音调
func _create_tone(frequency: float, duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	var sample_rate = 44100
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var envelope = 1.0 - (float(i) / num_samples)  # 淡出
		var sample = sin(2.0 * PI * frequency * t) * envelope * volume
		var int_sample = int(sample * 32767)
		data.append((int_sample) & 0xFF)
		data.append((int_sample >> 8) & 0xFF)
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BIT
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.sample_rate = sample_rate
	return stream

# 创建成功音效 (上行音阶)
func _create_success_fanfare() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	var sample_rate = 44100
	var duration = 0.3
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	
	var notes = [523, 659, 784]  # C5, E5, G5
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var note_index = int(t / (duration / notes.size()))
		if note_index >= notes.size():
			note_index = notes.size() - 1
		var freq = notes[note_index]
		var envelope = 1.0 - (float(i) / num_samples)
		var sample = sin(2.0 * PI * freq * t) * envelope * 0.5
		var int_sample = int(sample * 32767)
		data.append((int_sample) & 0xFF)
		data.append((int_sample >> 8) & 0xFF)
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BIT
	stream.sample_rate = sample_rate
	return stream

# 创建失败音效 (下行)
func _create_failure_sound() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	var sample_rate = 44100
	var duration = 0.25
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	
	var notes = [392, 330, 262]  # G4, E4, C4
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var note_index = int(t / (duration / notes.size()))
		if note_index >= notes.size():
			note_index = notes.size() - 1
		var freq = notes[note_index]
		var envelope = 1.0 - (float(i) / num_samples)
		var sample = sin(2.0 * PI * freq * t) * envelope * 0.4
		var int_sample = int(sample * 32767)
		data.append((int_sample) & 0xFF)
		data.append((int_sample >> 8) & 0xFF)
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BIT
	stream.sample_rate = sample_rate
	return stream

# 创建金币音效
func _create_coin_sound() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	var sample_rate = 44100
	var duration = 0.15
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var freq = 1200 + sin(t * 50) * 200  # 颤音
		var envelope = 1.0 - (float(i) / num_samples)
		var sample = sin(2.0 * PI * freq * t) * envelope * 0.5
		var int_sample = int(sample * 32767)
		data.append((int_sample) & 0xFF)
		data.append((int_sample >> 8) & 0xFF)
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BIT
	stream.sample_rate = sample_rate
	return stream

# 创建购买音效
func _create_purchase_sound() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	var sample_rate = 44100
	var duration = 0.2
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	
	var notes = [659, 784, 880]  # E5, G5, A5
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var note_index = int(t / (duration / notes.size()))
		if note_index >= notes.size():
			note_index = notes.size() - 1
		var freq = notes[note_index]
		var envelope = 1.0 - (float(i) / num_samples)
		var sample = sin(2.0 * PI * freq * t) * envelope * 0.4
		var int_sample = int(sample * 32767)
		data.append((int_sample) & 0xFF)
		data.append((int_sample >> 8) & 0xFF)
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BIT
	stream.sample_rate = sample_rate
	return stream

# 创建通知音效
func _create_notification_sound() -> AudioStreamWAV:
	return _create_tone(600, 0.1, 0.4)

# 创建成就音效
func _create_achievement_sound() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	var sample_rate = 44100
	var duration = 0.5
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	
	var notes = [523, 659, 784, 1047]  # C5, E5, G5, C6
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var note_index = int(t / (duration / notes.size()))
		if note_index >= notes.size():
			note_index = notes.size() - 1
		var freq = notes[note_index]
		var envelope = 1.0 - (float(i) / num_samples)
		var sample = sin(2.0 * PI * freq * t) * envelope * 0.4
		var int_sample = int(sample * 32767)
		data.append((int_sample) & 0xFF)
		data.append((int_sample >> 8) & 0xFF)
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BIT
	stream.sample_rate = sample_rate
	return stream

# 创建菜单音效
func _create_menu_sound(open: bool) -> AudioStreamWAV:
	if open:
		return _create_tone(400, 0.05, 0.3)
	else:
		return _create_tone(300, 0.05, 0.3)

# 创建新一天开始音效
func _create_daily_start_sound() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	var sample_rate = 44100
	var duration = 0.4
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	
	var notes = [440, 554, 659]  # A4, C#5, E5
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var note_index = int(t / (duration / notes.size()))
		if note_index >= notes.size():
			note_index = notes.size() - 1
		var freq = notes[note_index]
		var envelope = 1.0 - (float(i) / num_samples)
		var sample = sin(2.0 * PI * freq * t) * envelope * 0.35
		var int_sample = int(sample * 32767)
		data.append((int_sample) & 0xFF)
		data.append((int_sample >> 8) & 0xFF)
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BIT
	stream.sample_rate = sample_rate
	return stream

# 创建随机事件音效
func _create_event_sound() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	var sample_rate = 44100
	var duration = 0.35
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	
	var notes = [392, 494, 587, 784]  # G4, B4, D5, G5
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var note_index = int(t / (duration / notes.size()))
		if note_index >= notes.size():
			note_index = notes.size() - 1
		var freq = notes[note_index]
		var envelope = 1.0 - (float(i) / num_samples)
		var sample = sin(2.0 * PI * freq * t) * envelope * 0.35
		var int_sample = int(sample * 32767)
		data.append((int_sample) & 0xFF)
		data.append((int_sample >> 8) & 0xFF)
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BIT
	stream.sample_rate = sample_rate
	return stream

# 创建压力音效
func _create_stress_sound() -> AudioStreamWAV:
	return _create_tone(200, 0.15, 0.3)

# 创建放松音效
func _create_relief_sound() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	var sample_rate = 44100
	var duration = 0.3
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var freq = 300 + sin(t * 10) * 50  # 缓慢波动
		var envelope = 1.0 - (float(i) / num_samples)
		var sample = sin(2.0 * PI * freq * t) * envelope * 0.3
		var int_sample = int(sample * 32767)
		data.append((int_sample) & 0xFF)
		data.append((int_sample >> 8) & 0xFF)
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BIT
	stream.sample_rate = sample_rate
	return stream

# 创建进化音效
func _create_evolution_sound() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	var sample_rate = 44100
	var duration = 0.6
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	
	var notes = [262, 330, 392, 523, 659, 784]  # C4, E4, G4, C5, E5, G5
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var note_index = int(t / (duration / notes.size()))
		if note_index >= notes.size():
			note_index = notes.size() - 1
		var freq = notes[note_index]
		var envelope = 1.0 - (float(i) / num_samples)
		var sample = sin(2.0 * PI * freq * t) * envelope * 0.35
		var int_sample = int(sample * 32767)
		data.append((int_sample) & 0xFF)
		data.append((int_sample >> 8) & 0xFF)
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BIT
	stream.sample_rate = sample_rate
	return stream

# 创建警告音效
func _create_warning_sound() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	var sample_rate = 44100
	var duration = 0.2
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var freq = 300 + sin(t * 30) * 100  # 快速波动
		var envelope = 1.0 - (float(i) / num_samples)
		var sample = sin(2.0 * PI * freq * t) * envelope * 0.4
		var int_sample = int(sample * 32767)
		data.append((int_sample) & 0xFF)
		data.append((int_sample >> 8) & 0xFF)
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BIT
	stream.sample_rate = sample_rate
	return stream

# 设置主音量
func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	_update_volumes()
	_save_config()

# 设置音效音量
func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	_update_volumes()
	_save_config()

# 设置音乐音量
func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	if music_player:
		music_player.volume_db = linear_to_db(music_volume * master_volume)
	_save_config()

# 更新所有音量
func _update_volumes():
	for player in sfx_players:
		player.volume_db = linear_to_db(sfx_volume * master_volume)
	if music_player:
		music_player.volume_db = linear_to_db(music_volume * master_volume)

# 播放背景音乐 (使用合成音)
func play_music(track_name: String):
	if current_music == track_name:
		return
	
	current_music = track_name
	# 这里可以扩展为加载不同的背景音乐
	# 目前使用简单的背景音
	_play_background_ambient()

# 播放环境音
func _play_background_ambient():
	if not music_player:
		return
	
	# 创建一个简单的环境音
	var stream = AudioStreamWAV.new()
	var sample_rate = 44100
	var duration = 4.0  # 循环4秒
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		# 柔和的低频环境音
		var freq = 110  # A2
		var sample = sin(2.0 * PI * freq * t) * 0.1
		# 添加一点随机噪音
		sample += (randf() - 0.5) * 0.02
		var envelope = 0.3 + sin(t * 0.5) * 0.1
		sample *= envelope
		var int_sample = int(sample * 32767)
		data.append((int_sample) & 0xFF)
		data.append((int_sample >> 8) & 0xFF)
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BIT
	stream.loop_mode = AudioStreamWAV.LOOP_ENABLED
	stream.sample_rate = sample_rate
	
	music_player.stream = stream
	music_player.volume_db = linear_to_db(music_volume * master_volume)
	music_player.playing = true

# 停止音乐
func stop_music():
	if music_player:
		music_player.playing = false
	current_music = ""

# 暂停音乐
func pause_music():
	if music_player:
		music_player.playing = false

# 继续音乐
func resume_music():
	if music_player:
		music_player.playing = true

# 保存配置
func _save_config():
	var config = {
		"master_volume": master_volume,
		"sfx_volume": sfx_volume,
		"music_volume": music_volume
	}
	var json_string = JSON.stringify(config)
	var file = FileAccess.open(config_file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()

# 加载配置
func _load_config():
	if FileAccess.file_exists(config_file_path):
		var file = FileAccess.open(config_file_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_string()
			file.close()
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				var config = json.get_data()
				master_volume = config.get("master_volume", 0.7)
				sfx_volume = config.get("sfx_volume", 0.8)
				music_volume = config.get("music_volume", 0.5)
				_update_volumes()

# 便捷方法 - 按钮点击
func play_click():
	play_sfx(SFXType.CLICK)

# 便捷方法 - 成功
func play_success():
	play_sfx(SFXType.SUCCESS)

# 便捷方法 - 失败
func play_failure():
	play_sfx(SFXType.FAILURE)

# 便捷方法 - 金币
func play_coin():
	play_sfx(SFXType.COIN)

# 便捷方法 - 购买
func play_purchase():
	play_sfx(SFXType.PURCHASE)

# 便捷方法 - 成就
func play_achievement():
	play_sfx(SFXType.ACHIEVEMENT)

# 便捷方法 - 随机事件
func play_event():
	play_sfx(SFXType.EVENT_TRIGGER)

# 便捷方法 - 新一天
func play_daily_start():
	play_sfx(SFXType.DAILY_START)

# 便捷方法 - 压力
func play_stress():
	play_sfx(SFXType.STRESS)

# 便捷方法 - 放松
func play_relief():
	play_sfx(SFXType.RELIEF)

# 便捷方法 - 进化
func play_evolution():
	play_sfx(SFXType.EVOLUTION)
