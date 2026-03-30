extends Area2D

# Secret Area - Hidden rooms that reveal when player discovers them
# Part of Metroidvania exploration

var is_revealed = false
var secret_type = "treasure"  # treasure, health, speed, skill, boss
var secret_reward = {}
var area_visual: ColorRect
var reveal_particles: Node2D

const SECRET_COLORS = {
	"treasure": Color(1, 0.85, 0.3, 1),   # Gold
	"health": Color(1, 0.3, 0.3, 1),      # Red
	"speed": Color(0.3, 0.8, 1, 1),       # Cyan
	"skill": Color(0.8, 0.4, 1, 1),       # Purple
	"boss": Color(1, 0.2, 0.2, 1),       # Red danger
	"weapon": Color(1, 0.5, 0.2, 1),     # Orange
	"lore": Color(0.5, 0.8, 0.5, 1)      # Green
}

func _ready():
	# Random secret type
	var types = SECRET_COLORS.keys()
	secret_type = types[randi() % types.size()]
	
	# Create collision (invisible until revealed)
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(80, 80)
	col.shape = rect
	col.set_deferred("disabled", true)  # Initially disabled
	add_child(col)
	
	# Create subtle visual hint (question mark)
	var hint = Label.new()
	hint.text = "?"
	hint.position = Vector2(-5, -40)
	hint.add_theme_font_size_override("font_size", 24)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.3))
	add_child(hint)
	
	# Subtle glow effect
	var glow = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8
		pts.append(Vector2(cos(angle), sin(angle)) * 35)
	glow.polygon = pts
	glow.color = Color(0.5, 0.5, 0.6, 0.05)
	add_child(glow)
	
	# Animate glow
	var tw = create_tween()
	tw.set_loops()
	tw.tween_property(glow, "modulate:a", 0.15, 2.0)
	tw.tween_property(glow, "modulate:a", 0.05, 2.0)
	
	# Add to groups
	add_to_group("secret_area")
	add_to_group("exploration")

func _on_body_entered(body):
	if is_revealed:
		return
	if body.name == "Player" or body.has_method("take_damage"):
		reveal()

func reveal():
	if is_revealed:
		return
	is_revealed = true
	
	# Enable collision
	$CollisionShape2D.disabled = false
	
	# Big reveal effect
	spawn_reveal_effect()
	
	# Give reward
	give_reward()
	
	# Update hint
	for child in get_children():
		if child is Label:
			child.text = "!"
			child.add_theme_color_override("font_color", SECRET_COLORS[secret_type])

func spawn_reveal_effect():
	var color = SECRET_COLORS[secret_type]
	
	# Ring explosion
	for ring in range(4):
		var circle = Polygon2D.new()
		var pts = PackedVector2Array()
		for i in range(20):
			var angle = i * TAU / 20
			pts.append(Vector2(cos(angle), sin(angle)) * (30 + ring * 20))
		circle.polygon = pts
		circle.color = color
		circle.modulate.a = 0.7
		circle.position = global_position
		get_parent().add_child(circle)
		
		var tw = create_tween()
		tw.tween_property(circle, "scale", Vector2(2.5, 2.5), 0.5)
		tw.parallel().tween_property(circle, "modulate:a", 0.0, 0.5)
		tw.tween_callback(circle.queue_free)
	
	# Particles burst
	for i in range(30):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(4):
			var angle = j * TAU / 4
			pts.append(Vector2(cos(angle), sin(angle)) * 5)
		particle.polygon = pts
		particle.color = color
		particle.position = global_position
		get_parent().add_child(particle)
		
		var angle = randf() * TAU
		var dist = randf_range(40, 100)
		var target_pos = global_position + Vector2(cos(angle), sin(angle)) * dist
		
		var tw = create_tween()
		tw.tween_property(particle, "position", target_pos, 0.6)
		tw.parallel().tween_property(particle, "modulate:a", 0.0, 0.6)
		tw.parallel().tween_property(particle, "scale", Vector2(0.3, 0.3), 0.6)
		tw.tween_callback(particle.queue_free)

func give_reward():
	var game = get_tree().get_first_node_in_group("game")
	if not game:
		return
	
	var ui = get_tree().get_first_node_in_group("ui")
	
	match secret_type:
		"treasure":
			var coins = randi_range(10, 30)
			game.score += coins
			show_floating_text("💰 +%d Coins!" % coins, Color(1, 0.85, 0.3))
		"health":
			game.lives = min(game.lives + 1, 5)
			game._update_lives()
			show_floating_text("❤️ Secret Health!", Color(1, 0.3, 0.3))
		"speed":
			if game.player:
				game.player.activate_speed_boost(15.0, 1.8)
			show_floating_text("💨 Speed Secret!", Color(0.3, 0.8, 1))
		"skill":
			# Unlock random skill
			var skills = ["dash", "wall_climb", "double_jump", "ground_slam", "time_slow"]
			var skill = skills[randi() % skills.size()]
			game.unlock_ability(skill)
			show_floating_text("✨ New Ability: %s!" % skill, Color(0.8, 0.4, 1))
		"boss":
			show_floating_text("👹 Warning: BOSS APPROACHING!", Color(1, 0.2, 0.2))
			# Could trigger boss battle here
		"weapon":
			game.attack_damage += 1
			show_floating_text("⚔️ Weapon Upgraded!", Color(1, 0.5, 0.2))
		"lore":
			show_floating_text("📜 Ancient Lore Discovered!", Color(0.5, 0.8, 0.5))

func show_floating_text(text: String, color: Color):
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	var label = Label.new()
	label.text = text
	label.position = global_position
	label.position.y -= 60
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", color)
	ui.add_child(label)
	
	var tw = create_tween()
	tw.tween_property(label, "position:y", label.position.y - 40, 1.5)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 1.5)
	tw.tween_callback(label.queue_free)
