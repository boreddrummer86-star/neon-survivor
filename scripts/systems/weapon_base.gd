## WeaponBase - Base class for all weapon types
## Provides common functionality for firing, cooldowns, and upgrades
class_name WeaponBase
extends Node2D

# Weapon stats
@export_group("Base Stats")
@export var weapon_name: String = "Weapon"
@export var base_damage: float = 10.0
@export var base_cooldown: float = 1.0
@export var base_projectile_count: int = 1
@export var base_projectile_speed: float = 500.0
@export var base_range: float = 500.0
@export var base_knockback: float = 100.0

# Upgrade levels
var level: int = 1
var max_level: int = 8

# Stat multipliers (from upgrades)
var damage_multiplier: float = 1.0
var cooldown_multiplier: float = 1.0
var projectile_count_bonus: int = 0
var speed_multiplier: float = 1.0
var range_multiplier: float = 1.0

# Cooldown tracking
var cooldown_timer: float = 0.0
var can_fire: bool = true

# References
var owner_node: Node2D = null
@onready var projectile_scene: PackedScene = preload("res://scenes/weapons/projectile.tscn")


func _ready() -> void:
	owner_node = get_parent().get_parent() as Node2D  # WeaponMount -> Player


func _process(delta: float) -> void:
	if not can_fire:
		cooldown_timer -= delta
		if cooldown_timer <= 0.0:
			can_fire = true

	if can_fire and GameManager.is_playing():
		_attempt_fire()


## Override in subclasses for specific firing behavior
func _attempt_fire() -> void:
	var target := _find_target()
	if target:
		fire(target.global_position)


## Fire the weapon toward a target position
func fire(target_position: Vector2) -> void:
	can_fire = false
	cooldown_timer = get_cooldown()

	var projectile_count := get_projectile_count()

	for i in range(projectile_count):
		_spawn_projectile(target_position, i, projectile_count)


## Spawn a single projectile
func _spawn_projectile(target_position: Vector2, index: int, total: int) -> void:
	if projectile_scene == null:
		return

	var projectile := projectile_scene.instantiate() as Node2D
	projectile.global_position = global_position

	# Calculate direction with spread for multiple projectiles
	var base_direction := global_position.direction_to(target_position)
	var spread_angle := 0.0

	if total > 1:
		var spread_range := deg_to_rad(30.0)  # Total spread angle
		spread_angle = -spread_range / 2.0 + (spread_range / (total - 1)) * index

	var direction := base_direction.rotated(spread_angle)

	# Set projectile properties
	if projectile.has_method("setup"):
		projectile.setup(direction, get_damage(), get_speed(), get_range(), get_knockback())

	get_tree().current_scene.add_child(projectile)


## Find the nearest enemy target
func _find_target() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist := get_range()

	for enemy in enemies:
		if not enemy is Node2D:
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	return nearest


## Upgrade the weapon
func upgrade() -> bool:
	if level >= max_level:
		return false

	level += 1
	_apply_level_bonus()
	return true


## Apply bonuses based on current level
func _apply_level_bonus() -> void:
	match level:
		2:
			damage_multiplier += 0.2
		3:
			projectile_count_bonus += 1
		4:
			cooldown_multiplier -= 0.1
		5:
			damage_multiplier += 0.3
		6:
			projectile_count_bonus += 1
		7:
			speed_multiplier += 0.3
		8:
			damage_multiplier += 0.5
			projectile_count_bonus += 1


# Stat getters
func get_damage() -> float:
	var player_mult := 1.0
	if owner_node and owner_node.has_method("get") and "damage_multiplier" in owner_node:
		player_mult = owner_node.damage_multiplier
	return base_damage * damage_multiplier * player_mult


func get_cooldown() -> float:
	return base_cooldown * cooldown_multiplier


func get_projectile_count() -> int:
	return base_projectile_count + projectile_count_bonus


func get_speed() -> float:
	return base_projectile_speed * speed_multiplier


func get_range() -> float:
	return base_range * range_multiplier


func get_knockback() -> float:
	return base_knockback
