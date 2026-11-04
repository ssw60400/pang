extends CharacterBody2D

signal enemy_destroyed(enemy)

@export var speed: float = 50.0

var player: CharacterBody2D
var push_dir: Vector2 = Vector2(0, 0)
var push_strength: float = 0.0
var push_timer: float = 0.0

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var damage_text: Label = $DamageTextContainer/DamageText
@onready var anime_state_machine = animation_tree["parameters/playback"]
@onready var blood_particle = preload("res://scenes/blood_particle.tscn")
@export var max_health: int = 100
var health: int = 0

@onready var life_bar: ProgressBar = $LifeBar
func _ready():
	damage_text.visible = false
	max_health = maxi(1, max_health)
	health = max_health
	update_life_bar()


func update_life_bar():
	life_bar.min_value = 0
	life_bar.max_value = max_health
	life_bar.value = health
func setup(pos: Vector2, _player: CharacterBody2D):
	position = pos
	player = _player
	add_collision_exception_with(player)#asdf
	player.add_collision_exception_with(self)#asdf

func _physics_process(delta):
	var dir = (player.global_position - global_position).normalized()
	position += dir * delta * speed
	# Handle push
	push_back(delta)

func get_hit(damage: int, bullet_trans: Transform2D):
	health = maxi(health - damage, 0)
	update_life_bar()
	damage_text.text = str(damage)
	animation_tree['parameters/conditions/is_damaged'] = true
	if health <= 0:
		animation_tree['parameters/conditions/is_destroyed'] = true
	# Bleeding effect
	var bleeding_effect = blood_particle.instantiate()
	get_tree().root.add_child(bleeding_effect)
	bleeding_effect.setup(bullet_trans)
	set_push(Vector2.RIGHT.rotated(bullet_trans.get_rotation()), 150.0, 0.1)

func destroy():
	enemy_destroyed.emit(self)
	queue_free()

func set_push(dir: Vector2, strength: float, timer: float):
	push_dir = -dir
	push_strength = strength
	push_timer = timer

func push_back(delta: float):
	if push_timer > 0.0:
		position -= push_dir * push_strength * delta
		push_timer -= delta
	else:
		push_timer = 0.0

func _on_animation_tree_animation_finished(_anim_name):
	if anime_state_machine.get_current_node() == "get_damage":
		anime_state_machine.travel("move")
		animation_tree['parameters/conditions/is_damaged'] = false
	elif anime_state_machine.get_current_node() == "destroy":
		animation_tree['parameters/conditions/is_destroyed'] = false
		destroy()

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "destroy":
		#animation_tree['parameters/conditions/is_destroyed'] = false
		pass
