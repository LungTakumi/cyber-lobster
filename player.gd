extends CharacterBody2D

# 玩家移动脚本 - 支持键盘和虚拟按钮（多点触控）

# 移动参数
var speed: float = 300.0
var jump_force: float = -450.0
var gravity: float = 980.0
var speed_multiplier: float = 1.0

# 墙壁攀爬参数
var wall_slide_speed: float = 100.0
var wall_jump_force: Vector2 = Vector2(200, -400)
var is_on_wall_left: bool = false
var is_on_wall_right: bool = false

# 跳跃相关
var max_jumps: int = 1
var current_jumps: int = 0
var can_double_jump: bool = false

# 能力标志
var can_dash: bool = false
var can_wall_climb: bool = false
var can_ground_slam: bool = false
var can_time_slow: bool = false
var can_shadow_clone: bool = false
var can_combo_finale: bool = false
var has_permanent_double_jump: bool = false
var can_magic_wand: bool = false
var can_bounce: bool = false
var can_time_rewind: bool = false
var can_energy_shield: bool = false
var can_phase_shift: bool = false
var can_tracking_projectile: bool = false

# 重力反转能力 (Metroidvania 新功能!)
var can_gravity_flip: bool = false
var gravity_flipped: bool = false
var gravity_flip_cooldown: float = 0.0
var gravity_flip_cooldown_max: float = 2.0

# 状态
var is_invincible: bool = false
var invincible_timer: float = 0.0
var is_wall_sliding: bool = false

# 地面检测
@onready var floor_check: RayCast2D = RayCast2D.new()

# 攻击系统
var attack_cooldown: float = 0.0
var attack_cooldown_max: float = 0.4  # 攻击间隔 0.4秒
var is_attacking: bool = false
var attack_damage: int = 1
var attack_hitbox: Area2D = null

# 攻击特效
var attack_sprite: Polygon2D = null

# 冲刺系统 (Dash Ability - Metroidvania 新功能!)
var is_dashing: bool = false
var dash_cooldown: float = 0.0
var dash_cooldown_max: float = 1.5  # 冲刺冷却1.5秒
var dash_duration: float = 0.0
var dash_duration_max: float = 0.15  # 冲刺持续0.15秒
var dash_speed: float = 800.0  # 冲刺速度
var dash_direction: Vector2 = Vector2.RIGHT
var can_dash_while_airborne: bool = true  # 空中冲刺
var dash_count: int = 0
var max_dash_count: int = 1  # 空中最多冲刺次数

func _ready():
	# 设置 floor_check
	floor_check.position = Vector2(0, 20)
	floor_check.target_position = Vector2(0, 10)
	floor_check.enabled = true
	add_child(floor_check)
	
	# 默认启用双跳（如果已解锁）
	if has_permanent_double_jump:
		max_jumps = 2

func _physics_process(delta):
	# 应用重力（支持重力反转）
	var gravity_dir = -1 if gravity_flipped else 1
	if not is_on_floor():
		velocity.y += gravity * delta * gravity_dir
	
	# 处理重力反转冷却
	if gravity_flip_cooldown > 0:
		gravity_flip_cooldown -= delta
	
	# 处理水平移动 - 使用 Input.is_action_pressed 支持多点触控
	var direction: float = 0.0
	
	# 支持多点触控：同时检测左右方向
	if Input.is_action_pressed("move_left"):
		direction -= 1.0
	if Input.is_action_pressed("move_right"):
		direction += 1.0
	
	# 应用移动速度
	velocity.x = direction * speed * speed_multiplier
	
	# 墙壁滑动 (Wall Slide) - 当贴着墙壁时减慢下落速度
	is_on_wall_left = is_on_wall()
	is_on_wall_right = is_on_wall()
	
	# 检测是否在墙壁上
	if can_wall_climb and is_on_wall() and not is_on_floor() and velocity.y > 0:
		is_wall_sliding = true
		velocity.y = min(velocity.y, wall_slide_speed)  # 限制下落速度
	else:
		is_wall_sliding = false
	
	# 🌀 冲刺系统 (Dash)
	handle_dash(delta)
	
	# 处理跳跃
	if Input.is_action_just_pressed("jump"):
		_handle_jump()
	
	# 应用移动
	move_and_slide()
	
	# 重置地面跳跃次数
	if is_on_floor():
		current_jumps = 0
		if has_permanent_double_jump:
			current_jumps = 0  # 重置双跳
	
	# 处理无敌计时器
	if is_invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			is_invincible = false
			modulate = Color.WHITE
	
	# 处理攻击冷却
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	# 处理攻击（检测 J 键或数字键2）
	if Input.is_action_pressed("attack") and attack_cooldown <= 0:
		perform_attack()
	
	# 处理护盾激活（检测 F 键）
	if Input.is_action_pressed("shield"):
		if can_energy_shield and not shield_active and shield_energy >= shield_energy_cost:
			activate_shield()
	
	# 更新护盾状态
	if shield_active:
		shield_duration -= delta
		shield_energy -= shield_energy_cost * delta
		
		# 能量耗尽或时间结束，关闭护盾
		if shield_duration <= 0 or shield_energy <= 0:
			deactivate_shield()
	
	# 更新攻击特效位置和旋转
	if is_attacking and attack_sprite:
		attack_sprite.position = Vector2(20 * facing_direction(), 0)

func facing_direction() -> int:
	# 根据速度方向或朝向确定攻击方向
	if velocity.x > 0:
		return 1
	elif velocity.x < 0:
		return -1
	return 1  # 默认向右

func _handle_jump():
	# 重力反转跳跃 - 可以在空中反转重力
	if can_gravity_flip and gravity_flip_cooldown <= 0:
		# 按跳跃键时如果在空中且按下了方向键，反转重力
		if not is_on_floor():
			var dir = 0
			if Input.is_action_pressed("move_left"): dir -= 1
			if Input.is_action_pressed("move_right"): dir += 1
			if dir != 0:
				flip_gravity()
				return
	
	# 墙壁跳跃 (Wall Jump) - 按跳跃键从墙壁跳开
	if can_wall_climb and is_wall_sliding:
		# 获取墙壁法线方向
		var wall_normal = get_wall_normal()
		velocity = wall_jump_force * wall_normal
		is_wall_sliding = false
		return
	
	# 普通地面跳跃
	if is_on_floor():
		velocity.y = jump_force * (1 if not gravity_flipped else -1)
		current_jumps = 1
	# 双段跳跃
	elif has_permanent_double_jump and current_jumps < max_jumps:
		velocity.y = jump_force * (1 if not gravity_flipped else -1)
		current_jumps += 1

func flip_gravity():
	if gravity_flip_cooldown > 0:
		return
	gravity_flipped = not gravity_flipped
	gravity_flip_cooldown = gravity_flip_cooldown_max
	
	# 视觉反馈 - 颜色变化
	if gravity_flipped:
		modulate = Color(0.5, 0.8, 1, 1)  # 蓝色表示反转
	else:
		modulate = Color.WHITE
	
	# 给一个小初速度帮助玩家适应
	velocity.y = 100 if gravity_flipped else -100
	
	# 创建特效
	spawn_gravity_flip_effect()
	
	# 播放音效（如果有）
	var main = get_tree().get_first_node_in_group("game")
	if main and main.audio_manager:
		# 暂时不调用具体方法，避免报错
		pass

func spawn_gravity_flip_effect():
	var parent = get_parent()
	if parent:
		# 创建环状扩散特效
		for i in range(8):
			var ring = Polygon2D.new()
			var pts = PackedVector2Array()
			for j in range(12):
				var angle = j * TAU / 12
				pts.append(Vector2(cos(angle), sin(angle)) * (20 + i * 10))
			ring.polygon = pts
			ring.color = Color(0.3, 0.7, 1, 0.8)
			ring.position = global_position
			parent.add_child(ring)
			
			var tw = create_tween()
			tw.tween_property(ring, "scale", Vector2(2, 2), 0.4)
			tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.4)
			tw.tween_callback(ring.queue_free)

# 激活无敌
func activate_invincible(duration: float):
	is_invincible = true
	invincible_timer = duration
	modulate = Color(1, 1, 1, 0.5)

# 激活速度提升
func activate_speed_boost(duration: float, multiplier: float = 1.5):
	speed_multiplier = multiplier
	await get_tree().create_timer(duration).timeout
	speed_multiplier = 1.0

# 激活双段跳
func activate_double_jump():
	has_permanent_double_jump = true
	max_jumps = 2
	current_jumps = 0

# 激活地面重击
func activate_ground_slam():
	can_ground_slam = true

# 激活时间减缓
func activate_time_slow():
	can_time_slow = true

# 激活传送
func activate_teleport():
	can_teleport = true

# 激活暗影克隆
func activate_shadow_clone():
	can_shadow_clone = true

# 激活弹跳
func activate_bounce():
	can_bounce = true

# 激活时间倒流
func activate_time_rewind():
	can_time_rewind = true

# 激活能量护盾
func activate_energy_shield_ability():
	can_energy_shield = true

# 护盾状态变量
var shield_active: bool = false
var shield_energy: float = 100.0  # 护盾能量 0-100
var shield_duration: float = 0.0
var shield_sprite: Node2D = null
var shield_max_energy: float = 100.0
var shield_duration_max: float = 3.0  # 护盾持续3秒
var shield_energy_cost: float = 33.0  # 每秒消耗能量

func activate_shield():
	# 护盾激活条件
	if not can_energy_shield:
		return
	if shield_active:
		return
	if shield_energy < shield_energy_cost:
		return
	
	shield_active = true
	shield_duration = shield_duration_max
	shield_energy = shield_max_energy
	
	# 激活无敌
	activate_invincible(shield_duration)
	
	# 创建护盾视觉
	create_shield_visual()

func deactivate_shield():
	shield_active = false
	if shield_sprite:
		shield_sprite.queue_free()
		shield_sprite = null

func create_shield_visual():
	if shield_sprite:
		shield_sprite.queue_free()
	
	shield_sprite = Node2D.new()
	add_child(shield_sprite)
	
	# 创建圆形护盾
	var shield_circle = Polygon2D.new()
	var points = PackedVector2Array()
	var segments = 32
	for i in range(segments):
		var angle = (i as float / segments) * TAU
		points.append(Vector2(cos(angle) * 25, sin(angle) * 25))
	shield_circle.polygon = points
	shield_circle.color = Color(0.3, 0.5, 1, 0.3)  # 蓝色半透明
	shield_circle.width = 3.0
	shield_sprite.add_child(shield_circle)
	
	# 内部光晕
	var inner_glow = Polygon2D.new()
	var inner_points = PackedVector2Array()
	for i in range(segments):
		var angle = (i as float / segments) * TAU
		inner_points.append(Vector2(cos(angle) * 20, sin(angle) * 20))
	inner_glow.polygon = inner_points
	inner_glow.color = Color(0.5, 0.7, 1, 0.15)
	shield_sprite.add_child(inner_glow)
	
	# 动画效果 - 脉冲
	var tw = create_tween()
	tw.set_loops(-1)
	tw.tween_property(shield_sprite, "scale", Vector2(1.1, 1.1), 0.5)
	tw.tween_property(shield_sprite, "scale", Vector2(1.0, 1.0), 0.5)

# 激活相位转移
func activate_phase_shift_ability():
	can_phase_shift = true

# 激活追踪弹
func activate_tracking_projectile_ability():
	can_tracking_projectile = true

# 执行攻击
func perform_attack():
	if attack_cooldown > 0 or is_attacking:
		return
	
	is_attacking = true
	attack_cooldown = attack_cooldown_max
	
	# 创建攻击特效（挥舞的刀光）
	create_attack_effect()
	
	# 短暂无敌时间（攻击时无敌帧）
	activate_invincible(0.15)
	
	# 1秒后清除攻击状态
	await get_tree().create_timer(0.3).timeout
	is_attacking = false
	if attack_sprite:
		attack_sprite.queue_free()
		attack_sprite = null

func create_attack_effect():
	# 清除旧特效
	if attack_sprite:
		attack_sprite.queue_free()
	
	# 创建刀光多边形（弧形）
	var pts = PackedVector2Array()
	var facing = facing_direction()
	
	# 创建弧形刀光
	for i in range(8):
		var angle = (i / 7.0 - 0.5) * 1.2  # -0.6 到 0.6 弧度
		var r = 25 + sin(i * 0.8) * 8  # 弧长变化
		pts.append(Vector2(cos(angle) * r, sin(angle) * r))
	
	attack_sprite = Polygon2D.new()
	attack_sprite.polygon = pts
	attack_sprite.position = Vector2(20 * facing, -5)
	attack_sprite.color = Color(1, 0.9, 0.3, 0.8)  # 金黄色
	
	# 发光效果
	attack_sprite.modulate = Color(1, 1, 0.5, 1)
	
	add_child(attack_sprite)
	
	# 刀光动画：快速收缩消失
	var tw = create_tween()
	tw.tween_property(attack_sprite, "scale", Vector2(1.5, 1.5), 0.1)
	tw.parallel().tween_property(attack_sprite, "modulate:a", 0.0, 0.25)
	
	# 创建攻击检测区域
	create_attack_hitbox(facing)

func create_attack_hitbox(facing: int):
	# 移除旧的 hitbox
	if attack_hitbox and is_instance_valid(attack_hitbox):
		attack_hitbox.queue_free()
	
	attack_hitbox = Area2D.new()
	attack_hitbox.position = Vector2(30 * facing, -5)
	attack_hitbox.monitoring = true
	attack_hitbox.monitorable = true
	
	# 创建碰撞形状
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(40, 30)
	col.shape = shape
	attack_hitbox.add_child(col)
	
	add_child(attack_hitbox)
	
	# 连接碰撞信号
	attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered)
	
	# 0.3秒后移除 hitbox
	await get_tree().create_timer(0.3).timeout
	if attack_hitbox and is_instance_valid(attack_hitbox):
		attack_hitbox.queue_free()
		attack_hitbox = null

func _on_attack_hitbox_body_entered(body: Node):
	# 检查是否击中敌人
	if body.is_in_group("enemy"):
		# 造成伤害
		if body.has_method("take_damage"):
			body.take_damage(attack_damage)
		
		# 击退效果
		if body.has_method("knockback"):
			var knock_dir = (body.global_position - global_position).normalized()
			body.knockback(knock_dir * 300)
		
		# 显示击中特效
		spawn_hit_effect(body.global_position)
		
		# 播报击中：通知主游戏记录 combo
		var main = get_tree().get_first_node_in_group("game")
		if main and main.has_method("on_player_attack_hit"):
			main.on_player_attack_hit()

func spawn_hit_effect(pos: Vector2):
	# 在击中位置产生火花效果
	var parent = get_parent()
	if parent:
		for i in range(6):
			var spark = Polygon2D.new()
			spark.polygon = PackedVector2Array([Vector2(-2, 0), Vector2(0, -3), Vector2(2, 0), Vector2(0, 3)])
			spark.color = Color(1, 0.8, 0.2, 1)
			spark.position = pos + Vector2(randf_range(-5, 5), randf_range(-5, 5))
			parent.add_child(spark)
			
			var tw = create_tween()
			var angle = randf() * TAU
			var dist = randf_range(15, 30)
			tw.tween_property(spark, "position", pos + Vector2(cos(angle), sin(angle)) * dist, 0.25)
			tw.parallel().tween_property(spark, "modulate:a", 0.0, 0.25)
			tw.tween_callback(spark.queue_free)
