extends Area2D

# Pressure Plate - Step on it to trigger an event (open door, spawn enemy, etc.)

var is_activated = false
var trigger_type = "door"  # door, enemy, platform, secret
var trigger_id = 0
var linked_objects = []
var plate_visual: ColorRect
var label: Label

func _ready():
	# Create collision
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(40, 15)
	col.shape = rect
	add_child(col)
	
	# Visual plate
	plate_visual = ColorRect.new()
	plate_visual.size = Vector2(40, 8)
	plate_visual.position = Vector2(-20, -8)
	plate_visual.color = Color(0.4, 0.4, 0.5, 1)
	add_child(plate_visual)
	
	# Label
	label = Label.new()
	label.text = "? "
	label.position = Vector2(-10, -30)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.7, 0.5, 1, 0.8))
	add_child(label)
	
	# Set trigger type from parent data if available
	var game = get_tree().get_first_node_in_group("game")
	if game and game.has("pressure_plate_data"):
		var data = game.pressure_plate_data
		if data.has("type"):
			trigger_type = data["type"]
		if data.has("id"):
			trigger_id = data["id"]
	
	# Add glow effect
	var glow = Polygon2D.new()
	var pts = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8
		pts.append(Vector2(cos(angle), sin(angle)) * 25)
	glow.polygon = pts
	glow.color = Color(0.3, 0.5, 1, 0.1)
	glow.position = Vector2.ZERO
	add_child(glow)
	
	# Animate glow
	var tw = create_tween()
	tw.set_loops()
	tw.tween_property(glow, "modulate:a", 0.3, 1.0)
	tw.tween_property(glow, "modulate:a", 0.1, 1.0)

func _on_body_entered(body):
	if is_activated:
		return
	if body.has_method("take_damage") or body.name == "Player":
		activate()

func activate():
	if is_activated:
		return
	is_activated = true
	
	# Visual feedback - press down
	var tw = create_tween()
	tw.tween_property(plate_visual, "position:y", -3, 0.1)
	tw.tween_property(plate_visual, "color", Color(0.2, 0.8, 0.4, 1), 0.2)
	
	# Update label
	label.text = "✓"
	label.add_theme_color_override("font_color", Color(0.2, 1, 0.4))
	
	# Notify game
	var game = get_tree().get_first_node_in_group("game")
	if game and game.has_method("on_pressure_plate_activated"):
		game.on_pressure_plate_activated(trigger_type, trigger_id)
	
	# Spawn particles
	spawn_activation_effect()
	
	# Play sound
	play_activation_sound()

func spawn_activation_effect():
	for i in range(12):
		var particle = Polygon2D.new()
		var pts = PackedVector2Array()
		for j in range(4):
			var angle = j * TAU / 4
			pts.append(Vector2(cos(angle), sin(angle)) * 4)
		particle.polygon = pts
		particle.color = Color(0.3, 0.8, 1, 0.8)
		particle.position = global_position + Vector2(randf_range(-15, 15), randf_range(-20, 0))
		get_parent().add_child(particle)
		
		var tw = create_tween()
		tw.tween_property(particle, "position", particle.position + Vector2(randf_range(-30, 30), randf_range(-50, -20)), 0.5)
		tw.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tw.tween_callback(particle.queue_free)

func play_activation_sound():
	var game = get_tree().get_first_node_in_group("game")
	if game and game.audio_manager and game.audio_manager.has_method("play_checkbox"):
		game.audio_manager.play_checkbox()