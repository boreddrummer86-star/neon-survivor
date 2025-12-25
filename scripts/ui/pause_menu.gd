## PauseMenu - In-game pause menu
## Handles pause/resume and settings access
class_name PauseMenu
extends CanvasLayer

# Node references
@onready var panel: PanelContainer = $CenterContainer/PanelContainer
@onready var resume_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ResumeButton
@onready var restart_button: Button = $CenterContainer/PanelContainer/VBoxContainer/RestartButton
@onready var quit_button: Button = $CenterContainer/PanelContainer/VBoxContainer/QuitButton


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Connect buttons
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if GameManager.current_state == GameManager.GameState.PLAYING:
			show_pause()
		elif GameManager.current_state == GameManager.GameState.PAUSED:
			hide_pause()


func show_pause() -> void:
	visible = true
	GameManager.pause_game()

	# Animate in
	if panel:
		panel.scale = Vector2.ZERO
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(panel, "scale", Vector2.ONE, 0.3)


func hide_pause() -> void:
	visible = false
	GameManager.resume_game()


func _on_resume_pressed() -> void:
	hide_pause()


func _on_restart_pressed() -> void:
	visible = false
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()
