extends Area2D

# Puzzle Key - Collect to open locked doors
# Part of the Metroidvania puzzle system

var key_type = "silver"  # silver, gold, bronze
var is_collected = false
var key_visual: Polygon2D
var glow_visual: Polygon2D
var rotation_speed = 2.0

const KEY_COLORS = {
	"silver": Color(0.75, 0.75, 0.8, 1),
	"gold": Color(1, 0.85, 0.3, 1),
	"bronze": Color(0.8, 0.5, 0.3, 1),
	"crystal": Color(0.3, 0.8, 1, 1),
	"fire": Color(1, 0.4, 0.2, 1),
	"ice": Color(0.5, 0.8, 1, 1)
}

func _ready():
	# Random key type
	var types = KEY_COLORS.keys()
	var meta_type = get_meta("key_type", null)
	if meta_type != null:
		key_type = meta_type
	else:
		key_type = types[randi() % types.size()]
	
	# Create collision
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 15
	col.shape = circle
	add_child(col)
	
	# Create key visual (diamond shape)
	key_visual = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(4):
		var angle = i * TAU / 4 - PI/4
		var radius = 12
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	key_visual.polygon = pts
	key_visual.color = KEY_COLORS[key_type]
	add_child(key_visual)
	
	# Create glow
	glow_visual = Polygon2D.new()
	var glow_pts = PackedVector2Array()
	for i in range(6):
		var angle = i * TAU / 6
		glow_pts.append(Vector2(cos(angle), sin(angle)) * 22)
	glow_visual.polygon = glow_pts
	glow_visual.color = KEY_COLORS[key_type]
	glow_visual.color.a = 0.3
	add_child(glow_visual)
	
	# Floating animation
	var tw = create_tween()
	tw.set_loops()
	tw.tween_property(key_visual, "position:y", -3, 0.6)
	tw.tween_property(key_visual, "position:y", 0, 0.6)
	
	# Glow pulse
	var glow_tw = create_tween()
	glow_tw.set_loops()
	glow_tw.tween_property(glow_visual, "modulate:a", 0.5, 0.8)
	glow_tw.tween_property(glow_visual, "modulate:a", 0.2, 0.8)
	
	# Add to groups
	add_to_group("puzzle_key")
	add_to_group("collectible")

func _physics_process(delta):
	# Rotate
	key_visual.rotation += rotation_speed * delta
	glow_visual.rotation -= rotation_speed * 0.5 * delta

func _on_body_entered(body):
	if is_collected:
		return
	if body.has_method("take_damage") or body.name == "Player":
		collect()

func collect():
	if is_collected:
		return
	is_collected = true
	
	# Notify game
	var game = get_tree().get_first_node_in_group("game")
	if game:
		game.collect_puzzle_key(key_type)
	
	# Collection effect
	spawn_collection_effect()
	show_floating_text("🔑 %s Key!" % key_type.capitalize())
	
	await get_tree().create_timer(0.5).timeout
	queue_free()

func spawn_collection_effect():
	for i in range(15):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(4):
			var angle = j * TAU / 4
			pts.append(Vector2(cos(angle), sin(angle)) * 3)
		particle.polygon = pts
		particle.color = KEY_COLORS[key_type]
		particle.position = global_position
		get_parent().add_child(particle)
		
		var target_pos = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		var tw = create_tween()
		tw.tween_property(particle, "position", target_pos, 0.4)
		tw.parallel().tween_property(particle, "modulate:a", 0.0, 0.4)
		tw.parallel().tween_property(particle, "scale", Vector2(0.3, 0.3), 0.4)
		tw.tween_callback(particle.queue_free)

func show_floating_text(text: String):
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	var label = Label.new()
	label.text = text
	label.position = global_position
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", KEY_COLORS[key_type])
	ui.add_child(label)
	
	var tw = create_tween()
	tw.tween_property(label, "position:y", label.position.y - 40, 0.8)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tw.tween_callback(label.queue_free)
