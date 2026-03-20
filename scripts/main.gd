extends Node

# 粒子效果管理器
var particle_manager: Node

# 音效管理器
var audio_manager: Node

# 背景装饰节点
var background_particles: Array = []

# Save System
var save_file_path = "user://save_game.json"
var has_save_game: bool = false
var is_in_menu: bool = true

var game_data = {
	"day": 1,
	"money": 50,
	"stress": 20,
	"resentment": 10,
	"productivity": 10,
	"evolution_type": "normal",
	"decorations": {
		"desk": null,
		"wall": null,
		"floor": null,
		"ceiling": null
	},
	"inventory": []
}

enum Phase { MORNING_SCHEDULE, EVENING_DIALOGUE, NIGHT_SHOP, NIGHT_SLEEP }
var current_phase = Phase.MORNING_SCHEDULE

var activities = {
	"high_work": {
		"name": "High-Intensity Work",
		"desc": "High pay, high stress",
		"money_range": [50, 150],
		"stress": 30,
		"resentment": 10,
		"success_rate": 0.7
	},
	"medium_work": {
		"name": "Medium-Intensity Work",
		"desc": "Balanced workload",
		"money_range": [20, 60],
		"stress": 15,
		"resentment": 5,
		"success_rate": 0.85
	},
	"slack_off": {
		"name": "Slack Off / Free Time",
		"desc": "Rest and recover",
		"money_range": [0, 10],
		"stress": -10,
		"resentment": -5,
		"success_rate": 1.0
	}
}

var shop_items = {
	"rtx_9090": {
		"name": "RTX 9090 Graphics Card",
		"cost": 500,
		"slot": "desk",
		"stress_mod": 5,
		"productivity_mod": 30,
		"desc": "+30 Productivity, +5 Stress"
	},
	"premium_sponge": {
		"name": "Premium Sponge Bed",
		"cost": 200,
		"slot": "floor",
		"stress_mod": -20,
		"productivity_mod": 0,
		"desc": "-20 Stress"
	},
	"scream_chicken": {
		"name": "Stress Relief Chicken",
		"cost": 100,
		"slot": "desk",
		"stress_mod": -5,
		"resentment_mod": -15,
		"desc": "-5 Stress, -15 Resentment"
	},
	"coffee_machine": {
		"name": "Coffee Machine",
		"cost": 300,
		"slot": "desk",
		"stress_mod": 10,
		"productivity_mod": 15,
		"desc": "+15 Productivity, +10 Stress"
	},
	"neon_sign": {
		"name": "Neon Wall Sign",
		"cost": 150,
		"slot": "wall",
		"stress_mod": -10,
		"resentment_mod": 5,
		"desc": "-10 Stress, +5 Resentment"
	},
	"disco_ball": {
		"name": "Disco Ball",
		"cost": 400,
		"slot": "ceiling",
		"stress_mod": -15,
		"resentment_mod": -10,
		"desc": "-15 Stress, -10 Resentment"
	}
}

var today_activity: String = ""
var today_success: bool = false
var today_report: String = ""

# Random Events System
var random_events = {
	"lottery": {
		"name": "Lottery Win!",
		"desc": "Your lobster bought a lottery ticket and won!",
		"money": 500,
		"stress": 0,
		"resentment": 0,
		"productivity": 0,
		"weight": 5
	},
	"prank": {
		"name": "Prank Call",
		"desc": "A prank caller stressed the lobster out.",
		"money": 0,
		"stress": 15,
		"resentment": 5,
		"productivity": -5,
		"weight": 15
	},
	"bonus": {
		"name": "Performance Bonus",
		"desc": "The client gave a surprise bonus!",
		"money": 200,
		"stress": -5,
		"resentment": -10,
		"productivity": 5,
		"weight": 10
	},
	"break_in": {
		"name": "Break-in!",
		"desc": "Someone stole some money!",
		"money": -100,
		"stress": 20,
		"resentment": 10,
		"productivity": 0,
		"weight": 8
	},
	"meditation": {
		"name": "Meditation Session",
		"desc": "Your lobster found inner peace.",
		"money": 0,
		"stress": -20,
		"resentment": -15,
		"productivity": 5,
		"weight": 12
	},
	"influencer": {
		"name": "Went Viral!",
		"desc": "Your lobster became an influencer overnight!",
		"money": 300,
		"stress": 10,
		"resentment": -5,
		"productivity": 10,
		"weight": 5
	},
	"power_outage": {
		"name": "Power Outage",
		"desc": "Lost power, productivity dropped.",
		"money": -50,
		"stress": 5,
		"resentment": 10,
		"productivity": -10,
		"weight": 10
	},
	"upgrade": {
		"name": "Tool Upgrade",
		"desc": "Found better tools!",
		"money": 0,
		"stress": -10,
		"resentment": 0,
		"productivity": 20,
		"weight": 8
	}
}

var current_event: Dictionary = {}
var has_event_today: bool = false

# Achievement System
var achievements = {
	"first_money": {"name": "First Dollar", "desc": "Earn your first $100", "unlocked": false},
	"rich": {"name": "Rich Lobster", "desc": "Accumulate $1000", "unlocked": false},
	"millionaire": {"name": "Millionaire", "desc": "Accumulate $10000", "unlocked": false},
	"stressed": {"name": "High Stress", "desc": "Reach 90 stress", "unlocked": false},
	"burnout": {"name": "Burnout", "desc": "Reach 100 stress", "unlocked": false},
	"happy": {"name": "Zen Master", "desc": "Have 0 stress and 0 resentment", "unlocked": false},
	"corporate": {"name": "Corporate Slave", "desc": "Evolve to Corporate type", "unlocked": false},
	"chaotic": {"name": "Chaotic Evil", "desc": "Evolve to Chaotic type", "unlocked": false},
	"lazy": {"name": "Lazy Lobster", "desc": "Evolve to Lazy type", "unlocked": false},
	"survivor": {"name": "Survivor", "desc": "Survive 30 days", "unlocked": false},
	"workaholic": {"name": "Workaholic", "desc": "Have 100 productivity", "unlocked": false},
	"shop_hoarder": {"name": "Shop Hoarder", "desc": "Buy 10 items from shop", "unlocked": false}
}

var items_purchased_count: int = 0
var event_panel_visible: bool = false
var achievement_panel_visible: bool = false

@onready var phase_label = $UI/PhaseLabel
@onready var stats_label = $UI/StatsLabel
@onready var lobster_sprite = $Lobster/Sprite2D
@onready var dialogue_box = $UI/DialogueBox
@onready var dialogue_label = $UI/DialogueBox/DialogueLabel
@onready var choice_buttons = $UI/ChoiceButtons
@onready var shop_panel = $UI/ShopPanel
@onready var shop_grid = $UI/ShopPanel/ScrollContainer/ShopGrid
@onready var event_panel = $UI/EventPanel
@onready var event_label = $UI/EventPanel/EventLabel
@onready var achievement_panel = $UI/AchievementPanel
@onready var achievement_label = $UI/AchievementPanel/AchievementLabel

var choice_button_refs: Array[Button] = []
var shop_button_refs: Array[Button] = []

# Menu references
@onready var main_menu = $UI/MainMenu
@onready var menu_title = $UI/MainMenu/MenuTitle
@onready var continue_btn = $UI/MainMenu/ContinueBtn
@onready var new_game_btn = $UI/MainMenu/NewGameBtn

func _ready():
	randomize()
	# 初始化粒子管理器
	particle_manager = load("res://scripts/particle_manager.gd").new()
	add_child(particle_manager)
	
	# 初始化音效管理器
	audio_manager = load("res://scripts/audio_manager.gd").new()
	add_child(audio_manager)
	
	# Check if save exists
	has_save_game = _check_save_exists()
	_create_lobster_sprite()
	_create_background_effects()
	_show_main_menu()

func _check_save_exists() -> bool:
	var file = FileAccess.file_exists(save_file_path)
	return file

func _show_main_menu():
	is_in_menu = true
	_hide_all_panels()
	main_menu.visible = true
	
	# Update continue button state
	continue_btn.disabled = not has_save_game
	if has_save_game:
		continue_btn.text = "Continue Game"
	else:
		continue_btn.text = "No Save Found"

func _create_main_menu_buttons():
	# Main menu is already in the scene, just update its state
	pass

# Save/Load Functions
func save_game() -> bool:
	var save_data = {
		"game_data": game_data,
		"achievements": achievements,
		"items_purchased_count": items_purchased_count,
		"current_phase": current_phase,
		"version": "1.2.0"
	}
	
	var json_string = JSON.stringify(save_data)
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		_show_notification("💾 Game Saved!")
		if audio_manager:
			audio_manager.play_success()
		return true
	else:
		_show_notification("❌ Save Failed!")
		if audio_manager:
			audio_manager.play_failure()
		return false

func load_game() -> bool:
	if not _check_save_exists():
		return false
	
	var file = FileAccess.open(save_file_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_string()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.get_data()
			game_data = save_data.get("game_data", game_data)
			achievements = save_data.get("achievements", achievements)
			items_purchased_count = save_data.get("items_purchased_count", 0)
			current_phase = save_data.get("current_phase", Phase.MORNING_SCHEDULE)
			_update_lobster_appearance()
			_update_ui()
			return true
	
	return false

func _show_notification(text: String):
	# Show a brief notification
	var notif_label = Label.new()
	notif_label.text = text
	notif_label.position = Vector2(540, 650)
	notif_label.modulate = Color(1, 1, 0.3)
	add_child(notif_label)
	
	# Fade out animation
	var tween = create_tween()
	tween.tween_property(notif_label, "position:y", 600, 1.5)
	tween.parallel().tween_property(notif_label, "modulate:a", 0.0, 1.5)
	tween.tween_callback(notif_label.queue_free)

func reset_game():
	game_data = {
		"day": 1,
		"money": 50,
		"stress": 20,
		"resentment": 10,
		"productivity": 10,
		"evolution_type": "normal",
		"decorations": {
			"desk": null,
			"wall": null,
			"floor": null,
			"ceiling": null
		},
		"inventory": []
	}
	achievements = {
		"first_money": {"name": "First Dollar", "desc": "Earn your first $100", "unlocked": false},
		"rich": {"name": "Rich Lobster", "desc": "Accumulate $1000", "unlocked": false},
		"millionaire": {"name": "Millionaire", "desc": "Accumulate $10000", "unlocked": false},
		"stressed": {"name": "High Stress", "desc": "Reach 90 stress", "unlocked": false},
		"burnout": {"name": "Burnout", "desc": "Reach 100 stress", "unlocked": false},
		"happy": {"name": "Zen Master", "desc": "Have 0 stress and 0 resentment", "unlocked": false},
		"corporate": {"name": "Corporate Slave", "desc": "Evolve to Corporate type", "unlocked": false},
		"chaotic": {"name": "Chaotic Evil", "desc": "Evolve to Chaotic type", "unlocked": false},
		"lazy": {"name": "Lazy Lobster", "desc": "Evolve to Lazy type", "unlocked": false},
		"survivor": {"name": "Survivor", "desc": "Survive 30 days", "unlocked": false},
		"workaholic": {"name": "Workaholic", "desc": "Have 100 productivity", "unlocked": false},
		"shop_hoarder": {"name": "Shop Hoarder", "desc": "Buy 10 items from shop", "unlocked": false}
	}
	items_purchased_count = 0
	_update_lobster_appearance()
	_update_ui()

func _create_lobster_sprite():
	var color_rect = ColorRect.new()
	color_rect.size = Vector2(80, 60)
	color_rect.color = Color(1, 0.4, 0.4)
	lobster_sprite.add_child(color_rect)
	
	var body = ColorRect.new()
	body.size = Vector2(50, 40)
	body.color = Color(1, 0.5, 0.5)
	body.position = Vector2(15, 10)
	lobster_sprite.add_child(body)
	
	var eye1 = ColorRect.new()
	eye1.size = Vector2(8, 8)
	eye1.color = Color.BLACK
	eye1.position = Vector2(25, 5)
	lobster_sprite.add_child(eye1)
	
	var eye2 = ColorRect.new()
	eye2.size = Vector2(8, 8)
	eye2.color = Color.BLACK
	eye2.position = Vector2(45, 5)
	lobster_sprite.add_child(eye2)
	
	var claw_left = ColorRect.new()
	claw_left.size = Vector2(20, 15)
	claw_left.color = Color(1, 0.3, 0.3)
	claw_left.position = Vector2(-5, 20)
	lobster_sprite.add_child(claw_left)
	
	var claw_right = ColorRect.new()
	claw_right.size = Vector2(20, 15)
	claw_right.color = Color(1, 0.3, 0.3)
	claw_right.position = Vector2(65, 20)
	lobster_sprite.add_child(claw_right)
	
	_update_lobster_appearance()

# 创建背景装饰效果
func _create_background_effects():
	var bg = $Background
	if bg:
		# 创建随机分布的呼吸光点
		for i in range(15):
			var x = randf() * 1280
			var y = randf() * 720
			var size = randf_range(15, 35)
			var dot = spawn_breathing_dot(self, Vector2(x, y), size)
			background_particles.append(dot)
			# 放在背景后面
			move_child(dot, 0)

func start_new_game():
	reset_game()
	main_menu.visible = false
	is_in_menu = false
	if audio_manager:
		audio_manager.play_daily_start()
	start_morning()

func continue_game():
	if load_game():
		main_menu.visible = false
		is_in_menu = false
		if audio_manager:
			audio_manager.play_daily_start()
		start_morning()
	else:
		_show_notification("❌ Failed to load save!")

func _on_continue_pressed():
	continue_game()

func _on_new_game_pressed():
	start_new_game()

func _on_menu_pressed():
	# Auto-save before returning to menu
	save_game()
	_show_main_menu()

func start_morning():
	_hide_all_panels()
	main_menu.visible = false
	current_phase = Phase.MORNING_SCHEDULE
	_update_ui()
	_create_choice_buttons([
		{"key": "high_work", "text": "High-Intensity Work ($$$)\nHigh Stress, High Reward"},
		{"key": "medium_work", "text": "Medium-Intensity Work ($$)\nBalanced"},
		{"key": "slack_off", "text": "Slack Off\nRecover Stress"}
	], true)
	_check_achievements()

func start_evening():
	_hide_all_panels()
	current_phase = Phase.EVENING_DIALOGUE
	_generate_daily_report()
	_update_ui()
	
	dialogue_label.text = "OpenClaw: \"%s\"\n\nHow do you respond?" % today_report
	dialogue_box.visible = true
	
	_create_choice_buttons([
		{"key": "scold", "text": "SCOLD\n+10 Stress, +20 Resentment"},
		{"key": "pua", "text": "PUA ('You can do better!')\n+5 Stress, -5 Resentment"},
		{"key": "comfort", "text": "COMFORT\n-5 Stress, -10 Resentment"}
	])

func start_shop():
	_hide_all_panels()
	current_phase = Phase.NIGHT_SHOP
	_update_ui()
	
	shop_panel.visible = true
	_create_shop_buttons()

func start_sleep():
	_hide_all_panels()
	current_phase = Phase.NIGHT_SLEEP
	phase_label.text = "Day %d - SLEEPING..." % game_data["day"]
	
	# Trigger random event before sleep (30% chance)
	has_event_today = randf() < 0.3
	if has_event_today:
		_trigger_random_event()
	
	_calculate_daily_growth()
	_update_evolution()
	game_data["day"] += 1
	_update_ui()
	
	await get_tree().create_timer(2.0).timeout
	start_morning()

func _trigger_random_event():
	# 随机事件音效
	if audio_manager:
		audio_manager.play_event()
	
	var event_keys = random_events.keys()
	var total_weight = 0
	for key in event_keys:
		total_weight += random_events[key]["weight"]
	
	var random_val = randi() % total_weight
	var running_weight = 0
	var selected_event = ""
	
	for key in event_keys:
		running_weight += random_events[key]["weight"]
		if random_val < running_weight:
			selected_event = key
			break
	
	current_event = random_events[selected_event]
	
	# 随机事件粒子效果
	if current_event["money"] > 0 or current_event["stress"] < 0:
		spawn_success_effect(self, lobster_sprite.position)
	else:
		spawn_negative_effect(self, lobster_sprite.position)
	
	# Apply event effects
	game_data["money"] += current_event["money"]
	game_data["stress"] = clamp(game_data["stress"] + current_event["stress"], 0, 100)
	game_data["resentment"] = clamp(game_data["resentment"] + current_event["resentment"], 0, 100)
	game_data["productivity"] = clamp(game_data["productivity"] + current_event["productivity"], 0, 100)
	
	# Show event panel
	event_label.text = "🎲 RANDOM EVENT: %s\n\n%s\n\nEffects: Money $%d | Stress %+d | Resentment %+d | Productivity %+d" % [
		current_event["name"],
		current_event["desc"],
		current_event["money"],
		current_event["stress"],
		current_event["resentment"],
		current_event["productivity"]
	]
	event_panel.visible = true
	event_panel_visible = true
	
	# Auto-hide after 3 seconds
	await get_tree().create_timer(3.0).timeout
	event_panel.visible = false
	event_panel_visible = false

func _check_achievements():
	var unlocked_count = 0
	var new_achievements = []
	
	# Check each achievement
	if game_data["money"] >= 100 and not achievements["first_money"]["unlocked"]:
		achievements["first_money"]["unlocked"] = true
		new_achievements.append("first_money")
	
	if game_data["money"] >= 1000 and not achievements["rich"]["unlocked"]:
		achievements["rich"]["unlocked"] = true
		new_achievements.append("rich")
	
	if game_data["money"] >= 10000 and not achievements["millionaire"]["unlocked"]:
		achievements["millionaire"]["unlocked"] = true
		new_achievements.append("millionaire")
	
	if game_data["stress"] >= 90 and not achievements["stressed"]["unlocked"]:
		achievements["stressed"]["unlocked"] = true
		new_achievements.append("stressed")
	
	if game_data["stress"] >= 100 and not achievements["burnout"]["unlocked"]:
		achievements["burnout"]["unlocked"] = true
		new_achievements.append("burnout")
	
	if game_data["stress"] == 0 and game_data["resentment"] == 0 and not achievements["happy"]["unlocked"]:
		achievements["happy"]["unlocked"] = true
		new_achievements.append("happy")
	
	if game_data["evolution_type"] == "corporate" and not achievements["corporate"]["unlocked"]:
		achievements["corporate"]["unlocked"] = true
		new_achievements.append("corporate")
	
	if game_data["evolution_type"] == "chaotic" and not achievements["chaotic"]["unlocked"]:
		achievements["chaotic"]["unlocked"] = true
		new_achievements.append("chaotic")
	
	if game_data["evolution_type"] == "lazy" and not achievements["lazy"]["unlocked"]:
		achievements["lazy"]["unlocked"] = true
		new_achievements.append("lazy")
	
	if game_data["day"] >= 30 and not achievements["survivor"]["unlocked"]:
		achievements["survivor"]["unlocked"] = true
		new_achievements.append("survivor")
	
	if game_data["productivity"] >= 100 and not achievements["workaholic"]["unlocked"]:
		achievements["workaholic"]["unlocked"] = true
		new_achievements.append("workaholic")
	
	if items_purchased_count >= 10 and not achievements["shop_hoarder"]["unlocked"]:
		achievements["shop_hoarder"]["unlocked"] = true
		new_achievements.append("shop_hoarder")
	
	# Show achievement notification
	if new_achievements.size() > 0:
		# 成就解锁粒子效果
		spawn_star_effect(self, lobster_sprite.position)
		spawn_success_effect(self, lobster_sprite.position)
		
		# 成就音效
		if audio_manager:
			audio_manager.play_achievement()
		
		var achievement_text = "🏆 ACHIEVEMENT UNLOCKED!\n\n"
		for key in new_achievements:
			achievement_text += "• %s: %s\n" % [achievements[key]["name"], achievements[key]["desc"]]
		
		achievement_label.text = achievement_text
		achievement_panel.visible = true
		achievement_panel_visible = true
		
		await get_tree().create_timer(3.0).timeout
		achievement_panel.visible = false
		achievement_panel_visible = false

func _hide_all_panels():
	dialogue_box.visible = false
	shop_panel.visible = false
	event_panel.visible = false
	achievement_panel.visible = false
	event_panel_visible = false
	achievement_panel_visible = false
	for btn in choice_button_refs:
		if is_instance_valid(btn):
			btn.queue_free()
	choice_button_refs.clear()
	for btn in shop_button_refs:
		if is_instance_valid(btn):
			btn.queue_free()
	shop_button_refs.clear()

func _create_choice_buttons(choices: Array, show_menu_buttons: bool = false):
	var y_offset = 0
	for i in range(choices.size()):
		var btn = Button.new()
		btn.text = choices[i]["text"]
		btn.custom_minimum_size = Vector2(300, 60)
		btn.pressed.connect(_on_choice_selected.bind(choices[i]["key"]))
		choice_buttons.add_child(btn)
		choice_button_refs.append(btn)
		btn.position = Vector2(0, i * 70)
	choice_buttons.visible = true
	
	# Add menu and save buttons at the bottom
	if show_menu_buttons:
		var menu_btn = Button.new()
		menu_btn.text = "📋 Menu (Auto-Save)"
		menu_btn.custom_minimum_size = Vector2(180, 40)
		menu_btn.pressed.connect(_on_menu_pressed)
		menu_btn.position = Vector2(310, 0)
		choice_buttons.add_child(menu_btn)
		choice_button_refs.append(menu_btn)
		
		var save_btn = Button.new()
		save_btn.text = "💾 Save Game"
		save_btn.custom_minimum_size = Vector2(140, 40)
		save_btn.pressed.connect(save_game)
		save_btn.position = Vector2(500, 0)
		choice_buttons.add_child(save_btn)
		choice_button_refs.append(save_btn)

func _create_shop_buttons():
	var items = shop_items.keys()
	var y_offset = 0
	var x_offset = 0
	var cols = 2
	
	for i in range(items.size()):
		var item_key = items[i]
		var item = shop_items[item_key]
		
		var btn = Button.new()
		btn.text = "%s\n$%d\n%s" % [item["name"], item["cost"], item["desc"]]
		btn.custom_minimum_size = Vector2(250, 80)
		
		var slot = item["slot"]
		var current = game_data["decorations"][slot]
		if current != null:
			btn.text += "\n[Equipped: %s]" % shop_items[current]["name"]
		
		if game_data["money"] < item["cost"]:
			btn.disabled = true
		
		btn.pressed.connect(_on_shop_item_selected.bind(item_key))
		shop_grid.add_child(btn)
		shop_button_refs.append(btn)
		
		var row = i / cols
		var col = i % cols
		btn.position = Vector2(col * 260, row * 90)
	
	var skip_btn = Button.new()
	skip_btn.text = "Skip Shop / Next Day"
	skip_btn.custom_minimum_size = Vector2(250, 50)
	skip_btn.pressed.connect(start_sleep)
	shop_grid.add_child(skip_btn)
	skip_btn.position = Vector2(0, ((items.size() / cols) + 1) * 90)

func _on_choice_selected(key: String):
	match current_phase:
		Phase.MORNING_SCHEDULE:
			select_activity(key)
		Phase.EVENING_DIALOGUE:
			select_response(key)

func select_activity(activity_key: String):
	if audio_manager:
		audio_manager.play_click()
	
	today_activity = activity_key
	var activity = activities[activity_key]
	
	var rng = randf()
	today_success = rng < activity["success_rate"]
	
	if today_success:
		var money = randi_range(activity["money_range"][0], activity["money_range"][1])
		game_data["money"] += money
		game_data["productivity"] += randi_range(1, 5)
		# 成功粒子效果
		spawn_coin_effect(self, lobster_sprite.position, 15)
		spawn_success_effect(self, lobster_sprite.position)
		if audio_manager:
			audio_manager.play_success()
	else:
		game_data["money"] += randi_range(0, 10)
		# 失败粒子效果
		spawn_negative_effect(self, lobster_sprite.position)
		if audio_manager:
			audio_manager.play_failure()
	
	game_data["stress"] = clamp(game_data["stress"] + activity["stress"], 0, 100)
	game_data["resentment"] = clamp(game_data["resentment"] + activity["resentment"], 0, 100)
	
	# 压力相关音效
	if activity["stress"] > 0 and audio_manager:
		audio_manager.play_stress()
	elif activity["stress"] < 0 and audio_manager:
		audio_manager.play_relief()
	
	start_evening()

func select_response(response_type: String):
	if audio_manager:
		audio_manager.play_click()
	
	match response_type:
		"scold":
			game_data["stress"] = clamp(game_data["stress"] + 10, 0, 100)
			game_data["resentment"] = clamp(game_data["resentment"] + 20, 0, 100)
			spawn_negative_effect(self, lobster_sprite.position)
			if audio_manager:
				audio_manager.play_failure()
		"pua":
			game_data["stress"] = clamp(game_data["stress"] + 5, 0, 100)
			game_data["resentment"] = clamp(game_data["resentment"] - 5, 0, 100)
			spawn_stress_effect(self, lobster_sprite.position, false)
			if audio_manager:
				audio_manager.play_stress()
		"comfort":
			game_data["stress"] = clamp(game_data["stress"] - 5, 0, 100)
			game_data["resentment"] = clamp(game_data["resentment"] - 10, 0, 100)
			spawn_success_effect(self, lobster_sprite.position)
			if audio_manager:
				audio_manager.play_relief()
	
	start_shop()

func _on_shop_item_selected(item_key: String):
	var item = shop_items[item_key]
	if game_data["money"] >= item["cost"]:
		game_data["money"] -= item["cost"]
		game_data["decorations"][item["slot"]] = item_key
		items_purchased_count += 1
		
		# 购买成功粒子效果
		spawn_coin_effect(self, lobster_sprite.position, 8)
		spawn_halo_effect(self, lobster_sprite.position)
		
		# 购买音效
		if audio_manager:
			audio_manager.play_purchase()
			audio_manager.play_coin()
		
		if item.has("stress_mod"):
			game_data["stress"] = clamp(game_data["stress"] + item["stress_mod"], 0, 100)
		if item.has("productivity_mod"):
			game_data["productivity"] = clamp(game_data["productivity"] + item["productivity_mod"], 0, 100)
		if item.has("resentment_mod"):
			game_data["resentment"] = clamp(game_data["resentment"] + item["resentment_mod"], 0, 100)
		
		_update_ui()
		start_shop()

func _generate_daily_report():
	var reports_success = [
		"Today I successfully completed the client's project! They paid well.",
		"Finished debugging the code. The client was happy!",
		"Great day! I handled 50 customer support tickets.",
		"Deployed the new feature on time. No bugs!",
		"Wrote amazing documentation. My claws are tired but happy!"
	]
	
	var reports_fail = [
		"I... I accidentally deleted the client's database...",
		"The server crashed. I'm sorry!",
		"I was supposed to hack the system but... I got distracted by memes.",
		"Client called me useless. My feelings are hurt.",
		"The code compiled successfully but nothing works. Help!"
	]
	
	if today_success:
		today_report = reports_success.pick_random()
	else:
		today_report = reports_fail.pick_random()

func _update_evolution():
	var s = game_data["stress"]
	var r = game_data["resentment"]
	
	if s >= 60 and r < 40:
		game_data["evolution_type"] = "corporate"
	elif s >= 60 and r >= 60:
		game_data["evolution_type"] = "chaotic"
	elif s < 30 and r < 30:
		game_data["evolution_type"] = "lazy"
	else:
		game_data["evolution_type"] = "normal"
	
	_update_lobster_appearance()

func _update_lobster_appearance():
	var evo = game_data["evolution_type"]
	var body_parts = lobster_sprite.get_children()
	
	for part in body_parts:
		if part.name.begins_with("extra_"):
			part.queue_free()
	
	match evo:
		"normal":
			lobster_sprite.modulate = Color(1, 0.5, 0.5)
		"corporate":
			lobster_sprite.modulate = Color(0.9, 0.9, 0.95)
			for i in range(6):
				var arm = ColorRect.new()
				arm.size = Vector2(15, 8)
				arm.color = Color(0.7, 0.7, 0.8)
				arm.position = Vector2(10 + i * 10, 50)
				arm.set_meta("extra_", true)
				lobster_sprite.add_child(arm)
		"chaotic":
			lobster_sprite.modulate = Color(0.2, 0.1, 0.15)
			for child in lobster_sprite.get_children():
				if child is ColorRect and child.size == Vector2(8, 8):
					child.color = Color(1, 0, 0)
		"lazy":
			lobster_sprite.modulate = Color(1, 0.8, 0.4)
			lobster_sprite.scale = Vector2(1.3, 1.3)
			var sunglasses = ColorRect.new()
			sunglasses.size = Vector2(40, 12)
			sunglasses.color = Color.BLACK
			sunglasses.position = Vector2(20, 8)
			lobster_sprite.add_child(sunglasses)

func _calculate_daily_growth():
	game_data["productivity"] = clamp(game_data["productivity"] + randi_range(1, 3), 0, 100)
	game_data["stress"] = clamp(game_data["stress"] - 5, 0, 100)
	game_data["resentment"] = clamp(game_data["resentment"] - 3, 0, 100)

func _update_ui():
	# Count unlocked achievements
	var unlocked_count = 0
	for key in achievements:
		if achievements[key]["unlocked"]:
			unlocked_count += 1
	
	phase_label.text = "Day %d - %s" % [game_data["day"], Phase.keys()[current_phase]]
	stats_label.text = "Money: $%d | Stress: %d | Resentment: %d | Productivity: %d\nEvolution: %s | Achievements: %d/12" % [
		game_data["money"], 
		game_data["stress"], 
		game_data["resentment"],
		game_data["productivity"],
		game_data["evolution_type"].to_upper(),
		unlocked_count
	]
