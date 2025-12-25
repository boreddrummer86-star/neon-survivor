## CameraController - Smooth following camera with shake effects
## Follows the player with smoothing and provides screen shake
class_name CameraController
extends Camera2D

# Follow settings
@export_group("Follow Settings")
@export var follow_smoothing: float = 5.0
@export var look_ahead_distance: float = 50.0
@export var look_ahead_smoothing: float = 3.0

# Shake settings
@export_group("Shake Settings")
@export var max_shake_offset: float = 20.0
@export var shake_decay_rate: float = 5.0

# Target
var target: Node2D = null
var target_offset: Vector2 = Vector2.ZERO
var look_ahead_offset: Vector2 = Vector2.ZERO

# Shake state
var shake_intensity: float = 0.0
var shake_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Find player as initial target
	await get_tree().process_frame
	target = GameManager.player


func _process(delta: float) -> void:
	if target and is_instance_valid(target):
		_update_follow(delta)
		_update_look_ahead(delta)
		_update_shake(delta)

		# Apply final position
		global_position = target.global_position + target_offset + look_ahead_offset + shake_offset


func _update_follow(delta: float) -> void:
	# Smooth follow (already handled by setting position directly)
	pass


func _update_look_ahead(delta: float) -> void:
	if target is CharacterBody2D:
		var velocity := (target as CharacterBody2D).velocity
		var desired_offset := velocity.normalized() * look_ahead_distance

		look_ahead_offset = look_ahead_offset.lerp(desired_offset, look_ahead_smoothing * delta)


func _update_shake(delta: float) -> void:
	if shake_intensity > 0:
		# Random shake offset
		shake_offset = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * shake_intensity * max_shake_offset

		# Decay shake
		shake_intensity = maxf(0.0, shake_intensity - shake_decay_rate * delta)
	else:
		shake_offset = Vector2.ZERO


## Trigger a camera shake effect
func shake(intensity: float = 1.0) -> void:
	shake_intensity = clampf(intensity, 0.0, 1.0)


## Set the camera follow target
func set_target(new_target: Node2D) -> void:
	target = new_target


## Set an offset from the target
func set_target_offset(offset: Vector2) -> void:
	target_offset = offset
