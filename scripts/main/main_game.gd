## MainGame - Main game scene controller
## Initializes the game and manages core game loop
class_name MainGame
extends Node2D

# Scene references
@export var player_scene: PackedScene
@export var basic_weapon_scene: PackedScene

# Node references
@onready var world: Node2D = $World
@onready var camera: Camera2D = $Camera2D
@onready var enemy_spawner: Node2D = $EnemySpawner
@onready var game_ui: CanvasLayer = $GameUI
@onready var game_over_ui: CanvasLayer = $GameOverUI
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var background: ColorRect = $Background

# Player reference
var player: Node2D = null


func _ready() -> void:
	# Load scenes if not set
	if player_scene == null:
		player_scene = load("res://scenes/entities/player.tscn")
	if basic_weapon_scene == null:
		basic_weapon_scene = load("res://scenes/weapons/basic_weapon.tscn")

	# Spawn player
	_spawn_player()

	# Setup camera
	_setup_camera()

	# Give player starting weapon
	_give_starting_weapon()

	# Start the game
	GameManager.start_game()

	# Connect events
	EventBus.player_died.connect(_on_player_died)


func _spawn_player() -> void:
	if player_scene == null:
		push_error("Player scene not set!")
		return

	player = player_scene.instantiate()
	player.global_position = Vector2.ZERO
	world.add_child(player)


func _setup_camera() -> void:
	if camera and player:
		if camera is CameraController:
			(camera as CameraController).set_target(player)
		else:
			# If using regular Camera2D, just center on player
			camera.global_position = player.global_position


func _give_starting_weapon() -> void:
	if basic_weapon_scene == null or player == null:
		return

	var weapon := basic_weapon_scene.instantiate()
	var weapon_mount := player.get_node_or_null("WeaponMount")

	if weapon_mount:
		weapon_mount.add_child(weapon)


func _on_player_died() -> void:
	# Camera shake on death
	if camera is CameraController:
		(camera as CameraController).shake(1.0)


func _process(_delta: float) -> void:
	# Update background position to follow camera for endless feel
	if background and camera:
		background.global_position = camera.global_position - background.size / 2


## Restart the game
func restart() -> void:
	get_tree().reload_current_scene()
