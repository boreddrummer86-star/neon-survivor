## XPOrb - Collectible experience orb dropped by enemies
## Moves toward player when in range and grants XP on collection
class_name XPOrb
extends Area2D

# XP value
@export var xp_value: int = 5

# Movement settings
@export var attraction_speed: float = 400.0
@export var max_attraction_speed: float = 800.0
@export var acceleration: float = 1200.0

# Visual settings
@export var orb_color: Color = Color(0, 1, 0.8, 1)
@export var glow_intensity: float = 1.5

# State
var velocity: Vector2 = Vector2.ZERO
var is_attracted: bool = false
var target: Node2D = null

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("pickups")

	# Set visual
	if sprite:
		sprite.modulate = orb_color

	# Connect signals
	body_entered.connect(_on_body_entered)

	# Spawn animation
	_play_spawn_animation()


func _physics_process(delta: float) -> void:
	if is_attracted and target and is_instance_valid(target):
		# Accelerate toward target
		var direction := global_position.direction_to(target.global_position)
		velocity += direction * acceleration * delta
		velocity = velocity.limit_length(max_attraction_speed)

		global_position += velocity * delta

		# Check if close enough to collect
		if global_position.distance_to(target.global_position) < 20.0:
			collect(target)
	elif target and is_instance_valid(target):
		# Check if within pickup range
		var distance := global_position.distance_to(target.global_position)
		if distance <= target.get_pickup_range():
			is_attracted = true


func _process(_delta: float) -> void:
	# Find player if not set
	if target == null:
		target = GameManager.player

	# Pulsing glow effect
	if sprite:
		var pulse := (sin(Time.get_ticks_msec() * 0.01) + 1.0) * 0.5
		sprite.modulate.a = 0.7 + pulse * 0.3


## Collect this orb
func collect(collector: Node2D) -> void:
	if collector.has_method("add_xp"):
		collector.add_xp(xp_value)

	EventBus.xp_orb_collected.emit(xp_value)

	# Collection effect
	_play_collect_animation()


func _play_spawn_animation() -> void:
	if sprite:
		sprite.scale = Vector2.ZERO
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(sprite, "scale", Vector2.ONE * 0.3, 0.3)


func _play_collect_animation() -> void:
	# Disable collision immediately
	collision_shape.set_deferred("disabled", true)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.15)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect(body)
