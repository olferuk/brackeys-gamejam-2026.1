extends IMiniGame
class_name MusicBoxMiniGame
## IMiniGame wrapper for MusicBox puzzle

@export var puzzle_scene: PackedScene

var puzzle_instance: MusicBox

@onready var puzzle_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var cancel_button: Button = $CancelButton


func _on_setup() -> void:
	if not is_node_ready():
		await ready
	
	# Configure rounds based on difficulty
	var rounds_config = {
		1: 3,
		2: 4,
		3: 5,
		4: 6,
		5: 7,
	}
	
	if puzzle_scene:
		puzzle_instance = puzzle_scene.instantiate() as MusicBox
		puzzle_instance.max_rounds = rounds_config.get(difficulty, 5)
		puzzle_instance.puzzle_completed.connect(_on_puzzle_completed)
		puzzle_viewport.add_child(puzzle_instance)


func _on_puzzle_completed() -> void:
	await get_tree().create_timer(0.5).timeout
	win()


func _on_cancel_pressed() -> void:
	cancel()
