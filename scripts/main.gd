extends Node

# 粒子效果管理器
var particle_manager: Node

# 音效管理器
var audio_manager: Node

# 粒子效果包装函数 - 将调用转发到 particle_manager
func spawn_coin_effect(world_node: Node, position: Vector2, count: int = 10):
	if particle_manager:
		particle_manager.spawn_coin_effect(world_node, position, count)

func spawn_success_effect(world_node: Node, position: Vector2):
	if particle_manager:
		particle_manager.spawn_success_effect(world_node, position)

func spawn_negative_effect(world_node: Node, position: Vector2):
	if particle_manager:
		particle_manager.spawn_negative_effect(world_node, position)

func spawn_stress_effect(world_node: Node, position: Vector2, is_positive: bool):
	if particle_manager:
		particle_manager.spawn_stress_effect(world_node, position, is_positive)

func spawn_star_effect(world_node: Node, center: Vector2):
	if particle_manager:
		particle_manager.spawn_star_effect(world_node, center)

func spawn_halo_effect(world_node: Node, position: Vector2, color: Color = Color(1, 0.84, 0)):
	if particle_manager:
		particle_manager.spawn_halo_effect(world_node, position, color)

func spawn_breathing_dot(world_node: Node, position: Vector2, size: float = 20.0):
	if particle_manager:
		particle_manager.spawn_breathing_dot(world_node, position, size)

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
	"inventory": [],
	# Game Statistics
	"stats": {
		"total_work_days": 0,
		"high_work_count": 0,
		"medium_work_count": 0,
		"slack_off_count": 0,
		"total_earned": 0,
		"total_spent": 0,
		"scold_count": 0,
		"pua_count": 0,
		"comfort_count": 0,
		"events_triggered": 0,
		"achievements_unlocked": 0,
		"best_day_income": 0
	}
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
	},
	# Combat activities
	"combat": {
		"name": "Combat Mode",
		"desc": "Fight enemies",
		"money_range": [50, 50],
		"stress": 5,
		"resentment": 0,
		"success_rate": 1.0
	},
	"boss": {
		"name": "Boss Battle",
		"desc": "Fight the Slime King",
		"money_range": [500, 500],
		"stress": 20,
		"resentment": 0,
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
	},
	# New Items
	"ergonomic_chair": {
		"name": "Ergonomic Chair",
		"cost": 350,
		"slot": "floor",
		"stress_mod": -15,
		"productivity_mod": 10,
		"desc": "-15 Stress, +10 Productivity"
	},
	"air_purifier": {
		"name": "Smart Air Purifier",
		"cost": 250,
		"slot": "desk",
		"stress_mod": -12,
		"productivity_mod": 5,
		"desc": "-12 Stress, +5 Productivity"
	},
	"standing_desk": {
		"name": "Standing Desk",
		"cost": 450,
		"slot": "desk",
		"stress_mod": -8,
		"productivity_mod": 20,
		"desc": "-8 Stress, +20 Productivity"
	},
	"ambient_lighting": {
		"name": "Ambient RGB Lighting",
		"cost": 180,
		"slot": "wall",
		"stress_mod": -18,
		"resentment_mod": -5,
		"desc": "-18 Stress, -5 Resentment"
	},
	"plant_collection": {
		"name": "Desktop Plant Collection",
		"cost": 120,
		"slot": "desk",
		"stress_mod": -14,
		"productivity_mod": 3,
		"desc": "-14 Stress, +3 Productivity"
	},
	# New Shop Items
	"gaming_monitor": {
		"name": "Ultrawide Gaming Monitor",
		"cost": 550,
		"slot": "desk",
		"stress_mod": -5,
		"productivity_mod": 25,
		"resentment_mod": -10,
		"desc": "-5 Stress, +25 Productivity, -10 Resentment"
	},
	"massage_chair": {
		"name": "Deluxe Massage Chair",
		"cost": 600,
		"slot": "floor",
		"stress_mod": -25,
		"productivity_mod": 5,
		"resentment_mod": -15,
		"desc": "-25 Stress, +5 Productivity, -15 Resentment"
	},
	# Combat Skills
	"dash_boots": {
		"name": "⚡ Dash Boots",
		"cost": 800,
		"slot": "skill",
		"skill": "dash",
		"desc": "Unlock Dash skill in combat!"
	},
	"hammer_training": {
		"name": "🔨 Hammer Training",
		"cost": 1000,
		"slot": "skill",
		"skill": "ground_slam",
		"desc": "Unlock Ground Slam skill!"
	},
	"magic_wand": {
		"name": "✨ Magic Wand",
		"cost": 1200,
		"slot": "skill",
		"skill": "magic_shot",
		"desc": "Unlock Magic Shot skill!"
	},
	"healingherb": {
		"name": "💚 Healing Herb",
		"cost": 600,
		"slot": "skill",
		"skill": "heal",
		"desc": "Unlock Heal skill in combat!"
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
	},
	# New Events
	"health_check": {
		"name": "Health Checkup",
		"desc": "Your lobster got a checkup! All healthy.",
		"money": -30,
		"stress": -15,
		"resentment": -10,
		"productivity": 5,
		"weight": 10
	},
	"teammate_visit": {
		"name": "Teammate Visit",
		"desc": "A coworker visited and brought snacks!",
		"money": 0,
		"stress": -12,
		"resentment": -8,
		"productivity": 8,
		"weight": 12
	},
	"system_hack": {
		"name": "System Hacked!",
		"desc": "Oh no! A hacker breached the system!",
		"money": -200,
		"stress": 25,
		"resentment": 15,
		"productivity": -5,
		"weight": 6
	},
	# New Events Added
	"boss_visit": {
		"name": "Boss Visit!",
		"desc": "The boss dropped by unexpectedly!",
		"money": 100,
		"stress": 15,
		"resentment": 10,
		"productivity": -5,
		"weight": 12
	},
	"cat_video": {
		"name": "Cat Video Break",
		"desc": "Watched some adorable cat videos. So relaxing!",
		"money": 0,
		"stress": -18,
		"resentment": -12,
		"productivity": 3,
		"weight": 15
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
	"shop_hoarder": {"name": "Shop Hoarder", "desc": "Buy 10 items from shop", "unlocked": false},
	# New Achievements
	"workhorse": {"name": "Workhorse", "desc": "Complete 50 high-intensity work sessions", "unlocked": false},
	"balanced_player": {"name": "Balanced Player", "desc": "Complete 30 medium-intensity work sessions", "unlocked": false},
	"zen_master": {"name": "True Zen Master", "desc": "Reach day 50 with 0 stress and 0 resentment", "unlocked": false},
	"lucky_lobster": {"name": "Lucky Lobster", "desc": "Experience 10 random events", "unlocked": false},
	# Clicker Game Achievements
	"first_click": {"name": "First Poke", "desc": "Click the lobster for the first time", "unlocked": false},
	"click_master": {"name": "Click Master", "desc": "Click the lobster 50 times", "unlocked": false},
	"combo_king": {"name": "Combo King", "desc": "Get a 10x combo click", "unlocked": false},
	"click_millionaire": {"name": "Click Millionaire", "desc": "Earn $5000 from clicking", "unlocked": false}
}

var items_purchased_count: int = 0
var event_panel_visible: bool = false
var achievement_panel_visible: bool = false

# Clicker Game System
var click_count: int = 0
var last_click_time: float = 0
var combo_multiplier: float = 1.0
var combo_timer: float = 0.0
var click_rewards_earned: int = 0

# ========== NEW: COMBAT SYSTEM ==========
var combat_mode: bool = false
var current_enemy: Node = null
var enemies: Array = []
var boss_active: bool = false
var boss_health: int = 100
var boss_max_health: int = 100
var player_health: int = 100
var player_max_health: int = 100
var combat_cooldown: float = 0.0
var attack_range: float = 100.0

# Combat enemies data
var combat_enemies = {
	"slime": {
		"name": "Green Slime",
		"health": 30,
		"damage": 10,
		"speed": 50,
		"reward": 20,
		"color": Color(0.2, 0.8, 0.2)
	},
	"bat": {
		"name": "Night Bat",
		"health": 20,
		"damage": 15,
		"speed": 100,
		"reward": 30,
		"color": Color(0.4, 0.2, 0.6)
	},
	"skeleton": {
		"name": "Skeleton Warrior",
		"health": 50,
		"damage": 20,
		"speed": 40,
		"reward": 50,
		"color": Color(0.9, 0.9, 0.85)
	}
}

# Boss data
var bosses = {
	"boss_slime_king": {
		"name": "SLIME KING",
		"health": 200,
		"damage": 25,
		"speed": 30,
		"reward": 500,
		"color": Color(0.1, 0.6, 0.1),
		"description": "The giant slime ruler!"
	}
}

var unlocked_skills = {
	"double_jump": false,
	"dash": false,
	"ground_slam": false,
	"magic_shot": false,
	"heal": false
}

var skill_cooldowns = {
	"dash": 0.0,
	"ground_slam": 0.0,
	"magic_shot": 0.0,
	"heal": 0.0
}

# Combat UI
@onready var combat_hud = null
@onready var enemy_sprites = []

@onready var phase_label = $UI/PhaseLabel
@onready var stats_label = $UI/StatsLabel
@onready var lobster_sprite = $Lobster/Sprite2D
@onready var lobster_container = $Lobster
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
	_setup_lobster_interaction()
	_create_combat_ui()
	_show_main_menu()

func _setup_lobster_interaction():
	# 为小龙虾容器添加点击检测
	lobster_container.set_meta("clickable", true)
	# 使用输入事件检测点击
	pass

func _input(event):
	if is_in_menu:
		return
	
	# 检测鼠标点击
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_viewport().get_mouse_position()
		# 检查是否点击在小龙虾附近
		var lobster_pos = lobster_container.position
		var distance = mouse_pos.distance_to(lobster_pos)
		if distance < 100:  # 点击范围
			_on_lobster_clicked()

func _process(delta):
	# 更新连击计时器
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_multiplier = 1.0
			click_count = 0

func _on_lobster_clicked():
	if current_phase != Phase.MORNING_SCHEDULE:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# 检查连击（2秒内点击）
	if current_time - last_click_time < 2.0:
		click_count += 1
		combo_multiplier = 1.0 + (click_count * 0.1)  # 每次点击增加10%倍率
		combo_timer = 2.0
	else:
		click_count = 1
		combo_multiplier = 1.0
	
	last_click_time = current_time
	
	# 计算奖励
	var base_reward = randi_range(5, 15)
	var total_reward = int(base_reward * combo_multiplier)
	
	game_data["money"] += total_reward
	game_data["stats"]["total_earned"] += total_reward
	click_rewards_earned += total_reward
	
	# 记录点击次数
	if not game_data["stats"].has("total_clicks"):
		game_data["stats"]["total_clicks"] = 0
	game_data["stats"]["total_clicks"] += 1
	
	# 检查点击成就
	_check_achievements()
	
	# 视觉反馈
	spawn_coin_effect(self, lobster_container.position, 5)
	spawn_success_effect(self, lobster_container.position)
	
	# 显示连击文字
	_show_click_feedback(total_reward, click_count)
	
	# 播放音效
	if audio_manager:
		audio_manager.play_coin()
		if click_count >= 3:
			audio_manager.play_success()
	
	# 更新UI
	_update_ui()

# ========== NEW COMBAT SYSTEM FUNCTIONS ==========
func _create_combat_hud():
	var combat_ui = CanvasLayer.new()
	combat_ui.name = "CombatHUD"
	$UI.add_child(combat_ui)
	
	# Player HP bar
	var player_hp = ProgressBar.new()
	player_hp.name = "PlayerHP"
	player_hp.custom_minimum_size = Vector2(200, 20)
	player_hp.position = Vector2(20, 80)
	player_hp.max_value = player_max_health
	player_hp.value = player_health
	player_hp.show_percentage = false
	combat_ui.add_child(player_hp)
	
	# Player HP label
	var hp_label = Label.new()
	hp_label.name = "HPLabel"
	hp_label.position = Vector2(20, 60)
	hp_label.text = "🦞 HP: %d/%d" % [player_health, player_max_health]
	combat_ui.add_child(hp_label)
	
	# Boss health bar (hidden by default)
	var boss_hp = ProgressBar.new()
	boss_hp.name = "BossHP"
	boss_hp.custom_minimum_size = Vector2(400, 30)
	boss_hp.position = Vector2(440, 60)
	boss_hp.max_value = boss_max_health
	boss_hp.value = boss_health
	boss_hp.visible = false
	combat_ui.add_child(boss_hp)
	
	# Boss name label
	var boss_label = Label.new()
	boss_label.name = "BossLabel"
	boss_label.position = Vector2(440, 35)
	boss_label.text = ""
	boss_label.visible = false
	combat_ui.add_child(boss_label)
	
	# Attack button
	var attack_btn = Button.new()
	attack_btn.name = "AttackBtn"
	attack_btn.text = "⚔️ ATTACK"
	attack_btn.custom_minimum_size = Vector2(150, 50)
	attack_btn.position = Vector2(565, 600)
	attack_btn.pressed.connect(_on_attack_pressed)
	combat_ui.add_child(attack_btn)
	
	# Skill buttons
	var skills = ["dash", "ground_slam", "magic_shot", "heal"]
	var skill_x = 20
	for skill in skills:
		var btn = Button.new()
		btn.name = "Skill_" + skill
		btn.text = _get_skill_icon(skill) + " " + skill.to_upper()
		btn.custom_minimum_size = Vector2(120, 40)
		btn.position = Vector2(skill_x, 600)
		btn.pressed.connect(_on_skill_pressed.bind(skill))
		if not unlocked_skills.get(skill, false):
			btn.disabled = true
			btn.text = "🔒 " + skill.to_upper()
		combat_ui.add_child(btn)
		skill_x += 130
	
	# Combat menu button
	var combat_menu_btn = Button.new()
	combat_menu_btn.name = "CombatMenuBtn"
	combat_menu_btn.text = "📋 Menu"
	combat_menu_btn.custom_minimum_size = Vector2(100, 40)
	combat_menu_btn.position = Vector2(1150, 20)
	combat_menu_btn.pressed.connect(_on_combat_menu_pressed)
	combat_ui.add_child(combat_menu_btn)
	
	combat_hud = combat_ui

func _get_skill_icon(skill: String) -> String:
	match skill:
		"dash": return "💨"
		"ground_slam": return "🔨"
		"magic_shot": return "✨"
		"heal": return "💚"
	return "❓"

func start_combat():
	combat_mode = true
	player_health = 100
	player_max_health = 100
	enemy_sprites.clear()
	
	# Create enemies
	_spawn_enemies()
	
	# Create combat UI
	_create_combat_hud()
	_hide_all_panels()
	main_menu.visible = false
	
	# Update game phase
	current_phase = Phase.MORNING_SCHEDULE
	_update_combat_ui()

func _spawn_enemies():
	enemies.clear()
	var num_enemies = randi_range(2, 4)
	var enemy_types = combat_enemies.keys()
	
	for i in range(num_enemies):
		var enemy_type = enemy_types.pick_random()
		var enemy_data = combat_enemies[enemy_type].duplicate()
		enemy_data["type"] = enemy_type
		enemy_data["health"] = enemy_data["health"]
		enemy_data["max_health"] = enemy_data["health"]
		enemy_data["position"] = Vector2(100 + i * 300, 500)
		enemies.append(enemy_data)
		
		# Create visual sprite
		_create_enemy_sprite(enemy_data)

func _create_enemy_sprite(enemy_data: Dictionary):
	var enemy_node = Node2D.new()
	enemy_node.name = "Enemy_" + enemy_data["type"]
	enemy_node.position = enemy_data["position"]
	
	var body = ColorRect.new()
	body.size = Vector2(40, 40)
	body.color = enemy_data["color"]
	enemy_node.add_child(body)
	
	var eyes = ColorRect.new()
	eyes.size = Vector2(10, 5)
	eyes.color = Color.RED
	eyes.position = Vector2(15, 10)
	enemy_node.add_child(eyes)
	
	add_child(enemy_node)
	enemy_sprites.append(enemy_node)

func start_boss_battle():
	boss_active = true
	combat_mode = true
	player_health = 100
	player_max_health = 150
	enemy_sprites.clear()
	
	# Get boss data
	var boss_data = bosses["boss_slime_king"].duplicate()
	boss_health = boss_data["health"]
	boss_max_health = boss_data["health"]
	
	# Create boss sprite
	_create_boss_sprite(boss_data)
	
	# Create combat UI
	_create_combat_hud()
	_hide_all_panels()
	main_menu.visible = false
	
	current_phase = Phase.MORNING_SCHEDULE
	_update_combat_ui()
	_show_boss_intro()

func _create_boss_sprite(boss_data: Dictionary):
	var boss_node = Node2D.new()
	boss_node.name = "Boss"
	boss_node.position = Vector2(900, 450)
	
	# Big body
	var body = ColorRect.new()
	body.size = Vector2(120, 120)
	body.color = boss_data["color"]
	boss_node.add_child(body)
	
	# Crown
	var crown = ColorRect.new()
	crown.size = Vector2(80, 30)
	crown.color = Color(1, 0.84, 0)
	crown.position = Vector2(20, -25)
	boss_node.add_child(crown)
	
	# Angry eyes
	var eye1 = ColorRect.new()
	eye1.size = Vector2(20, 20)
	eye1.color = Color.RED
	eye1.position = Vector2(25, 30)
	boss_node.add_child(eye1)
	
	var eye2 = ColorRect.new()
	eye2.size = Vector2(20, 20)
	eye2.color = Color.RED
	eye2.position = Vector2(75, 30)
	boss_node.add_child(eye2)
	
	# Mouth
	var mouth = ColorRect.new()
	mouth.size = Vector2(60, 10)
	mouth.color = Color.BLACK
	mouth.position = Vector2(30, 80)
	boss_node.add_child(mouth)
	
	add_child(boss_node)
	enemy_sprites.append(boss_node)

func _show_boss_intro():
	var intro = Label.new()
	intro.text = "⚠️ BOSS BATTLE: SLIME KING ⚠️\n\nDefeat the boss to earn $500!"
	intro.position = Vector2(340, 250)
	intro.modulate = Color(1, 0.2, 0.2)
	add_child(intro)
	
	var tween = create_tween()
	tween.tween_property(intro, "modulate:a", 0.0, 4.0)
	tween.tween_callback(intro.queue_free)
	
	if audio_manager:
		audio_manager.play_event()

func _update_combat_ui():
	if combat_hud and combat_hud.has_node("PlayerHP"):
		combat_hud.get_node("PlayerHP").value = player_health
		combat_hud.get_node("PlayerHP").max_value = player_max_health
	
	if combat_hud and combat_hud.has_node("HPLabel"):
		combat_hud.get_node("HPLabel").text = "🦞 HP: %d/%d" % [player_health, player_max_health]
	
	if boss_active and combat_hud:
		if combat_hud.has_node("BossHP"):
			combat_hud.get_node("BossHP").visible = true
			combat_hud.get_node("BossHP").value = boss_health
		if combat_hud.has_node("BossLabel"):
			combat_hud.get_node("BossLabel").visible = true
			combat_hud.get_node("BossLabel").text = "👹 SLIME KING - HP: %d/%d" % [boss_health, boss_max_health]
	
	phase_label.text = "⚔️ COMBAT MODE" if not boss_active else "👹 BOSS BATTLE"
	stats_label.text = "Combat! Click ATTACK to fight! | Money: $%d" % game_data["money"]

func _on_attack_pressed():
	if combat_cooldown > 0:
		return
	
	combat_cooldown = 0.3
	
	# Attack animation
	_animate_attack()
	
	if boss_active:
		var damage = randi_range(10, 20)
		boss_health -= damage
		spawn_negative_effect(self, Vector2(900, 450))
		
		if audio_manager:
			audio_manager.play_success()
		
		if boss_health <= 0:
			_victory_boss()
			return
	else:
		_attack_enemies()
	
	_enemy_attack()
	_update_combat_ui()

func _animate_attack():
	var tween = create_tween()
	tween.tween_property(lobster_container, "position:x", lobster_container.position.x + 30, 0.1)
	tween.tween_property(lobster_container, "position:x", lobster_container.position.x, 0.1)

func _attack_enemies():
	var damage = randi_range(15, 25)
	
	for i in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[i]
		enemy["health"] -= damage
		spawn_stress_effect(self, enemy["position"], true)
		
		if enemy["health"] <= 0:
			var reward = enemy["reward"]
			game_data["money"] += reward
			game_data["stats"]["total_earned"] += reward
			
			if i < enemy_sprites.size():
				enemy_sprites[i].queue_free()
				enemy_sprites.remove_at(i)
			
			enemies.remove_at(i)
			spawn_success_effect(self, enemy["position"])
			spawn_coin_effect(self, enemy["position"], 10)
	
	if enemies.size() == 0:
		_victory_combat()

func _enemy_attack():
	if boss_active:
		var damage = randi_range(10, 20)
		player_health -= damage
		spawn_negative_effect(self, lobster_container.position)
	else:
		for enemy in enemies:
			var damage = enemy["damage"]
			player_health -= damage
			spawn_negative_effect(self, lobster_container.position)
	
	player_health = max(0, player_health)
	
	if player_health <= 0:
		_defeat_combat()

func _victory_combat():
	combat_mode = false
	_clear_combat_ui()
	
	var victory = Label.new()
	victory.text = "🎉 VICTORY!\n\nAll enemies defeated!\n\n+$50"
	victory.position = Vector2(490, 280)
	victory.modulate = Color(0.3, 1, 0.3)
	add_child(victory)
	
	game_data["money"] += 50
	game_data["stats"]["total_earned"] += 50
	
	if audio_manager:
		audio_manager.play_success()
	
	await get_tree().create_timer(2.0).timeout
	victory.queue_free()
	start_shop()

func _victory_boss():
	boss_active = false
	combat_mode = false
	_clear_combat_ui()
	
	var reward = 500
	game_data["money"] += reward
	game_data["stats"]["total_earned"] += reward
	
	spawn_star_effect(self, Vector2(900, 450))
	spawn_coin_effect(self, Vector2(900, 450), 30)
	spawn_success_effect(self, Vector2(900, 450))
	
	if audio_manager:
		audio_manager.play_success()
		audio_manager.play_achievement()
	
	var victory = Label.new()
	victory.text = "👑 BOSS DEFEATED! 👑\n\nThe Slime King has fallen!\n\n+$500!"
	victory.position = Vector2(390, 250)
	victory.modulate = Color(1, 0.84, 0)
	add_child(victory)
	
	await get_tree().create_timer(3.0).timeout
	victory.queue_free()
	
	if not achievements.has("boss_slayer"):
		achievements["boss_slayer"] = {"name": "Boss Slayer", "desc": "Defeat the Slime King", "unlocked": true}
	
	start_shop()

func _defeat_combat():
	combat_mode = false
	_clear_combat_ui()
	
	var defeat = Label.new()
	defeat.text = "💀 DEFEATED...\n\nYour lobster fainted!\n\n-$20 medical bill"
	defeat.position = Vector2(500, 280)
	defeat.modulate = Color(1, 0.2, 0.2)
	add_child(defeat)
	
	game_data["money"] = max(0, game_data["money"] - 20)
	
	if audio_manager:
		audio_manager.play_failure()
	
	await get_tree().create_timer(2.0).timeout
	defeat.queue_free()
	start_morning()

func _clear_combat_ui():
	for sprite in enemy_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	enemy_sprites.clear()
	
	if combat_hud:
		combat_hud.queue_free()
		combat_hud = null

func _on_skill_pressed(skill: String):
	if skill_cooldowns[skill] > 0:
		_show_notification("⏳ Skill on cooldown!")
		return
	
	match skill:
		"dash": _perform_dash()
		"ground_slam": _perform_ground_slam()
		"magic_shot": _perform_magic_shot()
		"heal": _perform_heal()

func _perform_dash():
	skill_cooldowns["dash"] = 5.0
	
	var tween = create_tween()
	var target_pos = lobster_container.position + Vector2(200, 0)
	tween.tween_property(lobster_container, "position", target_pos, 0.2)
	
	for enemy in enemies:
		enemy["health"] -= 25
		spawn_stress_effect(self, enemy["position"], true)
	
	if boss_active:
		boss_health -= 30
		spawn_negative_effect(self, Vector2(900, 450))
		if boss_health <= 0:
			_victory_boss()
	
	_update_combat_ui()

func _perform_ground_slam():
	skill_cooldowns["ground_slam"] = 8.0
	
	var tween = create_tween()
	tween.tween_property(lobster_container, "position:y", lobster_container.position.y - 100, 0.2)
	tween.tween_property(lobster_container, "position:y", lobster_container.position.y + 100, 0.2)
	
	for enemy in enemies:
		enemy["health"] -= 40
		spawn_stress_effect(self, enemy["position"], true)
	
	if boss_active:
		boss_health -= 50
		spawn_negative_effect(self, Vector2(900, 450))
		if boss_health <= 0:
			_victory_boss()
	
	_update_combat_ui()

func _perform_magic_shot():
	skill_cooldowns["magic_shot"] = 4.0
	
	var projectile = ColorRect.new()
	projectile.size = Vector2(20, 20)
	projectile.modulate = Color(0.5, 0.5, 1)
	projectile.position = lobster_container.position
	add_child(projectile)
	
	var tween = create_tween()
	tween.tween_property(projectile, "position:x", 900, 0.3)
	tween.tween_callback(projectile.queue_free)
	
	if boss_active:
		boss_health -= 35
		spawn_stress_effect(self, Vector2(900, 450), true)
		if boss_health <= 0:
			_victory_boss()
	else:
		for enemy in enemies:
			enemy["health"] -= 35
			spawn_stress_effect(self, enemy["position"], true)
	
	_update_combat_ui()

func _perform_heal():
	skill_cooldowns["heal"] = 10.0
	
	player_health = min(player_max_health, player_health + 50)
	spawn_halo_effect(self, lobster_container.position, Color(0.3, 1, 0.3))
	_update_combat_ui()

func _on_combat_menu_pressed():
	combat_mode = false
	_clear_combat_ui()
	_show_main_menu()

func _process_combat(delta):
	for skill in skill_cooldowns:
		if skill_cooldowns[skill] > 0:
			skill_cooldowns[skill] -= delta
	
	if combat_cooldown > 0:
		combat_cooldown -= delta

func _process(delta):
	# 更新连击计时器
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_multiplier = 1.0
			click_count = 0

	# Process combat
	if combat_mode:
		_process_combat(delta)

# ========== END COMBAT SYSTEM ==========

func _show_click_feedback(reward: int, combo: int):
	var feedback = Label.new()
	feedback.position = lobster_container.position + Vector2(-20, -50)
	feedback.modulate = Color(1, 0.9, 0.3)
	
	if combo >= 3:
		feedback.text = "+$%d 🔥%dx" % [reward, combo]
		feedback.modulate = Color(1, 0.5, 0.2)
	else:
		feedback.text = "+$%d" % reward
	
	add_child(feedback)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(feedback, "position:y", feedback.position.y - 50, 0.8)
	tween.tween_property(feedback, "modulate:a", 0.0, 0.8)
	tween.tween_callback(feedback.queue_free)

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
		"inventory": [],
		# Game Statistics
		"stats": {
			"total_work_days": 0,
			"high_work_count": 0,
			"medium_work_count": 0,
			"slack_off_count": 0,
			"total_earned": 0,
			"total_spent": 0,
			"scold_count": 0,
			"pua_count": 0,
			"comfort_count": 0,
			"events_triggered": 0,
			"achievements_unlocked": 0,
			"best_day_income": 0,
			"total_clicks": 0
		}
	}
	achievements = {
		"first_money": {"name": "First Dollar", "desc": "Earn your first $100", "unlocked": false},
		"rich": {"name": "Richich Lobster", "desc": "Accumulate $1000", "unlocked": false},
		"millionaire": {"name": "Millionaire", "desc": "Accumulate $10000", "unlocked": false},
		"stressed": {"name": "High Stress", "desc": "Reach 90 stress", "unlocked": false},
		"burnout": {"name": "Burnout", "desc": "Reach 100 stress", "unlocked": false},
		"happy": {"name": "Zen Master", "desc": "Have 0 stress and 0 resentment", "unlocked": false},
		"corporate": {"name": "Corporate Slave", "desc": "Evolve to Corporate type", "unlocked": false},
		"chaotic": {"name": "Chaotic Evil", "desc": "Evolve to Chaotic type", "unlocked": false},
		"lazy": {"name": "Lazy Lobster", "desc": "Evolve to Lazy type", "unlocked": false},
		"survivor": {"name": "Survivor", "desc": "Survive 30 days", "unlocked": false},
		"workaholic": {"name": "Workaholic", "desc": "Have 100 productivity", "unlocked": false},
		"shop_hoarder": {"name": "Shop Hoarder", "desc": "Buy 10 items from shop", "unlocked": false},
		"workhorse": {"name": "Workhorse", "desc": "Complete 50 high-intensity work sessions", "unlocked": false},
		"balanced_player": {"name": "Balanced Player", "desc": "Complete 30 medium-intensity work sessions", "unlocked": false},
		"zen_master": {"name": "True Zen Master", "desc": "Reach day 50 with 0 stress and 0 resentment", "unlocked": false},
		"lucky_lobster": {"name": "Lucky Lobster", "desc": "Experience 10 random events", "unlocked": false},
		"first_click": {"name": "First Poke", "desc": "Click the lobster for the first time", "unlocked": false},
		"click_master": {"name": "Click Master", "desc": "Click the lobster 50 times", "unlocked": false},
		"combo_king": {"name": "Combo King", "desc": "Get a 10x combo click", "unlocked": false},
		"click_millionaire": {"name": "Click Millionaire", "desc": "Earn $5000 from clicking", "unlocked": false}
	}
	items_purchased_count = 0
	click_rewards_earned = 0
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
	_clear_combat_ui()
	main_menu.visible = false
	current_phase = Phase.MORNING_SCHEDULE
	_update_ui()
	
	# 重置点击系统
	click_count = 0
	combo_multiplier = 1.0
	combo_timer = 0.0
	
	# 显示点击提示
	_show_click_hint()
	
	# Build choices - add combat options after day 3
	var choices = [
		{"key": "high_work", "text": "High-Intensity Work ($$$)\nHigh Stress, High Reward"},
		{"key": "medium_work", "text": "Medium-Intensity Work ($$)\nBalanced"},
		{"key": "slack_off", "text": "Slack Off\nRecover Stress"}
	]
	
	# Add combat options for higher days
	if game_data["day"] >= 3:
		choices.append({"key": "combat", "text": "⚔️ COMBAT\nFight Enemies (+$50)"})
	
	if game_data["day"] >= 5:
		choices.append({"key": "boss", "text": "👹 BOSS BATTLE\nFight Slime King (+$500)"})
	
	_create_choice_buttons(choices, true)
	_check_achievements()

func _show_click_hint():
	# 显示点击提示（仅在第一天或第一天几次显示）
	if game_data["day"] <= 3 or click_rewards_earned == 0:
		var hint = Label.new()
		hint.text = "👆 Click the lobster for bonus money!"
		hint.position = Vector2(440, 450)
		hint.modulate = Color(0.6, 0.8, 1, 0.8)
		hint.add_theme_font_size_override("font_size", 16)
		add_child(hint)
		
		var tween = create_tween()
		tween.tween_property(hint, "modulate:a", 0.0, 3.0)
		tween.tween_callback(hint.queue_free)

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
	
	# Update event stats
	if not game_data.has("stats"):
		game_data["stats"] = {
			"total_work_days": 0,
			"high_work_count": 0,
			"medium_work_count": 0,
			"slack_off_count": 0,
			"total_earned": 0,
			"total_spent": 0,
			"scold_count": 0,
			"pua_count": 0,
			"comfort_count": 0,
			"events_triggered": 0,
			"achievements_unlocked": 0,
			"best_day_income": 0
		}
	game_data["stats"]["events_triggered"] += 1
	
	# 随机事件粒子效果
	if current_event["money"] > 0 or current_event["stress"] < 0:
		spawn_success_effect(self, lobster_sprite.position)
	else:
		spawn_negative_effect(self, lobster_sprite.position)
	
	# Apply event effects
	game_data["money"] += current_event["money"]
	if current_event["money"] > 0:
		game_data["stats"]["total_earned"] += current_event["money"]
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
	
	if game_data["stats"]["events_triggered"] >= 10 and not achievements["lucky_lobster"]["unlocked"]:
		achievements["lucky_lobster"]["unlocked"] = true
		new_achievements.append("lucky_lobster")
	
	# Clicker game achievements
	if click_rewards_earned >= 1 and not achievements["first_click"]["unlocked"]:
		achievements["first_click"]["unlocked"] = true
		new_achievements.append("first_click")
	
	if game_data["stats"].has("total_clicks") and game_data["stats"]["total_clicks"] >= 50 and not achievements["click_master"]["unlocked"]:
		achievements["click_master"]["unlocked"] = true
		new_achievements.append("click_master")
	
	if combo_multiplier >= 10 and not achievements["combo_king"]["unlocked"]:
		achievements["combo_king"]["unlocked"] = true
		new_achievements.append("combo_king")
	
	if click_rewards_earned >= 5000 and not achievements["click_millionaire"]["unlocked"]:
		achievements["click_millionaire"]["unlocked"] = true
		new_achievements.append("click_millionaire")
	
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
	
	# Update activity stats
	if not game_data.has("stats"):
		game_data["stats"] = {
			"total_work_days": 0,
			"high_work_count": 0,
			"medium_work_count": 0,
			"slack_off_count": 0,
			"total_earned": 0,
			"total_spent": 0,
			"scold_count": 0,
			"pua_count": 0,
			"comfort_count": 0,
			"events_triggered": 0,
			"achievements_unlocked": 0,
			"best_day_income": 0
		}
	
	game_data["stats"]["total_work_days"] += 1
	if activity_key == "high_work":
		game_data["stats"]["high_work_count"] += 1
	elif activity_key == "medium_work":
		game_data["stats"]["medium_work_count"] += 1
	elif activity_key == "slack_off":
		game_data["stats"]["slack_off_count"] += 1
	
	var rng = randf()
	today_success = rng < activity["success_rate"]
	
	var earned_today = 0
	if today_success:
		earned_today = randi_range(activity["money_range"][0], activity["money_range"][1])
		game_data["money"] += earned_today
		game_data["stats"]["total_earned"] += earned_today
		if earned_today > game_data["stats"]["best_day_income"]:
			game_data["stats"]["best_day_income"] = earned_today
		game_data["productivity"] += randi_range(1, 5)
		# 成功粒子效果
		spawn_coin_effect(self, lobster_sprite.position, 15)
		spawn_success_effect(self, lobster_sprite.position)
		if audio_manager:
			audio_manager.play_success()
	else:
		var small_earning = randi_range(0, 10)
		game_data["money"] += small_earning
		game_data["stats"]["total_earned"] += small_earning
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
	
	# Handle combat modes
	if activity_key == "combat":
		start_combat()
		return
	elif activity_key == "boss":
		start_boss_battle()
		return
	
	start_evening()

func select_response(response_type: String):
	if audio_manager:
		audio_manager.play_click()
	
	# Update response stats
	if not game_data.has("stats"):
		game_data["stats"] = {
			"total_work_days": 0,
			"high_work_count": 0,
			"medium_work_count": 0,
			"slack_off_count": 0,
			"total_earned": 0,
			"total_spent": 0,
			"scold_count": 0,
			"pua_count": 0,
			"comfort_count": 0,
			"events_triggered": 0,
			"achievements_unlocked": 0,
			"best_day_income": 0
		}
	
	match response_type:
		"scold":
			game_data["stress"] = clamp(game_data["stress"] + 10, 0, 100)
			game_data["resentment"] = clamp(game_data["resentment"] + 20, 0, 100)
			game_data["stats"]["scold_count"] += 1
			spawn_negative_effect(self, lobster_sprite.position)
			if audio_manager:
				audio_manager.play_failure()
		"pua":
			game_data["stress"] = clamp(game_data["stress"] + 5, 0, 100)
			game_data["resentment"] = clamp(game_data["resentment"] - 5, 0, 100)
			game_data["stats"]["pua_count"] += 1
			spawn_stress_effect(self, lobster_sprite.position, false)
			if audio_manager:
				audio_manager.play_stress()
		"comfort":
			game_data["stress"] = clamp(game_data["stress"] - 5, 0, 100)
			game_data["resentment"] = clamp(game_data["resentment"] - 10, 0, 100)
			game_data["stats"]["comfort_count"] += 1
			spawn_success_effect(self, lobster_sprite.position)
			if audio_manager:
				audio_manager.play_relief()
	
	start_shop()

func _on_shop_item_selected(item_key: String):
	var item = shop_items[item_key]
	if game_data["money"] >= item["cost"]:
		game_data["money"] -= item["cost"]
		
		# Check if this is a skill item
		if item.has("slot") and item["slot"] == "skill":
			var skill_name = item["skill"]
			if not unlocked_skills.has(skill_name):
				unlocked_skills[skill_name] = true
			
			# Skill unlock effect
			spawn_star_effect(self, lobster_sprite.position)
			spawn_success_effect(self, lobster_sprite.position)
			
			if audio_manager:
				audio_manager.play_achievement()
			
			_show_notification("✅ Unlocked: " + item["name"])
		else:
			# Regular decoration item
			game_data["decorations"][item["slot"]] = item_key
		
		items_purchased_count += 1
		
		# Update spending stats
		if not game_data.has("stats"):
			game_data["stats"] = {
				"total_work_days": 0,
				"high_work_count": 0,
				"medium_work_count": 0,
				"slack_off_count": 0,
				"total_earned": 0,
				"total_spent": 0,
				"scold_count": 0,
				"pua_count": 0,
				"comfort_count": 0,
				"events_triggered": 0,
				"achievements_unlocked": 0,
				"best_day_income": 0
			}
		game_data["stats"]["total_spent"] += item["cost"]
		
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
	stats_label.text = "Money: $%d | Stress: %d | Resentment: %d | Productivity: %d\nEvolution: %s | Achievements: %d/16" % [
		game_data["money"], 
		game_data["stress"], 
		game_data["resentment"],
		game_data["productivity"],
		game_data["evolution_type"].to_upper(),
		unlocked_count
	]
