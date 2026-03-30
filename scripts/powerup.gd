extends Area2D

# Powerup script - gives player abilities when collected

var powerup_type = "dash"  # default type
var visual: Node2D
var glow: Polygon2D
var is_collected = false

# Powerup types and their colors
const POWERUP_COLORS = {
	"dash": Color(0.3, 0.8, 1, 1),           # Cyan
	"double_jump": Color(1, 0.6, 0.2, 1),    # Orange
	"wall_climb": Color(0.6, 0.8, 0.4, 1),   # Green
	"ground_slam": Color(1, 0.3, 0.3, 1),   # Red
	"time_slow": Color(0.3, 0.5, 1, 1),      # Blue
	"teleport": Color(0.4, 1, 0.5, 1),       # Green
	"shadow_clone": Color(0.5, 0.4, 0.7, 1), # Purple
	"bounce": Color(1, 0.5, 0.8, 1),        # Pink
	"time_rewind": Color(0.3, 0.8, 0.8, 1),  # Teal
	"energy_shield": Color(0.4, 0.6, 1, 1),  # Light blue
	"phase_shift": Color(0.7, 0.7, 0.9, 1), # Lavender
	"tracking_projectile": Color(1, 0.8, 0.3, 1),  # Gold
	"magic_wand": Color(0.9, 0.3, 0.9, 1),  # Magenta
	"health_regen": Color(1, 0.4, 0.4, 1),  # Red
	"gravity_flip": Color(0.5, 0.4, 0.9, 1) # Purple - NEW!
}

const POWERUP_ICONS = {
	"dash": "💨",
	"double_jump": "🔺",
	"wall_climb": "🧗",
	"ground_slam": "💥",
	"time_slow": "⏱️",
	"teleport": "🌀",
	"shadow_clone": "👤",
	"bounce": "⭕",
	"time_rewind": "🔄",
	"energy_shield": "🛡️",
	"phase_shift": "👻",
	"tracking_projectile": "🎯",
	"magic_wand": "🪄",
	"health_regen": "❤️",
	"gravity_flip": "⬇️"  # NEW!
}

func _ready():
	# Check for forced type from metadata (set by main.gd)
	if has_meta("forced_type"):
		powerup_type = get_meta("forced_type")
	else:
		# Random powerup type from available ones
		var types = POWERUP_COLORS.keys()
		powerup_type = types[randi() % types.size()]
	
	# Create collision
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 18
	col.shape = circle
	add_child(col)
	
	# Create visual
	create_visual()
	
	# Floating animation
	var tw = create_tween()
	tw.set_loops()
	tw.tween_property(visual, "position:y", -5, 0.6)
	tw.tween_property(visual, "position:y", 5, 0.6)
	
	# Glow pulse
	var glow_tw = create_tween()
	glow_tw.set_loops()
	glow_tw.tween_property(glow, "modulate:a", 0.5, 0.8)
	glow_tw.tween_property(glow, "modulate:a", 0.15, 0.8)
	
	# Add to groups
	add_to_group("powerup")
	add_to_group("collectible")
	
	# Connect body entered
	body_entered.connect(_on_body_entered)

func create_visual():
	var color = POWERUP_COLORS.get(powerup_type, Color.CYAN)
	
	# Main orb
	visual = Node2D.new()
	add_child(visual)
	
	# Create diamond shape
	var diamond = Polygon2D.new()
	var pts = PackedVector2Array([
		Vector2(0, -15),   # Top
		Vector2(12, 0),    # Right
		Vector2(0, 15),    # Bottom
		Vector2(-12, 0)    # Left
	])
	diamond.polygon = pts
	diamond.color = color
	visual.add_child(diamond)
	
	# Inner glow
	var inner = Polygon2D.new()
	inner.polygon = pts.duplicate()
	inner.scale = Vector2(0.5, 0.5)
	inner.color = Color(1, 1, 1, 0.6)
	visual.add_child(inner)
	
	# Glow ring
	glow = Polygon2D.new()
	var glow_pts = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8
		glow_pts.append(Vector2(cos(angle), sin(angle)) * 22)
	glow.polygon = glow_pts
	glow.color = color
	glow.color.a = 0.25
	visual.add_child(glow)
	
	# Icon label (emoji)
	var icon = Label.new()
	icon.text = POWERUP_ICONS.get(powerup_type, "✨")
	icon.add_theme_font_size_override("font_size", 16)
	icon.position = Vector2(-8, -10)
	visual.add_child(icon)

func _on_body_entered(body):
	if is_collected:
		return
	if body.has_method("take_damage") or body.name == "Player":
		collect(body)

func collect(body):
	if is_collected:
		return
	is_collected = true
	
	# Give ability to player
	if body.has_method("activate_" + powerup_type):
		body.call("activate_" + powerup_type)
	elif body.has_method("activate_" + powerup_type.replace("_", "_")):
		body.call("activate_" + powerup_type.replace("_", "_"))
	
	# Or just set the flag
	if body.has("can_" + powerup_type):
		body.set("can_" + powerup_type, true)
	
	# Apply ability unlock
	var main = get_tree().get_first_node_in_group("game")
	if main and main.has_method("unlock_ability"):
		main.unlock_ability(powerup_type)
	
	# Show collection effect
	spawn_collect_effect()
	
	# Show floating text
	show_collection_text()
	
	# Remove
	queue_free()

func spawn_collect_effect():
	var parent = get_parent()
	if not parent:
		return
	
	# Ring explosion
	for i in range(3):
		var ring = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(12):
			var angle = j * TAU / 12
			pts.append(Vector2(cos(angle), sin(angle)) * (15 + i * 10))
		ring.polygon = pts
		ring.color = POWERUP_COLORS.get(powerup_type, Color.CYAN)
		ring.modulate.a = 0.8
		ring.position = global_position
		parent.add_child(ring)
		
		var tw = create_tween()
		tw.tween_property(ring, "scale", Vector2(2, 2), 0.4)
		tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.4)
		tw.tween_callback(ring.queue_free)
	
	# Particles
	for i in range(15):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(4):
			var angle = j * TAU / 4
			pts.append(Vector2(cos(angle), sin(angle)) * 4)
		particle.polygon = pts
		particle.color = POWERUP_COLORS.get(powerup_type, Color.CYAN)
		particle.position = global_position
		parent.add_child(particle)
		
		var target_pos = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		var tw = create_tween()
		tw.tween_property(particle, "position", target_pos, 0.4)
		tw.parallel().tween_property(particle, "modulate:a", 0.0, 0.4)
		tw.tween_callback(particle.queue_free)

func show_collection_text():
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	var label = Label.new()
	var ability_names = {
		"dash": "Dash",
		"double_jump": "Double Jump",
		"wall_climb": "Wall Climb",
		"ground_slam": "Ground Slam",
		"time_slow": "Time Slow",
		"teleport": "Teleport",
		"shadow_clone": "Shadow Clone",
		"bounce": "Bounce",
		"time_rewind": "Time Rewind",
		"energy_shield": "Energy Shield",
		"phase_shift": "Phase Shift",
		"tracking_projectile": "Tracking Shot",
		"magic_wand": "Magic Wand",
		"health_regen": "Health Regen",
		"gravity_flip": "Gravity Flip"
	}
	label.text = "✨ " + ability_names.get(powerup_type, powerup_type) + "!"
	label.position = global_position
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", POWERUP_COLORS.get(powerup_type, Color.CYAN))
	ui.add_child(label)
	
	var tw = create_tween()
	tw.tween_property(label, "position:y", label.position.y - 50, 1.0)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tw.tween_callback(label.queue_free)
