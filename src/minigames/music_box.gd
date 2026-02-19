extends Node2D
class_name MusicBox

signal puzzle_completed
signal round_changed(round_num: int, total: int)
signal sequence_updated(sequence: Array[int])

@export var num_keys: int = 5
@export var max_rounds: int = 5
@export var note_sounds: Array[AudioStream] = []
@export var base_note_duration: float = 0.5
@export var base_pause_duration: float = 0.2

# Visual settings
@export var key_width: float = 80.0
@export var key_height: float = 150.0
@export var key_spacing: float = 10.0

# Creepy settings
@export var pitch_reduction_per_round: float = 0.08
@export var duration_increase_per_round: float = 0.15

@onready var keys_container: HBoxContainer = $KeysContainer
@onready var audio_player: AudioStreamPlayer = $AudioPlayer

var keys: Array[ColorRect] = []
var sequence: Array[int] = []
var player_input: Array[int] = []
var current_round: int = 0
var is_playing_sequence: bool = false
var is_player_turn: bool = false
var is_solved: bool = false

var key_colors: Array[Color] = [
	Color(0.8, 0.2, 0.2),  # Red
	Color(0.2, 0.7, 0.2),  # Green
	Color(0.2, 0.4, 0.9),  # Blue
	Color(0.9, 0.8, 0.1),  # Yellow
	Color(0.7, 0.2, 0.8),  # Purple
	Color(0.9, 0.5, 0.1),  # Orange
	Color(0.2, 0.8, 0.8),  # Cyan
]

var key_highlight_color: Color = Color(1, 1, 1, 0.8)


func _ready() -> void:
	_setup_keys()
	_start_game()


func _setup_keys() -> void:
	for child in keys_container.get_children():
		child.queue_free()
	keys.clear()
	
	for i in range(num_keys):
		var key = ColorRect.new()
		key.custom_minimum_size = Vector2(key_width, key_height)
		key.color = key_colors[i % key_colors.size()]
		key.name = "Key_%d" % i
		key.mouse_filter = Control.MOUSE_FILTER_STOP
		key.gui_input.connect(_on_key_input.bind(i))
		key.set_meta("original_color", key.color)
		key.set_meta("key_index", i)
		keys_container.add_child(key)
		keys.append(key)


func _start_game() -> void:
	sequence.clear()
	player_input.clear()
	current_round = 0
	is_solved = false
	is_player_turn = false
	_next_round()


func _next_round() -> void:
	if current_round >= max_rounds:
		_win_game()
		return
	
	current_round += 1
	player_input.clear()
	
	var new_note = randi() % num_keys
	sequence.append(new_note)
	
	round_changed.emit(current_round, max_rounds)
	sequence_updated.emit(sequence)
	
	await get_tree().create_timer(0.5).timeout
	_play_sequence()


func _play_sequence() -> void:
	is_playing_sequence = true
	is_player_turn = false
	_set_keys_enabled(false)
	
	var pitch_modifier = 1.0 - (current_round - 1) * pitch_reduction_per_round
	var duration_modifier = 1.0 + (current_round - 1) * duration_increase_per_round
	pitch_modifier = clampf(pitch_modifier, 0.5, 1.0)
	
	for i in range(sequence.size()):
		var key_index = sequence[i]
		await _play_note(key_index, pitch_modifier, duration_modifier)
		await get_tree().create_timer(base_pause_duration * duration_modifier).timeout
	
	is_playing_sequence = false
	is_player_turn = true
	_set_keys_enabled(true)


func _play_note(key_index: int, pitch_modifier: float = 1.0, duration_modifier: float = 1.0) -> void:
	if key_index < 0 or key_index >= keys.size():
		return
	
	var key = keys[key_index]
	var original_color: Color = key.get_meta("original_color")
	key.color = original_color.lightened(0.5)
	
	if key_index < note_sounds.size() and note_sounds[key_index] != null:
		audio_player.stream = note_sounds[key_index]
		audio_player.pitch_scale = pitch_modifier
		audio_player.play()
	
	await get_tree().create_timer(base_note_duration * duration_modifier).timeout
	key.color = original_color


func _on_key_input(event: InputEvent, key_index: int) -> void:
	if not event is InputEventMouseButton:
		return
	
	var mouse_event = event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	if not is_player_turn or is_playing_sequence or is_solved:
		return
	
	_player_press_key(key_index)


func _player_press_key(key_index: int) -> void:
	player_input.append(key_index)
	_flash_key(key_index)
	
	var input_index = player_input.size() - 1
	if sequence[input_index] != key_index:
		_on_wrong_input()
		return
	
	if player_input.size() == sequence.size():
		_on_correct_sequence()


func _flash_key(key_index: int) -> void:
	if key_index < 0 or key_index >= keys.size():
		return
	
	var key = keys[key_index]
	var original_color: Color = key.get_meta("original_color")
	
	var pitch_modifier = 1.0 - (current_round - 1) * pitch_reduction_per_round
	pitch_modifier = clampf(pitch_modifier, 0.5, 1.0)
	
	if key_index < note_sounds.size() and note_sounds[key_index] != null:
		audio_player.stream = note_sounds[key_index]
		audio_player.pitch_scale = pitch_modifier
		audio_player.play()
	
	key.color = key_highlight_color
	var tween = create_tween()
	tween.tween_property(key, "color", original_color, 0.2)


func _on_wrong_input() -> void:
	for key in keys:
		key.color = Color(1, 0, 0)
	
	await get_tree().create_timer(0.5).timeout
	
	for key in keys:
		key.color = key.get_meta("original_color")
	
	player_input.clear()
	await get_tree().create_timer(0.3).timeout
	_play_sequence()


func _on_correct_sequence() -> void:
	is_player_turn = false
	
	for key in keys:
		key.color = Color(0.2, 1, 0.2)
	
	await get_tree().create_timer(0.3).timeout
	
	for key in keys:
		key.color = key.get_meta("original_color")
	
	_next_round()


func _win_game() -> void:
	is_solved = true
	is_player_turn = false
	
	for i in range(3):
		for key in keys:
			key.color = Color(1, 0.9, 0.2)
		await get_tree().create_timer(0.2).timeout
		for key in keys:
			key.color = key.get_meta("original_color")
		await get_tree().create_timer(0.2).timeout
	
	puzzle_completed.emit()


func _set_keys_enabled(enabled: bool) -> void:
	for key in keys:
		key.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


## Public API

func reset() -> void:
	_start_game()


func replay_sequence() -> void:
	if not is_playing_sequence and not is_solved:
		_play_sequence()


func auto_solve() -> void:
	if not is_solved:
		_win_game()


func get_current_round() -> int:
	return current_round


func get_max_rounds() -> int:
	return max_rounds


func get_sequence() -> Array[int]:
	return sequence.duplicate()


func is_complete() -> bool:
	return is_solved
