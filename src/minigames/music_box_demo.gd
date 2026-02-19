extends Control
class_name MusicBoxDemo
## Demo wrapper for MusicBox puzzle with debug UI

@onready var puzzle: MusicBox = $SubViewportContainer/SubViewport/MusicBox
@onready var round_label: Label = $DebugUI/RoundLabel
@onready var sequence_label: Label = $DebugUI/SequenceLabel
@onready var play_button: Button = $DebugUI/PlayButton
@onready var autosolve_button: Button = $DebugUI/AutosolveButton
@onready var reset_button: Button = $DebugUI/ResetButton
@onready var win_label: Label = $WinLabel


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	autosolve_button.pressed.connect(_on_autosolve_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	
	puzzle.round_changed.connect(_on_round_changed)
	puzzle.sequence_updated.connect(_on_sequence_updated)
	puzzle.puzzle_completed.connect(_on_puzzle_completed)


func _on_round_changed(round_num: int, total: int) -> void:
	round_label.text = "Round: %d / %d" % [round_num, total]


func _on_sequence_updated(seq: Array[int]) -> void:
	var seq_str = ""
	for i in range(seq.size()):
		seq_str += str(seq[i])
		if i < seq.size() - 1:
			seq_str += " - "
	sequence_label.text = "Sequence: [%s]" % seq_str


func _on_puzzle_completed() -> void:
	win_label.visible = true
	round_label.text = "COMPLETED!"


func _on_play_pressed() -> void:
	puzzle.replay_sequence()


func _on_autosolve_pressed() -> void:
	puzzle.auto_solve()


func _on_reset_pressed() -> void:
	puzzle.reset()
	win_label.visible = false
