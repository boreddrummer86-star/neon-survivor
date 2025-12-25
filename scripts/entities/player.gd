## Player - Main player character controller
## Handles movement, health, experience, and level progression
class_name Player
extends CharacterBody2D

# Movement settings
@export_group("Movement")
@export var base_speed: float = 300.0
@export var acceleration: float = 2000.0
@export var friction: float = 1500.0

# Health settings
@export_group("Health")
@export var max_health: float = 100.0
@export var health_regen: float = 0.0
@export var invincibility_duration: float = 0.5

# Experience settings
@export_group("Experience")
@export var base_xp_required: int = 10
@export var xp_scaling: float = 1.5

# Current stats
var current_health: float
var current_level: int = 1
var current_xp: int = 0
var xp_required: int

# Stat modifiers (from upgrades)
var speed_multiplier: float = 1.0
var damage_multiplier: float = 1.0
var pickup_range_multiplier: float = 1.0
var health_multiplier: float = 1.0

# State
var is_invincible: bool = false
var is_alive: bool = true

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var pickup_area: Area2D = $PickupArea
@onready var hitbox: Area2D = $Hitbox
@onready var weapon_mount: Node2D = $WeaponMount
@onready var invincibility_timer: Timer = $InvincibilityTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	# Initialize health
	current_health = max_health * health_multiplier
	xp_required = base_xp_required

	# Register with GameManager
	GameManager.player = self

	# Connect signals
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	pickup_area.area_entered.connect(_on_pickup_area_entered)
	invincibility_timer.timeout.connect(_on_invincibility_timeout)

	# Emit initial health
	EventBus.player_health_changed.emit(current_health, get_max_health())


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Get input direction
	var input_dir := _get_input_direction()

	# Apply movement
	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * get_speed(), acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()

	# Update sprite direction
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

	# Apply health regeneration
	if health_regen > 0:
		heal(health_regen * delta)


func _get_input_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()


## Take damage from an enemy or hazard
func take_damage(amount: float) -> void:
	if is_invincible or not is_alive:
		return

	current_health -= amount
	current_health = maxf(current_health, 0.0)

	EventBus.player_health_changed.emit(current_health, get_max_health())
	EventBus.show_damage_number.emit(global_position, amount, false)

	# Start invincibility
	is_invincible = true
	invincibility_timer.start(invincibility_duration)

	# Play hurt animation
	if animation_player.has_animation("hurt"):
		animation_player.play("hurt")
	else:
		_flash_sprite()

	# Check for death
	if current_health <= 0:
		die()


## Heal the player
func heal(amount: float) -> void:
	if not is_alive:
		return

	var old_health := current_health
	current_health = minf(current_health + amount, get_max_health())

	if current_health != old_health:
		EventBus.player_health_changed.emit(current_health, get_max_health())


## Add experience points
func add_xp(amount: int) -> void:
	current_xp += amount
	EventBus.player_xp_gained.emit(amount, current_xp, xp_required)

	# Check for level up
	while current_xp >= xp_required:
		level_up()


## Level up the player
func level_up() -> void:
	current_xp -= xp_required
	current_level += 1
	xp_required = int(base_xp_required * pow(xp_scaling, current_level - 1))

	EventBus.player_level_up.emit(current_level)

	# Heal on level up
	heal(get_max_health() * 0.1)


## Handle player death
func die() -> void:
	is_alive = false
	velocity = Vector2.ZERO

	if animation_player.has_animation("death"):
		animation_player.play("death")

	EventBus.player_died.emit()


## Get current effective speed
func get_speed() -> float:
	return base_speed * speed_multiplier


## Get current effective max health
func get_max_health() -> float:
	return max_health * health_multiplier


## Get current effective pickup range
func get_pickup_range() -> float:
	return 100.0 * pickup_range_multiplier


## Flash sprite when hit
func _flash_sprite() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3), 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_attack"):
		var damage := area.get_meta("damage", 10.0) as float
		take_damage(damage * GameManager.enemy_damage_multiplier)


func _on_pickup_area_entered(area: Area2D) -> void:
	if area.is_in_group("pickups"):
		if area.has_method("collect"):
			area.collect(self)


func _on_invincibility_timeout() -> void:
	is_invincible = false
	sprite.modulate = Color.WHITE


## Apply a stat upgrade
func apply_upgrade(upgrade_id: String, value: float) -> void:
	match upgrade_id:
		"speed":
			speed_multiplier += value
		"damage":
			damage_multiplier += value
		"health":
			health_multiplier += value
			current_health += max_health * value
		"pickup_range":
			pickup_range_multiplier += value
			_update_pickup_range()
		"regen":
			health_regen += value


func _update_pickup_range() -> void:
	var shape := pickup_area.get_node("CollisionShape2D") as CollisionShape2D
	if shape and shape.shape is CircleShape2D:
		(shape.shape as CircleShape2D).radius = get_pickup_range()
