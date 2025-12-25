## Projectile - Base projectile that damages enemies on contact
## Handles movement, collision, and damage application
class_name Projectile
extends Area2D

# Projectile stats (set via setup())
var direction: Vector2 = Vector2.RIGHT
var damage: float = 10.0
var speed: float = 500.0
var max_range: float = 500.0
var knockback: float = 100.0

# Piercing
@export var pierce_count: int = 0
var pierced_enemies: Array[Node2D] = []

# State
var distance_traveled: float = 0.0
var is_active: bool = true

# Visual
@export var projectile_color: Color = Color(0, 1, 1, 1)

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("player_attack")
	set_meta("damage", damage)
	set_meta("knockback", knockback)

	# Set visual
	if sprite:
		sprite.modulate = projectile_color
		# Rotate sprite to face direction
		sprite.rotation = direction.angle()

	# Connect collision
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if not is_active:
		return

	# Move
	var movement := direction * speed * delta
	global_position += movement
	distance_traveled += movement.length()

	# Check range
	if distance_traveled >= max_range:
		destroy()


## Setup the projectile with stats
func setup(dir: Vector2, dmg: float, spd: float, rng: float, kb: float = 100.0) -> void:
	direction = dir.normalized()
	damage = dmg
	speed = spd
	max_range = rng
	knockback = kb

	set_meta("damage", damage)
	set_meta("knockback", knockback)


## Handle hitting an enemy
func _on_area_entered(area: Area2D) -> void:
	if not is_active:
		return

	var parent := area.get_parent()
	if parent and parent.is_in_group("enemies"):
		_hit_enemy(parent)


func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return

	if body.is_in_group("enemies"):
		_hit_enemy(body)
	elif body.is_in_group("walls"):
		destroy()


func _hit_enemy(enemy: Node2D) -> void:
	# Check if already pierced this enemy
	if enemy in pierced_enemies:
		return

	pierced_enemies.append(enemy)

	# Apply damage
	if enemy.has_method("take_damage"):
		var kb_force := direction * knockback
		enemy.take_damage(damage, kb_force)

	# Check pierce
	if pierced_enemies.size() > pierce_count:
		destroy()


## Destroy the projectile
func destroy() -> void:
	if not is_active:
		return

	is_active = false
	collision_shape.set_deferred("disabled", true)

	# Fade out
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.1)
	tween.tween_callback(queue_free)
