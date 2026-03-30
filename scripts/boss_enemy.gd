extends Node2D

# Boss Enemy - Epic boss battles for the Metroidvania experience
# Has multiple phases, unique attacks, and high health

var boss_name = "Slime King"
var max_health = 100
var current_health = 100
var current_phase = 1
var max_phases = 3
var is_enraged = false
var attack_cooldown = 0.0
var attack_cooldown_max = 2.0
var is_defeated = false

var boss_sprite: Polygon2D
var health_bar: ProgressBar
var phase_label: Label
var attack_indicators: Array = []

const BOSS_COLORS = {
	"Slime King": Color(0.2, 0.9, 0.3, 1),
	"Shadow Lord": Color(0.3, 0.2, 0.4, 1),
	"Fire Dragon": Color(1, 0.3, 0.1, 1),
	"Ice Queen": Color(0.5, 0.8, 1, 1),
	"Thunder Titan": Color(1, 0.9, 0.2, 1)
}

const PHASE_HEALTH_THRESHOLDS = [0.66, 0.33]  # Health % to trigger phase 2, 3

func _ready():
	# Random boss type
	var boss_types = BOSS_COLORS.keys()
	boss_name = boss_types[randi() % boss_types.size()]
	
	# Set health based on type
	match boss_name:
		"Slime King":
			max_health = 100
			max_phases = 3
		"Shadow Lord":
			max_health = 150
			max_phases = 3
		"Fire Dragon":
			max_health = 200
			max_phases = 4
		"Ice Queen":
			max_health = 120
			max_phases = 3
		"Thunder Titan":
			max_health = 180
			max_phases = 3
	
	current_health = max_health
	
	# Create boss visual
	_create_boss_sprite()
	
	# Create health bar
	_create_health_bar()
	
	# Add to groups
	add_to_group("enemy")
	add_to_group("boss")
	add_to_group("damageable")

func _create_boss_sprite():
	boss_sprite = Polygon2D.new()
	
	# Create blob shape
	var pts = PackedVector2Array()
	for i in range(12):
		var angle = i * TAU / 12
		var radius = 40 + sin(i * 1.5) * 10
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	boss_sprite.polygon = pts
	boss_sprite.color = BOSS_COLORS[boss_name]
	boss_sprite.position = Vector2.ZERO
	add_child(boss_sprite)
	
	# Eyes
	var left_eye = Polygon2D.new()
	left_eye.polygon = PackedVector2Array([Vector2(-15, -10), Vector2(-5, -10), Vector2(-10, -5)])
	left_eye.color = Color.WHITE
	boss_sprite.add_child(left_eye)
	
	var right_eye = Polygon2D.new()
	right_eye.polygon = PackedVector2Array([Vector2(5, -10), Vector2(15, -10), Vector2(10, -5)])
	right_eye.color = Color.WHITE
	boss_sprite.add_child(right_eye)
	
	# Idle animation
	var tw = create_tween()
	tw.set_loops()
	tw.tween_property(boss_sprite, "scale", Vector2(1.1, 0.9), 0.8)
	tw.tween_property(boss_sprite, "scale", Vector2(0.9, 1.1), 0.8)

func _create_health_bar():
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(440, 50)
	health_bar.size = Vector2(400, 20)
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.show_percentage = false
	
	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.5, 0.5, 1)
	health_bar.add_theme_stylebox_override("panel", style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = BOSS_COLORS[boss_name]
	health_bar.add_theme_stylebox_override("fill", fill_style)
	
	ui.add_child(health_bar)
	
	# Boss name label
	phase_label = Label.new()
	phase_label.text = "%s - Phase %d" % [boss_name, current_phase]
	phase_label.position = Vector2(540, 25)
	phase_label.add_theme_font_size_override("font_size", 18)
	phase_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
	ui.add_child(phase_label)

func _physics_process(delta):
	if is_defeated:
		return
	
	# Move towards player slowly
	var game = get_tree().get_first_node_in_group("game")
	if game and game.player:
		var dir = (game.player.global_position - global_position).normalized()
		global_position += dir * 50 * delta
	
	# Attack cooldown
	if attack_cooldown > 0:
		attack_cooldown -= delta
	else:
		perform_attack()

func perform_attack():
	if is_defeated:
		return
	
	# Choose attack based on phase
	var attack_type = _get_phase_attack()
	
	match attack_type:
		"slash":
			_attack_slash()
		"projectile":
			_attack_projectile()
		"area":
			_attack_area()
		"dash":
			_attack_dash()
	
	attack_cooldown = attack_cooldown_max

func _get_phase_attack() -> String:
	var attacks = ["slash"]
	
	if current_phase >= 2:
		attacks.append("projectile")
	
	if current_phase >= 3:
		attacks.append("area")
	
	if is_enraged and current_phase >= 2:
		attacks.append("dash")
	
	return attacks[randi() % attacks.size()]

func _attack_slash():
	# Quick slash attack
	var game = get_tree().get_first_node_in_group("game")
	if not game or not game.player:
		return
	
	var dir = (game.player.global_position - global_position).normalized()
	
	# Visual slash effect
	var slash = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8
		pts.append(Vector2(cos(angle), sin(angle)) * 30)
	slash.polygon = pts
	slash.color = BOSS_COLORS[boss_name].lerp(Color.WHITE, 0.5)
	slash.position = global_position + dir * 30
	get_parent().add_child(slash)
	
	var tw = create_tween()
	tw.tween_property(slash, "scale", Vector2(2, 2), 0.2)
	tw.parallel().tween_property(slash, "modulate:a", 0.0, 0.2)
	tw.tween_callback(slash.queue_free)
	
	# Check hit
	if game.player.global_position.distance_to(global_position) < 60:
		game._on_player_damaged(15)
	
	# Play attack sound
	play_attack_sound()

func _attack_projectile():
	# Shoot projectiles
	var game = get_tree().get_first_node_in_group("game")
	if not game or not game.player:
		return
	
	var dir = (game.player.global_position - global_position).normalized()
	
	for i in range(3):
		await get_tree().create_timer(i * 0.2).timeout
		
		var projectile = Polygon2D.new()
		projectile.polygon = PackedVector2Array([Vector2(-8, 0), Vector2(0, -5), Vector2(8, 0), Vector2(0, 5)])
		projectile.color = BOSS_COLORS[boss_name]
		projectile.position = global_position
		projectile.add_to_group("enemy_projectile")
		get_parent().add_child(projectile)
		
		# Move projectile
		var move_tween = create_tween()
		var target = game.player.global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
		move_tween.tween_property(projectile, "position", target, 0.8)
		move_tween.tween_callback(projectile.queue_free)
	
	play_attack_sound()

func _attack_area():
	# Area attack - warning circles then damage
	var game = get_tree().get_first_node_in_group("game")
	if not game or not game.player:
		return
	
	# Show warning
	for i in range(5):
		var warning = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(16):
			var angle = j * TAU / 16
			pts.append(Vector2(cos(angle), sin(angle)) * 40)
		warning.polygon = pts
		warning.color = Color(1, 0.2, 0.2, 0.5)
		warning.position = global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
		get_parent().add_child(warning)
		
		var tw = create_tween()
		tw.tween_property(warning, "modulate:a", 0.0, 0.5)
		tw.tween_callback(warning.queue_free)
	
	await get_tree().create_timer(0.5).timeout
	
	# Damage if player in area
	if game.player:
		var dist = game.player.global_position.distance_to(global_position)
		if dist < 100:
			game._on_player_damaged(25)

func _attack_dash():
	# Enraged dash attack
	var game = get_tree().get_first_node_in_group("game")
	if not game or not game.player:
		return
	
	var dir = (game.player.global_position - global_position).normalized()
	var target_pos = global_position + dir * 200
	
	# Visual charge up
	var charge = Polygon2D.new()
	charge.polygon = PackedVector2Array([Vector2(-20, 0), Vector2(0, -15), Vector2(20, 0), Vector2(0, 15)])
	charge.color = BOSS_COLORS[boss_name]
	charge.position = global_position
	get_parent().add_child(charge)
	
	var tw = create_tween()
	tw.tween_property(charge, "position", target_pos, 0.3)
	tw.tween_callback(charge.queue_free)
	
	global_position = target_pos
	
	# Damage
	if game.player.global_position.distance_to(global_position) < 50:
		game._on_player_damaged(30)

func take_damage(amount: int):
	if is_defeated:
		return
	
	current_health -= amount
	
	# Update health bar
	if health_bar:
		health_bar.value = current_health
	
	# Flash effect
	if boss_sprite:
		var original_color = boss_sprite.color
		boss_sprite.color = Color.WHITE
		await get_tree().create_timer(0.1).timeout
		boss_sprite.color = original_color
	
	# Check phase transition
	_check_phase_transition()
	
	# Check defeat
	if current_health <= 0:
		defeat()

func _check_phase_transition():
	var health_percent = float(current_health) / float(max_health)
	
	for i in range(PHASE_HEALTH_THRESHOLDS.size()):
		if health_percent < PHASE_HEALTH_THRESHOLDS[i] and current_phase == i + 1:
			current_phase = i + 2
			_trigger_phase_change()
			break

func _trigger_phase_change():
	# Visual indication
	if phase_label:
		phase_label.text = "%s - Phase %d" % [boss_name, current_phase]
	
	# Enrage at phase 3
	if current_phase >= 3:
		is_enraged = true
		attack_cooldown_max = 1.5
		if phase_label:
			phase_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
	
	# Phase change effect
	for i in range(20):
		var particle = Polygon2D.new()
		particle.polygon = PackedVector2Array([Vector2(-5, 0), Vector2(0, -5), Vector2(5, 0), Vector2(0, 5)])
		particle.color = BOSS_COLORS[boss_name]
		particle.position = global_position
		get_parent().add_child(particle)
		
		var tw = create_tween()
		var angle = randf() * TAU
		var dist = randf_range(50, 100)
		tw.tween_property(particle, "position", global_position + Vector2(cos(angle), sin(angle)) * dist, 0.5)
		tw.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tw.tween_callback(particle.queue_free)

func defeat():
	is_defeated = true
	
	# Remove health bar
	if health_bar:
		health_bar.queue_free()
	if phase_label:
		phase_label.queue_free()
	
	# Death animation
	_death_animation()
	
	# Give reward
	var game = get_tree().get_first_node_in_group("game")
	if game:
		game.score += 500
		game.show_victory_message("BOSS DEFEATED!\n+%d Coins!" % 500)
	
	queue_free()

func _death_animation():
	# Big explosion
	for ring in range(5):
		var circle = Polygon2D.new()
		var pts = PackedVector2Array()
		for i in range(24):
			var angle = i * TAU / 24
			pts.append(Vector2(cos(angle), sin(angle)) * (30 + ring * 25))
		circle.polygon = pts
		circle.color = BOSS_COLORS[boss_name]
		circle.modulate.a = 0.8
		circle.position = global_position
		get_parent().add_child(circle)
		
		var tw = create_tween()
		tw.tween_property(circle, "scale", Vector2(3, 3), 0.6)
		tw.parallel().tween_property(circle, "modulate:a", 0.0, 0.6)
		tw.tween_callback(circle.queue_free)

func play_attack_sound():
	var game = get_tree().get_first_node_in_group("game")
	if game and game.audio_manager and game.audio_manager.has_method("play_enemy_attack"):
		game.audio_manager.play_enemy_attack()
