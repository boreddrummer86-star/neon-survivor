## GameManager - Central game state and flow controller
## Handles game states, scoring, difficulty scaling, and persistence
class_name GameManagerClass
extends Node

# Game states enum
enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
	LEVEL_UP
}

# Current game state
var current_state: GameState = GameState.MENU

# Game statistics
var score: int = 0
var kill_count: int = 0
var survival_time: float = 0.0
var current_wave: int = 1

# Difficulty scaling
var difficulty_multiplier: float = 1.0
var enemy_spawn_rate_multiplier: float = 1.0
var enemy_health_multiplier: float = 1.0
var enemy_damage_multiplier: float = 1.0

# Time tracking
var _game_timer: float = 0.0
var _difficulty_timer: float = 0.0
const DIFFICULTY_INCREASE_INTERVAL: float = 30.0
const DIFFICULTY_INCREASE_AMOUNT: float = 0.1

# Player reference (set by player on ready)
var player: Node2D = null

# High score persistence
var high_score: int = 0
const SAVE_PATH: String = "user://neon_survivor_save.cfg"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_high_score()
	_connect_signals()


func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		_game_timer += delta
		survival_time = _game_timer
		_update_difficulty(delta)


func _connect_signals() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.player_died.connect(_on_player_died)
	EventBus.xp_orb_collected.connect(_on_xp_collected)


func start_game() -> void:
	_reset_game_state()
	current_state = GameState.PLAYING
	EventBus.game_started.emit()


func pause_game() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true
		EventBus.game_paused.emit()


func resume_game() -> void:
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false
		EventBus.game_resumed.emit()


func toggle_pause() -> void:
	if current_state == GameState.PLAYING:
		pause_game()
	elif current_state == GameState.PAUSED:
		resume_game()


func enter_level_up() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.LEVEL_UP
		get_tree().paused = true


func exit_level_up() -> void:
	if current_state == GameState.LEVEL_UP:
		current_state = GameState.PLAYING
		get_tree().paused = false


func end_game() -> void:
	current_state = GameState.GAME_OVER
	get_tree().paused = true

	if score > high_score:
		high_score = score
		_save_high_score()

	EventBus.game_over.emit(score, survival_time)


func add_score(amount: int) -> void:
	score += amount
	EventBus.score_updated.emit(score)


func _reset_game_state() -> void:
	score = 0
	kill_count = 0
	survival_time = 0.0
	current_wave = 1
	_game_timer = 0.0
	_difficulty_timer = 0.0
	difficulty_multiplier = 1.0
	enemy_spawn_rate_multiplier = 1.0
	enemy_health_multiplier = 1.0
	enemy_damage_multiplier = 1.0
	get_tree().paused = false


func _update_difficulty(delta: float) -> void:
	_difficulty_timer += delta

	if _difficulty_timer >= DIFFICULTY_INCREASE_INTERVAL:
		_difficulty_timer = 0.0
		difficulty_multiplier += DIFFICULTY_INCREASE_AMOUNT
		enemy_spawn_rate_multiplier = 1.0 + (difficulty_multiplier - 1.0) * 0.5
		enemy_health_multiplier = difficulty_multiplier
		enemy_damage_multiplier = 1.0 + (difficulty_multiplier - 1.0) * 0.3

		# Trigger wave progression
		current_wave += 1
		EventBus.wave_started.emit(current_wave)


func _on_enemy_died(enemy: Node2D, position: Vector2) -> void:
	kill_count += 1
	add_score(10 * int(difficulty_multiplier))
	EventBus.kill_count_updated.emit(kill_count)


func _on_player_died() -> void:
	end_game()


func _on_xp_collected(value: int) -> void:
	add_score(value)


func _save_high_score() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "high_score", high_score)
	config.save(SAVE_PATH)


func _load_high_score() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err == OK:
		high_score = config.get_value("game", "high_score", 0)


func get_formatted_time() -> String:
	var minutes := int(survival_time) / 60
	var seconds := int(survival_time) % 60
	return "%02d:%02d" % [minutes, seconds]


func is_playing() -> bool:
	return current_state == GameState.PLAYING
