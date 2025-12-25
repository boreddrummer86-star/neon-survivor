## GameOverUI - Game over screen
## Shows final stats and restart options
class_name GameOverUI
extends CanvasLayer

# Node references
@onready var panel: PanelContainer = $CenterContainer/PanelContainer
@onready var score_label: Label = $CenterContainer/PanelContainer/VBoxContainer/ScoreLabel
@onready var time_label: Label = $CenterContainer/PanelContainer/VBoxContainer/TimeLabel
@onready var kills_label: Label = $CenterContainer/PanelContainer/VBoxContainer/KillsLabel
@onready var high_score_label: Label = $CenterContainer/PanelContainer/VBoxContainer/HighScoreLabel
@onready var restart_button: Button = $CenterContainer/PanelContainer/VBoxContainer/RestartButton
@onready var quit_button: Button = $CenterContainer/PanelContainer/VBoxContainer/QuitButton


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Connect signals
	EventBus.game_over.connect(_on_game_over)

	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)


func _on_game_over(final_score: int, survival_time: float) -> void:
	visible = true

	# Update labels
	if score_label:
		score_label.text = "Final Score: %d" % final_score

	if time_label:
		var minutes := int(survival_time) / 60
		var seconds := int(survival_time) % 60
		time_label.text = "Survived: %02d:%02d" % [minutes, seconds]

	if kills_label:
		kills_label.text = "Enemies Defeated: %d" % GameManager.kill_count

	if high_score_label:
		if final_score >= GameManager.high_score:
			high_score_label.text = "NEW HIGH SCORE!"
			high_score_label.modulate = Color(1, 1, 0)
		else:
			high_score_label.text = "High Score: %d" % GameManager.high_score

	# Animate in
	if panel:
		panel.scale = Vector2.ZERO
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(panel, "scale", Vector2.ONE, 0.5)


func _on_restart_pressed() -> void:
	visible = false
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_accept"):
		_on_restart_pressed()
