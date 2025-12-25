## GameUI - Main HUD controller
## Manages health bar, XP bar, score display, and timer
class_name GameUI
extends CanvasLayer

# Node references
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/TopBar/HealthBar
@onready var health_label: Label = $MarginContainer/VBoxContainer/TopBar/HealthBar/HealthLabel
@onready var xp_bar: ProgressBar = $MarginContainer/VBoxContainer/TopBar/XPBar
@onready var level_label: Label = $MarginContainer/VBoxContainer/TopBar/XPBar/LevelLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/TopBar/ScoreLabel
@onready var timer_label: Label = $MarginContainer/VBoxContainer/TopBar/TimerLabel
@onready var kill_label: Label = $MarginContainer/VBoxContainer/TopBar/KillLabel
@onready var wave_label: Label = $MarginContainer/VBoxContainer/WaveLabel


func _ready() -> void:
	# Connect to EventBus signals
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.player_xp_gained.connect(_on_xp_changed)
	EventBus.player_level_up.connect(_on_level_up)
	EventBus.score_updated.connect(_on_score_updated)
	EventBus.kill_count_updated.connect(_on_kills_updated)
	EventBus.wave_started.connect(_on_wave_started)

	# Initialize displays
	_update_score(0)
	_update_kills(0)
	_update_wave(1)


func _process(_delta: float) -> void:
	if GameManager.is_playing():
		_update_timer()


func _on_health_changed(current: float, maximum: float) -> void:
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current

	if health_label:
		health_label.text = "%d / %d" % [int(current), int(maximum)]

	# Color based on health percentage
	var health_percent := current / maximum
	if health_bar:
		if health_percent <= 0.25:
			health_bar.modulate = Color(1, 0.2, 0.2)
		elif health_percent <= 0.5:
			health_bar.modulate = Color(1, 0.8, 0.2)
		else:
			health_bar.modulate = Color(0.2, 1, 0.6)


func _on_xp_changed(amount: int, total: int, required: int) -> void:
	if xp_bar:
		xp_bar.max_value = required
		xp_bar.value = total


func _on_level_up(new_level: int) -> void:
	if level_label:
		level_label.text = "Lv.%d" % new_level

	# Flash effect
	if xp_bar:
		var tween := create_tween()
		tween.tween_property(xp_bar, "modulate", Color(1, 1, 0), 0.1)
		tween.tween_property(xp_bar, "modulate", Color(0, 1, 1), 0.1)


func _on_score_updated(score: int) -> void:
	_update_score(score)


func _on_kills_updated(kills: int) -> void:
	_update_kills(kills)


func _on_wave_started(wave: int) -> void:
	_update_wave(wave)

	# Show wave notification
	if wave_label:
		wave_label.text = "WAVE %d" % wave
		wave_label.modulate.a = 1.0

		var tween := create_tween()
		tween.tween_interval(2.0)
		tween.tween_property(wave_label, "modulate:a", 0.0, 0.5)


func _update_score(score: int) -> void:
	if score_label:
		score_label.text = "Score: %d" % score


func _update_kills(kills: int) -> void:
	if kill_label:
		kill_label.text = "Kills: %d" % kills


func _update_wave(wave: int) -> void:
	pass  # Wave is shown via notification


func _update_timer() -> void:
	if timer_label:
		timer_label.text = GameManager.get_formatted_time()
