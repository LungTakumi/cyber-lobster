extends Node2D

# Game state
var score = 0
var lives = 3
var current_level = 0
var combo = 0
var combo_timer = 0.0
var combo_meter = 0.0  # 0-100 fills up for special ability
var combo_meter_max = 100.0
var super_combo_active = false
var super_combo_timer = 0.0
var last_coin_time = 0.0
var stars_collected = 0
var high_score = 0
var player: CharacterBody2D = null
var platforms: Array[Node2D] = []
var coins: Array[Area2D] = []
var gems: Array[Area2D] = []  # 💎 Gem collectibles
var stars: Array[Area2D] = []
var enemies: Array[CharacterBody2D] = []
var goal: Area2D = null
var game_started = false
var checkpoint_pos = Vector2(80, 350)
var active_checkpoint = null
var stars_container: Node2D = null
var moving_platforms: Array = []
var screen_shake = 0.0
var audio_manager: Node = null

# Checkpoint system
var checkpoints: Array[Area2D] = []

# ⏱️ Timer system
var level_start_time = 0.0
var total_play_time = 0.0
var current_level_time = 0.0

# 🏆 Achievement system
var achievements = {
	"first_coin": {"name": "First Coin", "desc": "Collect your first coin", "unlocked": false},
	"coin_collector": {"name": "Coin Collector", "desc": "Collect 100 coins", "unlocked": false, "progress": 0, "target": 100},
	"star_gatherer": {"name": "Star Gatherer", "desc": "Collect 10 stars", "unlocked": false, "progress": 0, "target": 10},
	"boss_slayer": {"name": "Boss Slayer", "desc": "Defeat the Red Dragon", "unlocked": false},
	"no_damage_boss": {"name": "Perfect Fighter", "desc": "Defeat boss without taking damage", "unlocked": false},
	"combo_master": {"name": "Combo Master", "desc": "Get a 10x combo", "unlocked": false},
	"speed_runner": {"name": "Speed Runner", "desc": "Complete a level in under 30 seconds", "unlocked": false},
	"perfect_level": {"name": "Perfect Level", "desc": "Complete a level without dying", "unlocked": false, "progress": 0, "target": 1},
	"gem_collector": {"name": "Gem Collector", "desc": "Collect 50 gems", "unlocked": false, "progress": 0, "target": 50},
	"explorer": {"name": "Explorer", "desc": "Find all secrets in 5 levels", "unlocked": false, "progress": 0, "target": 5},
	"perfectionist": {"name": "Perfectionist", "desc": "Get 3 stars in 10 levels", "unlocked": false, "progress": 0, "target": 10},
	"time_trialist": {"name": "Time Trialist", "desc": "Complete 5 levels under best time", "unlocked": false, "progress": 0, "target": 5},
	"ultimate_collector": {"name": "Ultimate Collector", "desc": "Collect all power-ups in one run", "unlocked": false, "progress": 0, "target": 10},
	"endurance_master": {"name": "Endurance Master", "desc": "Complete 5 endless levels", "unlocked": false, "progress": 0, "target": 5},
	"gladiator": {"name": "Gladiator", "desc": "Defeat 50 enemies", "unlocked": false, "progress": 0, "target": 50},
	"vault_breaker": {"name": "Vault Breaker", "desc": "Collect 1000 total coins", "unlocked": false, "progress": 0, "target": 1000},
	"combo_god": {"name": "Combo God", "desc": "Get a 20x combo", "unlocked": false, "progress": 0, "target": 20}
}
var boss_damage_taken = false
var level_deaths = 0
var health_regen_timer = 0.0
var is_paused = false  # ⏸️ Pause state

# Metroidvania: Save system
var save_data = {
	"unlocked_levels": [0, 1, 2],  # 已解锁的关卡
	"total_coins": 0,       # 总金币
	"total_stars": 0,        # 总星星
	"level_stars": {},       # 每个关卡的星星数 {level_index: stars_count}
	"unlocked_abilities": [], # 解锁的能力
	"best_times": {},         # 最佳时间
	"total_gems": 0,         # 总宝石数
	"level_gems": {},        # 每个关卡的宝石数
	"completed_challenges": [],  # 已完成的挑战
	"puzzle_keys": {},           # 已收集的谜题钥匙 {key_type: count}
}

# Time Trial Mode
var time_trial_mode = false
var time_trial_best_times = {}  # {level_index: best_time}
# 可解锁的能力
const ABILITIES = {
	"double_jump": {"name": "Double Jump", "desc": "Jump again in mid-air", "icon": "🔺"},
	"dash": {"name": "Dash", "desc": "Press Shift to dash", "icon": "💨"},
	"wall_climb": {"name": "Wall Climb", "desc": "Climb walls slowly", "icon": "🧗"},
	"ground_slam": {"name": "Ground Slam", "desc": "Press Down in air", "icon": "💥"},
	"time_slow": {"name": "Time Slow", "desc": "Press Z to slow time", "icon": "⏱️"},
	"teleport": {"name": "Teleport", "desc": "Press X to teleport", "icon": "🌀"},
	"shadow_clone": {"name": "Shadow Clone", "desc": "Press C to spawn clone", "icon": "👤"},
	"bounce": {"name": "Bounce", "desc": "Jump again in air to bounce", "icon": "⭕"},
	"time_rewind": {"name": "Time Rewind", "desc": "Press R to rewind time", "icon": "🔄"},
	"energy_shield": {"name": "Energy Shield", "desc": "Press F to block 1 hit", "icon": "🛡️"},
	"phase_shift": {"name": "Phase Shift", "desc": "Press Q to dodge through enemies", "icon": "👻"},
	"tracking_projectile": {"name": "Tracking Shot", "desc": "Press T to fire homing missile", "icon": "🎯"},
	"magic_wand": {"name": "Magic Wand", "desc": "Press V to fire magic blast", "icon": "🪄"},
	"health_regen": {"name": "Health Regen", "desc": "Slowly recover health over time", "icon": "❤️"}
}

# Skill Tree System - Ability upgrades
var skill_points = 0
var skill_tree = {
	"double_jump": {"level": 0, "max_level": 3, "desc": "Extra mid-air jumps", "icon": "🔺"},
	"dash": {"level": 0, "max_level": 3, "desc": "Faster and farther dash", "icon": "💨"},
	"speed": {"level": 0, "max_level": 3, "desc": "Movement speed boost", "icon": "⚡"},
	"health": {"level": 0, "max_level": 5, "desc": "Max health increase", "icon": "❤️"},
	"luck": {"level": 0, "max_level": 3, "desc": "Better item drops", "icon": "🍀"},
	"power": {"level": 0, "max_level": 3, "desc": "Damage boost", "icon": "💪"}
}

func add_skill_point():
	skill_points += 1

func upgrade_skill(skill_name):
	if not skill_tree.has(skill_name):
		return false
	if skill_points <= 0:
		return false
	var skill = skill_tree[skill_name]
	if skill["level"] >= skill["max_level"]:
		return false
	
	skill["level"] += 1
	skill_points -= 1
	apply_skill_upgrade(skill_name, skill["level"])
	return true

func apply_skill_upgrade(skill_name, level):
	match skill_name:
		"speed":
			if player:
				player.speed_multiplier = 1.0 + (level * 0.1)
		"health":
			lives = min(lives + 1, 5)
			_update_lives()
		"power":
			# Boost player damage (future implementation)

func screen_shake_intensity(amount):
	screen_shake = amount
	if amount > 15:
		flash_screen(Color(1, 0.5, 0.5, 0.3))

func flash_screen(color: Color):
	var flash = ColorRect.new()
	flash.size = Vector2(2000, 2000)
	flash.position = Vector2(-500, -500)
	flash.color = color
	flash.z_index = 100
	add_child(flash)
	
	var tw = create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.15)
	tw.tween_callback(flash.queue_free)

# Checkpoint system
func set_checkpoint(pos: Vector2):
	checkpoint_pos = pos + Vector2(0, -30)

func deactivate_all_checkpoints(current):
	active_checkpoint = current

func create_checkpoint(x, y):
	var checkpoint = Area2D.new()
	checkpoint.position = Vector2(x, y)
	checkpoint.script = load("res://checkpoint.gd")
	checkpoint.add_to_group("checkpoint")
	add_child(checkpoint)
	checkpoints.append(checkpoint)

func create_secret_area(x, y, w, h):
	var area = Area2D.new()
	area.position = Vector2(x, y)
	area.script = load("res://secret_area.gd")
	area.add_to_group("secret_area")
	
	# Collision shape
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(w, h)
	col.shape = rect
	col.position = Vector2(w/2, h/2)
	area.add_child(col)
	
	add_child(area)
	
	# Subtle shimmer effect - indicates secret area
	var shimmer = ColorRect.new()
	shimmer.size = Vector2(w, h)
	shimmer.color = Color(0.6, 0.4, 1, 0.08)
	shimmer.position = Vector2.ZERO
	area.add_child(shimmer)
	
	# Subtle particle hint
	var hint = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(6):
		var angle = i * TAU / 6
		pts.append(Vector2(cos(angle), sin(angle)) * 4)
	hint.polygon = pts
	hint.color = Color(0.7, 0.5, 1, 0.2)
	hint.position = Vector2(w/2, h/2)
	area.add_child(hint)
	
	# Gentle pulse animation
	var tw = create_tween()
	tw.set_loops()
	tw.tween_property(hint, "scale", Vector2(1.3, 1.3), 1.0)
	tw.tween_property(hint, "scale", Vector2(1.0, 1.0), 1.0)

# Check if player is near secret area and show hint
var secret_hint_shown = false

func check_secret_area_proximity():
	if not player or secret_hint_shown:
		return
	
	var secret_areas = get_tree().get_nodes_in_group("secret_area")
	for area in secret_areas:
		if is_instance_valid(area):
			var dist = player.global_position.distance_to(area.global_position)
			if dist < 80:
				show_secret_hint()
				secret_hint_shown = true
				break

func show_secret_hint():
	if not player:
		return
	
	# Subtle sparkle effect near player
	for i in range(6):
		var sparkle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(4):
			var angle = j * TAU / 4
			pts.append(Vector2(cos(angle), sin(angle)) * 3)
		sparkle.polygon = pts
		sparkle.color = Color(0.7, 0.5, 1, 0.6)
		sparkle.position = player.global_position + Vector2(randf_range(-15, 15), randf_range(-20, 0))
		add_child(sparkle)
		
		var tw = create_tween()
		tw.tween_property(sparkle, "position", sparkle.position + Vector2(randf_range(-10, 10), -randf_range(15, 30)), 0.6)
		tw.parallel().tween_property(sparkle, "modulate:a", 0.0, 0.6)
		tw.tween_callback(sparkle.queue_free)
	
	# Brief UI hint
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		var hint = Label.new()
		hint.text = "🔍 Something hidden nearby..."
		hint.add_theme_font_size_override("font_size", 16)
		hint.add_theme_color_override("font_color", Color(0.7, 0.5, 1, 0.8))
		hint.position = Vector2(500, 280)
		hint.modulate.a = 0
		ui.add_child(hint)
		
		var tw = create_tween()
		tw.tween_property(hint, "modulate:a", 1.0, 0.5)
		tw.tween_interval(2.0)
		tw.tween_property(hint, "modulate:a", 0.0, 0.5)
		tw.tween_property(hint, "position:y", hint.position.y - 20, 0.5)
		tw.tween_callback(hint.queue_free)

func clear_checkpoints():
	for cp in checkpoints:
		if is_instance_valid(cp):
			cp.queue_free()
	checkpoints.clear()
	active_checkpoint = null

func play_checkpoint_sound():
	if audio_manager and audio_manager.has_method("play_checkpoint"):
		audio_manager.play_checkpoint()

func play_chest_sound():
	if audio_manager and audio_manager.has_method("play_chest"):
		audio_manager.play_chest()
	else:
		screen_shake_intensity(3)

# Kenney assets - sprite sheets
var char_tilesheet: Texture2D
var tile_tilesheet: Texture2D
var bg_tilesheet: Texture2D
var enemy_tilesheet: Texture2D  # Kenney monster sprites

const GRAVITY = 980.0
const TILE_SIZE = Vector2(18, 18)  # For tiles
const CHAR_TILE_SIZE = Vector2(24, 24)  # For characters

func _ready():
	add_to_group("game")
	load_kenney_assets()
	load_high_score()  # 💾 Load saved high score
	load_achievements()  # 🏆 Load achievements
	load_save_data()  # 💾 Metroidvania save system
	RenderingServer.set_default_clear_color(Color(0.1, 0.15, 0.2))
	create_background_stars()
	show_start_screen()
	
	# Initialize audio manager
	audio_manager = Node.new()
	audio_manager.set_script(load("res://audio_manager.gd"))
	audio_manager.name = "AudioManager"
	add_child(audio_manager)

func load_kenney_assets():
	# Use Godot's built-in resource loader (works in exports)
	char_tilesheet = load("res://sprites/tilemap-characters_packed.png")
	tile_tilesheet = load("res://sprites/tilemap_packed.png")
	enemy_tilesheet = load("res://sprites/enemies.png")

# 💾 High score persistence
func load_high_score():
	var save_file = FileAccess.open("user://highscore.dat", FileAccess.READ)
	if save_file:
		high_score = save_file.get_var()
		save_file.close()

func save_high_score():
	if score > high_score:
		high_score = score
		var save_file = FileAccess.open("user://highscore.dat", FileAccess.WRITE)
		if save_file:
			save_file.store_var(high_score)
			save_file.close()

# 🏆 Achievement system
func load_achievements():
	var save_file = FileAccess.open("user://achievements.dat", FileAccess.READ)
	if save_file:
		var data = save_file.get_var()
		if data and typeof(data) == TYPE_DICTIONARY:
			for key in data:
				if achievements.has(key):
					achievements[key] = data[key]
		save_file.close()

func save_achievements():
	var save_file = FileAccess.open("user://achievements.dat", FileAccess.WRITE)
	if save_file:
		save_file.store_var(achievements)
		save_file.close()

func unlock_achievement(key):
	if achievements.has(key) and not achievements[key].get("unlocked", false):
		achievements[key]["unlocked"] = true
		save_achievements()
		show_achievement_notification(key)

func update_achievement_progress(key, progress):
	if achievements.has(key):
		achievements[key]["progress"] = progress
		if achievements[key].has("target") and progress >= achievements[key]["target"]:
			unlock_achievement(key)

func show_achievement_notification(key):
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		var ach = achievements[key]
		var notif = Label.new()
		notif.text = "🏆 Achievement Unlocked!\n" + ach["name"]
		notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		notif.position = Vector2(200, 100)
		notif.add_theme_font_size_override("font_size", 24)
		notif.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		notif.modulate.a = 0
		ui.add_child(notif)

# Metroidvania: Save System
func load_save_data():
	var save_file = FileAccess.open("user://save_data.dat", FileAccess.READ)
	if save_file:
		var data = save_file.get_var()
		if data and typeof(data) == TYPE_DICTIONARY:
			save_data = data
		save_file.close()

func save_save_data():
	var save_file = FileAccess.open("user://save_data.dat", FileAccess.WRITE)
	if save_file:
		save_file.store_var(save_data)
		save_file.close()

func unlock_level(level_index):
	if not level_index in save_data["unlocked_levels"]:
		save_data["unlocked_levels"].append(level_index)
		save_save_data()

func get_unlocked_levels():
	return save_data["unlocked_levels"]

func has_ability(ability_name):
	return ability_name in save_data["unlocked_abilities"]

func unlock_ability(ability_name):
	if not ability_name in save_data["unlocked_abilities"]:
		save_data["unlocked_abilities"].append(ability_name)
		save_save_data()
		show_ability_notification(ability_name)

func show_ability_notification(ability_name):
	var ui = get_tree().get_first_node_in_group("ui")
	if ui and ABILITIES.has(ability_name):
		var ab = ABILITIES[ability_name]
		var notif = Label.new()
		notif.text = "✨ New Ability!\n" + ab["icon"] + " " + ab["name"] + "\n" + ab["desc"]
		notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		notif.position = Vector2(200, 150)
		notif.add_theme_font_size_override("font_size", 22)
		notif.add_theme_color_override("font_color", Color(0.4, 1, 0.6))
		notif.modulate.a = 0
		ui.add_child(notif)
		
		var tween = create_tween()
		tween.tween_property(notif, "modulate:a", 1.0, 0.3)
		tween.tween_interval(3.0)
		tween.tween_property(notif, "modulate:a", 0.0, 0.5)
		tween.tween_property(notif, "position:y", notif.position.y - 30, 0.5)
		tween.tween_callback(notif.queue_free)
		
		var fade_tween = create_tween()
		fade_tween.tween_property(notif, "modulate:a", 1.0, 0.3)
		fade_tween.tween_interval(2.0)
		fade_tween.tween_property(notif, "modulate:a", 0.0, 0.5)
		fade_tween.tween_property(notif, "position:y", 50, 0.5)
		fade_tween.tween_callback(notif.queue_free)

# 🗝️ Puzzle Key functions
func collect_puzzle_key(key_type: String):
	if not save_data.has("puzzle_keys"):
		save_data["puzzle_keys"] = {}
	if not save_data["puzzle_keys"].has(key_type):
		save_data["puzzle_keys"][key_type] = 0
	save_data["puzzle_keys"][key_type] += 1
	save_save_data()

func has_puzzle_key(key_type: String) -> bool:
	return save_data.has("puzzle_keys") and save_data["puzzle_keys"].has(key_type) and save_data["puzzle_keys"][key_type] > 0

func use_puzzle_key(key_type: String) -> bool:
	if has_puzzle_key(key_type):
		save_data["puzzle_keys"][key_type] -= 1
		save_save_data()
		return true
	return false

# ⏱️ Timer functions
func start_level_timer():
	level_start_time = Time.get_ticks_msec() / 1000.0
	current_level_time = 0.0

func get_level_time():
	return current_level_time

func get_total_time():
	return total_play_time

# Level data - now including Bonus Stage!
var levels = [
	{
		"name": "Green Hills",
		"platforms": [
			{"x": 0, "y": 550, "w": 300, "h": 50},
			{"x": 300, "y": 500, "w": 200, "h": 20},
			{"x": 550, "y": 550, "w": 250, "h": 50},
			{"x": 400, "y": 400, "w": 150, "h": 20},
			{"x": 650, "y": 300, "w": 150, "h": 20},
			{"x": 850, "y": 400, "w": 100, "h": 20}
		],
		"coins": [
			{"x": 450, "y": 450}, {"x": 700, "y": 250}, {"x": 200, "y": 450},
			{"x": 900, "y": 350}, {"x": 500, "y": 250}
		],
		"stars": [
			{"x": 600, "y": 350}
		],
		"enemies": [{"x": 150, "y": 460, "min_x": 0, "max_x": 300}],
		"goal": {"x": 900, "y": 350},
		"checkpoint": {"x": 400, "y": 360},
		"secret_area": {"x": 150, "y": 200, "w": 100, "h": 100},
		"puzzle_key": {"x": 250, "y": 450, "type": "silver"},
		"locked_door": {"x": 750, "y": 340, "key_type": "silver"}
	},
	{
		"name": "Sky Bridges",
		"platforms": [
			{"x": 0, "y": 550, "w": 200, "h": 50}, {"x": 250, "y": 480, "w": 150, "h": 20},
			{"x": 450, "y": 400, "w": 150, "h": 20}, {"x": 650, "y": 320, "w": 120, "h": 20},
			{"x": 800, "y": 250, "w": 150, "h": 20}, {"x": 950, "y": 350, "w": 100, "h": 20},
			{"x": 1100, "y": 450, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 150, "y": 450}, {"x": 320, "y": 380}, {"x": 500, "y": 300},
			{"x": 700, "y": 220}, {"x": 860, "y": 150}, {"x": 1000, "y": 350}, {"x": 1150, "y": 350}
		],
		"stars": [
			{"x": 600, "y": 180}, {"x": 900, "y": 100}
		],
		"enemies": [
			{"x": 300, "y": 440, "min_x": 250, "max_x": 400},
			{"x": 950, "y": 310, "min_x": 950, "max_x": 1100}
		],
		"goal": {"x": 1150, "y": 400},
		"checkpoint": {"x": 600, "y": 250}
	},
	{
		"name": "Moving Platforms",
		"moving": true,
		"platforms": [
			{"x": 50, "y": 500, "w": 100, "h": 20, "move_x": 100, "move_y": 0},
			{"x": 250, "y": 450, "w": 80, "h": 20, "move_x": 80, "move_y": -50},
			{"x": 450, "y": 400, "w": 80, "h": 20, "move_x": 0, "move_y": -80},
			{"x": 650, "y": 350, "w": 100, "h": 20, "move_x": -80, "move_y": 0},
			{"x": 850, "y": 300, "w": 80, "h": 20, "move_x": 0, "move_y": -60},
			{"x": 1050, "y": 250, "w": 100, "h": 20}
		],
		"coins": [
			{"x": 150, "y": 420}, {"x": 300, "y": 380}, {"x": 500, "y": 320},
			{"x": 700, "y": 280}, {"x": 900, "y": 230}, {"x": 1100, "y": 180}
		],
		"enemies": [],
		"goal": {"x": 1100, "y": 200}
	},
	{
		"name": "Mountain Climb",
		"platforms": [
			{"x": 50, "y": 550, "w": 150, "h": 50}, {"x": 250, "y": 500, "w": 100, "h": 20},
			{"x": 400, "y": 450, "w": 100, "h": 20}, {"x": 550, "y": 380, "w": 120, "h": 20},
			{"x": 700, "y": 320, "w": 100, "h": 20}, {"x": 850, "y": 260, "w": 100, "h": 20},
			{"x": 1000, "y": 320, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 150, "y": 450}, {"x": 300, "y": 420}, {"x": 450, "y": 350},
			{"x": 600, "y": 280}, {"x": 750, "y": 220}, {"x": 900, "y": 200}, {"x": 1050, "y": 260}
		],
		"enemies": [
			{"x": 400, "y": 410, "min_x": 350, "max_x": 450},
			{"x": 850, "y": 220, "min_x": 800, "max_x": 900}
		],
		"goal": {"x": 1050, "y": 270}
	},
	{
		"name": "Floating Islands",
		"platforms": [
			{"x": 0, "y": 500, "w": 120, "h": 30}, {"x": 180, "y": 420, "w": 100, "h": 20},
			{"x": 350, "y": 350, "w": 100, "h": 20}, {"x": 500, "y": 450, "w": 120, "h": 20},
			{"x": 680, "y": 380, "w": 100, "h": 20}, {"x": 850, "y": 300, "w": 100, "h": 20},
			{"x": 1000, "y": 380, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 50, "y": 420}, {"x": 180, "y": 350}, {"x": 350, "y": 280},
			{"x": 550, "y": 380}, {"x": 700, "y": 310}, {"x": 880, "y": 230}, {"x": 1050, "y": 310}
		],
		"enemies": [
			{"x": 180, "y": 380, "min_x": 130, "max_x": 230},
			{"x": 500, "y": 410, "min_x": 440, "max_x": 560},
			{"x": 1000, "y": 340, "min_x": 925, "max_x": 1075}
		],
		"goal": {"x": 1050, "y": 330}
	},
	{
		"name": "The Tower",
		"platforms": [
			{"x": 50, "y": 550, "w": 150, "h": 40}, {"x": 150, "y": 480, "w": 80, "h": 20},
			{"x": 250, "y": 420, "w": 80, "h": 20}, {"x": 350, "y": 360, "w": 80, "h": 20},
			{"x": 450, "y": 300, "w": 80, "h": 20}, {"x": 550, "y": 240, "w": 80, "h": 20},
			{"x": 650, "y": 180, "w": 80, "h": 20}, {"x": 800, "y": 200, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 100, "y": 480}, {"x": 180, "y": 410}, {"x": 280, "y": 350},
			{"x": 380, "y": 290}, {"x": 480, "y": 230}, {"x": 580, "y": 170}, {"x": 850, "y": 140}
		],
		"enemies": [
			{"x": 150, "y": 440, "min_x": 110, "max_x": 190},
			{"x": 350, "y": 320, "min_x": 310, "max_x": 390},
			{"x": 550, "y": 200, "min_x": 510, "max_x": 590}
		],
		"goal": {"x": 850, "y": 150}
	},
	{
		"name": "Cave",
		"platforms": [
			{"x": 50, "y": 500, "w": 120, "h": 30}, {"x": 200, "y": 450, "w": 100, "h": 20},
			{"x": 350, "y": 500, "w": 100, "h": 20}, {"x": 500, "y": 420, "w": 100, "h": 20},
			{"x": 650, "y": 350, "w": 100, "h": 20}, {"x": 800, "y": 400, "w": 120, "h": 20},
			{"x": 950, "y": 320, "w": 100, "h": 20}, {"x": 1100, "y": 250, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 80, "y": 420}, {"x": 200, "y": 380}, {"x": 350, "y": 430},
			{"x": 500, "y": 350}, {"x": 680, "y": 280}, {"x": 830, "y": 330},
			{"x": 980, "y": 250}, {"x": 1150, "y": 180}
		],
		"enemies": [
			{"x": 200, "y": 410, "min_x": 150, "max_x": 250},
			{"x": 500, "y": 380, "min_x": 450, "max_x": 550},
			{"x": 800, "y": 360, "min_x": 740, "max_x": 860}
		],
		"goal": {"x": 1150, "y": 200}
	},
	{
		"name": "Rainbow Bridge",
		"platforms": [
			{"x": 0, "y": 500, "w": 100, "h": 20}, {"x": 150, "y": 450, "w": 80, "h": 20},
			{"x": 300, "y": 400, "w": 80, "h": 20}, {"x": 450, "y": 350, "w": 80, "h": 20},
			{"x": 600, "y": 300, "w": 80, "h": 20}, {"x": 750, "y": 350, "w": 80, "h": 20},
			{"x": 900, "y": 400, "w": 80, "h": 20}, {"x": 1050, "y": 450, "w": 100, "h": 20}
		],
		"coins": [
			{"x": 30, "y": 430}, {"x": 150, "y": 380}, {"x": 300, "y": 330},
			{"x": 450, "y": 280}, {"x": 620, "y": 230}, {"x": 770, "y": 280},
			{"x": 920, "y": 330}, {"x": 1080, "y": 380}
		],
		"enemies": [
			{"x": 300, "y": 360, "min_x": 260, "max_x": 340},
			{"x": 750, "y": 310, "min_x": 710, "max_x": 790}
		],
		"goal": {"x": 1080, "y": 400}
	},
	{
		"name": "Crystal Caverns",
		"bg_color": Color(0.1, 0.15, 0.25),
		"platforms": [
			{"x": 50, "y": 550, "w": 150, "h": 30},
			{"x": 250, "y": 480, "w": 100, "h": 20},
			{"x": 400, "y": 400, "w": 80, "h": 20},
			{"x": 550, "y": 320, "w": 100, "h": 20},
			{"x": 700, "y": 400, "w": 80, "h": 20},
			{"x": 850, "y": 320, "w": 100, "h": 20},
			{"x": 1000, "y": 250, "w": 80, "h": 20},
			{"x": 1150, "y": 350, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 80, "y": 480}, {"x": 280, "y": 420},
			{"x": 420, "y": 340}, {"x": 580, "y": 260},
			{"x": 720, "y": 340}, {"x": 880, "y": 260},
			{"x": 1020, "y": 190}, {"x": 1200, "y": 290}
		],
		"stars": [
			{"x": 600, "y": 180}, {"x": 950, "y": 150}
		],
		"enemies": [
			{"x": 300, "y": 440, "min_x": 200, "max_x": 350},
			{"x": 700, "y": 360, "min_x": 650, "max_x": 800}
		],
		"goal": {"x": 1200, "y": 300}
	},
	# Bonus Stage - lots of coins and moving platforms!
	{
		"name": "Bonus Stage",
		"moving": true,
		"platforms": [
			# Starting platform
			{"x": 80, "y": 500, "w": 160, "h": 30},
			# Moving platforms - lots of them!
			{"x": 280, "y": 480, "w": 100, "h": 20, "move_x": 120, "move_y": 0},
			{"x": 450, "y": 420, "w": 80, "h": 20, "move_x": 0, "move_y": -60},
			{"x": 600, "y": 400, "w": 80, "h": 20, "move_x": 80, "move_y": -40},
			{"x": 750, "y": 350, "w": 100, "h": 20, "move_x": -60, "move_y": 0},
			{"x": 900, "y": 320, "w": 80, "h": 20, "move_x": 0, "move_y": -80},
			{"x": 1050, "y": 280, "w": 80, "h": 20, "move_x": 60, "move_y": -50},
			{"x": 1200, "y": 250, "w": 100, "h": 20, "move_x": -80, "move_y": 0},
			# Final platform
			{"x": 1350, "y": 300, "w": 150, "h": 20}
		],
		"coins": [
			# Coins on starting platform
			{"x": 80, "y": 450}, {"x": 120, "y": 420},
			# Coins on moving platforms
			{"x": 300, "y": 400}, {"x": 350, "y": 380},
			{"x": 450, "y": 350}, {"x": 480, "y": 320},
			{"x": 600, "y": 330}, {"x": 650, "y": 300},
			{"x": 750, "y": 280}, {"x": 800, "y": 250},
			{"x": 900, "y": 250}, {"x": 950, "y": 220},
			{"x": 1050, "y": 210}, {"x": 1100, "y": 180},
			{"x": 1200, "y": 180}, {"x": 1250, "y": 150},
			# Extra bonus coins in the air
			{"x": 200, "y": 350}, {"x": 380, "y": 280},
			{"x": 550, "y": 220}, {"x": 700, "y": 180},
			{"x": 850, "y": 150}, {"x": 1000, "y": 120},
			{"x": 1150, "y": 100}, {"x": 1300, "y": 200}
		],
		"stars": [
			{"x": 400, "y": 300}, {"x": 700, "y": 200}, {"x": 1000, "y": 150}
		],
		"powerups": [
			{"x": 600, "y": 300, "type": "dash"},
			{"x": 900, "y": 200, "type": "double_jump"}
		],
		"gems": [
			{"x": 500, "y": 250}, {"x": 800, "y": 180}, {"x": 1100, "y": 130}
		],
		"treasure_chests": [
			{"x": 550, "y": 280, "type": "gold"},
			{"x": 950, "y": 180, "type": "silver"}
		],
		"enemies": [],
		"goal": {"x": 1350, "y": 250}
	},
	# NEW! Sky Fortress - with flying enemies!
	{
		"name": "Sky Fortress",
		"bg_color": Color(0.08, 0.1, 0.2),
		"platforms": [
			{"x": 50, "y": 550, "w": 180, "h": 30},
			{"x": 300, "y": 480, "w": 100, "h": 20},
			{"x": 500, "y": 400, "w": 120, "h": 20},
			{"x": 700, "y": 320, "w": 100, "h": 20},
			{"x": 900, "y": 400, "w": 80, "h": 20},
			{"x": 1050, "y": 320, "w": 100, "h": 20},
			{"x": 1200, "y": 250, "w": 120, "h": 20}
		],
		"coins": [
			{"x": 100, "y": 480}, {"x": 180, "y": 450},
			{"x": 320, "y": 420}, {"x": 520, "y": 340},
			{"x": 720, "y": 260}, {"x": 920, "y": 340},
			{"x": 1080, "y": 260}, {"x": 1250, "y": 190}
		],
		"stars": [
			{"x": 500, "y": 150}, {"x": 800, "y": 100}, {"x": 1100, "y": 120}
		],
		"gems": [
			{"x": 600, "y": 180}
		],
		"enemies": [
			{"x": 400, "y": 200, "type": "flying"},
			{"x": 700, "y": 150, "type": "flying"},
			{"x": 1000, "y": 180, "type": "flying"}
		],
		"goal": {"x": 1250, "y": 200}
	},
	# Boss Battle!
	{
		"name": "Dragon's Lair",
		"bg_color": Color(0.15, 0.05, 0.1),
		"is_boss": true,
		"boss_name": "Red Dragon",
		"platforms": [
			{"x": 50, "y": 550, "w": 200, "h": 40},
			{"x": 350, "y": 450, "w": 150, "h": 20},
			{"x": 600, "y": 350, "w": 100, "h": 20},
			{"x": 850, "y": 450, "w": 150, "h": 20},
			{"x": 1100, "y": 550, "w": 200, "h": 40}
		],
		"coins": [
			{"x": 100, "y": 480}, {"x": 200, "y": 450},
			{"x": 400, "y": 380}, {"x": 600, "y": 280},
			{"x": 900, "y": 380}, {"x": 1200, "y": 480}
		],
		"gems": [
			{"x": 500, "y": 200}, {"x": 700, "y": 150}
		],
		"enemies": [
			{"x": 700, "y": 250, "type": "boss", "hp": 5}
		],
		"goal": {"x": 1250, "y": 500},
		"checkpoint": {"x": 450, "y": 400}
	},
	# Secret Level - Unlockable!
	{
		"name": "Secret Garden",
		"bg_color": Color(0.05, 0.2, 0.15),
		"is_secret": true,
		"platforms": [
			{"x": 50, "y": 500, "w": 120, "h": 30},
			{"x": 200, "y": 420, "w": 80, "h": 20},
			{"x": 320, "y": 350, "w": 80, "h": 20},
			{"x": 450, "y": 420, "w": 80, "h": 20},
			{"x": 580, "y": 350, "w": 80, "h": 20},
			{"x": 700, "y": 280, "w": 100, "h": 20},
			{"x": 850, "y": 350, "w": 80, "h": 20},
			{"x": 980, "y": 280, "w": 80, "h": 20},
			{"x": 1100, "y": 350, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 80, "y": 430}, {"x": 150, "y": 400},
			{"x": 220, "y": 350}, {"x": 290, "y": 280},
			{"x": 350, "y": 350}, {"x": 420, "y": 280},
			{"x": 500, "y": 350}, {"x": 580, "y": 280},
			{"x": 650, "y": 210}, {"x": 720, "y": 210},
			{"x": 800, "y": 280}, {"x": 870, "y": 280},
			{"x": 940, "y": 210}, {"x": 1010, "y": 210},
			{"x": 1150, "y": 290}
		],
		"stars": [
			{"x": 350, "y": 180}, {"x": 720, "y": 150}, {"x": 1010, "y": 150}
		],
		"gems": [
			{"x": 500, "y": 220}
		],
		"enemies": [
			{"x": 300, "y": 310, "min_x": 260, "max_x": 380},
			{"x": 600, "y": 310, "min_x": 540, "max_x": 620},
			{"x": 900, "y": 240, "min_x": 850, "max_x": 980}
		],
		"goal": {"x": 1200, "y": 300}
	},
	# NEW! Ice Palace - Ice/Snow themed level
	{
		"name": "Ice Palace",
		"bg_color": Color(0.1, 0.15, 0.3),
		"weather": "snow",
		"platforms": [
			{"x": 50, "y": 550, "w": 150, "h": 30},
			{"x": 250, "y": 480, "w": 100, "h": 20},
			{"x": 400, "y": 400, "w": 80, "h": 20},
			{"x": 550, "y": 320, "w": 100, "h": 20},
			{"x": 400, "y": 220, "w": 80, "h": 20},
			{"x": 250, "y": 150, "w": 100, "h": 20},
			{"x": 450, "y": 100, "w": 80, "h": 20},
			{"x": 650, "y": 180, "w": 100, "h": 20},
			{"x": 800, "y": 280, "w": 80, "h": 20},
			{"x": 950, "y": 350, "w": 100, "h": 20},
			{"x": 1100, "y": 450, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 100, "y": 480}, {"x": 280, "y": 420},
			{"x": 420, "y": 340}, {"x": 580, "y": 260},
			{"x": 420, "y": 160}, {"x": 280, "y": 90},
			{"x": 470, "y": 40}, {"x": 680, "y": 120},
			{"x": 820, "y": 220}, {"x": 980, "y": 290},
			{"x": 1150, "y": 390}
		],
		"stars": [
			{"x": 280, "y": 50}, {"x": 800, "y": 180}, {"x": 1150, "y": 350}
		],
		"enemies": [
			{"x": 300, "y": 440, "min_x": 200, "max_x": 350},
			{"x": 600, "y": 280, "min_x": 500, "max_x": 650},
			{"x": 950, "y": 310, "min_x": 900, "max_x": 1050}
		],
		"goal": {"x": 1150, "y": 400}
	},
	# NEW! Volcano - Lava/Fire themed level (v2.0)
	{
		"name": "Volcano",
		"bg_color": Color(0.2, 0.08, 0.05),
		"platforms": [
			{"x": 50, "y": 550, "w": 120, "h": 30},
			{"x": 200, "y": 480, "w": 80, "h": 20},
			{"x": 350, "y": 400, "w": 80, "h": 20},
			{"x": 500, "y": 480, "w": 80, "h": 20},
			{"x": 650, "y": 400, "w": 100, "h": 20},
			{"x": 800, "y": 320, "w": 80, "h": 20},
			{"x": 650, "y": 220, "w": 80, "h": 20},
			{"x": 800, "y": 140, "w": 100, "h": 20},
			{"x": 950, "y": 220, "w": 80, "h": 20},
			{"x": 1100, "y": 300, "w": 100, "h": 20},
			{"x": 1250, "y": 400, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 80, "y": 480}, {"x": 220, "y": 420},
			{"x": 370, "y": 340}, {"x": 520, "y": 420},
			{"x": 680, "y": 340}, {"x": 820, "y": 260},
			{"x": 670, "y": 160}, {"x": 830, "y": 80},
			{"x": 970, "y": 160}, {"x": 1130, "y": 240},
			{"x": 1300, "y": 340}
		],
		"stars": [
			{"x": 350, "y": 280}, {"x": 700, "y": 100}, {"x": 1300, "y": 300}
		],
		"enemies": [
			{"x": 250, "y": 440, "min_x": 200, "max_x": 300},
			{"x": 700, "y": 360, "min_x": 650, "max_x": 750},
			{"x": 850, "y": 280, "min_x": 800, "max_x": 900},
			{"x": 1100, "y": 260, "min_x": 1050, "max_x": 1200}
		],
		"goal": {"x": 1300, "y": 350}
	},
	# NEW! Haunted Forest - Spooky themed level (v2.1)
	{
		"name": "Haunted Forest",
		"bg_color": Color(0.08, 0.05, 0.12),
		"platforms": [
			{"x": 50, "y": 550, "w": 150, "h": 30},
			{"x": 250, "y": 480, "w": 80, "h": 20},
			{"x": 380, "y": 400, "w": 100, "h": 20},
			{"x": 550, "y": 480, "w": 80, "h": 20},
			{"x": 700, "y": 400, "w": 100, "h": 20},
			{"x": 850, "y": 320, "w": 80, "h": 20},
			{"x": 700, "y": 220, "w": 80, "h": 20},
			{"x": 850, "y": 140, "w": 100, "h": 20},
			{"x": 1000, "y": 220, "w": 80, "h": 20},
			{"x": 1150, "y": 320, "w": 100, "h": 20},
			{"x": 1300, "y": 420, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 80, "y": 480}, {"x": 270, "y": 420},
			{"x": 400, "y": 340}, {"x": 570, "y": 420},
			{"x": 730, "y": 340}, {"x": 870, "y": 260},
			{"x": 730, "y": 160}, {"x": 880, "y": 80},
			{"x": 1020, "y": 160}, {"x": 1180, "y": 260},
			{"x": 1350, "y": 360}
		],
		"stars": [
			{"x": 400, "y": 280}, {"x": 750, "y": 100}, {"x": 1350, "y": 320}
		],
		"powerups": [
			{"x": 700, "y": 300, "type": "wall_climb"}
		],
		"enemies": [
			{"x": 300, "y": 440, "min_x": 250, "max_x": 350},
			{"x": 600, "y": 440, "min_x": 550, "max_x": 700},
			{"x": 900, "y": 280, "min_x": 850, "max_x": 1000},
			{"x": 1200, "y": 380, "min_x": 1150, "max_x": 1300}
		],
		"goal": {"x": 1350, "y": 370}
	},
	# NEW! Underwater Temple - Underwater themed level (v2.6)
	{
		"name": "Underwater Temple",
		"bg_color": Color(0.02, 0.15, 0.25),
		"platforms": [
			{"x": 50, "y": 500, "w": 150, "h": 30},
			{"x": 250, "y": 450, "w": 100, "h": 20},
			{"x": 100, "y": 350, "w": 80, "h": 20},
			{"x": 250, "y": 280, "w": 100, "h": 20},
			{"x": 450, "y": 350, "w": 80, "h": 20},
			{"x": 600, "y": 420, "w": 100, "h": 20},
			{"x": 750, "y": 350, "w": 80, "h": 20},
			{"x": 900, "y": 280, "w": 100, "h": 20},
			{"x": 1100, "y": 350, "w": 80, "h": 20},
			{"x": 1250, "y": 280, "w": 100, "h": 20},
			{"x": 1400, "y": 350, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 80, "y": 430}, {"x": 280, "y": 380},
			{"x": 120, "y": 280}, {"x": 280, "y": 210},
			{"x": 470, "y": 280}, {"x": 630, "y": 350},
			{"x": 770, "y": 280}, {"x": 930, "y": 210},
			{"x": 1120, "y": 280}, {"x": 1280, "y": 210},
			{"x": 1450, "y": 280}
		],
		"stars": [
			{"x": 150, "y": 200}, {"x": 650, "y": 180}, {"x": 1450, "y": 200}
		],
		"powerups": [
			{"x": 500, "y": 250, "type": "double_jump"}
		],
		"enemies": [
			{"x": 300, "y": 400, "min_x": 250, "max_x": 350, "type": "jellyfish"},
			{"x": 650, "y": 350, "min_x": 600, "max_x": 700, "type": "jellyfish"},
			{"x": 1000, "y": 280, "min_x": 900, "max_x": 1100, "type": "jellyfish"},
			{"x": 1300, "y": 230, "min_x": 1250, "max_x": 1350, "type": "jellyfish"}
		],
		"jellyfish_mode": true,
		"goal": {"x": 1450, "y": 300}
	},
	# NEW! Space Station - Sci-fi space themed level (v2.8)
	{
		"name": "Space Station",
		"bg_color": Color(0.02, 0.02, 0.1),
		"space_theme": true,
		"platforms": [
			{"x": 50, "y": 500, "w": 150, "h": 30},
			{"x": 250, "y": 450, "w": 80, "h": 20},
			{"x": 400, "y": 380, "w": 80, "h": 20},
			{"x": 550, "y": 300, "w": 100, "h": 20},
			{"x": 400, "y": 220, "w": 80, "h": 20},
			{"x": 250, "y": 150, "w": 100, "h": 20},
			{"x": 450, "y": 80, "w": 80, "h": 20},
			{"x": 650, "y": 150, "w": 100, "h": 20},
			{"x": 850, "y": 220, "w": 80, "h": 20},
			{"x": 1000, "y": 300, "w": 100, "h": 20},
			{"x": 1150, "y": 380, "w": 80, "h": 20},
			{"x": 1300, "y": 450, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 80, "y": 430}, {"x": 270, "y": 380},
			{"x": 420, "y": 310}, {"x": 580, "y": 230},
			{"x": 420, "y": 150}, {"x": 270, "y": 80},
			{"x": 470, "y": 10}, {"x": 680, "y": 80},
			{"x": 870, "y": 150}, {"x": 1030, "y": 230},
			{"x": 1170, "y": 310}, {"x": 1330, "y": 380}
		],
		"stars": [
			{"x": 280, "y": 50}, {"x": 680, "y": 80}, {"x": 1330, "y": 380}
		],
		"powerups": [
			{"x": 900, "y": 150, "type": "dash"}
		],
		"enemies": [
			{"x": 550, "y": 240, "min_x": 500, "max_x": 600, "type": "teleport"},
			{"x": 900, "y": 160, "min_x": 850, "max_x": 950, "type": "flying"},
			{"x": 1200, "y": 310, "min_x": 1150, "max_x": 1250, "type": "slime"}
		],
		"goal": {"x": 1450, "y": 230}
	},
	# NEW! Candy World - Rainbow candy themed level (v5.3)
	{
		"name": "Candy World",
		"bg_color": Color(0.95, 0.85, 0.9),
		"candy_theme": true,
		"platforms": [
			{"x": 50, "y": 520, "w": 120, "h": 30, "candy": "pink"},
			{"x": 200, "y": 460, "w": 100, "h": 25, "candy": "blue"},
			{"x": 80, "y": 380, "w": 80, "h": 25, "candy": "yellow"},
			{"x": 280, "y": 300, "w": 100, "h": 25, "candy": "green"},
			{"x": 450, "y": 380, "w": 80, "h": 25, "candy": "purple"},
			{"x": 600, "y": 300, "w": 100, "h": 25, "candy": "pink"},
			{"x": 450, "y": 180, "w": 80, "h": 25, "candy": "blue"},
			{"x": 650, "y": 120, "w": 100, "h": 25, "candy": "yellow"},
			{"x": 850, "y": 200, "w": 120, "h": 25, "candy": "green"},
			{"x": 1050, "y": 280, "w": 100, "h": 25, "candy": "purple"},
			{"x": 1200, "y": 200, "w": 80, "h": 25, "candy": "pink"},
			{"x": 1350, "y": 280, "w": 150, "h": 25, "candy": "blue"}
		],
		"coins": [
			{"x": 80, "y": 450}, {"x": 230, "y": 390},
			{"x": 110, "y": 310}, {"x": 310, "y": 230},
			{"x": 470, "y": 310}, {"x": 630, "y": 230},
			{"x": 480, "y": 110}, {"x": 680, "y": 50},
			{"x": 880, "y": 130}, {"x": 1080, "y": 210},
			{"x": 1230, "y": 130}, {"x": 1400, "y": 210}
		],
		"stars": [
			{"x": 280, "y": 180}, {"x": 680, "y": 80}, {"x": 1430, "y": 210}
		],
		"powerups": [
			{"x": 450, "y": 100, "type": "time_rewind"}
		],
		"rainbow_coins": [
			{"x": 350, "y": 250}, {"x": 750, "y": 150}, {"x": 1150, "y": 180}
		],
		"enemies": [
			{"x": 230, "y": 420, "min_x": 200, "max_x": 300, "type": "slime"},
			{"x": 480, "y": 340, "min_x": 450, "max_x": 550, "type": "jellyfish"},
			{"x": 750, "y": 80, "min_x": 700, "max_x": 800, "type": "flying"}
		],
		"goal": {"x": 1450, "y": 230}
	},
	# NEW! Lava Lake - Molten lava themed level (v5.4)
	{
		"name": "Lava Lake",
		"bg_color": Color(0.25, 0.08, 0.05),
		"lava_theme": true,
		"platforms": [
			{"x": 50, "y": 550, "w": 100, "h": 25, "lava": true},
			{"x": 200, "y": 480, "w": 80, "h": 25, "lava": true},
			{"x": 80, "y": 380, "w": 80, "h": 25, "lava": true},
			{"x": 250, "y": 320, "w": 80, "h": 25, "lava": true},
			{"x": 400, "y": 400, "w": 100, "h": 25, "lava": true},
			{"x": 550, "y": 300, "w": 80, "h": 25, "lava": true},
			{"x": 700, "y": 380, "w": 80, "h": 25, "lava": true},
			{"x": 850, "y": 280, "w": 80, "h": 25, "lava": true},
			{"x": 680, "y": 150, "w": 100, "h": 25, "lava": true},
			{"x": 880, "y": 100, "w": 80, "h": 25, "lava": true},
			{"x": 1050, "y": 180, "w": 100, "h": 25, "lava": true},
			{"x": 1200, "y": 250, "w": 80, "h": 25, "lava": true},
			{"x": 1350, "y": 350, "w": 100, "h": 25, "lava": true}
		],
		"coins": [
			{"x": 60, "y": 480}, {"x": 220, "y": 410},
			{"x": 100, "y": 310}, {"x": 270, "y": 250},
			{"x": 420, "y": 330}, {"x": 570, "y": 230},
			{"x": 720, "y": 310}, {"x": 870, "y": 210},
			{"x": 710, "y": 80}, {"x": 900, "y": 30},
			{"x": 1080, "y": 110}, {"x": 1220, "y": 180},
			{"x": 1380, "y": 280}
		],
		"stars": [
			{"x": 250, "y": 250}, {"x": 880, "y": 50}, {"x": 1400, "y": 280}
		],
		"powerups": [
			{"x": 680, "y": 80, "type": "invincible"}
		],
		"enemies": [
			{"x": 220, "y": 440, "min_x": 200, "max_x": 280, "type": "fireball"},
			{"x": 420, "y": 360, "min_x": 400, "max_x": 500, "type": "slime"},
			{"x": 570, "y": 260, "min_x": 550, "max_x": 630, "type": "flying"},
			{"x": 870, "y": 230, "min_x": 850, "max_x": 930, "type": "fireball"}
		],
		"goal": {"x": 1430, "y": 300}
	},
	# NEW! Magic Forest - Mystical forest with phantom enemies (v6.0)
	{
		"name": "Magic Forest",
		"bg_color": Color(0.05, 0.15, 0.1),
		"magic_theme": true,
		"platforms": [
			{"x": 50, "y": 550, "w": 150, "h": 30},
			{"x": 250, "y": 480, "w": 100, "h": 20},
			{"x": 100, "y": 380, "w": 80, "h": 20},
			{"x": 280, "y": 300, "w": 100, "h": 20},
			{"x": 450, "y": 380, "w": 80, "h": 20},
			{"x": 600, "y": 300, "w": 100, "h": 20},
			{"x": 450, "y": 180, "w": 80, "h": 20},
			{"x": 650, "y": 120, "w": 100, "h": 20},
			{"x": 850, "y": 200, "w": 80, "h": 20},
			{"x": 1000, "y": 280, "w": 100, "h": 20},
			{"x": 1200, "y": 350, "w": 80, "h": 20},
			{"x": 1350, "y": 280, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 80, "y": 480}, {"x": 270, "y": 420},
			{"x": 120, "y": 310}, {"x": 300, "y": 230},
			{"x": 470, "y": 310}, {"x": 630, "y": 230},
			{"x": 480, "y": 110}, {"x": 680, "y": 50},
			{"x": 870, "y": 130}, {"x": 1030, "y": 210},
			{"x": 1220, "y": 280}, {"x": 1400, "y": 210}
		],
		"stars": [
			{"x": 300, "y": 180}, {"x": 680, "y": 80}, {"x": 1400, "y": 180}
		],
		"runes": [
			{"x": 500, "y": 250}, {"x": 900, "y": 150}, {"x": 1300, "y": 200}
		],
		"powerups": [
			{"x": 750, "y": 80, "type": "teleport"}
		],
		"enemies": [
			{"x": 300, "y": 440, "min_x": 250, "max_x": 350, "type": "slime"},
			{"x": 600, "y": 260, "min_x": 550, "max_x": 650, "type": "phantom_mage"},
			{"x": 1000, "y": 240, "min_x": 950, "max_x": 1050, "type": "shadow_ninja"}
		],
		"goal": {"x": 1450, "y": 230}
	},
	# NEW! Crystal Tower - Vertical climbing level (v6.1)
	{
		"name": "Crystal Tower",
		"bg_color": Color(0.1, 0.2, 0.3),
		"platforms": [
			{"x": 50, "y": 550, "w": 150, "h": 30},
			{"x": 150, "y": 480, "w": 80, "h": 20},
			{"x": 80, "y": 400, "w": 80, "h": 20},
			{"x": 180, "y": 320, "w": 80, "h": 20},
			{"x": 100, "y": 240, "w": 80, "h": 20},
			{"x": 200, "y": 160, "w": 80, "h": 20},
			{"x": 350, "y": 200, "w": 100, "h": 20},
			{"x": 500, "y": 280, "w": 80, "h": 20},
			{"x": 650, "y": 350, "w": 100, "h": 20},
			{"x": 800, "y": 420, "w": 80, "h": 20},
			{"x": 950, "y": 350, "w": 80, "h": 20},
			{"x": 1100, "y": 280, "w": 100, "h": 20},
			{"x": 1250, "y": 200, "w": 150, "h": 20}
		],
		"coins": [
			{"x": 80, "y": 480}, {"x": 160, "y": 410},
			{"x": 100, "y": 330}, {"x": 200, "y": 250},
			{"x": 120, "y": 170}, {"x": 220, "y": 90},
			{"x": 370, "y": 130}, {"x": 520, "y": 210},
			{"x": 670, "y": 280}, {"x": 820, "y": 350},
			{"x": 970, "y": 280}, {"x": 1130, "y": 210},
			{"x": 1300, "y": 130}
		],
		"stars": [
			{"x": 200, "y": 50}, {"x": 650, "y": 200}, {"x": 1300, "y": 100}
		],
		"runes": [
			{"x": 400, "y": 150}
		],
		"enemies": [
			{"x": 180, "y": 440, "min_x": 150, "max_x": 250, "type": "flying"},
			{"x": 200, "y": 120, "min_x": 150, "max_x": 250, "type": "jellyfish"},
			{"x": 650, "y": 310, "min_x": 600, "max_x": 700, "type": "slime"},
			{"x": 1100, "y": 240, "min_x": 1050, "max_x": 1150, "type": "phantom_mage"}
		],
		"goal": {"x": 1350, "y": 150}
	},
	# NEW! Cherry Blossom Garden - Japanese themed level (v6.2)
	{
		"name": "Cherry Blossom Garden",
		"bg_color": Color(0.15, 0.08, 0.12),
		"cherry_blossom_theme": true,
		"platforms": [
			{"x": 50, "y": 500, "w": 120, "h": 30},
			{"x": 200, "y": 450, "w": 100, "h": 25},
			{"x": 80, "y": 350, "w": 80, "h": 25},
			{"x": 250, "y": 280, "w": 100, "h": 25},
			{"x": 450, "y": 350, "w": 80, "h": 25},
			{"x": 600, "y": 280, "w": 100, "h": 25},
			{"x": 450, "y": 180, "w": 80, "h": 25},
			{"x": 650, "y": 120, "w": 100, "h": 25},
			{"x": 850, "y": 200, "w": 80, "h": 25},
			{"x": 1000, "y": 280, "w": 100, "h": 25},
			{"x": 1200, "y": 350, "w": 80, "h": 25},
			{"x": 1350, "y": 280, "w": 150, "h": 25}
		],
		"coins": [
			{"x": 80, "y": 430}, {"x": 230, "y": 380},
			{"x": 110, "y": 280}, {"x": 280, "y": 210},
			{"x": 470, "y": 280}, {"x": 630, "y": 210},
			{"x": 480, "y": 110}, {"x": 680, "y": 50},
			{"x": 870, "y": 130}, {"x": 1030, "y": 210},
			{"x": 1220, "y": 280}, {"x": 1400, "y": 210}
		],
		"stars": [
			{"x": 280, "y": 150}, {"x": 680, "y": 80}, {"x": 1430, "y": 210}
		],
		"powerups": [
			{"x": 450, "y": 100, "type": "energy_shield"}
		],
		"enemies": [
			{"x": 250, "y": 400, "min_x": 200, "max_x": 300, "type": "slime"},
			{"x": 600, "y": 230, "min_x": 550, "max_x": 650, "type": "phantom_mage"},
			{"x": 1000, "y": 240, "min_x": 950, "max_x": 1050, "type": "slime"}
		],
		"goal": {"x": 1450, "y": 230}
	},
	# NEW! Neon City - Cyberpunk themed level (v6.4)
	{
		"name": "Neon City",
		"bg_color": Color(0.02, 0.05, 0.12),
		"neon_theme": true,
		"platforms": [
			{"x": 50, "y": 550, "w": 150, "h": 30},
			{"x": 250, "y": 480, "w": 100, "h": 25},
			{"x": 100, "y": 380, "w": 80, "h": 25},
			{"x": 280, "y": 300, "w": 100, "h": 25},
			{"x": 450, "y": 380, "w": 80, "h": 25},
			{"x": 600, "y": 300, "w": 100, "h": 25},
			{"x": 450, "y": 180, "w": 80, "h": 25},
			{"x": 650, "y": 120, "w": 100, "h": 25},
			{"x": 850, "y": 200, "w": 80, "h": 25},
			{"x": 1000, "y": 280, "w": 100, "h": 25},
			{"x": 1200, "y": 350, "w": 80, "h": 25},
			{"x": 1350, "y": 280, "w": 150, "h": 25}
		],
		"coins": [
			{"x": 80, "y": 480}, {"x": 270, "y": 420},
			{"x": 120, "y": 310}, {"x": 300, "y": 230},
			{"x": 470, "y": 310}, {"x": 630, "y": 230},
			{"x": 480, "y": 110}, {"x": 680, "y": 50},
			{"x": 870, "y": 130}, {"x": 1030, "y": 210},
			{"x": 1220, "y": 280}, {"x": 1400, "y": 210}
		],
		"stars": [
			{"x": 280, "y": 180}, {"x": 680, "y": 80}, {"x": 1430, "y": 210}
		],
		"powerups": [
			{"x": 450, "y": 100, "type": "tracking_projectile"}
		],
		"enemies": [
			{"x": 250, "y": 400, "min_x": 200, "max_x": 300, "type": "sprint"},
			{"x": 600, "y": 230, "min_x": 550, "max_x": 650, "type": "orb"},
			{"x": 1000, "y": 240, "min_x": 950, "max_x": 1050, "type": "teleport"}
		],
		"goal": {"x": 1450, "y": 230}
	},
	# NEW! Crystal Cavern - Crystal themed level (v6.5)
	{
		"name": "Crystal Cavern",
		"bg_color": Color(0.05, 0.1, 0.15),
		"platforms": [
			{"x": 50, "y": 550, "w": 150, "h": 30},
			{"x": 250, "y": 480, "w": 100, "h": 25},
			{"x": 100, "y": 380, "w": 80, "h": 25},
			{"x": 280, "y": 300, "w": 100, "h": 25},
			{"x": 450, "y": 380, "w": 80, "h": 25},
			{"x": 600, "y": 300, "w": 100, "h": 25},
			{"x": 450, "y": 180, "w": 80, "h": 25},
			{"x": 650, "y": 120, "w": 100, "h": 25},
			{"x": 850, "y": 200, "w": 80, "h": 25},
			{"x": 1000, "y": 280, "w": 100, "h": 25},
			{"x": 1200, "y": 350, "w": 80, "h": 25},
			{"x": 1350, "y": 280, "w": 150, "h": 25}
		],
		"coins": [
			{"x": 80, "y": 480}, {"x": 270, "y": 420},
			{"x": 120, "y": 310}, {"x": 300, "y": 230},
			{"x": 470, "y": 310}, {"x": 630, "y": 230},
			{"x": 480, "y": 110}, {"x": 680, "y": 50},
			{"x": 870, "y": 130}, {"x": 1030, "y": 210},
			{"x": 1220, "y": 280}, {"x": 1400, "y": 210}
		],
		"stars": [
			{"x": 280, "y": 180}, {"x": 680, "y": 80}, {"x": 1430, "y": 210}
		],
		"powerups": [
			{"x": 450, "y": 100, "type": "phase_shift"}
		],
		"enemies": [
			{"x": 250, "y": 400, "min_x": 200, "max_x": 300, "type": "jellyfish"},
			{"x": 600, "y": 230, "min_x": 550, "max_x": 650, "type": "electric"},
			{"x": 1000, "y": 240, "min_x": 950, "max_x": 1050, "type": "chaser"}
		],
		"goal": {"x": 1450, "y": 230}
	},
	# NEW! Desert Oasis - Desert themed level (v6.6)
	{
		"name": "Desert Oasis",
		"bg_color": Color(0.2, 0.15, 0.08),
		"weather": "sandstorm",
		"platforms": [
			{"x": 50, "y": 550, "w": 150, "h": 30},
			{"x": 250, "y": 480, "w": 100, "h": 25},
			{"x": 100, "y": 380, "w": 80, "h": 25},
			{"x": 280, "y": 300, "w": 100, "h": 25},
			{"x": 450, "y": 380, "w": 80, "h": 25},
			{"x": 600, "y": 300, "w": 100, "h": 25},
			{"x": 450, "y": 180, "w": 80, "h": 25},
			{"x": 650, "y": 120, "w": 100, "h": 25},
			{"x": 850, "y": 200, "w": 80, "h": 25},
			{"x": 1000, "y": 280, "w": 100, "h": 25},
			{"x": 1200, "y": 350, "w": 80, "h": 25},
			{"x": 1350, "y": 280, "w": 150, "h": 25}
		],
		"coins": [
			{"x": 80, "y": 480}, {"x": 270, "y": 420},
			{"x": 120, "y": 310}, {"x": 300, "y": 230},
			{"x": 470, "y": 310}, {"x": 630, "y": 230},
			{"x": 480, "y": 110}, {"x": 680, "y": 50},
			{"x": 870, "y": 130}, {"x": 1030, "y": 210},
			{"x": 1220, "y": 280}, {"x": 1400, "y": 210}
		],
		"stars": [
			{"x": 280, "y": 180}, {"x": 680, "y": 80}, {"x": 1430, "y": 210}
		],
		"powerups": [
			{"x": 450, "y": 100, "type": "speed"}
		],
		"enemies": [
			{"x": 250, "y": 400, "min_x": 200, "max_x": 300, "type": "slime"},
			{"x": 600, "y": 230, "min_x": 550, "max_x": 650, "type": "flying"},
			{"x": 1000, "y": 240, "min_x": 950, "max_x": 1050, "type": "suicide"}
		],
		"goal": {"x": 1450, "y": 230}
	},
	# NEW! Frozen Tundra - Ice themed level (v6.7)
	{
		"name": "Frozen Tundra",
		"bg_color": Color(0.1, 0.15, 0.2),
		"weather": "snow",
		"platforms": [
			{"x": 50, "y": 550, "w": 150, "h": 30},
			{"x": 250, "y": 480, "w": 100, "h": 25},
			{"x": 100, "y": 380, "w": 80, "h": 25},
			{"x": 280, "y": 300, "w": 100, "h": 25},
			{"x": 450, "y": 380, "w": 80, "h": 25},
			{"x": 600, "y": 300, "w": 100, "h": 25},
			{"x": 450, "y": 180, "w": 80, "h": 25},
			{"x": 650, "y": 120, "w": 100, "h": 25},
			{"x": 850, "y": 200, "w": 80, "h": 25},
			{"x": 1000, "y": 280, "w": 100, "h": 25},
			{"x": 1200, "y": 350, "w": 80, "h": 25},
			{"x": 1350, "y": 280, "w": 150, "h": 25}
		],
		"coins": [
			{"x": 80, "y": 480}, {"x": 270, "y": 420},
			{"x": 120, "y": 310}, {"x": 300, "y": 230},
			{"x": 470, "y": 310}, {"x": 630, "y": 230},
			{"x": 480, "y": 110}, {"x": 680, "y": 50},
			{"x": 870, "y": 130}, {"x": 1030, "y": 210},
			{"x": 1220, "y": 280}, {"x": 1400, "y": 210}
		],
		"stars": [
			{"x": 280, "y": 180}, {"x": 680, "y": 80}, {"x": 1430, "y": 210}
		],
		"powerups": [
			{"x": 450, "y": 100, "type": "freeze"}
		],
		"enemies": [
			{"x": 250, "y": 400, "min_x": 200, "max_x": 300, "type": "ice"},
			{"x": 600, "y": 230, "min_x": 550, "max_x": 650, "type": "slime"},
			{"x": 1000, "y": 240, "min_x": 950, "max_x": 1050, "type": "spike_ball"}
		],
		"goal": {"x": 1450, "y": 230}
	},
	# NEW! Haunted Mansion - Spooky themed level (v6.8)
	{
		"name": "Haunted Mansion",
		"bg_color": Color(0.08, 0.05, 0.1),
		"platforms": [
			{"x": 50, "y": 550, "w": 150, "h": 30},
			{"x": 250, "y": 480, "w": 100, "h": 25},
			{"x": 100, "y": 380, "w": 80, "h": 25},
			{"x": 280, "y": 300, "w": 100, "h": 25},
			{"x": 450, "y": 380, "w": 80, "h": 25},
			{"x": 600, "y": 300, "w": 100, "h": 25},
			{"x": 450, "y": 180, "w": 80, "h": 25},
			{"x": 650, "y": 120, "w": 100, "h": 25},
			{"x": 850, "y": 200, "w": 80, "h": 25},
			{"x": 1000, "y": 280, "w": 100, "h": 25},
			{"x": 1200, "y": 350, "w": 80, "h": 25},
			{"x": 1350, "y": 280, "w": 150, "h": 25}
		],
		"coins": [
			{"x": 80, "y": 480}, {"x": 270, "y": 420},
			{"x": 120, "y": 310}, {"x": 300, "y": 230},
			{"x": 470, "y": 310}, {"x": 630, "y": 230},
			{"x": 480, "y": 110}, {"x": 680, "y": 50},
			{"x": 870, "y": 130}, {"x": 1030, "y": 210},
			{"x": 1220, "y": 280}, {"x": 1400, "y": 210}
		],
		"stars": [
			{"x": 280, "y": 180}, {"x": 680, "y": 80}, {"x": 1430, "y": 210}
		],
		"powerups": [
			{"x": 450, "y": 100, "type": "shadow_clone"}
		],
		"enemies": [
			{"x": 250, "y": 400, "min_x": 200, "max_x": 300, "type": "phantom_mage"},
			{"x": 600, "y": 230, "min_x": 550, "max_x": 650, "type": "mimic"},
			{"x": 1000, "y": 240, "min_x": 950, "max_x": 1050, "type": "shadow_ninja"}
		],
		"goal": {"x": 1450, "y": 230}
	},
	# NEW! Ancient Temple - Ancient ruins themed level (v6.9)
	{
		"name": "Ancient Temple",
		"bg_color": Color(0.15, 0.1, 0.05),
		"platforms": [
			{"x": 50, "y": 550, "w": 150, "h": 30},
			{"x": 250, "y": 480, "w": 100, "h": 25},
			{"x": 100, "y": 380, "w": 80, "h": 25},
			{"x": 280, "y": 300, "w": 100, "h": 25},
			{"x": 450, "y": 380, "w": 80, "h": 25},
			{"x": 600, "y": 300, "w": 100, "h": 25},
			{"x": 450, "y": 180, "w": 80, "h": 25},
			{"x": 650, "y": 120, "w": 100, "h": 25},
			{"x": 850, "y": 200, "w": 80, "h": 25},
			{"x": 1000, "y": 280, "w": 100, "h": 25},
			{"x": 1200, "y": 350, "w": 80, "h": 25},
			{"x": 1350, "y": 280, "w": 150, "h": 25}
		],
		"coins": [
			{"x": 80, "y": 480}, {"x": 270, "y": 420},
			{"x": 120, "y": 310}, {"x": 300, "y": 230},
			{"x": 470, "y": 310}, {"x": 630, "y": 230},
			{"x": 480, "y": 110}, {"x": 680, "y": 50},
			{"x": 870, "y": 130}, {"x": 1030, "y": 210},
			{"x": 1220, "y": 280}, {"x": 1400, "y": 210}
		],
		"stars": [
			{"x": 280, "y": 180}, {"x": 680, "y": 80}, {"x": 1430, "y": 210}
		],
		"runes": [
			{"x": 500, "y": 250}, {"x": 900, "y": 150}
		],
		"powerups": [
			{"x": 450, "y": 100, "type": "teleport"}
		],
		"enemies": [
			{"x": 250, "y": 400, "min_x": 200, "max_x": 300, "type": "portal_guardian"},
			{"x": 600, "y": 230, "min_x": 550, "max_x": 650, "type": "orb"},
			{"x": 1000, "y": 240, "min_x": 950, "max_x": 1050, "type": "chaser"}
		],
		"goal": {"x": 1450, "y": 230}
	},
	# NEW! Mystic Gardens - Magical garden themed level
	{
		"name": "Mystic Gardens",
		"bg_color": Color(0.1, 0.25, 0.15),
		"platforms": [
			{"x": 50, "y": 550, "w": 150, "h": 30},
			{"x": 250, "y": 500, "w": 100, "h": 25},
			{"x": 150, "y": 400, "w": 80, "h": 25},
			{"x": 350, "y": 350, "w": 100, "h": 25},
			{"x": 550, "y": 400, "w": 80, "h": 25},
			{"x": 450, "y": 250, "w": 100, "h": 25},
			{"x": 650, "y": 180, "w": 80, "h": 25},
			{"x": 850, "y": 250, "w": 100, "h": 25},
			{"x": 1050, "y": 320, "w": 80, "h": 25},
			{"x": 900, "y": 450, "w": 100, "h": 25},
			{"x": 1150, "y": 400, "w": 100, "h": 25},
			{"x": 1300, "y": 320, "w": 150, "h": 25}
		],
		"coins": [
			{"x": 80, "y": 480}, {"x": 280, "y": 430},
			{"x": 170, "y": 330}, {"x": 380, "y": 280},
			{"x": 570, "y": 330}, {"x": 480, "y": 180},
			{"x": 670, "y": 110}, {"x": 870, "y": 180},
			{"x": 1070, "y": 250}, {"x": 920, "y": 380},
			{"x": 1180, "y": 330}, {"x": 1350, "y": 250}
		],
		"stars": [
			{"x": 350, "y": 220}, {"x": 670, "y": 80}, {"x": 1380, "y": 250}
		],
		"runes": [
			{"x": 500, "y": 180}, {"x": 950, "y": 280}
		],
		"powerups": [
			{"x": 450, "y": 100, "type": "double_jump"}
		],
		"enemies": [
			{"x": 250, "y": 420, "min_x": 200, "max_x": 300, "type": "slime"},
			{"x": 550, "y": 330, "min_x": 500, "max_x": 600, "type": "jellyfish"},
			{"x": 1050, "y": 280, "min_x": 1000, "max_x": 1100, "type": "orb"}
		],
		"goal": {"x": 1400, "y": 270}
	},
	# NEW! Ancient Temple - Puzzle level with pressure plates and runes (v7.0)
	{
		"name": "Ancient Temple",
		"bg_color": Color(0.12, 0.1, 0.08),
		"platforms": [
			{"x": 50, "y": 550, "w": 180, "h": 40},      # Starting platform
			{"x": 300, "y": 480, "w": 120, "h": 25},     # Step 1
			{"x": 480, "y": 400, "w": 80, "h": 25},      # Middle
			{"x": 650, "y": 320, "w": 100, "h": 25},     # Upper
			{"x": 850, "y": 250, "w": 80, "h": 25},      # High
			{"x": 1050, "y": 320, "w": 100, "h": 25},    # Descend
			{"x": 1250, "y": 400, "w": 100, "h": 25},    # Low again
			{"x": 1400, "y": 500, "w": 150, "h": 40}     # Final platform
		],
		"coins": [
			{"x": 100, "y": 480}, {"x": 340, "y": 410},
			{"x": 500, "y": 330}, {"x": 680, "y": 250},
			{"x": 880, "y": 180}, {"x": 1080, "y": 250},
			{"x": 1280, "y": 330}, {"x": 1450, "y": 430}
		],
		"stars": [
			{"x": 500, "y": 200}, {"x": 850, "y": 100}, {"x": 1300, "y": 250}
		],
		"gems": [
			{"x": 880, "y": 120}
		],
		# 💎 Pressure Plates - Step on them to trigger effects
		"pressure_plates": [
			{"x": 350, "y": 445, "type": "spawn_enemy", "id": 0},   # Spawns enemy when stepped
			{"x": 700, "y": 285, "type": "reveal_coin", "id": 1},   # Reveals hidden coins
			{"x": 1100, "y": 285, "type": "unlock_shortcut", "id": 2}  # Opens shortcut path
		],
		# ✨ Magic Runes - Ancient symbols with power-ups
		"runes": [
			{"x": 150, "y": 480},    # Starting area - coin bonus
			{"x": 520, "y": 330},    # Middle area - power boost
			{"x": 900, "y": 180}     # High area - special reward
		],
		"enemies": [
			{"x": 400, "y": 350, "min_x": 300, "max_x": 480, "type": "slime"},
			{"x": 800, "y": 200, "min_x": 650, "max_x": 850, "type": "phantom_mage"}
		],
		"goal": {"x": 1450, "y": 450}
	}
]

func create_background_stars():
	stars_container = Node2D.new()
	stars_container.name = "Stars"
	add_child(stars_container)
	stars_container.z_index = -100  # Behind everything
	
	# 创建多层星空 - 远景（更小更暗）
	for i in range(80):
		var star = ColorRect.new()
		star.size = Vector2(1, 1)
		star.color = Color(0.6, 0.7, 1, randf_range(0.2, 0.4))
		star.position = Vector2(randf() * 1400, randf() * 800)
		star.add_to_group("star")
		star.add_to_group("star_far")
		stars_container.add_child(star)
	
	# 中景星星
	for i in range(40):
		var star = ColorRect.new()
		star.size = Vector2(2, 2)
		star.color = Color(0.8, 0.9, 1, randf_range(0.4, 0.7))
		star.position = Vector2(randf() * 1400, randf() * 800)
		star.add_to_group("star")
		star.add_to_group("star_mid")
		stars_container.add_child(star)
	
	# 近景星星（更亮）
	for i in range(20):
		var star = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(4):
			var angle = j * TAU / 4
			pts.append(Vector2(cos(angle), sin(angle)) * 2)
		star.polygon = pts
		star.color = Color(1, 1, 0.9)
		star.position = Vector2(randf() * 1400, randf() * 800)
		star.add_to_group("star")
		star.add_to_group("star_near")
		stars_container.add_child(star)

# ❄️ Ice crystal effect for Crystal Palace level
var ice_crystals_container: Node2D = null

func create_ice_crystals():
	# Remove existing ice crystals if any
	if ice_crystals_container:
		ice_crystals_container.queue_free()
	
	ice_crystals_container = Node2D.new()
	ice_crystals_container.name = "IceCrystals"
	add_child(ice_crystals_container)
	ice_crystals_container.z_index = -50  # Behind platforms but above background
	
	# Create floating ice crystals
	for i in range(30):
		var crystal = Polygon2D.new()
		# Diamond shape
		var pts = PackedVector2Array([
			Vector2(0, -8),    # Top
			Vector2(5, 0),     # Right
			Vector2(0, 8),     # Bottom
			Vector2(-5, 0)     # Left
		])
		crystal.polygon = pts
		crystal.color = Color(0.7, 0.9, 1.0, randf_range(0.3, 0.6))
		crystal.position = Vector2(randf() * 1400, randf() * 800)
		crystal.add_to_group("ice_crystal")
		ice_crystals_container.add_child(crystal)
		
		# Add gentle float animation
		var tween = create_tween()
		var start_pos = crystal.position
		var float_offset = randf_range(-20, 20)
		tween.set_loops()
		tween.tween_property(crystal, "position:y", start_pos.y + float_offset, randf_range(2.0, 4.0))
		tween.tween_property(crystal, "position:y", start_pos.y, randf_range(2.0, 4.0))

func clear_ice_crystals():
	if ice_crystals_container:
		ice_crystals_container.queue_free()
		ice_crystals_container = null

func clear_effects():
	clear_ice_crystals()
	clear_nebula_effect()
	clear_void_effect()
	clear_phoenix_effect()
	clear_abyss_effect()
	clear_aurora_effect()
	clear_weather_effect()
	clear_twilight_effect()
	clear_solar_effect()
	clear_pet_effect()
	clear_mirror_effect()
	clear_chaos_effect()
	clear_candy_effect()
	clear_lava_effect()
	clear_cherry_blossom_effect()

# 🪞 Mirror effect for Mirror World level
var mirror_container: Node2D = null

func create_mirror_effect():
	if mirror_container:
		mirror_container.queue_free()
	
	mirror_container = Node2D.new()
	mirror_container.name = "MirrorEffect"
	add_child(mirror_container)
	mirror_container.z_index = -60
	
	for i in range(25):
		var shard = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * randf_range(4, 8))
		shard.polygon = pts
		shard.color = Color(0.6, 0.8, 1, randf_range(0.2, 0.5))
		shard.position = Vector2(randf() * 1400, randf() * 800)
		mirror_container.add_child(shard)
		
		var tween = create_tween()
		var start_pos = shard.position
		tween.set_loops()
		tween.tween_property(shard, "position:y", start_pos.y - randf_range(20, 40), randf_range(2.0, 4.0))
		tween.tween_property(shard, "position:y", start_pos.y, randf_range(2.0, 4.0))
		
		var pulse_tween = create_tween()
		pulse_tween.set_loops()
		pulse_tween.tween_property(shard, "rotation", 0.1, randf_range(3.0, 5.0))
		pulse_tween.tween_property(shard, "rotation", -0.1, randf_range(3.0, 5.0))

func clear_mirror_effect():
	if mirror_container:
		mirror_container.queue_free()
		mirror_container = null

# 🔀 Chaos effect for Chaos Realm level
var chaos_container: Node2D = null

func create_chaos_effect():
	if chaos_container:
		chaos_container.queue_free()
	
	chaos_container = Node2D.new()
	chaos_container.name = "ChaosEffect"
	add_child(chaos_container)
	chaos_container.z_index = -60
	
	for i in range(30):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(4):
			var angle = j * TAU / 4
			pts.append(Vector2(cos(angle), sin(angle)) * randf_range(3, 7))
		particle.polygon = pts
		
		var color_choice = randi() % 4
		if color_choice == 0:
			particle.color = Color(1, 0.3, 0.3, randf_range(0.3, 0.6))
		elif color_choice == 1:
			particle.color = Color(0.3, 1, 0.3, randf_range(0.3, 0.6))
		elif color_choice == 2:
			particle.color = Color(0.3, 0.3, 1, randf_range(0.3, 0.6))
		else:
			particle.color = Color(1, 1, 0.3, randf_range(0.3, 0.6))
		
		particle.position = Vector2(randf() * 1400, randf() * 800)
		chaos_container.add_child(particle)
		
		var tween = create_tween()
		var start_pos = particle.position
		tween.set_loops()
		tween.tween_property(particle, "position", start_pos + Vector2(randf_range(-50, 50), randf_range(-50, 50)), randf_range(1.5, 3.0))
		tween.tween_property(particle, "position", start_pos, randf_range(1.5, 3.0))

func clear_chaos_effect():
	if chaos_container:
		chaos_container.queue_free()
		chaos_container = null

# 🍬 Candy effect for Candy World level
var candy_container: Node2D = null

func create_candy_effect():
	if candy_container:
		candy_container.queue_free()
	
	candy_container = Node2D.new()
	candy_container.name = "CandyEffect"
	add_child(candy_container)
	candy_container.z_index = -60
	
	for i in range(30):
		var candy = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * randf_range(3, 6))
		candy.polygon = pts
		
		var color_choice = randi() % 5
		if color_choice == 0:
			candy.color = Color(1, 0.7, 0.8, randf_range(0.3, 0.6))
		elif color_choice == 1:
			candy.color = Color(0.7, 0.9, 1, randf_range(0.3, 0.6))
		elif color_choice == 2:
			candy.color = Color(1, 0.9, 0.5, randf_range(0.3, 0.6))
		elif color_choice == 3:
			candy.color = Color(0.7, 1, 0.7, randf_range(0.3, 0.6))
		else:
			candy.color = Color(0.8, 0.7, 1, randf_range(0.3, 0.6))
		
		candy.position = Vector2(randf() * 1400, randf() * 600)
		candy_container.add_child(candy)
		
		var tween = create_tween()
		var start_pos = candy.position
		tween.set_loops()
		tween.tween_property(candy, "position:y", start_pos.y - randf_range(15, 30), randf_range(2.0, 4.0))
		tween.tween_property(candy, "position:y", start_pos.y, randf_range(2.0, 4.0))

func clear_candy_effect():
	if candy_container:
		candy_container.queue_free()
		candy_container = null

# 🌋 Lava effect for Lava Lake level
var lava_container: Node2D = null

func create_lava_effect():
	if lava_container:
		lava_container.queue_free()
	
	lava_container = Node2D.new()
	lava_container.name = "LavaEffect"
	add_child(lava_container)
	lava_container.z_index = -55
	
	for i in range(40):
		var bubble = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(8):
			var angle = j * TAU / 8
			pts.append(Vector2(cos(angle), sin(angle)) * randf_range(4, 8))
		bubble.polygon = pts
		bubble.color = Color(1, 0.5 + randf() * 0.3, 0.1, randf_range(0.3, 0.6))
		bubble.position = Vector2(randf() * 1400, randf() * 600 + 200)
		lava_container.add_child(bubble)
		
		var tween = create_tween()
		var start_pos = bubble.position
		tween.set_loops()
		tween.tween_property(bubble, "position:y", start_pos.y - randf_range(40, 80), randf_range(2.0, 4.0))
		tween.tween_property(bubble, "position:y", start_pos.y, randf_range(0.5, 1.0))
		
		var scale_tween = create_tween()
		scale_tween.set_loops()
		scale_tween.tween_property(bubble, "scale", Vector2(1.2, 1.2), randf_range(0.5, 1.0))
		scale_tween.tween_property(bubble, "scale", Vector2(1.0, 1.0), randf_range(0.5, 1.0))

func clear_lava_effect():
	if lava_container:
		lava_container.queue_free()
		lava_container = null

# 🌅 Twilight effect for Twilight Temple level
var twilight_container: Node2D = null

func create_twilight_effect():
	if twilight_container:
		twilight_container.queue_free()
	
	twilight_container = Node2D.new()
	twilight_container.name = "TwilightEffect"
	add_child(twilight_container)
	twilight_container.z_index = -60
	
	# Create floating spirit orbs
	for i in range(25):
		var orb = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * randf_range(3, 6))
		orb.polygon = pts
		# Twilight colors - purple, pink, orange
		var color_choice = randi() % 3
		if color_choice == 0:
			orb.color = Color(0.6, 0.3, 0.7, randf_range(0.3, 0.6))
		elif color_choice == 1:
			orb.color = Color(0.9, 0.4, 0.5, randf_range(0.3, 0.6))
		else:
			orb.color = Color(0.8, 0.5, 0.3, randf_range(0.3, 0.6))
		orb.position = Vector2(randf() * 1400, randf() * 800)
		twilight_container.add_child(orb)
		
		# Gentle float animation
		var tween = create_tween()
		var start_pos = orb.position
		tween.set_loops()
		tween.tween_property(orb, "position:y", start_pos.y - randf_range(20, 40), randf_range(3.0, 5.0))
		tween.tween_property(orb, "position:y", start_pos.y, randf_range(3.0, 5.0))
		
		# Pulse animation
		var pulse_tween = create_tween()
		pulse_tween.set_loops()
		pulse_tween.tween_property(orb, "scale", Vector2(1.2, 1.2), randf_range(1.5, 2.5))
		pulse_tween.tween_property(orb, "scale", Vector2(0.8, 0.8), randf_range(1.5, 2.5))

func clear_twilight_effect():
	if twilight_container:
		twilight_container.queue_free()
		twilight_container = null

# ☀️ Solar effect for Solar Core level
var solar_container: Node2D = null

func create_solar_effect():
	if solar_container:
		solar_container.queue_free()
	
	solar_container = Node2D.new()
	solar_container.name = "SolarEffect"
	add_child(solar_container)
	solar_container.z_index = -60
	
	# Create sun rays
	for i in range(12):
		var ray = ColorRect.new()
		ray.size = Vector2(4, randf_range(60, 100))
		ray.color = Color(1, 0.9, 0.4, randf_range(0.1, 0.25))
		ray.position = Vector2(randf() * 1400, randf() * 200)
		ray.rotation = randf() * TAU
		solar_container.add_child(ray)
		
		# Rotate animation
		var tween = create_tween()
		tween.set_loops()
		var rotation_dir = 1 if randf() > 0.5 else -1
		tween.tween_property(ray, "rotation", ray.rotation + rotation_dir * 0.1, randf_range(5.0, 8.0))
		tween.tween_property(ray, "rotation", ray.rotation, randf_range(5.0, 8.0))
	
	# Create floating light particles
	for i in range(40):
		var particle = ColorRect.new()
		particle.size = Vector2(randf_range(3, 6), randf_range(3, 6))
		particle.color = Color(1, 0.9, 0.5, randf_range(0.4, 0.7))
		particle.position = Vector2(randf() * 1400, randf() * 800)
		solar_container.add_child(particle)
		
		# Float animation
		var tween = create_tween()
		var start_pos = particle.position
		tween.set_loops()
		tween.tween_property(particle, "position:y", start_pos.y - randf_range(30, 60), randf_range(2.0, 4.0))
		tween.tween_property(particle, "position:y", start_pos.y, randf_range(2.0, 4.0))

func clear_solar_effect():
	if solar_container:
		solar_container.queue_free()
		solar_container = null

# 🌈 Aurora effect for special levels
var aurora_container: Node2D = null

func create_aurora_effect():
	if aurora_container:
		aurora_container.queue_free()
	
	aurora_container = Node2D.new()
	aurora_container.name = "AuroraEffect"
	add_child(aurora_container)
	aurora_container.z_index = -60
	
	# Create aurora curtains (colored waves)
	for i in range(8):
		var aurora = Polygon2D.new()
		var center = Vector2(randf() * 1400, randf() * 200 + 50)
		var pts = PackedVector2Array()
		var num_points = 20
		for j in range(num_points):
			var angle = j * TAU / num_points
			var radius = randf_range(80, 150)
			pts.append(Vector2(cos(angle), sin(angle)) * radius)
		aurora.polygon = pts
		
		# Random aurora colors - green, cyan, pink, purple
		var color_choice = randi() % 4
		if color_choice == 0:
			aurora.color = Color(0.2, 0.9, 0.4, randf_range(0.1, 0.25))
		elif color_choice == 1:
			aurora.color = Color(0.2, 0.8, 0.7, randf_range(0.1, 0.25))
		elif color_choice == 2:
			aurora.color = Color(0.9, 0.3, 0.6, randf_range(0.1, 0.25))
		else:
			aurora.color = Color(0.5, 0.3, 0.9, randf_range(0.1, 0.25))
		
		aurora.position = center
		aurora.add_to_group("aurora")
		aurora_container.add_child(aurora)
		
		# Wave animation
		var tween = create_tween()
		tween.set_loops()
		var wave_offset = randf_range(0.5, 1.5)
		tween.tween_property(aurora, "position:y", center.y + randf_range(-20, 20), wave_offset)
		tween.tween_property(aurora, "position:y", center.y, wave_offset)
	
	# Add floating light particles
	for i in range(30):
		var particle = ColorRect.new()
		particle.size = Vector2(randf_range(2, 4), randf_range(2, 4))
		particle.color = Color(0.6, 1.0, 0.8, randf_range(0.3, 0.6))
		particle.position = Vector2(randf() * 1400, randf() * 300)
		aurora_container.add_child(particle)
		
		# Float animation
		var tween = create_tween()
		var start_pos = particle.position
		tween.set_loops()
		tween.tween_property(particle, "position:y", start_pos.y - randf_range(30, 60), randf_range(2.0, 4.0))
		tween.tween_property(particle, "position:y", start_pos.y, randf_range(2.0, 4.0))

func clear_aurora_effect():
	if aurora_container:
		aurora_container.queue_free()
		aurora_container = null

# 🌸 Cherry blossom effect for Japanese themed levels
var cherry_blossom_container: Node2D = null

func create_cherry_blossom_effect():
	if cherry_blossom_container:
		cherry_blossom_container.queue_free()
	
	cherry_blossom_container = Node2D.new()
	cherry_blossom_container.name = "CherryBlossomEffect"
	add_child(cherry_blossom_container)
	cherry_blossom_container.z_index = -50
	
	for i in range(40):
		var petal = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(5):
			var angle = j * TAU / 5
			pts.append(Vector2(cos(angle), sin(angle)) * randf_range(3, 6))
		petal.polygon = pts
		petal.color = Color(1, randf_range(0.7, 0.9), randf_range(0.8, 0.95), randf_range(0.6, 0.9))
		petal.position = Vector2(randf() * 1400, randf() * 800)
		cherry_blossom_container.add_child(petal)
		
		var tween = create_tween()
		var start_pos = petal.position
		tween.set_loops()
		var fall_speed = randf_range(3.0, 6.0)
		var drift = randf_range(-30, 30)
		var rot_speed = randf_range(-2, 2)
		tween.tween_property(petal, "position:y", petal.position.y + 400, fall_speed)
		tween.tween_property(petal, "position:x", petal.position.x + drift, fall_speed)
		tween.tween_property(petal, "rotation", petal.rotation + rot_speed, fall_speed)
		tween.tween_property(petal, "position:y", petal.position.y - 400, 0)
		tween.tween_property(petal, "position:x", petal.position.x, 0)
		tween.tween_property(petal, "rotation", petal.rotation, 0)

func clear_cherry_blossom_effect():
	if cherry_blossom_container:
		cherry_blossom_container.queue_free()
		cherry_blossom_container = null

# 🐾 Pet theme effect for Pet Haven level
var pet_effect_container: Node2D = null

func create_pet_effect():
	if pet_effect_container:
		pet_effect_container.queue_free()
	
	pet_effect_container = Node2D.new()
	pet_effect_container.name = "PetEffect"
	add_child(pet_effect_container)
	pet_effect_container.z_index = -50
	
	# Create floating hearts and sparkles
	for i in range(25):
		var sparkle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(4):
			var angle = j * TAU / 4
			pts.append(Vector2(cos(angle), sin(angle)) * randf_range(2, 5))
		sparkle.polygon = pts
		
		var color_choice = randi() % 3
		if color_choice == 0:
			sparkle.color = Color(1, 0.5, 0.7, randf_range(0.3, 0.6))
		elif color_choice == 1:
			sparkle.color = Color(1, 0.9, 0.5, randf_range(0.3, 0.6))
		else:
			sparkle.color = Color(0.5, 1, 0.8, randf_range(0.3, 0.6))
		
		sparkle.position = Vector2(randf() * 1400, randf() * 600)
		pet_effect_container.add_child(sparkle)
		
		var tween = create_tween()
		var start_pos = sparkle.position
		tween.set_loops()
		tween.tween_property(sparkle, "position:y", start_pos.y - randf_range(20, 40), randf_range(2.0, 4.0))
		tween.tween_property(sparkle, "position:y", start_pos.y, randf_range(2.0, 4.0))

func clear_pet_effect():
	if pet_effect_container:
		pet_effect_container.queue_free()
		pet_effect_container = null

# 🌌 Nebula effect for Nebula Nexus level
var nebula_container: Node2D = null

func create_nebula_effect():
	if nebula_container:
		nebula_container.queue_free()
	
	nebula_container = Node2D.new()
	nebula_container.name = "NebulaEffect"
	add_child(nebula_container)
	nebula_container.z_index = -60
	
	# Create nebula clouds (colored gradients)
	for i in range(15):
		var nebula = Polygon2D.new()
		var center = Vector2(randf() * 1400, randf() * 700)
		var pts = PackedVector2Array()
		var num_points = 12
		for j in range(num_points):
			var angle = j * TAU / num_points
			var radius = randf_range(60, 120)
			pts.append(Vector2(cos(angle), sin(angle)) * radius)
		nebula.polygon = pts
		
		# Random purple/pink colors
		var color_choice = randi() % 3
		if color_choice == 0:
			nebula.color = Color(0.4, 0.1, 0.5, randf_range(0.1, 0.25))
		elif color_choice == 1:
			nebula.color = Color(0.6, 0.2, 0.4, randf_range(0.1, 0.25))
		else:
			nebula.color = Color(0.2, 0.1, 0.4, randf_range(0.1, 0.25))
		
		nebula.position = center
		nebula.add_to_group("nebula")
		nebula_container.add_child(nebula)
		
		# Gentle rotation animation
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(nebula, "rotation", randf_range(-0.1, 0.1), randf_range(8.0, 12.0))
		tween.tween_property(nebula, "rotation", -randf_range(-0.1, 0.1), randf_range(8.0, 12.0))
	
	# Add floating cosmic dust
	for i in range(40):
		var dust = ColorRect.new()
		dust.size = Vector2(randf_range(2, 4), randf_range(2, 4))
		dust.color = Color(0.8, 0.6, 1.0, randf_range(0.2, 0.5))
		dust.position = Vector2(randf() * 1400, randf() * 800)
		dust.add_to_group("cosmic_dust")
		nebula_container.add_child(dust)
		
		# Float animation
		var tween = create_tween()
		var start_pos = dust.position
		var float_offset = randf_range(-30, 30)
		tween.set_loops()
		tween.tween_property(dust, "position:y", start_pos.y + float_offset, randf_range(3.0, 5.0))
		tween.tween_property(dust, "position:y", start_pos.y, randf_range(3.0, 5.0))

func clear_nebula_effect():
	if nebula_container:
		nebula_container.queue_free()
		nebula_container = null

# 🌑 Void effect for Void Dimension level
var void_container: Node2D = null

func create_void_effect():
	if void_container:
		void_container.queue_free()
	
	void_container = Node2D.new()
	void_container.name = "VoidEffect"
	add_child(void_container)
	void_container.z_index = -60
	
	# Create void portals (dark swirling areas)
	for i in range(10):
		var portal = Polygon2D.new()
		var center = Vector2(randf() * 1400, randf() * 700)
		var pts = PackedVector2Array()
		var num_points = 16
		for j in range(num_points):
			var angle = j * TAU / num_points
			var radius = randf_range(40, 80)
			pts.append(Vector2(cos(angle), sin(angle)) * radius)
		portal.polygon = pts
		
		# Dark void colors with subtle purple/blue glow
		var color_choice = randi() % 3
		if color_choice == 0:
			portal.color = Color(0.1, 0.05, 0.15, randf_range(0.15, 0.3))
		elif color_choice == 1:
			portal.color = Color(0.05, 0.1, 0.2, randf_range(0.15, 0.3))
		else:
			portal.color = Color(0.15, 0.05, 0.1, randf_range(0.15, 0.3))
		
		portal.position = center
		portal.add_to_group("void_portal")
		void_container.add_child(portal)
		
		# Swirling rotation animation
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(portal, "rotation", randf_range(0.2, 0.4), randf_range(10.0, 15.0))
		tween.tween_property(portal, "rotation", -randf_range(0.2, 0.4), randf_range(10.0, 15.0))
	
	# Add floating void particles
	for i in range(50):
		var particle = ColorRect.new()
		particle.size = Vector2(randf_range(1, 3), randf_range(1, 3))
		particle.color = Color(0.4, 0.3, 0.6, randf_range(0.15, 0.4))
		particle.position = Vector2(randf() * 1400, randf() * 800)
		particle.add_to_group("void_particle")
		void_container.add_child(particle)
		
		# Float animation
		var tween = create_tween()
		var start_pos = particle.position
		var float_offset = randf_range(-40, 40)
		tween.set_loops()
		tween.tween_property(particle, "position:y", start_pos.y + float_offset, randf_range(4.0, 6.0))
		tween.tween_property(particle, "position:y", start_pos.y, randf_range(4.0, 6.0))
	
	# Add dark energy wisps
	for i in range(20):
		var wisp = ColorRect.new()
		wisp.size = Vector2(randf_range(2, 5), randf_range(2, 5))
		wisp.color = Color(0.2, 0.1, 0.3, randf_range(0.2, 0.5))
		wisp.position = Vector2(randf() * 1400, randf() * 800)
		wisp.add_to_group("void_wisp")
		void_container.add_child(wisp)
		
		# Drift animation
		var tween = create_tween()
		var start_pos = wisp.position
		tween.set_loops()
		tween.tween_property(wisp, "position:x", start_pos.x + randf_range(-20, 20), randf_range(5.0, 8.0))
		tween.tween_property(wisp, "position:x", start_pos.x, randf_range(5.0, 8.0))

func clear_void_effect():
	if void_container:
		void_container.queue_free()
		void_container = null

# 🔥 Phoenix effect for Phoenix Realm level
var phoenix_container: Node2D = null

func create_phoenix_effect():
	if phoenix_container:
		phoenix_container.queue_free()
	
	phoenix_container = Node2D.new()
	phoenix_container.name = "PhoenixEffect"
	add_child(phoenix_container)
	phoenix_container.z_index = -60
	
	# Create floating fire embers
	for i in range(50):
		var ember = ColorRect.new()
		ember.size = Vector2(randf_range(2, 5), randf_range(2, 5))
		# Fire colors - orange, red, yellow
		var color_choice = randi() % 3
		if color_choice == 0:
			ember.color = Color(1, 0.5, 0.1, randf_range(0.4, 0.8))
		elif color_choice == 1:
			ember.color = Color(1, 0.2, 0.05, randf_range(0.4, 0.8))
		else:
			ember.color = Color(1, 0.8, 0.2, randf_range(0.4, 0.8))
		ember.position = Vector2(randf() * 1400, randf() * 800)
		phoenix_container.add_child(ember)
		
		# Float upward animation
		var tween = create_tween()
		var start_pos = ember.position
		tween.set_loops()
		tween.tween_property(ember, "position:y", start_pos.y - randf_range(50, 100), randf_range(2.0, 4.0))
		tween.tween_property(ember, "position:y", start_pos.y, randf_range(0.5, 1.0))
	
	# Create fire wisps
	for i in range(20):
		var wisp = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * randf_range(3, 6))
		wisp.polygon = pts
		wisp.color = Color(1, 0.4, 0.1, randf_range(0.3, 0.6))
		wisp.position = Vector2(randf() * 1400, randf() * 800)
		phoenix_container.add_child(wisp)
		
		# Flicker animation
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(wisp, "scale", Vector2(1.2, 1.2), randf_range(0.3, 0.6))
		tween.tween_property(wisp, "scale", Vector2(0.8, 0.8), randf_range(0.3, 0.6))

func clear_phoenix_effect():
	if phoenix_container:
		phoenix_container.queue_free()
		phoenix_container = null

# 🫧 Abyss effect for Abyss Core level
var abyss_container: Node2D = null

func create_abyss_effect():
	if abyss_container:
		abyss_container.queue_free()
	
	abyss_container = Node2D.new()
	abyss_container.name = "AbyssEffect"
	add_child(abyss_container)
	abyss_container.z_index = -60
	
	# Create bioluminescent creatures (glowing orbs)
	for i in range(30):
		var orb = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(8):
			var angle = j * TAU / 8
			pts.append(Vector2(cos(angle), sin(angle)) * randf_range(3, 7))
		orb.polygon = pts
		# Deep sea colors - blue, cyan, purple bioluminescence
		var color_choice = randi() % 3
		if color_choice == 0:
			orb.color = Color(0.2, 0.6, 1.0, randf_range(0.3, 0.6))
		elif color_choice == 1:
			orb.color = Color(0.3, 0.8, 0.7, randf_range(0.3, 0.6))
		else:
			orb.color = Color(0.6, 0.3, 0.9, randf_range(0.3, 0.6))
		orb.position = Vector2(randf() * 1400, randf() * 800)
		abyss_container.add_child(orb)
		
		# Gentle float animation
		var tween = create_tween()
		var start_pos = orb.position
		tween.set_loops()
		tween.tween_property(orb, "position:y", start_pos.y - randf_range(20, 40), randf_range(3.0, 5.0))
		tween.tween_property(orb, "position:y", start_pos.y, randf_range(3.0, 5.0))
		
		# Pulse animation
		var pulse_tween = create_tween()
		pulse_tween.set_loops()
		pulse_tween.tween_property(orb, "scale", Vector2(1.3, 1.3), randf_range(1.0, 2.0))
		pulse_tween.tween_property(orb, "scale", Vector2(0.7, 0.7), randf_range(1.0, 2.0))
	
	# Add floating particles (marine snow)
	for i in range(60):
		var particle = ColorRect.new()
		particle.size = Vector2(randf_range(1, 3), randf_range(1, 3))
		particle.color = Color(0.6, 0.8, 1.0, randf_range(0.1, 0.3))
		particle.position = Vector2(randf() * 1400, randf() * 800)
		abyss_container.add_child(particle)
		
		# Slow drift animation
		var tween = create_tween()
		var start_pos = particle.position
		tween.set_loops()
		tween.tween_property(particle, "position:y", start_pos.y + randf_range(-30, 30), randf_range(4.0, 7.0))
		tween.tween_property(particle, "position:y", start_pos.y, randf_range(4.0, 7.0))

func clear_abyss_effect():
	if abyss_container:
		abyss_container.queue_free()
		abyss_container = null

# 🌧️ Weather System - Rain, Snow, Fog
var weather_container: Node2D = null
enum WeatherType { NONE, RAIN, SNOW, FOG, STORM }

func create_weather_effect(weather_type: WeatherType):
	clear_weather_effect()
	
	if weather_type == WeatherType.NONE:
		return
	
	weather_container = Node2D.new()
	weather_container.name = "WeatherEffect"
	add_child(weather_container)
	weather_container.z_index = -40
	
	match weather_type:
		WeatherType.RAIN:
			create_rain_effect()
		WeatherType.SNOW:
			create_snow_effect()
		WeatherType.FOG:
			create_fog_effect()
		WeatherType.STORM:
			create_storm_effect()

func clear_weather_effect():
	if weather_container:
		weather_container.queue_free()
		weather_container = null

func create_rain_effect():
	# Rain drops falling
	for i in range(100):
		var drop = ColorRect.new()
		drop.size = Vector2(2, randf_range(8, 15))
		drop.color = Color(0.5, 0.6, 0.8, randf_range(0.3, 0.5))
		drop.position = Vector2(randf() * 1400, randf() * 800)
		weather_container.add_child(drop)
		
		var fall_speed = randf_range(300, 500)
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(drop, "position:y", drop.position.y + 600, fall_speed / 300)
		tween.tween_property(drop, "position:y", drop.position.y - 600, 0)

func create_snow_effect():
	# Snowflakes falling slowly
	for i in range(60):
		var snow = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * randf_range(2, 4))
		snow.polygon = pts
		snow.color = Color(1, 1, 1, randf_range(0.6, 0.9))
		snow.position = Vector2(randf() * 1400, randf() * 800)
		weather_container.add_child(snow)
		
		var tween = create_tween()
		tween.set_loops()
		var fall_speed = randf_range(2.0, 4.0)
		var drift = randf_range(-20, 20)
		tween.tween_property(snow, "position:y", snow.position.y + 400, fall_speed)
		tween.tween_property(snow, "position:x", snow.position.x + drift, fall_speed)
		tween.tween_property(snow, "position:y", snow.position.y - 400, 0)

func create_fog_effect():
	# Fog layers
	for i in range(5):
		var fog = ColorRect.new()
		fog.size = Vector2(400, 200)
		fog.color = Color(0.7, 0.7, 0.75, randf_range(0.15, 0.25))
		fog.position = Vector2(randf() * 1200, randf() * 400 + 100)
		weather_container.add_child(fog)
		
		var tween = create_tween()
		tween.set_loops()
		var move_speed = randf_range(5.0, 10.0)
		var drift = randf_range(-50, 50)
		tween.tween_property(fog, "position:x", fog.position.x + drift, move_speed)
		tween.tween_property(fog, "position:x", fog.position.x, move_speed)

func create_storm_effect():
	# Storm - heavy rain + lightning
	for i in range(150):
		var drop = ColorRect.new()
		drop.size = Vector2(2, randf_range(10, 20))
		drop.color = Color(0.4, 0.5, 0.7, randf_range(0.4, 0.6))
		drop.position = Vector2(randf() * 1400, randf() * 800)
		weather_container.add_child(drop)
		
		var fall_speed = randf_range(400, 700)
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(drop, "position:y", drop.position.y + 600, fall_speed / 400)
		tween.tween_property(drop, "position:y", drop.position.y - 600, 0)
	
	# Random lightning
	var lightning_timer = randf_range(3.0, 6.0)
	await get_tree().create_timer(lightning_timer).timeout
	if weather_container:
		spawn_lightning()
		create_storm_effect()  # Continue storm

func spawn_lightning():
	var flash = ColorRect.new()
	flash.size = Vector2(2000, 2000)
	flash.position = Vector2(-500, -500)
	flash.color = Color(0.8, 0.9, 1, 0.3)
	flash.z_index = 50
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.2)
	tween.tween_callback(flash.queue_free)
	
	screen_shake_intensity(8)

func show_level_name(level_name):
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		# Remove existing level name
		var existing = ui.get_node_or_null("LevelName")
		if existing: existing.queue_free()
		
		# 创建更大的容器来放置动画
		var container = Node2D.new()
		container.name = "LevelName"
		container.position = Vector2(640, 200)  # 屏幕中心
		ui.add_child(container)
		
		# 背景板
		var bg = ColorRect.new()
		bg.color = Color(0, 0, 0, 0.5)
		bg.size = Vector2(400, 60)
		bg.position = Vector2(-200, -30)
		bg.modulate.a = 0
		container.add_child(bg)
		
		# 主标题
		var name_label = Label.new()
		name_label.name = "LevelText"
		name_label.text = "🎮 " + level_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 42)
		name_label.add_theme_color_override("font_color", Color(0.2, 0.8, 1))
		name_label.position = Vector2(-100, -25)
		name_label.modulate.a = 0
		container.add_child(name_label)
		
		# 入场动画 - 缩放 + 淡入
		bg.modulate.a = 0
		name_label.modulate.a = 0
		container.scale = Vector2(0.5, 0.5)
		
		var tween = create_tween()
		# 弹跳入场
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(container, "scale", Vector2(1.1, 1.1), 0.4)
		tween.tween_property(container, "scale", Vector2(1, 1), 0.2)
		# 淡入背景和文字
		tween.parallel().tween_property(bg, "modulate:a", 0.7, 0.3)
		tween.parallel().tween_property(name_label, "modulate:a", 1.0, 0.3)
		# 停留
		tween.tween_interval(1.5)
		# 退场
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(container, "modulate:a", 0.0, 0.5)
		tween.tween_property(container, "position:y", container.position.y - 30, 0.5)
		tween.tween_callback(container.queue_free)

# 🎯 In-game hint system
var shown_hints = {}

func show_hint(hint_key: String, hint_text: String):
	# Don't show same hint twice per session
	if shown_hints.get(hint_key, false):
		return
	shown_hints[hint_key] = true
	
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	# Create hint container
	var hint_container = Node2D.new()
	hint_container.name = "Hint"
	hint_container.position = Vector2(640, 450)
	ui.add_child(hint_container)
	
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.15, 0.85)
	bg.size = Vector2(500, 50)
	bg.position = Vector2(-250, -25)
	hint_container.add_child(bg)
	
	# Hint text
	var hint_label = Label.new()
	hint_label.text = "💡 " + hint_text
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 18)
	hint_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.7))
	hint_label.position = Vector2(-100, -12)
	hint_container.add_child(hint_label)
	
	# Animate in
	hint_container.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(hint_container, "modulate:a", 1.0, 0.3)
	tween.tween_interval(4.0)
	tween.tween_property(hint_container, "modulate:a", 0.0, 0.5)
	tween.tween_property(hint_container, "position:y", hint_container.position.y - 20, 0.5)
	tween.tween_callback(hint_container.queue_free)

func show_level_hints(level_index: int):
	# Show hints based on level
	match level_index:
		0:
			show_hint("level_0_1", "Collect coins for points!")
			await get_tree().create_timer(2.0).timeout
			show_hint("level_0_2", "Jump on enemies to defeat them!")
		2:
			show_hint("level_2_1", "Moving platforms - time your jumps!")
		4:
			show_hint("level_4_1", "Floating islands - watch your step!")
		10:
			show_hint("level_10_1", "Boss battle! Watch for attacks!")
			await get_tree().create_timer(2.0).timeout
			show_hint("level_10_2", "Jump on the boss to deal damage!")

func update_stars_parallax():
	if stars_container and player:
		var cam_offset = Vector2.ZERO
		if player.get_child_count() > 0:
			var cam = player.get_node_or_null("Camera2D")
			if cam:
				cam_offset = cam.offset
		
		var time = Time.get_ticks_msec() / 1000.0
		
		# 不同层次的星星不同速度移动
		for star in stars_container.get_children():
			if star.is_in_group("star_far"):
				# 远景 - 最慢
				star.position.x -= cam_offset.x * 0.02
				star.modulate.a = 0.3 + 0.2 * sin(time * 2 + star.position.x)
			elif star.is_in_group("star_mid"):
				# 中景
				star.position.x -= cam_offset.x * 0.05
				star.modulate.a = 0.5 + 0.3 * sin(time * 3 + star.position.y)
			elif star.is_in_group("star_near"):
				# 近景 - 稍快
				star.position.x -= cam_offset.x * 0.08
				# 旋转效果
				star.rotation += 0.02
			
			# 视差包裹
			if star.position.x < 0:
				star.position.x += 1400
			elif star.position.x > 1400:
				star.position.x -= 1400
			if star.position.y < 0:
				star.position.y += 800
			elif star.position.y > 800:
				star.position.y -= 800

func _process(delta):
	# ⏸️ Handle pause
	if Input.is_action_just_pressed("pause"):
		toggle_pause()
	
	if is_paused:
		return
	
	if game_started and player:
		update_stars_parallax()
		# Update combo timer
		if combo_timer > 0:
			combo_timer -= delta
			if combo_timer <= 0:
				combo = 0
				update_combo_display()
		
		# Super combo timer
		if super_combo_active:
			super_combo_timer -= delta
			if super_combo_timer <= 0:
				super_combo_active = false
				combo_meter = 0.0
				# Reset player powers
				if player:
					player.speed_multiplier = 1.0
					if not player.is_invincible:  # Don't reset if has other invincibility
						player.modulate = Color.WHITE
		
		# Update combo meter display
		update_combo_meter_display()
		
		# Camera shake effect
		if screen_shake > 0:
			screen_shake -= delta * 30
			var cam = player.get_node_or_null("Camera2D")
			if cam:
				cam.offset = Vector2(randf_range(-screen_shake, screen_shake), randf_range(-screen_shake, screen_shake))
		else:
			var cam = player.get_node_or_null("Camera2D")
			if cam:
				cam.offset = Vector2.ZERO
		
		# Update level timer
		if level_start_time > 0:
			current_level_time = (Time.get_ticks_msec() / 1000.0) - level_start_time
			update_timer_display()
		
		# Check for secret area proximity
		check_secret_area_proximity()
		
		# Random event system - chance to trigger special events
		trigger_random_event(delta)
		
		# Health Regen ability - recover 1 life every 3 seconds
		if has_ability("health_regen") and player:
			health_regen_timer += delta
			if health_regen_timer >= 3.0:
				health_regen_timer = 0.0
				if lives < 99:  # Max 99 lives
					lives += 1
					update_lives_display()
					# Show recovery effect
					player.modulate = Color(0.3, 1.0, 0.3)
					await get_tree().create_timer(0.2).timeout
					player.modulate = Color.WHITE

func show_start_screen():
	game_started = false
	clear_level()
	
	var canvas = CanvasLayer.new()
	canvas.add_to_group("ui")
	add_child(canvas)
	
	# Center container for cleaner layout
	var container = VBoxContainer.new()
	container.position = Vector2(250, 80)
	container.add_theme_constant_override("separation", 15)
	canvas.add_child(container)
	
	# Animated title
	var title = Label.new()
	title.text = "🦞 LOBSTER PLATFORMER 🦞"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.2, 0.8, 1))
	container.add_child(title)
	
	# High score
	if high_score > 0:
		var hs = Label.new()
		hs.text = "🏆 High Score: " + str(high_score)
		hs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hs.add_theme_font_size_override("font_size", 18)
		hs.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		container.add_child(hs)
	
	# Controls info
	var instr = Label.new()
	instr.text = "🎮 Controls:\nArrow Keys / WASD: Move\nSpace: Jump\nESC: Pause\nShift: Dash | Z: Time Slow | X: Teleport\nC: Shadow Clone | V: Combo Finale"
	instr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instr.add_theme_font_size_override("font_size", 18)
	instr.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	container.add_child(instr)
	
	# Start button
	var start_btn = Button.new()
	start_btn.text = "🎮 Start Game"
	start_btn.custom_minimum_size = Vector2(200, 50)
	start_btn.pressed.connect(func(): start_game())
	container.add_child(start_btn)
	
	# Level Select button
	var level_select_btn = Button.new()
	level_select_btn.text = "🗺️ Level Select"
	level_select_btn.custom_minimum_size = Vector2(200, 50)
	level_select_btn.pressed.connect(func(): show_level_select())
	container.add_child(level_select_btn)
	
	# Time Trial button
	var time_trial_btn = Button.new()
	time_trial_btn.text = "⏱️ Time Trial"
	time_trial_btn.custom_minimum_size = Vector2(200, 50)
	time_trial_btn.pressed.connect(func(): start_time_trial())
	container.add_child(time_trial_btn)
	
	# Endless Mode button
	var endless_btn = Button.new()
	endless_btn.text = "♾️ Endless Mode"
	endless_btn.custom_minimum_size = Vector2(200, 50)
	endless_btn.pressed.connect(func(): start_endless_mode())
	container.add_child(endless_btn)
	
	# Daily Challenge button
	var daily_btn = Button.new()
	daily_btn.text = "📅 Daily Challenge"
	daily_btn.custom_minimum_size = Vector2(200, 50)
	daily_btn.pressed.connect(func(): start_daily_challenge())
	container.add_child(daily_btn)
	
	# Boss Rush button - NEW!
	var boss_rush_btn = Button.new()
	boss_rush_btn.text = "🐉 Boss Rush"
	boss_rush_btn.custom_minimum_size = Vector2(200, 50)
	boss_rush_btn.pressed.connect(func(): start_boss_rush())
	container.add_child(boss_rush_btn)
	
	# New Game+ button - Hard mode!
	var new_game_plus_btn = Button.new()
	new_game_plus_btn.text = "⭐ New Game+"
	new_game_plus_btn.custom_minimum_size = Vector2(200, 50)
	new_game_plus_btn.pressed.connect(func(): start_new_game_plus())
	container.add_child(new_game_plus_btn)
	
	# 🏪 Shop button - Buy abilities with coins
	var shop_btn = Button.new()
	shop_btn.text = "🏪 Shop (" + str(save_data["total_coins"]) + " coins)"
	shop_btn.custom_minimum_size = Vector2(200, 50)
	shop_btn.pressed.connect(func(): show_shop())
	container.add_child(shop_btn)
	
	# Metroidvania: 显示进度
	var progress_text = "💾 Progress:\n"
	progress_text += "🪙 Coins: " + str(save_data["total_coins"]) + " | "
	progress_text += "⭐ Stars: " + str(save_data["total_stars"]) + "\n"
	progress_text += "💎 Gems: " + str(save_data.get("total_gems", 0)) + " | "
	progress_text += "🔓 Levels: " + str(save_data["unlocked_levels"].size()) + "/" + str(levels.size())
	
	# 显示已解锁的能力
	if save_data["unlocked_abilities"].size() > 0:
		progress_text += "\n✨ Abilities: "
		for ab in save_data["unlocked_abilities"]:
			if ABILITIES.has(ab):
				progress_text += ABILITIES[ab]["icon"] + " "
	
	var progress = Label.new()
	progress.text = progress_text
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress.add_theme_font_size_override("font_size", 14)
	progress.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	container.add_child(progress)
	
	# Show unlocked achievements count
	var unlocked_count = 0
	for key in achievements:
		if achievements[key].get("unlocked", false):
			unlocked_count += 1
	
	if unlocked_count > 0:
		var ach = Label.new()
		ach.text = "🏆 Achievements: " + str(unlocked_count) + "/" + str(achievements.size())
		ach.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ach.add_theme_font_size_override("font_size", 14)
		ach.add_theme_color_override("font_color", Color(0.8, 0.9, 1))
		container.add_child(ach)
	
	# Version in bottom right
	var version = Label.new()
	version.text = "v6.9"
	version.position = Vector2(650, 550)
	version.add_theme_font_size_override("font_size", 14)
	version.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	canvas.add_child(version)

# 🏪 Shop System
var shop_items = {
	"double_jump": {"name": "Double Jump", "desc": "Jump again in mid-air", "icon": "🔺", "price": 100},
	"dash": {"name": "Dash", "desc": "Press Shift to dash", "icon": "💨", "price": 150},
	"wall_climb": {"name": "Wall Climb", "desc": "Climb walls slowly", "icon": "🧗", "price": 200},
	"ground_slam": {"name": "Ground Slam", "desc": "Press Down in air", "icon": "💥", "price": 250},
	"time_slow": {"name": "Time Slow", "desc": "Press Z to slow time", "icon": "⏱️", "price": 300},
	"teleport": {"name": "Teleport", "desc": "Press X to teleport", "icon": "🌀", "price": 350},
	"shadow_clone": {"name": "Shadow Clone", "desc": "Press C to spawn clone", "icon": "👤", "price": 400},
	"bounce": {"name": "Bounce", "desc": "Jump again in air to bounce", "icon": "⭕", "price": 250},
	"time_rewind": {"name": "Time Rewind", "desc": "Press R to rewind time", "icon": "🔄", "price": 500},
	"energy_shield": {"name": "Energy Shield", "desc": "Press F to block 1 hit", "icon": "🛡️", "price": 450},
	"phase_shift": {"name": "Phase Shift", "desc": "Press Q to dodge through enemies", "icon": "👻", "price": 550},
	"magic_wand": {"name": "Magic Wand", "desc": "Press V to fire magic blast", "icon": "🪄", "price": 600},
	"health_regen": {"name": "Health Regen", "desc": "Slowly recover health over time", "icon": "❤️", "price": 350}
}

func show_shop():
	var old_canvas = get_tree().get_first_node_in_group("ui")
	if old_canvas: old_canvas.queue_free()
	
	var canvas = CanvasLayer.new()
	canvas.add_to_group("ui")
	add_child(canvas)
	
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(50, 80)
	scroll.size = Vector2(1200, 450)
	canvas.add_child(scroll)
	
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 30)
	scroll.add_child(grid)
	
	for item_key in shop_items:
		var item = shop_items[item_key]
		var item_box = VBoxContainer.new()
		item_box.custom_minimum_size = Vector2(200, 180)
		
		var icon = Label.new()
		icon.text = item["icon"]
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.add_theme_font_size_override("font_size", 40)
		item_box.add_child(icon)
		
		var name = Label.new()
		name.text = item["name"]
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.add_theme_font_size_override("font_size", 16)
		name.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
		item_box.add_child(name)
		
		var desc = Label.new()
		desc.text = item["desc"]
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.add_theme_font_size_override("font_size", 12)
		desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		item_box.add_child(desc)
		
		var price = Label.new()
		price.text = "💰 " + str(item["price"]) + " coins"
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price.add_theme_font_size_override("font_size", 14)
		if save_data["unlocked_abilities"].has(item_key):
			price.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
			price.text = "✅ Owned"
		elif save_data["total_coins"] < item["price"]:
			price.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
		else:
			price.add_theme_color_override("font_color", Color(0.3, 0.8, 0.8))
		item_box.add_child(price)
		
		var buy_btn = Button.new()
		if save_data["unlocked_abilities"].has(item_key):
			buy_btn.text = "Owned"
			buy_btn.disabled = true
		else:
			buy_btn.text = "Buy"
			buy_btn.pressed.connect(func(): buy_item(item_key, item["price"]))
		item_box.add_child(buy_btn)
		
		grid.add_child(item_box)
	
	var coin_display = Label.new()
	coin_display.text = "🪙 Your Coins: " + str(save_data["total_coins"])
	coin_display.position = Vector2(50, 30)
	coin_display.add_theme_font_size_override("font_size", 24)
	coin_display.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	canvas.add_child(coin_display)
	
	var back_btn = Button.new()
	back_btn.text = "⬅️ Back"
	back_btn.position = Vector2(20, 30)
	back_btn.custom_minimum_size = Vector2(100, 40)
	back_btn.pressed.connect(func(): show_start_screen())
	canvas.add_child(back_btn)

func buy_item(item_key: String, price: int):
	if save_data["unlocked_abilities"].has(item_key):
		return
	if save_data["total_coins"] < price:
		return
	
	save_data["total_coins"] -= price
	save_data["unlocked_abilities"].append(item_key)
	save_save_data()
	
	show_shop()

# 🆕 Level Select Screen
func show_level_select():
	# Clear existing UI
	var old_canvas = get_tree().get_first_node_in_group("ui")
	if old_canvas: old_canvas.queue_free()
	
	var canvas = CanvasLayer.new()
	canvas.add_to_group("ui")
	add_child(canvas)
	
	# Title
	var title = Label.new()
	title.text = "🗺️ SELECT LEVEL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 20)
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.2, 0.8, 1))
	canvas.add_child(title)
	
	# Back button
	var back_btn = Button.new()
	back_btn.text = "⬅️ Back"
	back_btn.position = Vector2(20, 20)
	back_btn.custom_minimum_size = Vector2(120, 40)
	back_btn.pressed.connect(func(): show_start_screen())
	canvas.add_child(back_btn)
	
	# Scroll container for levels
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(50, 100)
	scroll.size = Vector2(700, 500)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	canvas.add_child(scroll)
	
	# Grid container for level buttons
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	scroll.add_child(grid)
	
	# Get unlocked levels
	var unlocked = get_unlocked_levels()
	
	# Create level buttons
	for i in range(levels.size()):
		var level = levels[i]
		var is_unlocked = i in unlocked
		
		# Level button container
		var level_container = VBoxContainer.new()
		level_container.custom_minimum_size = Vector2(200, 100)
		
		# Level number
		var level_num = Label.new()
		level_num.text = "Level " + str(i + 1)
		level_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_num.add_theme_font_size_override("font_size", 18)
		level_num.add_theme_color_override("font_color", Color.WHITE)
		level_container.add_child(level_num)
		
		# Level name
		var level_name = Label.new()
		level_name.text = level["name"]
		level_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_name.add_theme_font_size_override("font_size", 14)
		level_name.add_theme_color_override("font_color", Color(0.8, 0.9, 1))
		level_container.add_child(level_name)
		
		# Lock indicator
		var lock = Label.new()
		if is_unlocked:
			lock.text = "✅ UNLOCKED"
			lock.add_theme_color_override("font_color", Color(0.4, 1, 0.4))
		else:
			lock.text = "🔒 LOCKED"
			lock.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock.add_theme_font_size_override("font_size", 12)
		level_container.add_child(lock)
		
		# 🌟 Star collect status
		var star_display = Label.new()
		var level_star_count = save_data["level_stars"].get(i, 0)
		var max_stars = level.get("stars", []).size()
		if max_stars > 0:
			# Show stars with icons
			var star_str = ""
			for s in range(max_stars):
				if s < level_star_count:
					star_str += "⭐"
				else:
					star_str += "☆"
			star_display.text = star_str + " (" + str(level_star_count) + "/" + str(max_stars) + ")"
		else:
			# No stars in this level
			star_display.text = "⭐ " + str(level_star_count)
		star_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star_display.add_theme_font_size_override("font_size", 14)
		if level_star_count > 0:
			star_display.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		else:
			star_display.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		level_container.add_child(star_display)
		
		# Play button
		var play_btn = Button.new()
		if is_unlocked:
			play_btn.text = "▶️ PLAY"
			play_btn.pressed.connect(func(): start_selected_level(i))
		else:
			play_btn.text = "🔒 LOCKED"
			play_btn.disabled = true
		play_btn.custom_minimum_size = Vector2(180, 35)
		level_container.add_child(play_btn)
		
		grid.add_child(level_container)
	
	# Update grid size
	grid.custom_minimum_size.y = ceil(levels.size() / 3.0) * 120 + 20

func start_selected_level(level_index):
	game_started = true
	current_level = level_index
	score = 0
	lives = 3
	total_play_time = 0.0
	level_deaths = 0
	setup_level(current_level)

func toggle_pause():
	if not game_started:
		return
	
	is_paused = !is_paused
	
	var ui = get_tree().get_first_node_in_group("ui")
	
	if is_paused:
		# Show pause menu
		show_pause_menu()
		get_tree().paused = true
	else:
		# Hide pause menu
		hide_pause_menu()
		get_tree().paused = false

func show_pause_menu():
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	# Remove existing pause menu if any
	var existing = ui.get_node_or_null("PauseMenu")
	if existing:
		existing.queue_free()
	
	var pause_menu = VBoxContainer.new()
	pause_menu.name = "PauseMenu"
	pause_menu.position = Vector2(400, 180)
	pause_menu.add_theme_constant_override("separation", 15)
	ui.add_child(pause_menu)
	
	# Pause title
	var title = Label.new()
	title.text = "⏸️ PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 1))
	pause_menu.add_child(title)
	
	# Resume button
	var resume_btn = Button.new()
	resume_btn.text = "Resume (ESC)"
	resume_btn.custom_minimum_size = Vector2(200, 45)
	resume_btn.pressed.connect(func(): toggle_pause())
	pause_menu.add_child(resume_btn)
	
	# Restart button
	var restart_btn = Button.new()
	restart_btn.text = "Restart Level"
	restart_btn.custom_minimum_size = Vector2(200, 45)
	restart_btn.pressed.connect(func(): restart_current_level())
	pause_menu.add_child(restart_btn)
	
	# Volume controls section
	var volume_label = Label.new()
	volume_label.text = "🔊 Volume"
	volume_label.add_theme_font_size_override("font_size", 24)
	volume_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1))
	pause_menu.add_child(volume_label)
	
	# Master volume
	var master_row = HBoxContainer.new()
	var master_label = Label.new()
	master_label.text = "Master:"
	master_label.custom_minimum_size = Vector2(70, 0)
	master_row.add_child(master_label)
	var master_slider = HSlider.new()
	master_slider.custom_minimum_size = Vector2(120, 0)
	master_slider.min_value = 0
	master_slider.max_value = 1
	master_slider.step = 0.1
	master_slider.value = audio_manager.master_volume if audio_manager else 0.7
	master_slider.value_changed.connect(func(v): 
		if audio_manager: audio_manager.set_master_volume(v)
	)
	master_row.add_child(master_slider)
	pause_menu.add_child(master_row)
	
	# SFX volume
	var sfx_row = HBoxContainer.new()
	var sfx_label = Label.new()
	sfx_label.text = "SFX:"
	sfx_label.custom_minimum_size = Vector2(70, 0)
	sfx_row.add_child(sfx_label)
	var sfx_slider = HSlider.new()
	sfx_slider.custom_minimum_size = Vector2(120, 0)
	sfx_slider.min_value = 0
	sfx_slider.max_value = 1
	sfx_slider.step = 0.1
	sfx_slider.value = audio_manager.sfx_volume if audio_manager else 0.8
	sfx_slider.value_changed.connect(func(v): 
		if audio_manager: audio_manager.set_sfx_volume(v)
	)
	sfx_row.add_child(sfx_slider)
	pause_menu.add_child(sfx_row)
	
	# Quick Warp button - Teleport to unlocked levels
	var warp_btn = Button.new()
	warp_btn.text = "🌀 Quick Warp"
	warp_btn.custom_minimum_size = Vector2(200, 45)
	warp_btn.pressed.connect(func(): 
		hide_pause_menu()
		show_warp_menu()
	)
	pause_menu.add_child(warp_btn)
	
	# Quit button
	var quit_btn = Button.new()
	quit_btn.text = "Quit to Menu"
	quit_btn.custom_minimum_size = Vector2(200, 45)
	quit_btn.pressed.connect(func(): quit_to_menu())
	pause_menu.add_child(quit_btn)

# 🌀 Quick Warp Menu - Teleport to unlocked levels
func show_warp_menu():
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	is_paused = false
	get_tree().paused = false
	
	# Remove existing warp menu if any
	var existing = ui.get_node_or_null("WarpMenu")
	if existing:
		existing.queue_free()
	
	var warp_menu = VBoxContainer.new()
	warp_menu.name = "WarpMenu"
	warp_menu.position = Vector2(400, 120)
	warp_menu.add_theme_constant_override("separation", 10)
	ui.add_child(warp_menu)
	
	# Title
	var title = Label.new()
	title.text = "🌀 QUICK WARP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 1))
	warp_menu.add_child(title)
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Teleport to unlocked levels"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	warp_menu.add_child(subtitle)
	
	# Level buttons grid
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	warp_menu.add_child(grid)
	
	var unlocked = get_unlocked_levels()
	
	# Create level warp buttons
	for i in range(min(levels.size(), 20)):  # Show first 20 levels
		var level = levels[i]
		var is_unlocked = i in unlocked
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 50)
		
		if is_unlocked:
			btn.text = str(i + 1)
			btn.tooltip_text = level["name"]
			btn.pressed.connect(func(): warp_to_level(i))
		else:
			btn.text = "🔒"
			btn.disabled = true
		
		grid.add_child(btn)
	
	# More levels button if there are more
	if levels.size() > 20:
		var more_btn = Button.new()
		more_btn.text = "More..."
		more_btn.custom_minimum_size = Vector2(200, 40)
		more_btn.pressed.connect(func(): 
			ui.get_node("WarpMenu").queue_free()
			show_warp_menu_more()
		)
		warp_menu.add_child(more_btn)
	
	# Back button
	var back_btn = Button.new()
	back_btn.text = "⬅️ Back to Game"
	back_btn.custom_minimum_size = Vector2(200, 40)
	back_btn.pressed.connect(func(): 
		ui.get_node("WarpMenu").queue_free()
		toggle_pause()
	)
	warp_menu.add_child(back_btn)

func show_warp_menu_more():
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	# Remove existing warp menu if any
	var existing = ui.get_node_or_null("WarpMenu")
	if existing:
		existing.queue_free()
	
	var warp_menu = VBoxContainer.new()
	warp_menu.name = "WarpMenu"
	warp_menu.position = Vector2(350, 80)
	warp_menu.add_theme_constant_override("separation", 8)
	ui.add_child(warp_menu)
	
	# Title
	var title = Label.new()
	title.text = "🌀 MORE LEVELS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 1))
	warp_menu.add_child(title)
	
	# Level buttons grid
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	warp_menu.add_child(grid)
	
	var unlocked = get_unlocked_levels()
	
	# Create level warp buttons (20-40)
	for i in range(20, levels.size()):
		var level = levels[i]
		var is_unlocked = i in unlocked
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 50)
		
		if is_unlocked:
			btn.text = str(i + 1)
			btn.tooltip_text = level["name"]
			btn.pressed.connect(func(): warp_to_level(i))
		else:
			btn.text = "🔒"
			btn.disabled = true
		
		grid.add_child(btn)
	
	# Back button
	var back_btn = Button.new()
	back_btn.text = "⬅️ Back"
	back_btn.custom_minimum_size = Vector2(200, 40)
	back_btn.pressed.connect(func(): 
		ui.get_node("WarpMenu").queue_free()
		show_warp_menu()
	)
	warp_menu.add_child(back_btn)

func warp_to_level(level_index):
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		var warp_menu = ui.get_node_or_null("WarpMenu")
		if warp_menu:
			warp_menu.queue_free()
	
	is_paused = false
	get_tree().paused = false
	
	# Warp to selected level
	current_level = level_index
	setup_level(current_level)

func hide_pause_menu():
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		var pause_menu = ui.get_node_or_null("PauseMenu")
		if pause_menu:
			pause_menu.queue_free()

func restart_current_level():
	is_paused = false
	get_tree().paused = false
	hide_pause_menu()
	
	if endless_mode:
		# Reset endless mode
		endless_score = 0
		endless_difficulty = 1.0
		score = 0
		lives = 3
		setup_endless_level()
	else:
		# Reset current level
		score = max(0, score - 50)  # Penalty for restarting
		lives = 3  # Reset lives
		setup_level(current_level)

func quit_to_menu():
	is_paused = false
	get_tree().paused = false
	Engine.time_scale = 1.0  # Reset time scale to fix potential slow-mo bug
	hide_pause_menu()
	game_started = false
	show_start_screen()

func clear_level():
	# CRITICAL: Reset time scale when clearing level to prevent permanent slow-mo
	if Engine.time_scale != 1.0:
		Engine.time_scale = 1.0
	
	for p in platforms:
		if is_instance_valid(p): p.queue_free()
	platforms.clear()
	moving_platforms.clear()  # Clear moving platforms
	for c in coins:
		if is_instance_valid(c): c.queue_free()
	coins.clear()
	for rc in rainbow_coins:  # 🌈 Clear rainbow coins
		if is_instance_valid(rc): rc.queue_free()
	rainbow_coins.clear()
	for g in gems:  # 💎 Clear gems
		if is_instance_valid(g): g.queue_free()
	gems.clear()
	for s in stars:  # 🌟 Clear stars
		if is_instance_valid(s): s.queue_free()
	stars.clear()
	for r in runes:  # ✨ Clear runes
		if is_instance_valid(r): r.queue_free()
	runes.clear()
	for e in enemies:
		if is_instance_valid(e): e.queue_free()
	enemies.clear()
	if goal and is_instance_valid(goal):
		goal.queue_free()
	if player and is_instance_valid(player):
		player.queue_free()
	# Reset checkpoint position when clearing level
	checkpoint_pos = Vector2(80, 350)

func _input(event):
	# Easter egg: Konami code detection (↑↑↓↓←→←→BA)
	if event is InputEventKey and event.pressed:
		handle_konami_code(event)
	
	# 处理跳跃键
	if event.is_action_pressed("jump"):
		_handle_continue_or_start()
	# 处理触摸/点击事件（移动端替代空格键）
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_continue_or_start()
	elif event is InputEventScreenTouch and event.pressed:
		_handle_continue_or_start()

# 🎮 Easter egg: Konami code for super secret!
var konami_buffer = []
var konami_code = [KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT, KEY_B, KEY_A]

func handle_konami_code(event: InputEventKey):
	konami_buffer.append(event.keycode)
	if konami_buffer.size() > 10:
		konami_buffer.pop_front()
	
	# Check if Konami code is complete
	if konami_buffer.size() == 10:
		var match = true
		for i in range(10):
			if konami_buffer[i] != konami_code[i]:
				match = false
				break
		if match:
			activate_konami_cheat()

func activate_konami_cheat():
	# Give player all abilities and 99 lives!
	if player:
		player.lives = 99
		player.max_jumps = 3
		player.can_dash = true
		player.can_wall_climb = true
		player.can_ground_slam = true
		player.can_time_slow = true
		player.has_permanent_double_jump = true
	
	# Unlock all abilities
	for ability in ABILITIES.keys():
		unlock_ability(ability)
	
	# Big score bonus
	score += 9999
	
	# Show secret message
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		var secret = Label.new()
		secret.text = "🎮 CHEAT ACTIVATED!\nAll abilities unlocked!\n99 lives granted!"
		secret.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		secret.position = Vector2(640, 300)
		secret.add_theme_font_size_override("font_size", 28)
		secret.add_theme_color_override("font_color", Color(1, 0.3, 0.8))
		secret.z_index = 200
		ui.add_child(secret)
		
		var tw = create_tween()
		tw.tween_interval(3.0)
		tw.tween_property(secret, "modulate:a", 0.0, 0.5)
		tw.tween_property(secret, "position:y", secret.position.y - 30, 0.5)
		tw.tween_callback(secret.queue_free)
	
	# Reset buffer
	konami_buffer.clear()
	update_ui_labels()

func _handle_continue_or_start():
	if not game_started:
		start_game()
	else:
		var ui = get_tree().get_first_node_in_group("ui")
		if ui:
			# Check for game over or victory and restart
			if ui.has_node("GameOverOverlay") or ui.has_node("GameOverText"):
				# Reset game
				current_level = 0
				score = 0
				lives = 3
				stars_collected = 0
				game_started = true
				setup_level(0)
			elif ui.has_node("VictoryOverlay") or ui.has_node("VictoryText"):
				# Reset game
				current_level = 0
				score = 0
				lives = 3
				stars_collected = 0
				game_started = true
				setup_level(0)

func skip_shop():
	# Skip shop - go directly to level 1
	game_started = true
	current_level = 0
	score = 0
	lives = 3
	total_play_time = 0.0
	level_deaths = 0
	setup_level(current_level)

func start_game():
	game_started = true
	time_trial_mode = false
	current_level = 0
	score = 0
	lives = 3
	total_play_time = 0.0
	level_deaths = 0
	setup_level(current_level)

func start_time_trial():
	# Time Trial mode - speedrun through levels
	time_trial_mode = true
	game_started = true
	current_level = 0
	score = 0
	lives = 3
	total_play_time = 0.0
	level_deaths = 0
	show_time_trial_intro()

func show_time_trial_intro():
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	# Show time trial intro overlay
	var intro = Node2D.new()
	intro.name = "TimeTrialIntro"
	intro.position = Vector2(640, 360)
	ui.add_child(intro)
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.size = Vector2(500, 200)
	bg.position = Vector2(-250, -100)
	intro.add_child(bg)
	
	var title = Label.new()
	title.text = "⏱️ TIME TRIAL MODE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	title.position = Vector2(-120, -60)
	intro.add_child(title)
	
	var info = Label.new()
	info.text = "Complete levels as fast as possible!\nYour best times will be saved."
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 16)
	info.add_theme_color_override("font_color", Color(0.8, 0.9, 1))
	info.position = Vector2(-120, 0)
	intro.add_child(info)
	
	# Auto-start after delay
	await get_tree().create_timer(2.5).timeout
	if intro and is_instance_valid(intro):
		intro.queue_free()
	setup_level(current_level)

var endless_mode = false
var endless_score = 0
var endless_difficulty = 1.0
var endless_platform_count = 0
var endless_coin_count = 0

# Daily Challenge system
var daily_challenge_mode = false
var daily_challenge_seed = 0
var daily_challenge_completed_today = false
var daily_challenge_date = ""

func start_daily_challenge():
	# Check if already completed today
	var today = Time.get_date_string_from_system()
	if daily_challenge_date == today and daily_challenge_completed_today:
		show_daily_challenge_result(true)
		return
	
	daily_challenge_mode = true
	daily_challenge_seed = Time.get_unix_time_from_system() / 86400  # Day number
	daily_challenge_date = today
	game_started = true
	current_level = 0
	score = 0
	lives = 3
	total_play_time = 0.0
	level_deaths = 0
	show_daily_challenge_intro()

func show_daily_challenge_intro():
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	var intro = Node2D.new()
	intro.name = "DailyIntro"
	intro.position = Vector2(640, 360)
	ui.add_child(intro)
	
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.05, 0.2, 0.9)
	bg.size = Vector2(500, 250)
	bg.position = Vector2(-250, -125)
	intro.add_child(bg)
	
	var title = Label.new()
	title.text = "📅 DAILY CHALLENGE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	title.position = Vector2(-120, -80)
	intro.add_child(title)
	
	# Show challenge type based on seed
	var challenge_types = ["Speed Run", "No Damage", "Coin Collector", "Endless Rush"]
	var challenge_idx = int(daily_challenge_seed) % challenge_types.size()
	var challenge = challenge_types[challenge_idx]
	
	var info = Label.new()
	info.text = "Today's Challenge: " + challenge + "\nComplete for bonus points!\nYour unique seed: " + str(daily_challenge_seed)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 16)
	info.add_theme_color_override("font_color", Color(0.9, 0.9, 1))
	info.position = Vector2(-120, -20)
	intro.add_child(info)
	
	await get_tree().create_timer(3.0).timeout
	if intro and is_instance_valid(intro):
		intro.queue_free()
	setup_level(current_level)

func show_daily_challenge_result(show_completed = false):
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	var result = Node2D.new()
	result.name = "DailyResult"
	result.position = Vector2(640, 360)
	ui.add_child(result)
	
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.05, 0.2, 0.9)
	bg.size = Vector2(400, 180)
	bg.position = Vector2(-200, -90)
	result.add_child(bg)
	
	var title = Label.new()
	if show_completed:
		title.text = "✅ Already Completed Today!"
		title.add_theme_color_override("font_color", Color(0.4, 1, 0.4))
	else:
		title.text = "📅 Daily Challenge Complete!"
		title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.position = Vector2(-100, -50)
	result.add_child(title)
	
	var bonus = Label.new()
	bonus.text = "Bonus: +500 points!"
	bonus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus.add_theme_font_size_override("font_size", 18)
	bonus.add_theme_color_override("font_color", Color(0.8, 0.9, 1))
	bonus.position = Vector2(-80, 10)
	result.add_child(bonus)
	
	score += 500
	await get_tree().create_timer(2.5).timeout
	if result and is_instance_valid(result):
		result.queue_free()

# 🐉 Boss Rush Mode - Fight all bosses in sequence!
var boss_rush_mode = false
var boss_rush_bosses = []
var current_boss_index = 0
var boss_rush_wins = 0
var boss_rush_max_bosses = 5

# ⭐ New Game+ Mode - Harder difficulty!
var new_game_plus_mode = false
var ngp_multiplier = 1.5  # 50% more enemies, harder platforming

func start_new_game_plus():
	new_game_plus_mode = true
	ngp_multiplier = 1.5
	game_started = true
	current_level = 0
	score = 0
	lives = 2  # One less life!
	total_play_time = 0.0
	level_deaths = 0
	show_new_game_plus_intro()

func show_new_game_plus_intro():
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	var intro = Node2D.new()
	intro.name = "NewGamePlusIntro"
	intro.position = Vector2(640, 360)
	ui.add_child(intro)
	
	var bg = ColorRect.new()
	bg.color = Color(0.15, 0.1, 0.2, 0.95)
	bg.size = Vector2(500, 220)
	bg.position = Vector2(-250, -110)
	intro.add_child(bg)
	
	var title = Label.new()
	title.text = "⭐ NEW GAME+"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	title.position = Vector2(-80, -70)
	intro.add_child(title)
	
	var info = Label.new()
	info.text = "Hard Mode Enabled!\n• Enemies are 50% stronger\n• Only 2 lives (no extra)\n• Double score multiplier\n• All abilities unlocked!\nProve you're a true platformer master!"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 14)
	info.add_theme_color_override("font_color", Color(0.9, 0.9, 1))
	info.position = Vector2(-120, -10)
	intro.add_child(info)
	
	# Unlock all abilities for NG+
	for ability in ABILITIES.keys():
		unlock_ability(ability)
	
	await get_tree().create_timer(4.0).timeout
	if intro and is_instance_valid(intro):
		intro.queue_free()
	setup_level(current_level)

func start_boss_rush():
	boss_rush_mode = true
	boss_rush_bosses = []
	current_boss_index = 0
	boss_rush_wins = 0
	game_started = true
	score = 0
	lives = 3
	total_play_time = 0.0
	level_deaths = 0
	collect_boss_levels()
	show_boss_rush_intro()

func collect_boss_levels():
	for i in range(levels.size()):
		var level = levels[i]
		if level.get("is_boss", false):
			boss_rush_bosses.append(i)
	if boss_rush_bosses.size() == 0:
		boss_rush_bosses = [10]  # Default boss level
	boss_rush_max_bosses = boss_rush_bosses.size()

func show_boss_rush_intro():
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	var intro = Node2D.new()
	intro.name = "BossRushIntro"
	intro.position = Vector2(640, 360)
	ui.add_child(intro)
	
	var bg = ColorRect.new()
	bg.color = Color(0.2, 0.05, 0.1, 0.95)
	bg.size = Vector2(550, 280)
	bg.position = Vector2(-275, -140)
	intro.add_child(bg)
	
	var title = Label.new()
	title.text = "🐉 BOSS RUSH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1, 0.3, 0.1))
	title.position = Vector2(-80, -100)
	intro.add_child(title)
	
	var info = Label.new()
	info.text = "Defeat all bosses in sequence!\n" + str(boss_rush_max_bosses) + " bosses await you.\nEach victory grants bonus points.\nDon't lose all lives!"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 16)
	info.add_theme_color_override("font_color", Color(1, 0.9, 0.8))
	info.position = Vector2(-130, -20)
	intro.add_child(info)
	
	await get_tree().create_timer(3.5).timeout
	if intro and is_instance_valid(intro):
		intro.queue_free()
	setup_boss_rush_level()

func setup_boss_rush_level():
	if current_boss_index >= boss_rush_bosses.size():
		finish_boss_rush(true)
		return
	
	clear_level()
	clear_checkpoints()
	
	var level_index = boss_rush_bosses[current_boss_index]
	var level = levels[level_index]
	
	RenderingServer.set_default_clear_color(Color(0.15, 0.05, 0.1))
	clear_effects()
	
	create_platform(50, 550, 200, 40)
	create_platform(350, 450, 150, 20)
	create_platform(600, 350, 100, 20)
	create_platform(850, 450, 150, 20)
	create_platform(1100, 550, 200, 40)
	
	for coin in level.get("coins", []):
		create_coin(coin.x, coin.y)
	
	for gem in level.get("gems", []):
		create_gem(gem.x, gem.y)
	
	create_enemy(700, 250, "boss", level.get("boss_hp", 5), 600, 800)
	
	create_goal(1250, 500)
	
	checkpoint_pos = Vector2(450, 400)
	
	show_level_name("Boss " + str(current_boss_index + 1) + ": " + level.get("boss_name", "Boss"))
	
	start_level_timer()
	
	player = CharacterBody2D.new()
	player.position = checkpoint_pos
	player.script = load("res://player.gd")
	player.add_to_group("player")
	add_child(player)
	create_player_visual(player)
	
	var cam = Camera2D.new()
	player.add_child(cam)
	
	await get_tree().create_timer(2.0).timeout
	show_hint("boss_rush", "Jump on the boss to deal damage! Watch for attacks!")

func on_boss_defeated():
	boss_rush_wins += 1
	score += 500 + (current_boss_index + 1) * 100
	current_boss_index += 1
	
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		var msg = Label.new()
		msg.text = "Boss Defeated!\n+" + str(500 + current_boss_index * 100) + " points"
		msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		msg.add_theme_font_size_override("font_size", 28)
		msg.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		msg.position = Vector2(540, 280)
		msg.z_index = 100
		ui.add_child(msg)
		
		await get_tree().create_timer(2.0).timeout
		msg.queue_free()
	
	if current_boss_index >= boss_rush_bosses.size():
		finish_boss_rush(true)
	else:
		setup_boss_rush_level()

func finish_boss_rush(victory: bool):
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	var result = Node2D.new()
	result.name = "BossRushResult"
	result.position = Vector2(640, 360)
	ui.add_child(result)
	
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.05, 0.15, 0.95)
	bg.size = Vector2(450, 250)
	bg.position = Vector2(-225, -125)
	result.add_child(bg)
	
	var title = Label.new()
	if victory:
		title.text = "🎉 BOSS RUSH COMPLETE!"
		title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		score += 1000
	else:
		title.text = "💀 BOSS RUSH FAILED"
		title.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.position = Vector2(-130, -80)
	result.add_child(title)
	
	var stats = Label.new()
	stats.text = "Bosses Defeated: " + str(boss_rush_wins) + "/" + str(boss_rush_max_bosses) + "\nScore: " + str(score)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 18)
	stats.add_theme_color_override("font_color", Color(0.9, 0.9, 1))
	stats.position = Vector2(-80, -10)
	result.add_child(stats)
	
	var back_btn = Button.new()
	back_btn.text = "Back to Menu"
	back_btn.position = Vector2(-80, 60)
	back_btn.custom_minimum_size = Vector2(160, 40)
	back_btn.pressed.connect(func(): 
		result.queue_free()
		boss_rush_mode = false
		quit_to_menu()
	)
	result.add_child(back_btn)

func start_endless_mode():
	endless_mode = true
	endless_score = 0
	endless_difficulty = 1.0
	game_started = true
	current_level = -1  # Special value for endless
	score = 0
	lives = 3
	total_play_time = 0.0
	level_deaths = 0
	show_endless_intro()

func show_endless_intro():
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	var intro = Node2D.new()
	intro.name = "EndlessIntro"
	intro.position = Vector2(640, 360)
	ui.add_child(intro)
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.size = Vector2(500, 200)
	bg.position = Vector2(-250, -100)
	intro.add_child(bg)
	
	var title = Label.new()
	title.text = "♾️ ENDLESS MODE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.8, 0.4, 1))
	title.position = Vector2(-120, -60)
	intro.add_child(title)
	
	var info = Label.new()
	info.text = "Survive as long as you can!\nPlatforms get harder over time."
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 16)
	info.add_theme_color_override("font_color", Color(0.9, 0.9, 1))
	info.position = Vector2(-120, 0)
	intro.add_child(info)
	
	await get_tree().create_timer(2.5).timeout
	if intro and is_instance_valid(intro):
		intro.queue_free()
	setup_endless_level()

func setup_endless_level():
	clear_level()
	clear_checkpoints()
	
	# Set background
	RenderingServer.set_default_clear_color(Color(0.05, 0.05, 0.1))
	clear_effects()
	
	# Create player
	create_player()
	
	# Generate endless platforms
	endless_platform_count = 0
	endless_coin_count = 0
	generate_endless_platforms()
	
	# Create goal
	create_goal(1200, 200)
	
	# Show level name
	show_level_name("ENDLESS - Score: " + str(endless_score))
	
	# Start timer
	start_level_timer()

func generate_endless_platforms():
	var start_x = 50.0
	var start_y = 500.0
	
	# Starting platform
	create_platform(start_x, start_y, 150, 30)
	endless_platform_count += 1
	
	# Generate platforms progressively
	var current_x = start_x + 200
	var current_y = start_y
	var num_platforms = 15 + int(endless_difficulty * 5)
	
	for i in range(num_platforms):
		var platform_width = randf_range(60, 120)
		var gap = randf_range(80, 150) + (endless_difficulty * 10)
		var height_change = randf_range(-80, 60)
		
		current_x += gap
		current_y += height_change
		
		# Keep within bounds
		current_y = clamp(current_y, 100, 550)
		current_x = clamp(current_x, 100, 1800)
		
		create_platform(current_x, current_y, platform_width, 20)
		endless_platform_count += 1
		
		# Add coins on some platforms
		if randf() < 0.7:
			var coin_x = current_x + randf_range(-20, 20)
			var coin_y = current_y - 40 - randf() * 30
			create_coin(coin_x, coin_y)
			endless_coin_count += 1
		
		# Add enemies based on difficulty
		if endless_difficulty > 0.5 and randf() < 0.3 * endless_difficulty:
			var enemy_x = current_x
			var enemy_y = current_y - 30
			create_enemy(enemy_x, enemy_y, "ground", 1, current_x - 30, current_x + 30)
		
		# Add mimic enemies at higher difficulty
		if endless_difficulty > 1.0 and randf() < 0.15 * (endless_difficulty - 1.0):
			var mimic_x = current_x + randf_range(-20, 20)
			var mimic_y = current_y - 20
			create_mimic(mimic_x, mimic_y)
		
		# Add powerups occasionally
		if randf() < 0.05:
			var powerup_x = current_x
			var powerup_y = current_y - 50
			create_powerup(powerup_x, powerup_y)
	
	# Create final goal
	create_goal(current_x + 100, current_y - 50)

func advance_endless_level():
	endless_score += 100 + (endless_platform_count * 10) + (endless_coin_count * 5)
	endless_difficulty += 0.15
	score += endless_score
	
	# Show level complete
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		var msg = Label.new()
		msg.text = "Level Complete!\nScore: " + str(endless_score)
		msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		msg.add_theme_font_size_override("font_size", 28)
		msg.add_theme_color_override("font_color", Color(0.8, 1, 0.8))
		msg.position = Vector2(500, 250)
		ui.add_child(msg)
		
		await get_tree().create_timer(2.0).timeout
		msg.queue_free()
	
	# Setup next level
	setup_endless_level()

func setup_level(level_index):
	clear_level()
	clear_checkpoints()  # Clear old checkpoints
	
	if level_index >= levels.size():
		score += 500
		level_index = 0
	current_level = level_index
	
	var level = levels[level_index]
	RenderingServer.set_default_clear_color(level.get("bg_color", Color(0.1, 0.12, 0.18)))
	
	# ❄️ Create ice crystal effect for Crystal Palace
	if level.get("crystal_theme", false):
		create_ice_crystals()
	else:
		clear_ice_crystals()
	
	# 🌸 Create cherry blossom effect for Japanese themed levels
	if level.get("cherry_blossom_theme", false):
		create_cherry_blossom_effect()
	else:
		clear_cherry_blossom_effect()
	
	# 🌌 Create nebula effect for Nebula Nexus
	if level.get("nebula_theme", false):
		create_nebula_effect()
	else:
		clear_nebula_effect()
	
	# 🌑 Create void effect for Void Dimension
	if level.get("void_theme", false):
		create_void_effect()
	else:
		clear_void_effect()
	
	# 🔥 Create phoenix effect for Phoenix Realm
	if level.get("phoenix_theme", false):
		create_phoenix_effect()
	else:
		clear_phoenix_effect()
	
	# 🫧 Create abyss effect for Abyss Core
	if level.get("abyss_theme", false):
		create_abyss_effect()
	else:
		clear_abyss_effect()
	
	# 🐾 Create pet theme effect for Pet Haven
	if level.get("pet_theme", false):
		create_pet_effect()
	else:
		clear_pet_effect()
	
	# 🌧️ Create weather effect
	var weather_str = level.get("weather", "")
	if weather_str != "":
		var weather_type = WeatherType.RAIN
		match weather_str:
			"rain": weather_type = WeatherType.RAIN
			"snow": weather_type = WeatherType.SNOW
			"fog": weather_type = WeatherType.FOG
			"storm": weather_type = WeatherType.STORM
		create_weather_effect(weather_type)
	else:
		clear_weather_effect()
	
	# 🌅 Create twilight effect for Twilight Temple
	if level.get("name", "").find("Twilight") != -1:
		create_twilight_effect()
	else:
		clear_twilight_effect()
	
	# ☀️ Create solar effect for Solar Core
	if level.get("name", "").find("Solar") != -1:
		create_solar_effect()
	else:
		clear_solar_effect()
	
	# 🪞 Create mirror effect for Mirror World
	if level.get("mirror_theme", false):
		create_mirror_effect()
	else:
		clear_mirror_effect()
	
	# 🔀 Create chaos effect for Chaos Realm
	if level.get("chaos_theme", false):
		create_chaos_effect()
	else:
		clear_chaos_effect()
	
	# 🍬 Create candy effect for Candy World
	if level.get("candy_theme", false):
		create_candy_effect()
	else:
		clear_candy_effect()
	
	# 🌋 Create lava effect for Lava Lake
	if level.get("lava_theme", false):
		create_lava_effect()
	else:
		clear_lava_effect()
	
	# ⏱️ Start level timer
	start_level_timer()
	level_deaths = 0
	boss_damage_taken = false
	gems_collected = 0  # Reset gems for new level
	
	# Show level name
	show_level_name(level.get("name", "Level " + str(level_index + 1)))
	
	# Show level hints
	await get_tree().create_timer(2.0).timeout
	show_level_hints(level_index)
	
	# Show boss warning if boss level
	if level.get("is_boss", false):
		await get_tree().create_timer(1.5).timeout
		show_boss_warning()
	
	# Create player - use checkpoint position
	player = CharacterBody2D.new()
	player.position = checkpoint_pos
	player.script = load("res://player.gd")
	player.add_to_group("player")
	add_child(player)
	
	# Apply unlocked abilities to player
	apply_player_abilities(player)
	
	create_player_visual(player)
	
	# Camera
	var cam = Camera2D.new()
	player.add_child(cam)
	
	# Create platforms
	for p in level["platforms"]:
		# Check if platform has movement data
		var move_data = null
		if p.has("move_x") or p.has("move_y"):
			move_data = {"move_x": p.get("move_x", 0), "move_y": p.get("move_y", 0)}
		# Check for crystal platform
		var crystal_type = p.get("crystal", null)
		# Check for fire platform
		var fire_type = p.get("fire", null)
		create_platform(p.x, p.y, p.w, p.h, move_data, crystal_type, fire_type)
	
	# Create coins
	for c in level["coins"]:
		create_coin(c.x, c.y)
	
	# 🌈 Create rainbow coins (if defined in level) - rare bonus collectibles
	if level.has("rainbow_coins"):
		for rc in level["rainbow_coins"]:
			create_rainbow_coin(rc.x, rc.y)
	
	# 💎 Create gems (if defined in level) - rare collectibles
	if level.has("gems"):
		for g in level["gems"]:
			create_gem(g.x, g.y)
	
	# ✨ Create magic runes (if defined in level) - special collectibles with effects
	runes.clear()
	if level.has("runes"):
		for r in level["runes"]:
			create_rune(r.x, r.y)
	
	# 🌟 Create stars (if defined in level)
	if level.has("stars"):
		for s in level["stars"]:
			create_star(s.x, s.y)
	
	# Create checkpoint if defined
	if level.has("checkpoint"):
		create_checkpoint(level["checkpoint"].x, level["checkpoint"].y)
	
	# Create secret area if defined
	if level.has("secret_area"):
		create_secret_area(level["secret_area"].x, level["secret_area"].y, 
			level["secret_area"].get("w", 100), level["secret_area"].get("h", 100))
	
	# Create enemies
	for e in level["enemies"]:
		var enemy_type = e.get("type", "ground")
		var enemy_hp = e.get("hp", 1)
		var enemy_min_x = e.get("min_x", 0)
		var enemy_max_x = e.get("max_x", 300)
		var enemy = create_enemy(e.x, e.y, enemy_type, enemy_hp, enemy_min_x, enemy_max_x)
		if enemy.has_method("setup_movement"):
			enemy.platform_bounds = {"min_x": e.get("min_x", 0), "max_x": e.get("max_x", 300)}
	
	# Create powerups (if defined in level)
	if level.has("powerups"):
		for p in level["powerups"]:
			create_powerup(p.x, p.y, p.get("type", "dash"))
	
	# Create pet companion (if defined in level)
	if level.has("pet_spawn") and player:
		player.spawn_pet(level["pet_spawn"].get("type", "default"))
	
	# Create treasure chests (if defined in level)
	if level.has("treasure_chests"):
		for t in level["treasure_chests"]:
			create_treasure_chest(t.x, t.y, t.get("type", null))
	
	# Create pressure plates (if defined in level)
	if level.has("pressure_plates"):
		for pp in level["pressure_plates"]:
			create_pressure_plate(pp.x, pp.y, pp.get("type", "enemy"), pp.get("id", 0))
	
	# Create puzzle keys (if defined in level)
	if level.has("puzzle_key"):
		create_puzzle_key(level["puzzle_key"].x, level["puzzle_key"].y, level["puzzle_key"].get("type", "silver"))
	
	# Create locked doors (if defined in level)
	if level.has("locked_door"):
		create_locked_door(level["locked_door"].x, level["locked_door"].y, level["locked_door"].get("key_type", "silver"))
	
	# Create goal
	if level.has("goal"):
		create_goal(level.goal.x, level.goal.y)
	
	setup_ui()
	# 启用虚拟移动控件（多点触控版本）
	setup_mobile_controls()

func apply_player_abilities(p):
	# Apply all unlocked abilities from save data
	if has_ability("double_jump"):
		p.activate_double_jump()
	if has_ability("dash"):
		p.can_dash = true
	if has_ability("wall_climb"):
		p.can_wall_climb = true
	if has_ability("ground_slam"):
		p.activate_ground_slam()
	if has_ability("time_slow"):
		p.can_time_slow = true
	if has_ability("teleport"):
		p.can_teleport = true
	if has_ability("shadow_clone"):
		p.can_shadow_clone = true
	if has_ability("bounce"):
		p.can_bounce = true
	if has_ability("time_rewind"):
		p.activate_time_rewind()
	if has_ability("energy_shield"):
		p.activate_energy_shield_ability()
	if has_ability("phase_shift"):
		p.activate_phase_shift_ability()
	if has_ability("tracking_projectile"):
		p.activate_tracking_projectile_ability()
	if has_ability("magic_wand"):
		p.can_magic_wand = true
	if has_ability("health_regen"):
		p.has_health_regen = true

func create_player_visual(p):
	# Create lobster character using polygons
	var visual = Node2D.new()
	visual.name = "Visual"
	p.add_child(visual)
	
	# Body - main lobster shell
	var body = Polygon2D.new()
	var body_pts = PackedVector2Array([
		Vector2(-8, -18), Vector2(8, -18),
		Vector2(10, -12), Vector2(10, -4),
		Vector2(8, 2), Vector2(4, 6),
		Vector2(-4, 6), Vector2(-8, 2),
		Vector2(-10, -4), Vector2(-10, -12)
	])
	body.polygon = body_pts
	body.color = Color(0.9, 0.3, 0.3)  # Red lobster color
	visual.add_child(body)
	
	# Shell highlight
	var highlight = Polygon2D.new()
	var hl_pts = PackedVector2Array([
		Vector2(-4, -16), Vector2(4, -16),
		Vector2(5, -10), Vector2(3, -6),
		Vector2(-3, -6), Vector2(-5, -10)
	])
	highlight.polygon = hl_pts
	highlight.color = Color(1, 0.5, 0.5)
	visual.add_child(highlight)
	
	# Left claw
	var claw_l = Polygon2D.new()
	var claw_l_pts = PackedVector2Array([
		Vector2(-10, -14), Vector2(-14, -12),
		Vector2(-16, -8), Vector2(-14, -4),
		Vector2(-10, -6), Vector2(-10, -10)
	])
	claw_l.polygon = claw_l_pts
	claw_l.color = Color(0.85, 0.25, 0.25)
	visual.add_child(claw_l)
	
	# Right claw
	var claw_r = Polygon2D.new()
	var claw_r_pts = PackedVector2Array([
		Vector2(10, -14), Vector2(14, -12),
		Vector2(16, -8), Vector2(14, -4),
		Vector2(10, -6), Vector2(10, -10)
	])
	claw_r.polygon = claw_r_pts
	claw_r.color = Color(0.85, 0.25, 0.25)
	visual.add_child(claw_r)
	
	# Eyes
	var eye_l = ColorRect.new()
	eye_l.size = Vector2(3, 3)
	eye_l.color = Color(0.1, 0.1, 0.1)
	eye_l.position = Vector2(-4, -14)
	visual.add_child(eye_l)
	
	var eye_r = ColorRect.new()
	eye_r.size = Vector2(3, 3)
	eye_r.color = Color(0.1, 0.1, 0.1)
	eye_r.position = Vector2(2, -14)
	visual.add_child(eye_r)
	
	# Antennae
	var ant_l = Polygon2D.new()
	ant_l.polygon = PackedVector2Array([Vector2(-4, -18), Vector2(-8, -24), Vector2(-2, -22)])
	ant_l.color = Color(0.7, 0.2, 0.2)
	visual.add_child(ant_l)
	
	var ant_r = Polygon2D.new()
	ant_r.polygon = PackedVector2Array([Vector2(4, -18), Vector2(8, -24), Vector2(2, -22)])
	ant_r.color = Color(0.7, 0.2, 0.2)
	visual.add_child(ant_r)
	
	# Tail segments
	for i in range(3):
		var tail = Polygon2D.new()
		var tail_pts = PackedVector2Array()
		var y_pos = 6 + i * 5
		tail_pts.append(Vector2(-4 - i, y_pos))
		tail_pts.append(Vector2(4 + i, y_pos))
		tail_pts.append(Vector2(3 + i, y_pos + 4))
		tail_pts.append(Vector2(-3 - i, y_pos + 4))
		tail.polygon = tail_pts
		tail.color = Color(0.8, 0.25, 0.25)
		visual.add_child(tail)
	
	# Legs (small dots)
	for i in range(3):
		var leg_l = ColorRect.new()
		leg_l.size = Vector2(2, 2)
		leg_l.color = Color(0.7, 0.2, 0.2)
		leg_l.position = Vector2(-8 - i * 2, 4 + i * 3)
		visual.add_child(leg_l)
		
		var leg_r = ColorRect.new()
		leg_r.size = Vector2(2, 2)
		leg_r.color = Color(0.7, 0.2, 0.2)
		leg_r.position = Vector2(6 + i * 2, 4 + i * 3)
		visual.add_child(leg_r)
	
	# Collision - position at center of player body
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(20, 28)  # Match visual size
	col.shape = rect
	col.position = Vector2(0, -14)  # Same center as visual
	p.add_child(col)

func create_platform(x, y, w, h, move_data = null, crystal_type = null, fire_type = null):
	var platform: Node2D
	var is_moving = move_data != null
	
	if is_moving:
		# 使用 CharacterBody2D 实现移动平台
		platform = CharacterBody2D.new()
		platform.set_script(load("res://moving_platform.gd"))  # 创建移动平台脚本
	else:
		platform = StaticBody2D.new()
	
	platform.position = Vector2(x, y)
	
	# Fire platform rendering (Phoenix theme)
	if fire_type != null:
		var fire_colors = {
			"true": Color(0.9, 0.3, 0.1, 0.85),  # Red-orange fire
			"orange": Color(1.0, 0.5, 0.1, 0.85),  # Orange fire
			"red": Color(0.8, 0.2, 0.1, 0.85)      # Red fire
		}
		var fire_color = fire_colors.get(str(fire_type), Color(0.9, 0.3, 0.1, 0.85))
		
		# Create fire-like platform using gradient
		var gradient = Gradient.new()
		gradient.set_color(0, Color(fire_color.r, fire_color.g, fire_color.b, fire_color.a * 0.4))
		gradient.set_color(1, fire_color)
		
		var gradient_texture = GradientTexture2D.new()
		gradient_texture.gradient = gradient
		gradient_texture.fill = 1  # Vertical fill
		gradient_texture.fill_from = Vector2(0, 0)
		gradient_texture.fill_to = Vector2(1, 1)
		gradient_texture.width = int(w)
		gradient_texture.height = int(h)
		
		var sprite = Sprite2D.new()
		sprite.texture = gradient_texture
		sprite.position = Vector2(w/2, h/2)
		platform.add_child(sprite)
		
		# Add flame edge effect
		var edge_sprite = Sprite2D.new()
		var edge_gradient = Gradient.new()
		edge_gradient.set_color(0, Color(1, 0.6, 0.1, 0))
		edge_gradient.set_color(1, Color(1, 0.4, 0.1, 0.7))
		
		var edge_texture = GradientTexture2D.new()
		edge_texture.gradient = edge_gradient
		edge_texture.fill = 1  # Vertical fill
		edge_texture.width = int(w)
		edge_texture.height = 6
		
		edge_sprite.texture = edge_texture
		edge_sprite.position = Vector2(w/2, h - 3)
		platform.add_child(edge_sprite)
		
		# Add glow effect at top
		var glow_sprite = Sprite2D.new()
		var glow_gradient = Gradient.new()
		glow_gradient.set_color(0, Color(1, 0.8, 0.3, 0.5))
		glow_gradient.set_color(1, Color(1, 0.5, 0.1, 0))
		
		var glow_texture = GradientTexture2D.new()
		glow_texture.gradient = glow_gradient
		glow_texture.fill = 1
		glow_texture.width = int(w)
		glow_texture.height = 8
		
		glow_sprite.texture = glow_texture
		glow_sprite.position = Vector2(w/2, 4)
		platform.add_child(glow_sprite)
	
	# Crystal platform rendering (Ice crystal theme)
	elif crystal_type != null:
		var crystal_colors = {
			"cyan": Color(0.4, 0.9, 1.0, 0.85),   # Cyan ice
			"blue": Color(0.3, 0.5, 1.0, 0.85),   # Blue ice
			"purple": Color(0.7, 0.4, 1.0, 0.85), # Purple crystal
			"white": Color(0.9, 0.95, 1.0, 0.9)    # White crystal
		}
		var crystal_color = crystal_colors.get(crystal_type, Color(0.5, 0.8, 1.0, 0.8))
		
		# Create crystal-like platform using gradient
		var gradient = Gradient.new()
		gradient.set_color(0, crystal_color)
		gradient.set_color(1, Color(crystal_color.r, crystal_color.g, crystal_color.b, crystal_color.a * 0.6))
		
		var gradient_texture = GradientTexture2D.new()
		gradient_texture.gradient = gradient
		gradient_texture.fill = 1  # Vertical fill
		gradient_texture.fill_from = Vector2(0, 0)
		gradient_texture.fill_to = Vector2(1, 1)
		gradient_texture.width = int(w)
		gradient_texture.height = int(h)
		
		var sprite = Sprite2D.new()
		sprite.texture = gradient_texture
		sprite.position = Vector2(w/2, h/2)
		platform.add_child(sprite)
		
		# Add shimmer effect (light edge)
		var edge_sprite = Sprite2D.new()
		var edge_gradient = Gradient.new()
		var edge_color = Color(1, 1, 1, 0.6)
		edge_gradient.set_color(0, Color(1, 1, 1, 0))
		edge_gradient.set_color(1, edge_color)
		
		var edge_texture = GradientTexture2D.new()
		edge_texture.gradient = edge_gradient
		edge_texture.fill = 1  # Vertical fill
		edge_texture.width = int(w)
		edge_texture.height = 4
		
		edge_sprite.texture = edge_texture
		edge_sprite.position = Vector2(w/2, 2)
		platform.add_child(edge_sprite)
	
	# Use Kenney tile sprites for platforms (non-crystal)
	else:
		# Different tiles for different level themes
		var tile_indices = [
			0,   # Grass/green
			6,   # Stone/gray  
			12,  # Brown/wood
			18,  # Dark
			24,  # More grass
			30,  # Stone variant
			36,  # Cave
			42   # Rainbow
		]
		var tile_idx = tile_indices[current_level % tile_indices.size()]
		
		# Calculate tile position in spritesheet
		var tiles_per_row = 20  # From tilesheet info
		var tile_x = (tile_idx % tiles_per_row) * 19 + 1  # 18px + 1px gap
		var tile_y = (tile_idx / tiles_per_row) * 19 + 1
		
		# Create multiple sprites to tile across the platform
		var tile_size = 18
		var tiles_x = ceil(w / float(tile_size))
		var tiles_y = ceil(h / float(tile_size))
		
		for ty in range(tiles_y):
			for tx in range(tiles_x):
				var sprite = Sprite2D.new()
				sprite.texture = tile_tilesheet
				sprite.region_enabled = true
				sprite.region_rect = Rect2(tile_x, tile_y, tile_size, tile_size)
				# Position sprite - start from top-left
				sprite.position = Vector2(tx * tile_size, ty * tile_size)
				# Clip to platform bounds
				if tx == tiles_x - 1:
					sprite.scale.x = (w - tx * tile_size) / tile_size
				if ty == tiles_y - 1:
					sprite.scale.y = (h - ty * tile_size) / tile_size
				platform.add_child(sprite)
	
	# Collision - position at center of platform
	var collision = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(w, h)
	collision.shape = rect
	collision.position = Vector2(w/2, h/2)  # Center collision
	platform.add_child(collision)
	
	add_child(platform)
	platforms.append(platform)
	
	# Setup moving platform if needed
	if is_moving:
		platform.setup_movement(move_data)
		moving_platforms.append(platform)

func create_coin(x, y):
	var coin = Area2D.new()
	coin.position = Vector2(x, y)
	coin.script = load("res://coin.gd")
	
	# Use Kenney coin sprite (tile 18 in characters sheet = yellow/orange)
	var sprite = Sprite2D.new()
	sprite.texture = char_tilesheet
	sprite.region_enabled = true
	# Tile 18 is the coin in characters sheet
	sprite.region_rect = Rect2(18 * 25, 0, 24, 24)  # 24px + 1px gap
	sprite.position = Vector2(0, -12)
	coin.add_child(sprite)
	
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 12
	col.shape = circle
	coin.add_child(col)
	
	add_child(coin)
	coins.append(coin)

# 💎 Create a gem collectible - rare valuable item
var gems_collected = 0

func create_gem(x, y):
	var gem = Area2D.new()
	gem.position = Vector2(x, y)
	gem.set_script(load("res://coin.gd"))  # Reuse coin script with custom behavior
	
	# Create diamond/gem shape using Polygon2D
	var sprite = Polygon2D.new()
	var pts = PackedVector2Array([
		Vector2(0, -12),   # Top
		Vector2(8, -4),    # Upper right
		Vector2(8, 6),    # Lower right
		Vector2(0, 12),    # Bottom
		Vector2(-8, 6),   # Lower left
		Vector2(-8, -4)    # Upper left
	])
	sprite.polygon = pts
	sprite.color = Color(0.3, 0.9, 1.0, 1)  # Cyan diamond
	sprite.position = Vector2(0, 0)
	gem.add_child(sprite)
	
	# Add inner glow
	var inner = Polygon2D.new()
	inner.polygon = pts.duplicate()
	inner.scale = Vector2(0.5, 0.5)
	inner.color = Color(0.8, 1, 1, 0.7)
	gem.add_child(inner)
	
	# Add sparkle effect
	var sparkle = Polygon2D.new()
	var sparkle_pts = PackedVector2Array()
	for i in range(4):
		var angle = i * TAU / 4
		sparkle_pts.append(Vector2(cos(angle), sin(angle)) * 10)
	sparkle.polygon = sparkle_pts
	sparkle.color = Color(1, 1, 1, 0.8)
	sparkle.position = Vector2(0, -2)
	gem.add_child(sparkle)
	
	# Collision
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 14
	col.shape = circle
	gem.add_child(col)
	
	# Override the collect method for gems
	gem.collect = func():
		if is_instance_valid(gem):
			gems_collected += 1
			add_score(50)  # Gems worth more than coins
			collect_gem()
			spawn_collection_particles(Color(0.3, 0.9, 1.0), gem.position)
			gem.queue_free()
	
	# Connect body entered
	gem.body_entered.connect(func(body):
		if body.is_in_group("player") and gem.collect:
			gem.collect.call()
	)
	
	add_child(gem)
	gems.append(gem)
	
	# Add floating animation
	var float_tween = create_tween()
	float_tween.set_loops()
	float_tween.tween_property(gem, "position:y", gem.position.y - 5, 1.0)
	float_tween.tween_property(gem, "position:y", gem.position.y + 5, 1.0)

func collect_gem():
	save_data["total_gems"] += 1
	update_achievement_progress("gem_collector", save_data["total_gems"])
	update_ui_labels()

# ✨ Create a magic rune - special collectible with effects
var runes_collected = 0

func create_rune(x, y):
	var rune = Area2D.new()
	rune.position = Vector2(x, y)
	rune.script = load("res://rune.gd")
	
	add_child(rune)
	runes.append(rune)
	
	# Add to collectibles group for tracking
	rune.add_to_group("collectible")

# Track runes
var runes: Array[Area2D] = []
	
	# 💎 Gem collection - big effect!
	if player:
		spawn_big_collection_effect(Color(0.3, 0.9, 1.0), player.global_position)
		screen_shake_intensity(4)

# 🌟 Create a star collectible
func create_star(x, y):
	var star = Area2D.new()
	star.position = Vector2(x, y)
	star.script = load("res://star.gd")
	
	# Create star shape using Polygon2D
	var sprite = Polygon2D.new()
	var pts = PackedVector2Array()
	var inner_radius = 8.0
	var outer_radius = 16.0
	for i in range(10):
		var radius = inner_radius if i % 2 == 0 else outer_radius
		var angle = i * TAU / 10 - TAU / 4
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	sprite.polygon = pts
	sprite.color = Color(1, 0.85, 0.2, 1)
	sprite.position = Vector2(0, -8)
	star.add_child(sprite)
	
	# Add glow effect
	var glow = Polygon2D.new()
	glow.polygon = pts.duplicate()
	glow.color = Color(1, 0.9, 0.4, 0.4)
	glow.position = sprite.position
	star.add_child(glow)
	
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 14
	col.shape = circle
	star.add_child(col)
	
	# Connect body entered signal manually
	star.body_entered.connect(star._on_body_entered)
	
	add_child(star)
	stars.append(star)

func create_enemy(x, y, type = "ground", hp = 1, min_x = 0, max_x = 300) -> CharacterBody2D:
	var enemy: CharacterBody2D
	
	if type == "flying":
		enemy = CharacterBody2D.new()
		enemy.script = load("res://flying_enemy.gd")
		
		# Kenney monster sprite (tile 0)
		var sprite = Sprite2D.new()
		sprite.name = "Visual"
		sprite.texture = enemy_tilesheet
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, 24, 24)
		sprite.position = Vector2(0, -12)
		enemy.add_child(sprite)
		
		# Collision
		var col = CollisionShape2D.new()
		col.position = Vector2(0, -12)
		var rect = RectangleShape2D.new()
		rect.size = Vector2(20, 20)
		col.shape = rect
		enemy.add_child(col)
	elif type == "jellyfish":
		enemy = CharacterBody2D.new()
		enemy.script = load("res://jellyfish_enemy.gd")
		
		# Kenney monster sprite (tile 1)
		var sprite = Sprite2D.new()
		sprite.name = "Visual"
		sprite.texture = enemy_tilesheet
		sprite.region_enabled = true
		sprite.region_rect = Rect2(24, 0, 24, 24)
		sprite.position = Vector2(0, -12)
		sprite.modulate = Color(1, 0.6, 0.8, 0.8)  # Pink tint
		enemy.add_child(sprite)
		
		# Collision
		var col = CollisionShape2D.new()
		col.position = Vector2(0, -12)
		var rect = RectangleShape2D.new()
		rect.size = Vector2(18, 18)
		col.shape = rect
		enemy.add_child(col)
		
		# Set movement bounds
		enemy.set_meta("min_x", x - 50)
		enemy.set_meta("max_x", x + 50)
	elif type == "slime":
		# Slime enemy - green bouncing enemy
		enemy = CharacterBody2D.new()
		enemy.position = Vector2(x, y)
		enemy.script = load("res://slime_enemy.gd")
		
		# Kenney monster sprite (tile 2)
		var sprite = Sprite2D.new()
		sprite.name = "Visual"
		sprite.texture = enemy_tilesheet
		sprite.region_enabled = true
		sprite.region_rect = Rect2(48, 0, 24, 24)
		sprite.position = Vector2(0, -12)
		sprite.modulate = Color(0.3, 1, 0.3, 1)  # Green tint
		enemy.add_child(sprite)
		
		# Collision
		var col = CollisionShape2D.new()
		col.position = Vector2(0, -12)
		var rect = RectangleShape2D.new()
		rect.size = Vector2(20, 20)
		col.shape = rect
		enemy.add_child(col)
		
		# Set movement bounds
		enemy.set_meta("min_x", min_x)
		enemy.set_meta("max_x", max_x)
	elif type == "electric":
		# Electric Eel - fast horizontal movement with electric discharge
		enemy = CharacterBody2D.new()
		enemy.position = Vector2(x, y)
		enemy.script = load("res://electric_enemy.gd")
		
		# Kenney monster sprite (tile 3)
		var sprite = Sprite2D.new()
		sprite.name = "Visual"
		sprite.texture = enemy_tilesheet
		sprite.region_enabled = true
		sprite.region_rect = Rect2(72, 0, 24, 24)
		sprite.position = Vector2(0, -12)
		sprite.modulate = Color(1, 0.9, 0.3, 1)  # Yellow tint
		enemy.add_child(sprite)
		
		# Collision
		var col = CollisionShape2D.new()
		col.position = Vector2(0, -12)
		var rect = RectangleShape2D.new()
		rect.size = Vector2(18, 18)
		col.shape = rect
		enemy.add_child(col)
		
		# Set movement bounds
		enemy.set_meta("min_x", min_x)
		enemy.set_meta("max_x", max_x)
	elif type == "shooting":
		# Shooting Turret - shoots projectiles at player
		enemy = CharacterBody2D.new()
		enemy.position = Vector2(x, y)
		enemy.script = load("res://shooting_enemy.gd")
		
		# Kenney monster sprite (tile 4)
		var sprite = Sprite2D.new()
		sprite.name = "Visual"
		sprite.texture = enemy_tilesheet
		sprite.region_enabled = true
		sprite.region_rect = Rect2(96, 0, 24, 24)
		sprite.position = Vector2(0, -12)
		enemy.add_child(sprite)
		
		# Collision
		var col = CollisionShape2D.new()
		col.position = Vector2(0, -12)
		var rect = RectangleShape2D.new()
		rect.size = Vector2(20, 20)
		col.shape = rect
		enemy.add_child(col)
		
		# Set movement bounds
		enemy.set_meta("min_x", min_x)
		enemy.set_meta("max_x", max_x)
	elif type == "fireball":
		# Fireball enemy - fiery bouncing enemy
		enemy = CharacterBody2D.new()
		enemy.position = Vector2(x, y)
		enemy.script = load("res://fireball_enemy.gd")
		
		# Kenney monster sprite (tile 5)
		var sprite = Sprite2D.new()
		sprite.name = "Visual"
		sprite.texture = enemy_tilesheet
		sprite.region_enabled = true
		sprite.region_rect = Rect2(120, 0, 24, 24)
		sprite.position = Vector2(0, -12)
		sprite.modulate = Color(1, 0.5, 0.2, 1)  # Fire tint
		enemy.add_child(sprite)
		
		# Collision
		var col = CollisionShape2D.new()
		col.position = Vector2(0, -12)
		var rect = RectangleShape2D.new()
		rect.size = Vector2(18, 18)
		col.shape = rect
		enemy.add_child(col)
		
		# Set movement bounds
		enemy.set_meta("min_x", min_x)
		enemy.set_meta("max_x", max_x)
	elif type == "chaser":
		# Chaser enemy - follows player
		enemy = CharacterBody2D.new()
		enemy.position = Vector2(x, y)
		enemy.script = load("res://chaser_enemy.gd")
		
		# Kenney monster sprite
		var sprite = Sprite2D.new()
		sprite.name = "Visual"
		sprite.texture = enemy_tilesheet
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, 24, 24)
		sprite.position = Vector2(0, -12)
		sprite.modulate = Color(1, 0.3, 0.3, 1)  # Red tint
		enemy.add_child(sprite)
		
		var col = CollisionShape2D.new()
		col.position = Vector2(0, -10)
		var rect = RectangleShape2D.new()
		rect.size = Vector2(18, 18)
		col.shape = rect
		enemy.add_child(col)
	elif type == "suicide":
		# Suicide bomber enemy - explodes when close
		enemy = CharacterBody2D.new()
		enemy.position = Vector2(x, y)
		enemy.script = load("res://suicide_enemy.gd")
		
		# Kenney monster sprite
		var sprite = Sprite2D.new()
		sprite.name = "Visual"
		sprite.texture = enemy_tilesheet
		sprite.region_enabled = true
		sprite.region_rect = Rect2(24, 0, 24, 24)
		sprite.position = Vector2(0, -12)
		sprite.modulate = Color(1, 0.2, 0.2, 1)  # Red danger
		enemy.add_child(sprite)
		
		var col = CollisionShape2D.new()
		col.position = Vector2(0, -12)
		var rect = RectangleShape2D.new()
		rect.size = Vector2(20, 20)
		col.shape = rect
		enemy.add_child(col)
	elif type == "boss":
		# Boss enemy
		enemy = CharacterBody2D.new()
		enemy.position = Vector2(x, y)
		enemy.script = load("res://boss_enemy.gd")
		enemy.hp = hp
		enemy.max_hp = hp
		
		# Kenney monster sprite (scaled up for boss)
		var sprite = Sprite2D.new()
		sprite.name = "Visual"
		sprite.texture = enemy_tilesheet
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, 24, 24)
		sprite.position = Vector2(0, -24)
		sprite.scale = Vector2(2, 2)  # Make boss bigger
		sprite.modulate = Color(0.5, 0.1, 0.1, 1)  # Dark red
		enemy.add_child(sprite)
		
		# Boss collision
		var col = CollisionShape2D.new()
		col.position = Vector2(0, -20)
		var rect = RectangleShape2D.new()
		rect.size = Vector2(40, 40)
		col.shape = rect
		enemy.add_child(col)
	elif type == "teleport":
		# Teleport enemy - teleports around the level
		enemy = CharacterBody2D.new()
		enemy.position = Vector2(x, y)
		enemy.script = load("res://teleport_enemy.gd")
		
		# Kenney monster sprite
		var sprite = Sprite2D.new()
		sprite.name = "Visual"
		sprite.texture = enemy_tilesheet
		sprite.region_enabled = true
		sprite.region_rect = Rect2(48, 0, 24, 24)
		sprite.position = Vector2(0, -12)
		sprite.modulate = Color(0.6, 0.3, 1, 1)  # Purple tint
		enemy.add_child(sprite)
		
		# Collision
		var col = CollisionShape2D.new()
		col.position = Vector2(0, -12)
		var rect = RectangleShape2D.new()
		rect.size = Vector2(20, 20)
		col.shape = rect
		enemy.add_child(col)
	elif type == "phantom_mage":
		# Phantom Mage - magical floating enemy with special attacks
		enemy = CharacterBody2D.new()
		enemy.position = Vector2(x, y)
		enemy.script = load("res://phantom_mage_enemy.gd")
		
		# Kenney monster sprite
		var sprite = Sprite2D.new()
		sprite.name = "Visual"
		sprite.texture = enemy_tilesheet
		sprite.region_enabled = true
		sprite.region_rect = Rect2(72, 0, 24, 24)
		sprite.position = Vector2(0, -12)
		sprite.modulate = Color(0.4, 0.3, 0.8, 1)  # Purple tint
		enemy.add_child(sprite)
		
		# Collision
		var col = CollisionShape2D.new()
		col.position = Vector2(0, -15)
		var circle = CircleShape2D.new()
		circle.radius = 15
		col.shape = circle
		enemy.add_child(col)
		
		# Set movement bounds
		enemy.set_meta("min_x", min_x)
		enemy.set_meta("max_x", max_x)
	else:
		enemy = CharacterBody2D.new()
		enemy.position = Vector2(x, y)
		enemy.script = load("res://enemy.gd")
		enemy.platform_bounds = {"min_x": 0, "max_x": 300}
		
		# Use Kenney enemy/monster sprite (tile 9-11 in characters sheet)
		var sprite = Sprite2D.new()
		sprite.name = "Visual"  # Named for animation functions
		sprite.texture = char_tilesheet
		sprite.region_enabled = true
		# Monster/enemy is around tile 9-12 in characters sheet
		sprite.region_rect = Rect2(9 * 25, 0, 24, 24)
		sprite.position = Vector2(0, -12)
		enemy.add_child(sprite)
		
		# Collision
		var col = CollisionShape2D.new()
		col.position = Vector2(0, -12)
		var rect = RectangleShape2D.new()
		rect.size = Vector2(20, 24)
		col.shape = rect
		enemy.add_child(col)
	
	add_child(enemy)
	enemies.append(enemy)
	return enemy

func create_checkpoint(x, y):
	var cp = Area2D.new()
	cp.position = Vector2(x, y)
	
	var vis = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(6):
		var a = i * TAU / 6
		pts.append(Vector2(cos(a), sin(a)) * 16)
	vis.polygon = pts
	vis.color = Color(0.3, 0.8, 0.3, 0.6)
	cp.add_child(vis)
	
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 15
	col.shape = circle
	cp.add_child(col)
	
	cp.body_entered.connect(func(body):
		if body.is_in_group("player"):
			checkpoint_pos = cp.position
			# Visual feedback
			vis.color = Color(0.3, 1, 0.3, 0.8)
	)
	
	add_child(cp)

func create_mimic(x, y):
	var mimic = CharacterBody2D.new()
	mimic.position = Vector2(x, y)
	mimic.script = load("res://mimic_enemy.gd")
	mimic.add_to_group("enemy")
	add_child(mimic)
	enemies.append(mimic)

func create_goal(x, y):
	goal = Area2D.new()
	goal.position = Vector2(x, y)
	goal.script = load("res://goal.gd")
	
	# Use Kenney portal/door sprite (tile 21-22 in characters sheet)
	var sprite = Sprite2D.new()
	sprite.texture = char_tilesheet
	sprite.region_enabled = true
	# Portal/door is around tile 21-23
	sprite.region_rect = Rect2(21 * 25, 0, 24, 24)
	sprite.position = Vector2(0, -12)
	goal.add_child(sprite)
	
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 16
	col.shape = circle
	goal.add_child(col)
	
	add_child(goal)

# 🌀 Create a powerup
var powerups: Array[Area2D] = []

func create_powerup(x, y, powerup_type = null):
	var powerup = Area2D.new()
	powerup.position = Vector2(x, y)
	powerup.script = load("res://powerup.gd")
	# Set specific type if provided
	if powerup_type != null:
		# Force specific type by setting it after ready
		powerup.set_meta("forced_type", powerup_type)
	add_child(powerup)
	powerups.append(powerup)

# 💰 Create a treasure chest
func create_treasure_chest(x, y, chest_type = null):
	var chest = Area2D.new()
	chest.position = Vector2(x, y)
	chest.script = load("res://treasure_chest.gd")
	if chest_type != null:
		chest.set_meta("forced_type", chest_type)
	add_child(chest)

# 🎯 Create a pressure plate trigger
func create_pressure_plate(x, y, trigger_type = "enemy", trigger_id = 0):
	var plate = Area2D.new()
	plate.position = Vector2(x, y)
	plate.script = load("res://pressure_plate.gd")
	plate.set_meta("trigger_type", trigger_type)
	plate.set_meta("trigger_id", trigger_id)
	add_child(plate)

# 🗝️ Create a puzzle key
var puzzle_keys: Array[Area2D] = []

func create_puzzle_key(x, y, key_type = "silver"):
	var key = Area2D.new()
	key.position = Vector2(x, y)
	key.script = load("res://puzzle_key.gd")
	if key_type != null:
		key.set_meta("key_type", key_type)
	add_child(key)
	puzzle_keys.append(key)

# 🔒 Create a locked door
var locked_doors: Array[Area2D] = []

func create_locked_door(x, y, key_type = "silver"):
	var door = Area2D.new()
	door.position = Vector2(x, y)
	door.script = load("res://locked_door.gd")
	door.set_meta("required_key_type", key_type)
	add_child(door)
	locked_doors.append(door)

# 🎯 Handle pressure plate activation (called from pressure_plate.gd)
func on_pressure_plate_activated(trigger_type: String, trigger_id: int):
	match trigger_type:
		"spawn_enemy":
			# Spawn a special enemy near the player
			if player:
				var enemy = CharacterBody2D.new()
				enemy.position = player.position + Vector2(randf_range(-100, 100), -50)
				enemy.script = load("res://enemy.gd")
				add_child(enemy)
				enemies.append(enemy)
				show_floating_text_in_game("⚠️ Enemy Spawned!")
		"reveal_coin":
			# Reveal hidden bonus coins
			if player:
				for i in range(5):
					var coin = Area2D.new()
					coin.position = player.position + Vector2(randf_range(-80, 80), randf_range(-40, 40))
					coin.script = load("res://coin.gd")
					add_child(coin)
					coins.append(coin)
				show_floating_text_in_game("💰 Hidden Coins Revealed!")
		"unlock_shortcut":
			# Unlock a hidden platform/path
			show_floating_text_in_game("🗺️ Shortcut Opened!")
			# Create a bonus platform
			var shortcut = StaticBody2D.new()
			shortcut.position = Vector2(1150, 350)
			var col = CollisionShape2D.new()
			var rect = RectangleShape2D.new()
			rect.size = Vector2(80, 20)
			col.shape = rect
			shortcut.add_child(col)
			var visual = ColorRect.new()
			visual.size = Vector2(80, 20)
			visual.color = Color(0.3, 0.6, 1, 0.8)  # Glowing blue
			shortcut.add_child(visual)
			add_child(shortcut)
			platforms.append(shortcut)
			# Animate appearance
			visual.modulate.a = 0
			var tw = create_tween()
			tw.tween_property(visual, "modulate:a", 1.0, 0.5)

func show_floating_text_in_game(text: String):
	if not player:
		return
	var label = Label.new()
	label.text = text
	label.position = player.global_position + Vector2(0, -50)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
	add_child(label)
	var tw = create_tween()
	tw.tween_property(label, "position:y", label.position.y - 40, 1.0)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tw.tween_callback(label.queue_free)

# 🦋 Create a pet companion
var current_pet: Node2D = null

func create_pet(pet_type_name: String, owner: Node2D):
	if current_pet and is_instance_valid(current_pet):
		current_pet.queue_free()
	
	var pet = Node2D.new()
	pet.position = owner.position + Vector2(0, -40)
	pet.set_script(load("res://pet.gd"))
	add_child(pet)
	
	var pet_type_map = {"lobster": 0, "firefly": 1, "ghost": 2, "robot": 3}
	var ptype = pet_type_map.get(pet_type_name.to_lower(), 0)
	pet.activate(ptype, owner)
	current_pet = pet
	
	# Show pet notification
	show_pet_notification(pet_type_name, pet.get_pet_bonus())
	
	return pet

func show_pet_notification(pet_type: String, bonuses: Dictionary):
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	var pet_names = {"lobster": "🦞 Lobster Pet", "firefly": "✨ Firefly", "ghost": "👻 Ghost", "robot": "🤖 Robot"}
	var notif = Label.new()
	notif.text = "🦋 New Pet: " + pet_names.get(pet_type, pet_type) + "\n"
	
	var bonus_text = ""
	for key in bonuses:
		bonus_text += "• " + key + ": " + str(bonuses[key]) + "\n"
	notif.text += bonus_text
	
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif.position = Vector2(500, 120)
	notif.add_theme_font_size_override("font_size", 18)
	notif.add_theme_color_override("font_color", Color(0.4, 1, 0.8))
	notif.modulate.a = 0
	ui.add_child(notif)
	
	var tween = create_tween()
	tween.tween_property(notif, "modulate:a", 1.0, 0.3)
	tween.tween_interval(3.0)
	tween.tween_property(notif, "modulate:a", 0.0, 0.5)
	tween.tween_property(notif, "position:y", notif.position.y - 20, 0.5)
	tween.tween_callback(notif.queue_free)

# 🌈 Rainbow coin - rare bonus collectible
var rainbow_coins: Array[Area2D] = []

func create_rainbow_coin(x, y):
	var coin = Area2D.new()
	coin.position = Vector2(x, y)
	coin.add_to_group("rainbow_coin")
	
	# Rainbow colored sprite
	var sprite = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8
		pts.append(Vector2(cos(angle), sin(angle)) * 10)
	sprite.polygon = pts
	sprite.position = Vector2(0, -8)
	coin.add_child(sprite)
	
	# Rainbow animation
	var colors = [Color(1, 0, 0), Color(1, 0.5, 0), Color(1, 1, 0), Color(0, 1, 0), Color(0, 0, 1), Color(0.5, 0, 1)]
	
	var tween = create_tween()
	tween.set_loops()
	var color_idx = 0
	for c in colors:
		tween.tween_property(sprite, "color", c, 0.2)
	
	# Collision
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 10
	col.shape = circle
	coin.add_child(col)
	
	coin.body_entered.connect(func(body):
		if body.is_in_group("player"):
			collect_rainbow_coin(coin)
	)
	
	add_child(coin)
	rainbow_coins.append(coin)

func collect_rainbow_coin(coin):
	if not is_instance_valid(coin):
		return
	
	# Big bonus!
	var bonus = 100 + randi() % 100  # 100-200 points
	add_score(bonus)
	
	# Rainbow explosion effect
	spawn_rainbow_explosion(coin.global_position)
	
	coin.queue_free()

func spawn_rainbow_explosion(pos: Vector2):
	for i in range(12):
		var particle = Polygon2D.new()
		var colors = [Color(1, 0, 0), Color(1, 0.5, 0), Color(1, 1, 0), Color(0, 1, 0), Color(0, 0, 1), Color(0.5, 0, 1)]
		particle.polygon = PackedVector2Array([Vector2(-3, 0), Vector2(0, -3), Vector2(3, 0), Vector2(0, 3)])
		particle.color = colors[randi() % colors.size()]
		particle.position = pos
		add_child(particle)
		
		var angle = i * TAU / 12
		var dist = randf_range(30, 60)
		var tw = create_tween()
		tw.tween_property(particle, "position", pos + Vector2(cos(angle), sin(angle)) * dist, 0.4)
		tw.tween_property(particle, "modulate:a", 0.0, 0.4)
		tw.tween_callback(particle.queue_free)

# 🍀 Lucky Coin - grants random positive effect
var lucky_coins: Array[Area2D] = []

func create_lucky_coin(x, y):
	var coin = Area2D.new()
	coin.position = Vector2(x, y)
	coin.add_to_group("lucky_coin")
	
	# Clover-shaped sprite
	var sprite = Polygon2D.new()
	var pts = PackedVector2Array([
		Vector2(0, -8), Vector2(-3, -6), Vector2(-6, -3),
		Vector2(-8, 0), Vector2(-6, 3), Vector2(-3, 6),
		Vector2(0, 8), Vector2(3, 6), Vector2(6, 3),
		Vector2(8, 0), Vector2(6, -3), Vector2(3, -6)
	])
	sprite.polygon = pts
	sprite.position = Vector2(0, -8)
	sprite.color = Color(0.2, 1, 0.4, 1)  # Lucky green
	coin.add_child(sprite)
	
	# Glow effect
	var glow = Polygon2D.new()
	glow.polygon = pts.duplicate()
	glow.scale = Vector2(1.3, 1.3)
	glow.color = Color(0.4, 1, 0.6, 0.4)
	glow.position = sprite.position
	coin.add_child(glow)
	
	# Sparkle animation
	var sparkle = Polygon2D.new()
	var sparkle_pts = PackedVector2Array()
	for i in range(4):
		var angle = i * TAU / 4
		sparkle_pts.append(Vector2(cos(angle), sin(angle)) * 6)
	sparkle.polygon = sparkle_pts
	sparkle.color = Color(1, 1, 0.5, 0.8)
	sparkle.position = Vector2(4, -12)
	coin.add_child(sparkle)
	
	var tw = create_tween()
	tw.set_loops()
	tw.tween_property(sparkle, "scale", Vector2(1.5, 1.5), 0.3)
	tw.tween_property(sparkle, "scale", Vector2(1.0, 1.0), 0.3)
	
	# Collision
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 12
	col.shape = circle
	coin.add_child(col)
	
	coin.body_entered.connect(func(body):
		if body.is_in_group("player"):
			collect_lucky_coin(coin)
	)
	
	add_child(coin)
	lucky_coins.append(coin)

func collect_lucky_coin(coin):
	if not is_instance_valid(coin):
		return
	
	# Random lucky effect
	var effects = [
		"score_boost", "invincibility", "speed_boost", "extra_life", "skill_point"
	]
	var effect = effects[randi() % effects.size()]
	
	match effect:
		"score_boost":
			add_score(200)
			show_floating_text("+200 LUCKY!", coin.global_position, Color(1, 0.9, 0.2))
		"invincibility":
			if player:
				player.activate_invincible(3.0)
			show_floating_text("INVINCIBLE!", coin.global_position, Color(1, 0.8, 0.2))
		"speed_boost":
			if player:
				player.activate_speed_boost(5.0)
			show_floating_text("SPEED UP!", coin.global_position, Color(0.2, 0.9, 1))
		"extra_life":
			lives = min(lives + 1, 5)
			_update_lives()
			show_floating_text("+1 LIFE!", coin.global_position, Color(1, 0.4, 0.4))
		"skill_point":
			add_skill_point()
			show_floating_text("+1 SKILL POINT!", coin.global_position, Color(0.4, 1, 0.6))
	
	# Lucky explosion
	spawn_lucky_explosion(coin.global_position)
	coin.queue_free()

func spawn_lucky_explosion(pos: Vector2):
	for i in range(10):
		var particle = Polygon2D.new()
		particle.polygon = PackedVector2Array([Vector2(-2, 0), Vector2(0, -2), Vector2(2, 0), Vector2(0, 2)])
		particle.color = Color(0.2 + randf() * 0.8, 1, 0.2 + randf() * 0.6, 0.9)
		particle.position = pos
		add_child(particle)
		
		var angle = i * TAU / 10
		var dist = randf_range(25, 50)
		var tw = create_tween()
		tw.tween_property(particle, "position", pos + Vector2(cos(angle), sin(angle)) * dist, 0.4)
		tw.parallel().tween_property(particle, "scale", Vector2(0.5, 0.5), 0.4)
		tw.tween_property(particle, "modulate:a", 0.0, 0.4)
		tw.tween_callback(particle.queue_free)
	
	screen_shake_intensity(3)

func show_floating_text(text: String, pos: Vector2, color: Color):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", color)
	label.position = pos + Vector2(-30, -30)
	add_child(label)
	
	var tw = create_tween()
	tw.tween_property(label, "position", label.position + Vector2(0, -30), 1.0)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tw.tween_callback(label.queue_free)

# 🌀 Create a warp portal - teleports to unlocked levels
var warp_portals: Array[Area2D] = []

func create_warp_portal(x, y):
	var portal = Area2D.new()
	portal.position = Vector2(x, y)
	portal.script = load("res://warp_portal.gd")
	
	# Create visual - swirling portal effect
	var sprite = Polygon2D.new()
	var pts = PackedVector2Array()
	var num_points = 8
	for i in range(num_points):
		var angle = i * TAU / num_points
		pts.append(Vector2(cos(angle), sin(angle)) * 16)
	sprite.polygon = pts
	sprite.color = Color(0.4, 0.8, 1, 0.8)
	portal.add_child(sprite)
	
	# Inner glow
	var inner = Polygon2D.new()
	inner.polygon = pts.duplicate()
	inner.scale = Vector2(0.6, 0.6)
	inner.color = Color(0.6, 0.9, 1, 0.6)
	portal.add_child(inner)
	
	# Collision
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 18
	col.shape = circle
	portal.add_child(col)
	
	portal.body_entered.connect(func(body):
		if body.is_in_group("player"):
			portal.collect()
	)
	
	add_child(portal)
	warp_portals.append(portal)

func setup_ui():
	var old = get_tree().get_first_node_in_group("ui")
	if old: old.queue_free()
	
	var canvas = CanvasLayer.new()
	canvas.add_to_group("ui")
	add_child(canvas)
	
	# 创建 UI 面板背景
	var panel = PanelContainer.new()
	panel.position = Vector2(10, 10)
	panel.custom_minimum_size = Vector2(180, 0)
	canvas.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	# 分数 - 带图标的
	var score_container = HBoxContainer.new()
	var score_icon = Label.new()
	score_icon.text = "💰"
	score_icon.add_theme_font_size_override("font_size", 20)
	score_container.add_child(score_icon)
	
	var score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "0"
	score_label.add_theme_font_size_override("font_size", 22)
	score_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	score_container.add_child(score_label)
	vbox.add_child(score_container)
	
	# 生命 - 带图标的
	var lives_container = HBoxContainer.new()
	var lives_icon = Label.new()
	lives_icon.text = "❤️"
	lives_icon.add_theme_font_size_override("font_size", 20)
	lives_container.add_child(lives_icon)
	
	var lives_label = Label.new()
	lives_label.name = "LivesLabel"
	lives_label.text = "3"
	lives_label.add_theme_font_size_override("font_size", 22)
	lives_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	lives_container.add_child(lives_label)
	vbox.add_child(lives_container)
	
	# 关卡 - 带图标的
	var level_container = HBoxContainer.new()
	var level_icon = Label.new()
	level_icon.text = "🗺️"
	level_icon.add_theme_font_size_override("font_size", 20)
	level_container.add_child(level_icon)
	
	var level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.text = "1"
	level_label.add_theme_font_size_override("font_size", 22)
	level_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1))
	level_container.add_child(level_label)
	vbox.add_child(level_container)
	
	# ⏱️ Timer label
	var timer_container = HBoxContainer.new()
	var timer_icon = Label.new()
	timer_icon.text = "⏱️"
	timer_icon.add_theme_font_size_override("font_size", 18)
	timer_container.add_child(timer_icon)
	
	var timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.text = "00:00"
	timer_label.add_theme_font_size_override("font_size", 18)
	timer_label.add_theme_color_override("font_color", Color(0.7, 0.8, 1))
	timer_container.add_child(timer_label)
	vbox.add_child(timer_container)
	
	# Combo label
	var combo_label = Label.new()
	combo_label.name = "ComboLabel"
	combo_label.text = ""
	combo_label.add_theme_font_size_override("font_size", 24)
	combo_label.add_theme_color_override("font_color", Color(1, 0.7, 0.1))
	vbox.add_child(combo_label)
	
	# 🔥 Super Combo Meter - fills up for special ability
	var meter_container = HBoxContainer.new()
	var meter_icon = Label.new()
	meter_icon.text = "🔥"
	meter_icon.add_theme_font_size_override("font_size", 16)
	meter_container.add_child(meter_icon)
	
	var meter_label = Label.new()
	meter_label.name = "ComboMeterLabel"
	meter_label.text = "[=====     ]"
	meter_label.add_theme_font_size_override("font_size", 14)
	meter_label.add_theme_color_override("font_color", Color(1, 0.5, 0.2))
	meter_container.add_child(meter_label)
	vbox.add_child(meter_container)
	
	# 🌟 Stars collected
	var star_container = HBoxContainer.new()
	var star_icon = Label.new()
	star_icon.text = "⭐"
	star_icon.add_theme_font_size_override("font_size", 18)
	star_container.add_child(star_icon)
	
	var star_label = Label.new()
	star_label.name = "StarLabel"
	star_label.text = "0"
	star_label.add_theme_font_size_override("font_size", 18)
	star_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	star_container.add_child(star_label)
	vbox.add_child(star_container)
	
	# 💎 Gems collected
	var gem_container = HBoxContainer.new()
	var gem_icon = Label.new()
	gem_icon.text = "💎"
	gem_icon.add_theme_font_size_override("font_size", 18)
	gem_container.add_child(gem_icon)
	
	var gem_label = Label.new()
	gem_label.name = "GemLabel"
	gem_label.text = "0"
	gem_label.add_theme_font_size_override("font_size", 18)
	gem_label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	gem_container.add_child(gem_label)
	vbox.add_child(gem_container)

func setup_mobile_controls():
	# 只在移动端显示虚拟按钮，Web PC 隐藏
	var is_mobile = OS.get_name() == "Android" or OS.get_name() == "iOS"
	var is_web = OS.get_name() == "Web"
	
	# Web 平台使用键盘，不需要虚拟按钮（除非检测到触摸设备）
	if is_web and not is_mobile:
		return  # Web PC 隐藏虚拟按钮
	
	var controls = CanvasLayer.new()
	controls.name = "MobileControls"
	add_child(controls)
	
	# 创建虚拟按钮容器 - 使用 TouchScreenButton 实现多点触控支持
	# 关键：使用 TouchScreenButton 而非普通 Button，支持多点触控
	# 同时添加 signal 处理以确保可靠的输入检测
	
	# 左侧方向按钮区域（左右）
	var dpad_bg = ColorRect.new()
	dpad_bg.color = Color(0.2, 0.2, 0.2, 0.5)
	dpad_bg.position = Vector2(20, 460)
	dpad_bg.size = Vector2(160, 100)
	controls.add_child(dpad_bg)
	
	# 左方向键 - 使用 signal 确保多点触控可靠
	var left_btn = TouchScreenButton.new()
	left_btn.name = "LeftBtn"
	left_btn.position = Vector2(30, 470)
	left_btn.size = Vector2(50, 50)
	left_btn.normal_color = Color(0.4, 0.4, 0.5)
	left_btn.pressed_color = Color(0.6, 0.6, 0.8)
	left_btn.action = "move_left"
	left_btn.visibility_layer = 1
	left_btn.ignore_input_ended = false
	# 确保支持多点触控的关键设置
	left_btn.passby_press = false
	left_btn.toggle_mode = false
	controls.add_child(left_btn)
	
	# 添加左按钮显示
	var left_label = Label.new()
	left_label.text = "◀"
	left_label.position = Vector2(38, 475)
	left_label.add_theme_font_size_override("font_size", 24)
	controls.add_child(left_label)
	
	# 右方向键
	var right_btn = TouchScreenButton.new()
	right_btn.name = "RightBtn"
	right_btn.position = Vector2(90, 470)
	right_btn.size = Vector2(50, 50)
	right_btn.normal_color = Color(0.4, 0.4, 0.5)
	right_btn.pressed_color = Color(0.6, 0.6, 0.8)
	right_btn.action = "move_right"
	right_btn.visibility_layer = 1
	right_btn.ignore_input_ended = false
	right_btn.passby_press = false
	right_btn.toggle_mode = false
	controls.add_child(right_btn)
	
	# 添加右按钮显示
	var right_label = Label.new()
	right_label.text = "▶"
	right_label.position = Vector2(98, 475)
	right_label.add_theme_font_size_override("font_size", 24)
	controls.add_child(right_label)
	
	# 跳跃按钮区域
	var jump_bg = ColorRect.new()
	jump_bg.color = Color(0.2, 0.2, 0.2, 0.5)
	jump_bg.position = Vector2(620, 460)
	jump_bg.size = Vector2(100, 100)
	controls.add_child(jump_bg)
	
	# 跳跃键
	var jump_btn = TouchScreenButton.new()
	jump_btn.name = "JumpBtn"
	jump_btn.position = Vector2(640, 470)
	jump_btn.size = Vector2(60, 60)
	jump_btn.normal_color = Color(0.4, 0.6, 0.4)
	jump_btn.pressed_color = Color(0.6, 0.8, 0.6)
	jump_btn.action = "jump"
	jump_btn.visibility_layer = 1
	jump_btn.ignore_input_ended = false
	jump_btn.passby_press = false
	jump_btn.toggle_mode = false
	controls.add_child(jump_btn)
	
	# 添加跳跃按钮显示
	var jump_label = Label.new()
	jump_label.text = "⬆"
	jump_label.position = Vector2(652, 475)
	jump_label.add_theme_font_size_override("font_size", 24)
	controls.add_child(jump_label)
	
	# 输出调试信息
	print("Mobile controls setup complete - multi-touch enabled")

func update_ui_labels():
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		var sl = ui.get_node_or_null("ScoreLabel")
		var ll = ui.get_node_or_null("LevelLabel")
		var lv = ui.get_node_or_null("LivesLabel")
		var star_lbl = ui.get_node_or_null("StarLabel")
		var gem_lbl = ui.get_node_or_null("GemLabel")
		if sl: sl.text = "Score: " + str(score)
		if ll: ll.text = "Level: " + str(current_level + 1)
		if lv and player: lv.text = "Lives: " + str(player.lives)
		if star_lbl: star_lbl.text = "⭐: " + str(stars_collected)
		if gem_lbl: gem_lbl.text = "💎: " + str(gems_collected)
		update_combo_display()
		update_timer_display()

func update_timer_display():
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		var tl = ui.get_node_or_null("TimerLabel")
		if tl:
			var mins = int(current_level_time) / 60
			var secs = int(current_level_time) % 60
			var ms = int((current_level_time - floor(current_level_time)) * 100)
			tl.text = "⏱️ %02d:%02d.%02d" % [mins, secs, ms]

func update_combo_display():
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		var cl = ui.get_node_or_null("ComboLabel")
		if cl:
			if combo > 1:
				cl.text = "Combo x" + str(combo) + "!"
				# Dynamic color based on combo level
				var combo_color = Color(1, 0.8, 0.2)
				if combo >= 5:
					combo_color = Color(1, 0.5, 0.2)  # Orange
				if combo >= 8:
					combo_color = Color(1, 0.2, 0.4)  # Red
				if combo >= 10:
					combo_color = Color(1, 0.2, 0.8)  # Purple - MAX!
				cl.add_theme_color_override("font_color", combo_color)
				# Pulse effect
				var scale = 1.0 + 0.1 * sin(Time.get_ticks_msec() / 100.0)
				cl.scale = Vector2(scale, scale)
			else:
				cl.text = ""
				cl.scale = Vector2(1, 1)

func trigger_combo_firework():
	# Firework effect for high combos
	if combo >= 5 and player:
		for i in range(min(combo - 2, 8)):
			var particle = Polygon2D.new()
			var pts = PackedVector2Array()
			for j in range(6):
				var angle = j * TAU / 6
				pts.append(Vector2(cos(angle), sin(angle)) * randf_range(3, 6))
			particle.polygon = pts
			
			var color_choice = randi() % 4
			if color_choice == 0:
				particle.color = Color(1, 0.8, 0.2, 0.9)
			elif color_choice == 1:
				particle.color = Color(1, 0.4, 0.4, 0.9)
			elif color_choice == 2:
				particle.color = Color(0.4, 0.8, 1, 0.9)
			else:
				particle.color = Color(0.8, 0.4, 1, 0.9)
			
			particle.position = player.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 10))
			add_child(particle)
			
			var tw = create_tween()
			var angle = i * TAU / 8
			var dist = randf_range(30, 60)
			tw.tween_property(particle, "position", particle.position + Vector2(cos(angle), sin(angle)) * dist, 0.5)
			tw.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
			tw.tween_callback(particle.queue_free)

func add_score(points):
	# Combo system - collect coins quickly for bonus!
	var now = Time.get_ticks_msec()
	if now - last_coin_time < 1500:  # 1.5 second window
		combo = min(combo + 1, 10)  # Max 10x combo
	else:
		combo = 1
	
	last_coin_time = now
	combo_timer = 2.0  # 2 seconds to maintain combo
	
	# Calculate bonus from combo
	var bonus = points * combo
	score += bonus
	
	# 🔥 Fill combo meter based on points
	if not super_combo_active:
		combo_meter = min(combo_meter + points * 0.5, combo_meter_max)
		if combo_meter >= combo_meter_max:
			activate_super_combo()
	
	# Trigger combo firework on high combos
	if combo >= 5:
		trigger_combo_firework()
	
	update_ui_labels()
	
	# Spawn coin collection particles
	if player:
		spawn_collection_particles(Color(1, 0.85, 0.2), player.global_position)
	
	# 🏆 Check achievements
	if points == 25:  # Enemy kill
		screen_shake_intensity(5)
	
	# Combo achievements
	if combo >= 10:
		unlock_achievement("combo_master")
	if combo >= 20:
		unlock_achievement("combo_god")

func activate_super_combo():
	super_combo_active = true
	super_combo_timer = 5.0  # 5 seconds of super combo
	
	# Give player temporary powers
	if player:
		player.speed_multiplier = 1.5
		player.is_invincible = true
		player.invincible_timer = 5.0
		# Enable Combo Finale ability
		player.can_combo_finale = true
	
	# Visual effect - screen flash
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		var flash = ColorRect.new()
		flash.size = Vector2(2000, 2000)
		flash.position = Vector2(-500, -500)
		flash.color = Color(1, 0.5, 0.2, 0.3)
		flash.z_index = 50
		ui.add_child(flash)
		
		var tw = create_tween()
		tw.tween_property(flash, "color:a", 0.0, 0.5)
		tw.tween_callback(flash.queue_free)
	
	# Show combo finale ready notification
	if ui:
		var notif = Label.new()
		notif.text = "⚡ COMBO FINALE READY!\nPress V to activate!"
		notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		notif.position = Vector2(200, 120)
		notif.add_theme_font_size_override("font_size", 24)
		notif.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		notif.modulate.a = 0
		ui.add_child(notif)
		
		var tw = create_tween()
		tw.tween_property(notif, "modulate:a", 1.0, 0.3)
		tw.tween_interval(3.0)
		tw.tween_property(notif, "modulate:a", 0.0, 0.5)
		tw.tween_property(notif, "position:y", notif.position.y - 30, 0.5)
		tw.tween_callback(notif.queue_free)
	
	screen_shake_intensity(8)

func update_combo_meter_display():
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		var meter_label = ui.get_node_or_null("ComboMeterLabel")
		if meter_label:
			if super_combo_active:
				meter_label.text = "🔥 SUPER! 🔥"
				meter_label.add_theme_color_override("font_color", Color(1, 0.3, 0.1))
			else:
				var filled = int(combo_meter / combo_meter_max * 5)
				var bar = ""
				for i in range(5):
					bar += "█" if i < filled else "░"
				meter_label.text = "[" + bar + "]"
				meter_label.add_theme_color_override("font_color", Color(1, 0.5, 0.2))

# 🌟 Called when player collects a star
func collect_star():
	stars_collected += 1
	update_ui_labels()
	
	# 🌟 Star collection particles - big effect!
	spawn_big_collection_effect(Color(1, 0.85, 0.3), player.global_position if player else Vector2.ZERO)
	screen_shake_intensity(3)
	
	# 🏆 Star achievements
	update_achievement_progress("star_gatherer", stars_collected)

# Spawn collection particles - 华丽版
func spawn_collection_particles(color: Color, pos: Vector2):
	# 创建圆形粒子而不是方形
	for i in range(12):
		var particle = Polygon2D.new()
		# 创建圆形
		var pts = PackedVector2Array()
		var radius = randf_range(2, 5)
		for j in range(8):
			var angle = j * TAU / 8
			pts.append(Vector2(cos(angle), sin(angle)) * radius)
		particle.polygon = pts
		particle.color = color
		particle.position = pos + Vector2(randf_range(-8, 8), randf_range(-15, 0))
		particle.z_index = 10
		add_child(particle)
		
		var tween = create_tween()
		var target = Vector2(randf_range(-50, 50), randf_range(-60, -30))
		tween.tween_property(particle, "position", particle.position + target, 0.6)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.6)
		tween.parallel().tween_property(particle, "scale", Vector2(0.2, 0.2), 0.6)
		tween.tween_callback(particle.queue_free)
	
	# 添加闪烁星星效果
	for i in range(6):
		var star = Polygon2D.new()
		var pts = PackedVector2Array()
		var inner_r = 3.0
		var outer_r = 8.0
		for j in range(10):
			var r = inner_r if j % 2 == 0 else outer_r
			var angle = j * TAU / 10 - TAU / 4
			pts.append(Vector2(cos(angle), sin(angle)) * r)
		star.polygon = pts
		star.color = Color(1, 1, 0.8)
		star.position = pos + Vector2(randf_range(-15, 15), randf_range(-20, 0))
		star.modulate.a = 0.9
		star.z_index = 11
		add_child(star)
		
		var tween = create_tween()
		tween.tween_property(star, "position", star.position + Vector2(randf_range(-30, 30), randf_range(-40, -20)), 0.5)
		tween.parallel().tween_property(star, "modulate:a", 0.0, 0.5)
		tween.parallel().tween_property(star, "scale", Vector2(0.3, 0.3), 0.5)
		tween.tween_callback(star.queue_free)

# Big collection effect for gems and stars
func spawn_big_collection_effect(color: Color, pos: Vector2):
	# Ring explosion
	for i in range(16):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(6):
			var angle = j * TAU / 6
			pts.append(Vector2(cos(angle), sin(angle)) * randf_range(2, 4))
		particle.polygon = pts
		particle.color = color
		particle.position = pos
		particle.z_index = 12
		add_child(particle)
		
		var angle = i * TAU / 16
		var distance = randf_range(40, 80)
		var target = Vector2(cos(angle), sin(angle)) * distance
		
		var tween = create_tween()
		tween.tween_property(particle, "position", pos + target, 0.8)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.8)
		tween.parallel().tween_property(particle, "scale", Vector2(0.1, 0.1), 0.8)
		tween.tween_callback(particle.queue_free)
	
	# Sparkle burst
	for i in range(8):
		var sparkle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(4):
			var angle = j * TAU / 4
			pts.append(Vector2(cos(angle), sin(angle)) * 6)
		sparkle.polygon = pts
		sparkle.color = Color(1, 1, 0.9, 0.9)
		sparkle.position = pos + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		sparkle.z_index = 13
		add_child(sparkle)
		
		var tween = create_tween()
		var target_pos = pos + Vector2(randf_range(-60, 60), randf_range(-80, -20))
		tween.tween_property(sparkle, "position", target_pos, 0.6)
		tween.parallel().tween_property(sparkle, "modulate:a", 0.0, 0.6)
		tween.parallel().tween_property(sparkle, "rotation", randf_range(2, 4), 0.6)
		tween.tween_callback(sparkle.queue_free)
	
	# Screen flash
	var flash = ColorRect.new()
	flash.size = Vector2(2000, 2000)
	flash.position = Vector2(-500, -500)
	flash.color = Color(color.r, color.g, color.b, 0.3)
	flash.z_index = 100
	add_child(flash)
	
	var flash_tween = create_tween()
	flash_tween.tween_property(flash, "color:a", 0.0, 0.3)
	flash_tween.tween_callback(flash.queue_free)

# 屏幕震动效果
func shake_screen(intensity: float, duration: float):
	screen_shake_intensity(intensity)
	await get_tree().create_timer(duration).timeout
	screen_shake = 0.0

func _update_lives():
	update_ui_labels()

# Random Event System - triggers special events during gameplay
var random_event_timer = 0.0
var last_random_event_time = 0.0
var active_random_event = ""

func trigger_random_event(delta):
	if not game_started or endless_mode or boss_rush_mode:
		return
	
	random_event_timer += delta
	
	# Only trigger random event every 30 seconds
	if random_event_timer - last_random_event_time < 30.0:
		return
	
	# 20% chance to trigger an event
	if randf() > 0.2:
		return
	
	last_random_event_time = random_event_timer
	
	# Pick random event
	var events = ["coin_rain", "speed_boost", "mystery_gift", "enemies_appear", "star_shower"]
	var event = events[randi() % events.size()]
	active_random_event = event
	
	match event:
		"coin_rain":
			trigger_coin_rain()
		"speed_boost":
			trigger_speed_boost_event()
		"mystery_gift":
			trigger_mystery_gift()
		"enemies_appear":
			trigger_enemy_swarm()
		"star_shower":
			trigger_star_shower()

func trigger_coin_rain():
	if not player:
		return
	
	# Spawn coins falling from sky
	for i in range(15):
		await get_tree().create_timer(randf_range(0.1, 0.5)).timeout
		
		var coin_x = player.global_position.x + randf_range(-200, 200)
		var coin_y = -50
		create_coin(coin_x, coin_y)
	
	show_event_notification("💰 Coin Rain!")

func trigger_speed_boost_event():
	if player:
		player.activate_speed_boost(8.0)
	show_event_notification("⚡ Speed Boost!")

func trigger_mystery_gift():
	if not player:
		return
	
	var gift_pos = player.global_position + Vector2(randf_range(-50, 50), -30)
	var powerup = Area2D.new()
	powerup.position = gift_pos
	powerup.script = load("res://powerup.gd")
	get_parent().add_child(powerup)
	
	show_event_notification("🎁 Mystery Gift!")

func trigger_enemy_swarm():
	if not player:
		return
	
	# Spawn extra enemies
	var spawn_x = player.global_position.x + randf_range(100, 300)
	create_enemy(spawn_x, player.global_position.y + 50, "slime", 1, spawn_x - 50, spawn_x + 50)
	create_enemy(spawn_x + 100, player.global_position.y + 50, "slime", 1, spawn_x + 50, spawn_x + 150)
	
	show_event_notification("⚠️ Enemy Swarm!")

func trigger_star_shower():
	if not player:
		return
	
	# Spawn stars falling from sky
	for i in range(10):
		await get_tree().create_timer(randf_range(0.1, 0.4)).timeout
		
		var star_x = player.global_position.x + randf_range(-250, 250)
		var star_y = -50
		create_star(star_x, star_y)
	
	show_event_notification("⭐ Star Shower!")

func show_event_notification(text: String):
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		var notif = Label.new()
		notif.text = text
		notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		notif.add_theme_font_size_override("font_size", 28)
		notif.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
		notif.position = Vector2(540, 150)
		notif.modulate.a = 0
		ui.add_child(notif)
		
		var tw = create_tween()
		tw.tween_property(notif, "modulate:a", 1.0, 0.3)
		tw.tween_interval(2.0)
		tw.tween_property(notif, "modulate:a", 0.0, 0.5)
		tw.tween_property(notif, "position:y", notif.position.y - 30, 0.5)
		tw.tween_callback(notif.queue_free)

func track_death():
	level_deaths += 1

func next_level():
	# Handle endless mode
	if endless_mode:
		advance_endless_level()
		return
	
	# 保存进度到存档
	save_data["total_coins"] += score
	save_data["total_stars"] += stars_collected
	save_data["total_gems"] += gems_collected
	# 保存每个关卡的星星数量（取最大值）
	if not save_data["level_stars"].has(current_level):
		save_data["level_stars"][current_level] = 0
	save_data["level_stars"][current_level] = max(save_data["level_stars"][current_level], stars_collected)
	# 保存每个关卡的宝石数量（取最大值）
	if not save_data["level_gems"].has(current_level):
		save_data["level_gems"][current_level] = 0
	save_data["level_gems"][current_level] = max(save_data["level_gems"][current_level], gems_collected)
	# 保存最佳时间
	var prev_best = save_data["best_times"].get(current_level, 999.0)
	if current_level_time < prev_best:
		save_data["best_times"][current_level] = current_level_time
		# Check time trial achievement
		var time_trial_count = 0
		for level_idx in save_data["best_times"]:
			if save_data["best_times"][level_idx] < 60:  # Under 60 seconds
				time_trial_count += 1
		update_achievement_progress("time_trialist", time_trial_count)
	
	# 解锁下一关
	unlock_level(current_level + 1)
	save_save_data()
	
	# Reset gems collected for next level
	gems_collected = 0
	
	# Show level complete popup
	show_level_complete_popup()
	
	current_level += 1
	# Check if player completed all levels (including boss)
	if current_level >= levels.size():
		# Show victory screen instead of looping
		show_victory()
	else:
		# 🏆 Check speed runner achievement
		if current_level_time < 30:
			unlock_achievement("speed_runner")
		
		# 🏆 Check perfect level achievement (no deaths)
		if level_deaths == 0:
			update_achievement_progress("perfect_level", achievements["perfect_level"].get("progress", 0) + 1)
		
		# Show level complete popup, then load next level
		await get_tree().create_timer(2.0).timeout
		setup_level(current_level)
		# Check if next level is boss level
		if levels[current_level].get("is_boss", false):
			show_boss_warning()

func show_level_complete_popup():
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	# Create popup container
	var popup = Node2D.new()
	popup.name = "LevelComplete"
	popup.position = Vector2(640, 360)
	ui.add_child(popup)
	
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.size = Vector2(400, 200)
	bg.position = Vector2(-200, -100)
	popup.add_child(bg)
	
	# Title
	var title = Label.new()
	title.text = "LEVEL COMPLETE!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.4, 1, 0.4))
	title.position = Vector2(-100, -70)
	popup.add_child(title)
	
	# Statistics
	var stats = Label.new()
	var time_str = "%02d:%02d" % [int(current_level_time) / 60, int(current_level_time) % 60]
	stats.text = "Time: %s\nDeaths: %d\nScore: +%d" % [time_str, level_deaths, score]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 18)
	stats.add_theme_color_override("font_color", Color(0.8, 0.9, 1))
	stats.position = Vector2(-60, -20)
	popup.add_child(stats)
	
	# Time bonus
	var bonus = 0
	if current_level_time < 20:
		bonus = 100
	elif current_level_time < 30:
		bonus = 50
	
	if bonus > 0:
		var bonus_label = Label.new()
		bonus_label.text = "Time Bonus: +%d!" % bonus
		bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bonus_label.add_theme_font_size_override("font_size", 16)
		bonus_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		bonus_label.position = Vector2(-80, 30)
		popup.add_child(bonus_label)
		score += bonus
	
	# Animate in
	popup.scale = Vector2(0.5, 0.5)
	popup.modulate.a = 0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "scale", Vector2(1.1, 1.1), 0.3)
	tween.tween_property(popup, "modulate:a", 1.0, 0.2)
	tween.tween_callback(func():
		var t2 = create_tween()
		t2.tween_property(popup, "scale", Vector2(1, 1), 0.15)
	)
	
	# Animate out after delay
	var out_tween = create_tween()
	out_tween.tween_interval(1.8)
	out_tween.tween_property(popup, "modulate:a", 0.0, 0.3)
	out_tween.tween_property(popup, "position:y", popup.position.y - 30, 0.3)
	out_tween.tween_callback(popup.queue_free)

func show_boss_warning():
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		# 屏幕红光闪烁
		var flash = ColorRect.new()
		flash.name = "BossFlash"
		flash.size = Vector2(2000, 2000)
		flash.position = Vector2(-500, -500)
		flash.color = Color(1, 0, 0, 0)
		flash.z_index = 100
		ui.add_child(flash)
		
		var warning = Label.new()
		warning.name = "BossWarning"
		warning.text = "⚠️ BOSS BATTLE! ⚠️"
		warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		warning.position = Vector2(640, 200)
		warning.add_theme_font_size_override("font_size", 56)
		warning.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		warning.z_index = 101
		ui.add_child(warning)
		
		# 闪烁动画
		var tween = create_tween()
		# 屏幕闪烁
		tween.set_loops(4)
		tween.tween_property(flash, "color:a", 0.3, 0.15)
		tween.tween_property(flash, "color:a", 0.0, 0.15)
		tween.tween_callback(flash.queue_free)
		
		# 文字动画 - 缩放 + 闪烁
		warning.scale = Vector2(1.5, 1.5)
		warning.modulate.a = 0
		var text_tween = create_tween()
		text_tween.tween_property(warning, "modulate:a", 1.0, 0.2)
		text_tween.set_trans(Tween.TRANS_ELASTIC)
		text_tween.set_ease(Tween.EASE_OUT)
		text_tween.tween_property(warning, "scale", Vector2(1, 1), 0.5)
		# 闪烁效果
		text_tween.set_loops(3)
		text_tween.tween_property(warning, "modulate:a", 0.5, 0.2)
		text_tween.tween_property(warning, "modulate:a", 1.0, 0.2)
		# 退场
		text_tween.tween_interval(1.0)
		text_tween.tween_property(warning, "modulate:a", 0.0, 0.5)
		text_tween.tween_property(warning, "position:y", warning.position.y - 30, 0.5)
		text_tween.tween_callback(warning.queue_free)

func show_game_over():
	# CRITICAL: Reset time scale to prevent permanent slow-mo
	Engine.time_scale = 1.0
	
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		if ui.has_node("GameOverOverlay"): ui.get_node("GameOverOverlay").queue_free()
		if ui.has_node("GameOverText"): ui.get_node("GameOverText").queue_free()
		
		var overlay = ColorRect.new()
		overlay.name = "GameOverOverlay"
		overlay.size = Vector2(2000, 2000)
		overlay.position = Vector2(-500, -500)
		overlay.color = Color(0, 0, 0, 0.8)
		ui.add_child(overlay)
		
		var game_over = Label.new()
		game_over.name = "GameOverText"
		
		if endless_mode:
			game_over.text = "GAME OVER\n\nEndless Score: " + str(endless_score) + "\nDifficulty: " + str(round(endless_difficulty * 10) / 10) + "x\n\nPress SPACE to Restart"
		else:
			game_over.text = "GAME OVER\n\nScore: " + str(score) + "\n\nPress SPACE to Restart"
		
		game_over.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		game_over.position = Vector2(300, 280)
		game_over.add_theme_font_size_override("font_size", 42)
		game_over.add_theme_color_override("font_color", Color.RED)
		ui.add_child(game_over)

func show_victory():
	# CRITICAL: Reset time scale to prevent permanent slow-mo
	Engine.time_scale = 1.0
	
	# Save high score
	save_high_score()
	
	# 🏆 Unlock boss slayer achievement
	unlock_achievement("boss_slayer")
	if not boss_damage_taken:
		unlock_achievement("no_damage_boss")
	
	# Add total time to score bonus
	var time_bonus = max(0, 300 - int(total_play_time))  # Time bonus
	score += time_bonus
	
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		if ui.has_node("VictoryOverlay"): ui.get_node("VictoryOverlay").queue_free()
		if ui.has_node("VictoryText"): ui.get_node("VictoryText").queue_free()
		if ui.has_node("GameOverOverlay"): ui.get_node("GameOverOverlay").queue_free()
		if ui.has_node("GameOverText"): ui.get_node("GameOverText").queue_free()
		
		var overlay = ColorRect.new()
		overlay.name = "VictoryOverlay"
		overlay.size = Vector2(2000, 2000)
		overlay.position = Vector2(-500, -500)
		overlay.color = Color(0.05, 0.1, 0.15, 0.9)
		ui.add_child(overlay)
		
		# Format total time
		var mins = int(total_play_time) / 60
		var secs = int(total_play_time) % 60
		
		var victory = Label.new()
		victory.name = "VictoryText"
		victory.text = "🏆 VICTORY! 🏆\n\n" + "You completed all levels!\n\n" + "Final Score: " + str(score) + "\n" + "Stars: " + str(stars_collected) + "\n" + "Time: %02d:%02d" % [mins, secs] + "\n" + "High Score: " + str(high_score) + "\n\n" + "Press SPACE to Play Again"
		victory.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		victory.position = Vector2(200, 180)
		victory.add_theme_font_size_override("font_size", 32)
		victory.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		ui.add_child(victory)
		
		# Add celebration particles
		for i in range(30):
			await get_tree().create_timer(0.1).timeout
			var particle = ColorRect.new()
			particle.size = Vector2(6, 6)
			particle.color = Color(1, randf(), randf(), 1)
			particle.position = Vector2(randf() * 800, randf() * 600)
			particle.z_index = 100
			ui.add_child(particle)
			
			var tween = create_tween()
			tween.tween_property(particle, "position", particle.position + Vector2(randf_range(-100, 100), randf_range(-150, 50)), 2.0)
			tween.parallel().tween_property(particle, "modulate:a", 0.0, 2.0)
			tween.tween_callback(particle.queue_free)
