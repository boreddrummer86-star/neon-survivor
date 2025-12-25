extends Node
## Logger Autoload - Comprehensive logging system for debugging
## Writes timestamped entries to both console and file
## Critical for debugging AI-generated code throughout 100-step development

class_name GameLogger  # Changed from "Logger" to avoid native class conflict

# Log levels for filtering and categorization
enum LogLevel { DEBUG, INFO, WARNING, ERROR, CRITICAL }

# Configuration
const LOG_DIR := "user://logs/"
const MAX_LOG_FILES := 10  # Keep last N log files
const LOG_TO_CONSOLE := true
const LOG_TO_FILE := true
const MIN_CONSOLE_LEVEL: LogLevel = LogLevel.DEBUG
const MIN_FILE_LEVEL: LogLevel = LogLevel.DEBUG

# Color codes for console output (ANSI - works in Godot output)
const LEVEL_COLORS: Dictionary = {
	LogLevel.DEBUG: "[color=gray]",
	LogLevel.INFO: "[color=white]",
	LogLevel.WARNING: "[color=yellow]",
	LogLevel.ERROR: "[color=red]",
	LogLevel.CRITICAL: "[color=magenta]",
}

# Level names for output - explicitly typed to avoid inference issues
const LEVEL_NAMES: Dictionary = {
	LogLevel.DEBUG: "DEBUG",
	LogLevel.INFO: "INFO",
	LogLevel.WARNING: "WARN",
	LogLevel.ERROR: "ERROR",
	LogLevel.CRITICAL: "CRIT",
}

# File handle
var _log_file: FileAccess = null
var _log_file_path: String = ""
var _session_start_time: int = 0


func _ready() -> void:
	_session_start_time = Time.get_unix_time_from_system()

	if LOG_TO_FILE:
		_setup_log_file()

	info("GameLogger", "Logging system initialized")
	info("GameLogger", "Session started at: " + _get_timestamp())


func _exit_tree() -> void:
	info("GameLogger", "Session ended")
	_close_log_file()


## Setup the log file with rotation
func _setup_log_file() -> void:
	# Ensure log directory exists
	var dir := DirAccess.open("user://")
	if dir:
		if not dir.dir_exists("logs"):
			dir.make_dir("logs")

	# Create new log file with timestamp
	var timestamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	_log_file_path = LOG_DIR + "game_" + timestamp + ".log"

	_log_file = FileAccess.open(_log_file_path, FileAccess.WRITE)

	if _log_file:
		_log_file.store_line("=== Neon Survivor Log File ===")
		_log_file.store_line("Started: " + Time.get_datetime_string_from_system())
		_log_file.store_line("=" .repeat(40))
		_log_file.store_line("")

	# Rotate old logs
	_rotate_logs()


## Rotate old log files, keeping only MAX_LOG_FILES
func _rotate_logs() -> void:
	var dir := DirAccess.open(LOG_DIR)
	if not dir:
		return

	var log_files: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if file_name.ends_with(".log"):
			log_files.append(file_name)
		file_name = dir.get_next()

	dir.list_dir_end()

	# Sort by name (which includes timestamp)
	log_files.sort()

	# Remove oldest files if we exceed max
	while log_files.size() > MAX_LOG_FILES:
		var oldest := log_files.pop_front()
		if oldest:
			dir.remove(oldest as String)


## Close the log file
func _close_log_file() -> void:
	if _log_file:
		_log_file.close()
		_log_file = null


## Get formatted timestamp
func _get_timestamp() -> String:
	var time := Time.get_time_dict_from_system()
	return "%02d:%02d:%02d" % [time.hour, time.minute, time.second]


## Get level name with explicit return type
func _get_level_name(level: LogLevel) -> String:
	if LEVEL_NAMES.has(level):
		return LEVEL_NAMES[level] as String
	return "UNKNOWN"


## Core logging function
func _log(level: LogLevel, category: String, message: String) -> void:
	var timestamp := _get_timestamp()
	var level_name := _get_level_name(level)

	# Format: [HH:MM:SS] [LEVEL] [Category] Message
	var formatted := "[%s] [%s] [%s] %s" % [timestamp, level_name, category, message]

	# Console output
	if LOG_TO_CONSOLE and level >= MIN_CONSOLE_LEVEL:
		var color_code: String = LEVEL_COLORS.get(level, "[color=white]") as String
		print_rich(color_code + formatted + "[/color]")

	# File output
	if LOG_TO_FILE and _log_file and level >= MIN_FILE_LEVEL:
		_log_file.store_line(formatted)
		_log_file.flush()


## Convenience methods for each log level
func debug(category: String, message: String) -> void:
	_log(LogLevel.DEBUG, category, message)


func info(category: String, message: String) -> void:
	_log(LogLevel.INFO, category, message)


func warning(category: String, message: String) -> void:
	_log(LogLevel.WARNING, category, message)


func error(category: String, message: String) -> void:
	_log(LogLevel.ERROR, category, message)


func critical(category: String, message: String) -> void:
	_log(LogLevel.CRITICAL, category, message)


## Log with format string support
func debug_f(category: String, format_str: String, args: Array) -> void:
	_log(LogLevel.DEBUG, category, format_str % args)


func info_f(category: String, format_str: String, args: Array) -> void:
	_log(LogLevel.INFO, category, format_str % args)


func warning_f(category: String, format_str: String, args: Array) -> void:
	_log(LogLevel.WARNING, category, format_str % args)


func error_f(category: String, format_str: String, args: Array) -> void:
	_log(LogLevel.ERROR, category, format_str % args)


## Log game events specifically
func game_event(event_name: String, details: Dictionary = {}) -> void:
	var details_str := ""
	if not details.is_empty():
		details_str = " | " + str(details)
	info("GameEvent", event_name + details_str)


## Log player actions
func player_action(action: String, details: Dictionary = {}) -> void:
	var details_str := ""
	if not details.is_empty():
		details_str = " | " + str(details)
	debug("Player", action + details_str)


## Log combat events
func combat(event: String, details: Dictionary = {}) -> void:
	var details_str := ""
	if not details.is_empty():
		details_str = " | " + str(details)
	debug("Combat", event + details_str)


## Performance logging
func perf(metric: String, value: float) -> void:
	debug("Perf", "%s: %.2f" % [metric, value])


## Get session duration
func get_session_duration() -> float:
	return float(Time.get_unix_time_from_system() - _session_start_time)


## Get log file path
func get_log_file_path() -> String:
	return _log_file_path
