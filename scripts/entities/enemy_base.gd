## EnemyBase - Base class for all enemy types
## Provides common functionality for AI, health, and combat
class_name EnemyBase
extends CharacterBody2D

# Enemy stats
@export_group("Stats")
@export var max_health: float = 30.0
@export var base_speed: float = 100.0
@export var contact_damage: float = 10.0
@export var xp_value: int = 5
@export var score_value: int = 10

# Visual settings
@export_group("Visual")
@export var enemy_color: Color = Color(1, 0, 0.5)
@export var death_particles: PackedScene

# State
var current_health: float
var is_alive: bool = true
var target: Node2D = null

# Knockback
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_resistance: float = 0.8

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox
@onready var attack_area: Area2D = $AttackArea


func _ready() -> void:
	# Apply difficulty scaling
	max_health *= GameManager.enemy_health_multiplier
	contact_damage *= GameManager.enemy_damage_multiplier

	current_health = max_health

	# Set visual color
	if sprite:
		sprite.modulate = enemy_color

	# Set up attack area
	if attack_area:
		attack_area.set_meta("damage", contact_damage)

	# Find player target
	target = GameManager.player

	# Add to groups
	add_to_group("enemies")

	# Connect signals
	if hitbox:
		hitbox.area_entered.connect(_on_hitbox_area_entered)

	# Emit spawn signal
	EventBus.enemy_spawned.emit(self)


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Process AI
	_update_ai(delta)

	# Apply knockback
	if knockback_velocity.length() > 10.0:
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_resistance * delta * 10.0)

	# Move
	move_and_slide()

	# Face movement direction
	if velocity.x != 0 and sprite:
		sprite.flip_h = velocity.x < 0


## Override in subclasses for specific AI behavior
func _update_ai(delta: float) -> void:
	if target and is_instance_valid(target):
		var direction := global_position.direction_to(target.global_position)
		velocity = (direction * get_speed() + knockback_velocity)


## Take damage from a weapon or hazard
func take_damage(amount: float, knockback_force: Vector2 = Vector2.ZERO) -> void:
	if not is_alive:
		return

	current_health -= amount
	current_health = maxf(current_health, 0.0)

	EventBus.enemy_damaged.emit(self, amount)
	EventBus.show_damage_number.emit(global_position, amount, amount > max_health * 0.3)

	# Apply knockback
	knockback_velocity += knockback_force

	# Flash effect
	_flash_damage()

	# Check for death
	if current_health <= 0:
		die()


## Handle enemy death
func die() -> void:
	if not is_alive:
		return

	is_alive = false
	velocity = Vector2.ZERO

	# Disable collision
	collision_shape.set_deferred("disabled", true)
	if hitbox:
		hitbox.set_deferred("monitoring", false)
	if attack_area:
		attack_area.set_deferred("monitoring", false)

	# Emit signals
	EventBus.enemy_died.emit(self, global_position)

	# Spawn XP orb
	_spawn_xp_orb()

	# Death animation
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.1)
	tween.tween_callback(queue_free)


## Get current speed with any modifiers
func get_speed() -> float:
	return base_speed


## Spawn an XP orb at death position
func _spawn_xp_orb() -> void:
	var xp_orb_scene := load("res://scenes/entities/xp_orb.tscn") as PackedScene
	if xp_orb_scene:
		var orb := xp_orb_scene.instantiate()
		orb.global_position = global_position
		orb.xp_value = xp_value
		get_tree().current_scene.add_child(orb)


## Flash red when taking damage
func _flash_damage() -> void:
	if sprite:
		var original_color := sprite.modulate
		sprite.modulate = Color.WHITE
		await get_tree().create_timer(0.05).timeout
		if is_instance_valid(self) and is_alive:
			sprite.modulate = original_color


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_attack"):
		var damage := area.get_meta("damage", 10.0) as float
		var knockback := Vector2.ZERO
		if area.has_meta("knockback"):
			knockback = global_position.direction_to(area.global_position).normalized() * -area.get_meta("knockback", 0.0)
		take_damage(damage, knockback)


## Apply a status effect
func apply_status(status_id: String, duration: float, potency: float = 1.0) -> void:
	match status_id:
		"slow":
			var original_speed := base_speed
			base_speed *= (1.0 - potency * 0.5)
			await get_tree().create_timer(duration).timeout
			if is_instance_valid(self):
				base_speed = original_speed
		"burn":
			for i in range(int(duration)):
				if is_instance_valid(self) and is_alive:
					take_damage(potency * 5.0)
					await get_tree().create_timer(1.0).timeout
