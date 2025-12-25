## EnemySpawner - Handles wave-based enemy spawning
## Manages spawn patterns, difficulty scaling, and enemy variety
class_name EnemySpawner
extends Node2D

# Spawn settings
@export_group("Spawn Settings")
@export var base_spawn_interval: float = 2.0
@export var min_spawn_interval: float = 0.3
@export var spawn_distance: float = 600.0
@export var max_enemies: int = 100

# Enemy scenes
@export_group("Enemy Types")
@export var basic_enemy_scene: PackedScene
@export var fast_enemy_scene: PackedScene
@export var tank_enemy_scene: PackedScene

# Internal state
var spawn_timer: float = 0.0
var active_enemies: Array[Node2D] = []
var enemies_spawned: int = 0

# Spawn weights (change over time)
var enemy_weights: Dictionary = {
	"basic": 1.0,
	"fast": 0.0,
	"tank": 0.0
}


func _ready() -> void:
	# Load default enemy scene if not set
	if basic_enemy_scene == null:
		basic_enemy_scene = load("res://scenes/entities/enemy_basic.tscn")

	# Connect to events
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.wave_started.connect(_on_wave_started)


func _process(delta: float) -> void:
	if not GameManager.is_playing():
		return

	spawn_timer -= delta

	if spawn_timer <= 0.0:
		_spawn_enemy()
		spawn_timer = _get_spawn_interval()


func _spawn_enemy() -> void:
	if active_enemies.size() >= max_enemies:
		return

	if GameManager.player == null:
		return

	# Choose enemy type based on weights
	var enemy_scene := _choose_enemy_scene()
	if enemy_scene == null:
		return

	# Calculate spawn position around player
	var spawn_pos := _get_spawn_position()

	# Instance and add enemy
	var enemy := enemy_scene.instantiate() as Node2D
	enemy.global_position = spawn_pos
	get_tree().current_scene.add_child(enemy)

	active_enemies.append(enemy)
	enemies_spawned += 1


func _choose_enemy_scene() -> PackedScene:
	var total_weight: float = 0.0
	for weight in enemy_weights.values():
		total_weight += weight

	var roll := randf() * total_weight
	var current_weight: float = 0.0

	for enemy_type in enemy_weights.keys():
		current_weight += enemy_weights[enemy_type]
		if roll <= current_weight:
			match enemy_type:
				"basic":
					return basic_enemy_scene
				"fast":
					return fast_enemy_scene if fast_enemy_scene else basic_enemy_scene
				"tank":
					return tank_enemy_scene if tank_enemy_scene else basic_enemy_scene

	return basic_enemy_scene


func _get_spawn_position() -> Vector2:
	var player_pos := GameManager.player.global_position

	# Random angle
	var angle := randf() * TAU

	# Spawn at distance with some variance
	var distance := spawn_distance + randf_range(-50.0, 100.0)

	return player_pos + Vector2.from_angle(angle) * distance


func _get_spawn_interval() -> float:
	var interval := base_spawn_interval / GameManager.enemy_spawn_rate_multiplier
	return maxf(interval, min_spawn_interval)


func _on_enemy_died(enemy: Node2D, _position: Vector2) -> void:
	active_enemies.erase(enemy)


func _on_wave_started(wave_number: int) -> void:
	# Update enemy variety based on wave
	if wave_number >= 2:
		enemy_weights["fast"] = 0.3
	if wave_number >= 3:
		enemy_weights["tank"] = 0.2
	if wave_number >= 5:
		enemy_weights["fast"] = 0.4
		enemy_weights["tank"] = 0.3

	# Spawn burst of enemies for new wave
	for i in range(wave_number * 2):
		call_deferred("_spawn_enemy")


## Get count of active enemies
func get_enemy_count() -> int:
	return active_enemies.size()


## Clear all enemies (for game restart)
func clear_all_enemies() -> void:
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()
