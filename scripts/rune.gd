extends Area2D

# Magic Rune - Ancient symbols that when activated give rewards
# Puzzle: Player must find and activate all runes in an area

var is_activated = false
var rune_type = "power"  # power, coin, health, speed, invincibility
var rune_visual: Polygon2D
var glow_visual: Polygon2D
var particles: Node2D

const RUNE_COLORS = {
	"power": Color(1, 0.4, 0.2, 1),      # Orange - attack boost
	"coin": Color(1, 0.85, 0.3, 1),     # Gold - bonus coins
	"health": Color(1, 0.3, 0.4, 1),    # Red - health
	"speed": Color(0.3, 0.8, 1, 1),    # Cyan - speed boost
	"invincibility": Color(0.8, 0.4, 1, 1),  # Purple - temporary invincibility
	"teleport": Color(0.4, 1, 0.5, 1), # Green - teleport ability
	"double_coin": Color(1, 0.6, 0.1, 1), # Bright gold - double coins
	"combo": Color(1, 0.2, 0.5, 1)     # Pink - combo boost
}

func _ready():
	# Create collision
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 20
	col.shape = circle
	add_child(col)
	
	# Random rune type
	var types = RUNE_COLORS.keys()
	rune_type = types[randi() % types.size()]
	
	# Create rune visual (star shape)
	rune_visual = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(6):
		var angle = i * TAU / 6 - PI/2
		var radius = 18 if i % 2 == 0 else 10
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	rune_visual.polygon = pts
	rune_visual.color = RUNE_COLORS[rune_type]
	add_child(rune_visual)
	
	# Create glow
	glow_visual = Polygon2D.new()
	var glow_pts = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8
		glow_pts.append(Vector2(cos(angle), sin(angle)) * 28)
	glow_visual.polygon = glow_pts
	glow_visual.color = RUNE_COLORS[rune_type].lerp(Color.BLACK, 0.5)
	glow_visual.color.a = 0.3
	add_child(glow_visual)
	
	# Floating animation
	var tw = create_tween()
	tw.set_loops()
	tw.tween_property(rune_visual, "position:y", -5, 0.8)
	tw.tween_property(rune_visual, "position:y", 0, 0.8)
	
	# Glow pulse
	var glow_tw = create_tween()
	glow_tw.set_loops()
	glow_tw.tween_property(glow_visual, "modulate:a", 0.5, 1.0)
	glow_tw.tween_property(glow_visual, "modulate:a", 0.2, 1.0)
	
	# Add to group
	add_to_group("rune")
	add_to_group("collectible")

func _on_body_entered(body):
	if is_activated:
		return
	if body.has_method("take_damage") or body.name == "Player":
		activate()

func activate():
	if is_activated:
		return
	is_activated = true
	
	# Big activation effect
	spawn_activation_effect()
	
	# Give reward
	give_reward()
	
	# Remove after effect
	await get_tree().create_timer(1.0).timeout
	queue_free()

func spawn_activation_effect():
	# Ring explosion
	for ring in range(3):
		var circle = Polygon2D.new()
		var pts = PackedVector2Array()
		for i in range(16):
			var angle = i * TAU / 16
			pts.append(Vector2(cos(angle), sin(angle)) * (20 + ring * 15))
		circle.polygon = pts
		circle.color = RUNE_COLORS[rune_type]
		circle.modulate.a = 0.8
		circle.position = global_position
		get_parent().add_child(circle)
		
		var tw = create_tween()
		tw.tween_property(circle, "scale", Vector2(2, 2), 0.4)
		tw.parallel().tween_property(circle, "modulate:a", 0.0, 0.4)
		tw.tween_callback(circle.queue_free)
	
	# Particles
	for i in range(20):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(4):
			var angle = j * TAU / 4
			pts.append(Vector2(cos(angle), sin(angle)) * 4)
		particle.polygon = pts
		particle.color = RUNE_COLORS[rune_type]
		particle.position = global_position
		get_parent().add_child(particle)
		
		var target_pos = global_position + Vector2(randf_range(-60, 60), randf_range(-60, 60))
		var tw = create_tween()
		tw.tween_property(particle, "position", target_pos, 0.5)
		tw.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tw.parallel().tween_property(particle, "scale", Vector2(0.5, 0.5), 0.5)
		tw.tween_callback(particle.queue_free)

func give_reward():
	var game = get_tree().get_first_node_in_group("game")
	if not game:
		return
	
	match rune_type:
		"power":
			# Attack boost - increase combo meter faster
			game.combo_meter = min(game.combo_meter + 30, game.combo_meter_max)
			show_floating_text("⚔️ Power Up!")
		"coin", "double_coin":
			# Bonus coins
			var amount = 10 if rune_type == "coin" else 25
			game.score += amount
			game.save_data["total_coins"] += amount
			game.save_save_data()
			show_floating_text("💰 +%d Coins!" % amount)
		"health":
			# Restore health
			game.lives = min(game.lives + 1, 5)
			game._update_lives()
			show_floating_text("❤️ +1 Life!")
		"speed":
			# Speed boost
			if game.player:
				game.player.activate_speed_boost(10.0, 1.5)
			show_floating_text("💨 Speed Up!")
		"invincibility":
			# Temporary invincibility
			if game.player:
				game.player.activate_invincible(5.0)
			show_floating_text("🛡️ Invincible!")
		"teleport":
			# Unlock teleport ability
			game.unlock_ability("teleport")
			show_floating_text("🌀 Teleport!")
		"combo":
			# Combo boost
			game.combo = min(game.combo + 3, 20)
			game.combo_meter = min(game.combo_meter + 50, game.combo_meter_max)
			show_floating_text("🔥 Combo +3!")

func show_floating_text(text: String):
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	var label = Label.new()
	label.text = text
	label.position = global_position
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", RUNE_COLORS[rune_type])
	ui.add_child(label)
	
	var tw = create_tween()
	tw.tween_property(label, "position:y", label.position.y - 50, 1.0)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tw.tween_callback(label.queue_free)