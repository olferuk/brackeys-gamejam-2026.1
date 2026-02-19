extends IMiniGame
class_name StainedGlassMiniGame
## IMiniGame wrapper for StainedGlass puzzle

@export var puzzle_scene: PackedScene

var puzzle_instance: StainedGlass

@onready var puzzle_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var cancel_button: Button = $CancelButton


func _on_setup() -> void:
	if not is_node_ready():
		await ready
	
	# Instantiate puzzle into viewport
	if puzzle_scene:
		puzzle_instance = puzzle_scene.instantiate() as StainedGlass
		puzzle_instance.puzzle_completed.connect(_on_puzzle_completed)
		puzzle_viewport.add_child(puzzle_instance)


func _on_puzzle_completed() -> void:
	await get_tree().create_timer(0.5).timeout
	win()


func _on_cancel_pressed() -> void:
	cancel()
