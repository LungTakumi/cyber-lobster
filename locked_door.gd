extends Area2D

# Locked Door - Opens when player has the right key
# Part of the Metroidvania puzzle system

var required_key_type = "silver"
var is_open = false
var door_visual: ColorRect
var lock_visual: Polygon2D
var glow_visual: Polygon2D
var label: Label

const KEY_COLORS = {
	"silver": Color(0.75, 0.75, 0.8, 1),
	"gold": Color(1, 0.85, 0.3, 1),
	"bronze": Color(0.8, 0.5, 0.3, 1),
	"crystal": Color(0.3, 0.8, 1, 1),
	"fire": Color(1, 0.4, 0.2, 1),
	"ice": Color(0.5, 0.8, 1, 1)
}

func _ready():
	# Random key type if not set
	var meta_type = get_meta("required_key_type", null)
	if meta_type != null:
		required_key_type = meta_type
	elif required_key_type == "random":
		var types = ["silver", "gold", "bronze", "crystal", "fire", "ice"]
		required_key_type = types[randi() % types.size()]
	
	# Create collision
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(30, 60)
	col.shape = rect
	add_child(col)
	
	# Door visual
	door_visual = ColorRect.new()
	door_visual.size = Vector2(24, 54)
	door_visual.position = Vector2(-12, -27)
	door_visual.color = Color(0.2, 0.2, 0.25, 1)
	add_child(door_visual)
	
	# Lock visual
	lock_visual = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8
		pts.append(Vector2(cos(angle), sin(angle)) * 10)
	lock_visual.polygon = pts
	lock_visual.color = KEY_COLORS.get(required_key_type, Color.WHITE)
	lock_visual.position = Vector2(0, 10)
	add_child(lock_visual)
	
	# Glow
	glow_visual = Polygon2D.new()
	var glow_pts = PackedVector2Array()
	for i in range(6):
		var angle = i * TAU / 6
		glow_pts.append(Vector2(cos(angle), sin(angle)) * 18)
	glow_visual.polygon = glow_pts
	glow_visual.color = KEY_COLORS.get(required_key_type, Color.WHITE)
	glow_visual.color.a = 0.2
	glow_visual.position = Vector2(0, 10)
	add_child(glow_visual)
	
	# Label
	label = Label.new()
	label.text = "🔒 " + required_key_type.capitalize()
	label.position = Vector2(-35, -45)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.8))
	add_child(label)
	
	# Glow pulse
	var tw = create_tween()
	tw.set_loops()
	tw.tween_property(glow_visual, "modulate:a", 0.4, 1.0)
	tw.tween_property(glow_visual, "modulate:a", 0.1, 1.0)
	
	# Add to groups
	add_to_group("locked_door")
	add_to_group("puzzle_object")

func _on_body_entered(body):
	if is_open:
		return
	if body.has_method("take_damage") or body.name == "Player":
		try_open()

func try_open():
	var game = get_tree().get_first_node_in_group("game")
	if game and game.has_puzzle_key(required_key_type):
		game.use_puzzle_key(required_key_type)
		open()
	else:
		show_locked_message()

func open():
	if is_open:
		return
	is_open = true
	
	# Open animation
	var tw = create_tween()
	tw.tween_property(door_visual, "size:x", 0, 0.3)
	tw.parallel().tween_property(door_visual, "position:x", 0, 0.3)
	tw.parallel().tween_property(lock_visual, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(glow_visual, "modulate:a", 0.0, 0.3)
	
	# Update label
	label.text = "🔓 Open!"
	label.add_theme_color_override("font_color", Color(0.3, 1, 0.3, 1))
	
	# Disable collision
	$CollisionShape2D.disabled = true
	
	# Spawn open effect
	spawn_open_effect()

func spawn_open_effect():
	var color = KEY_COLORS.get(required_key_type, Color.WHITE)
	for i in range(20):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(4):
			var angle = j * TAU / 4
			pts.append(Vector2(cos(angle), sin(angle)) * 4)
		particle.polygon = pts
		particle.color = color
		particle.position = global_position + Vector2(randf_range(-15, 15), randf_range(-30, 30))
		get_parent().add_child(particle)
		
		var target_pos = particle.position + Vector2(randf_range(-50, 50), randf_range(-20, 20))
		var tw = create_tween()
		tw.tween_property(particle, "position", target_pos, 0.5)
		tw.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tw.tween_callback(particle.queue_free)

func show_locked_message():
	var ui = get_tree().get_first_node_in_group("ui")
	if not ui:
		return
	
	var label = Label.new()
	label.text = "🔑 Need " + required_key_type.capitalize() + " Key!"
	label.position = global_position + Vector2(-50, -60)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1, 0.5, 0.5, 1))
	ui.add_child(label)
	
	var tw = create_tween()
	tw.tween_property(label, "position:y", label.position.y - 30, 1.0)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tw.tween_callback(label.queue_free)
