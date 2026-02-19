extends IMiniGame
class_name StainedGlassMiniGame
## Wrapper for StainedGlass — embeds Node2D puzzle directly

@export var puzzle_scene: PackedScene

var puzzle_instance: StainedGlass


func _on_setup() -> void:
	if not is_node_ready():
		await ready
	
	if puzzle_scene:
		puzzle_instance = puzzle_scene.instantiate() as StainedGlass
		puzzle_instance.puzzle_completed.connect(_on_puzzle_completed)
		add_child(puzzle_instance)


func _on_puzzle_completed() -> void:
	await get_tree().create_timer(0.5).timeout
	win()
