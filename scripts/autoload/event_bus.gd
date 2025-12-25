## EventBus - Centralized signal hub for decoupled communication
## Following Godot 4.5 best practices for signal-based architecture
extends Node

# Player signals
signal player_health_changed(current_health: float, max_health: float)
signal player_died
signal player_level_up(new_level: int)
signal player_xp_gained(amount: int, total: int, required: int)

# Enemy signals
signal enemy_spawned(enemy: Node2D)
signal enemy_died(enemy: Node2D, position: Vector2)
signal enemy_damaged(enemy: Node2D, damage: float)

# Game state signals
signal game_started
signal game_paused
signal game_resumed
signal game_over(final_score: int, survival_time: float)
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)

# Pickup signals
signal xp_orb_collected(value: int)
signal health_pickup_collected(value: float)
signal weapon_pickup_collected(weapon_id: String)

# Score signals
signal score_updated(new_score: int)
signal kill_count_updated(kills: int)

# UI signals
signal show_damage_number(position: Vector2, damage: float, is_crit: bool)
signal show_level_up_ui(level: int, choices: Array)
signal upgrade_selected(upgrade_id: String)
