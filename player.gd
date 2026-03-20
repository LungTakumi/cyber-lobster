extends CharacterBody2D

# 玩家移动脚本 - 支持键盘和虚拟按钮（多点触控）

# 移动参数
var speed: float = 300.0
var jump_force: float = -450.0
var gravity: float = 980.0
var speed_multiplier: float = 1.0

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

# 状态
var is_invincible: bool = false
var invincible_timer: float = 0.0

# 地面检测
@onready var floor_check: RayCast2D = RayCast2D.new()

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
	# 应用重力
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# 处理水平移动 - 使用 Input.is_action_pressed 支持多点触控
	var direction: float = 0.0
	
	# 支持多点触控：同时检测左右方向
	if Input.is_action_pressed("move_left"):
		direction -= 1.0
	if Input.is_action_pressed("move_right"):
		direction += 1.0
	
	# 应用移动速度
	velocity.x = direction * speed * speed_multiplier
	
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

func _handle_jump():
	if is_on_floor():
		velocity.y = jump_force
		current_jumps = 1
	elif has_permanent_double_jump and current_jumps < max_jumps:
		velocity.y = jump_force
		current_jumps += 1

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