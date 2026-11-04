extends CharacterBody2D

@export var speed: float = 360.0
@export var lr_flag: bool = true # Enable body left right animation
@export var rotate_flag: bool = true # Enable body rotation 

var screen_size # Size of the game window.
var lr: bool = true # Default face right
var aim_pos: Vector2 = Vector2(0, 0)
var is_shot_cd: bool = false
var push_dir: Vector2 = Vector2(0, 0)
var push_strength: float = 0.0
var push_timer: float = 0.0
@export var max_lives: int = 3
@export var invincible_seconds: float = 1.0

var lives: int = 0
var is_invincible: bool = false

@onready var life_label: Label = $LifeLabel

# Reference
@onready var body_lr: Polygon2D = $BodyLR
@onready var body_rotate: Polygon2D = $BodyRotate
@onready var body_lr_player: AnimationPlayer = $BodyLRPlayer
@onready var body_rotete_player: AnimationPlayer = $BodyRotatePlayer
@onready var move_trail_effect: GPUParticles2D = $MovementTrailEffect
@onready var bullet_scene = preload("res://scenes/bullet.tscn")
@onready var bullet_spawn_pos: Node2D = $BodyRotate/BulletSpawnPoint
@onready var shot_timer: Timer = $ShotTimer
@onready var shot_effect: GPUParticles2D = $BodyRotate/ShootingEffect
@onready var body_lr_collider: CollisionPolygon2D = $CollisionBodyLR
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready():
	screen_size = get_viewport_rect().size
	max_lives = maxi(1, max_lives)
	lives = max_lives
	update_life_label()
	hide()

func update_life_label():
	life_label.text = "%d / %d" % [lives, max_lives]

func _physics_process(delta):
	velocity = Vector2.ZERO # The player's movement vector.
	# Movement input
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1
	# Shot input
	if Input.is_action_pressed("shot") and not is_shot_cd:
		shoot()
		is_shot_cd = true
		shot_timer.start(0.2)
	# Normalize velocity if move along x and y together
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		move_trail_effect.emitting = true # Play movement trail effect
	# Handle body_lr
	update_body_lr()
	# Handle push
	push_back(delta)
	# Limit the player movement, add your character scale if needed
	#position.x = clamp(position.x, 0, screen_size.x)
	#position.y = clamp(position.y, 0, screen_size.y)
	move_and_slide()

		
func _input(event):
	if event is InputEventMouseMotion:
		update_body_rotate(get_global_mouse_position())

func setup(pos: Vector2):
	position = pos
	show()

func update_body_lr():
	if not lr_flag:
		return
	# Play body animation
	if velocity.length() > 0:
		# Move up / down
		if lr:
			body_lr_player.play("MoveR")
		else:
			body_lr_player.play("MoveL")
		# Move left / right
		if velocity.x > 0:
			body_lr_player.play("MoveR")
			body_lr_collider.scale.x = -1
			lr = true
		elif velocity.x < 0:
			body_lr_player.play("MoveL")
			body_lr_collider.scale.x = 1
			lr = false
	else:
		# Idle
		if lr:
			body_lr_player.play("IdleR")
		else:
			body_lr_player.play("IdleL")
	
func update_body_rotate(mouse_pos: Vector2):
	if not rotate_flag:
		return

	body_rotate.look_at(mouse_pos)
	aim_pos = (mouse_pos - global_position).normalized()

func shoot():
	body_rotete_player.play("Shot")
	var bullet = bullet_scene.instantiate()
	bullet.setup(bullet_spawn_pos.global_transform)
	get_tree().root.add_child(bullet)
	shot_effect.emitting = true
	set_push(Vector2.RIGHT.rotated(body_rotate.rotation), 200.0, 0.2)
	# Play shoot sound
	audio_player.play()

func set_push(dir: Vector2, strength: float, timer: float):
	push_dir = dir
	push_strength = strength
	push_timer = timer

func push_back(delta: float):
	if push_timer > 0.0:
		position -= push_dir * push_strength * delta
		push_timer -= delta
	else:
		push_timer = 0.0

func _on_shot_timer_timeout():
	is_shot_cd = false
	
func _on_hit_area_body_entered(body: Node2D) -> void: #asdf
	if body.is_in_group("enemy"):
		take_damage()

func take_damage():
	# 무적 상태이거나 이미 죽었으면 피해를 받지 않음
	if is_invincible or lives <= 0:
		return
	lives -= 1
	update_life_label()

	# 라이프 표시용 Label이 있으면 갱신
	var label = get_parent().get_node_or_null("CanvasLayer/LifeLabel")
	if label != null:
		label.text = "라이프: %d" % lives

	if lives <= 0:
		get_parent().game_over()
		return

	# 무적 시작: 플레이어를 반투명하게 표시
	is_invincible = true
	modulate.a = 0.4

	await get_tree().create_timer(invincible_seconds, false).timeout

	# 무적 종료
	is_invincible = false
	modulate.a = 1.0

	# 무적이 끝났는데도 적과 겹쳐 있으면 다시 피해를 받음
	for body in $HitArea.get_overlapping_bodies():
		if body.is_in_group("enemy"):
			take_damage()
			break
func set_max_lives(new_max: int, refill: bool = false):
	max_lives = maxi(1, new_max)

	if refill:
		lives = max_lives
	else:
		lives = mini(lives, max_lives)

	update_life_label()
