@tool
extends Node3D
class_name Painting
## ============================================================================
## PAINTING — 3D interactive painting with embedded minigame via SubViewport
## ============================================================================
##
## The minigame is displayed ON the painting surface. Camera zooms in on interact.
##
## Place in level, configure via Inspector:
##   - painting_id: unique identifier
##   - minigame_type: which minigame to launch
##   - difficulty: 1-5
##   - art_texture: texture shown when idle
##
## ============================================================================

#region SIGNALS
signal minigame_started(painting_id: String, minigame_type: MiniGameManagerClass.Type, difficulty: int)
signal minigame_finished(painting_id: String, result: IMiniGame.Result)
signal painting_completed(painting_id: String)
signal interaction_blocked(painting_id: String, reason: String)
#endregion


#region ENUMS
enum State {
	AVAILABLE,
	ZOOMING_IN,
	IN_PROGRESS,
	ZOOMING_OUT,
	COMPLETED,
}
#endregion


#region EXPORTS
@export_group("Identity")
@export var painting_id: String = "painting_01"

@export_group("Minigame")
@export var minigame_type: MiniGameManagerClass.Type = MiniGameManagerClass.Type.MOCK_WIN_LOSE
@export_range(1, 5) var difficulty: int = 1

@export_group("Appearance")
@export var art_texture: Texture2D:
	set(value):
		art_texture = value
		_update_art()

@export var painting_size: Vector2 = Vector2(1.0, 1.2):
	set(value):
		painting_size = value
		_update_size()

@export_group("Camera Transition")
@export var transition_time: float = 0.6
@export var zoom_fov: float = 40.0

@export_group("Behavior")
@export var one_shot_on_win: bool = true
#endregion


#region STATE
var current_state: State = State.AVAILABLE:
	set(value):
		current_state = value
		_update_visuals()

var active: bool = false
var original_camera_transform: Transform3D
var original_fov: float
var player_camera: Camera3D
var current_minigame: IMiniGame = null
#endregion


#region NODE REFERENCES
@onready var canvas_mesh: MeshInstance3D = $CanvasMesh
@onready var frame_mesh: MeshInstance3D = $FrameMesh
@onready var interaction_area: Area3D = $InteractionArea
@onready var completed_indicator: Node3D = $CompletedIndicator
@onready var camera_anchor: Marker3D = $CameraAnchor
@onready var subviewport: SubViewport = $SubViewport
#endregion


#region LIFECYCLE
func _ready() -> void:
	if Engine.is_editor_hint():
		_update_art()
		_update_size()
		return
	
	# Check persistence
	if GameManager and GameManager.is_painting_healed(painting_id):
		current_state = State.COMPLETED
	
	# Setup SubViewport texture on canvas
	_setup_viewport_texture()
	
	_update_art()
	_update_size()
	_update_visuals()
	
	# Find player camera
	var player = get_tree().get_first_node_in_group("player") as FlyingCamera
	if player:
		player_camera = player.get_node("Camera3D")


func _setup_viewport_texture() -> void:
	if not subviewport or not canvas_mesh:
		return
	
	# Initially show art texture, not viewport
	# Viewport texture will be shown when minigame starts


func _update_art() -> void:
	if not canvas_mesh:
		return
	
	if current_state == State.IN_PROGRESS and subviewport:
		# Show viewport texture during minigame
		var material := StandardMaterial3D.new()
		var vp_texture := ViewportTexture.new()
		vp_texture.viewport_path = subviewport.get_path()
		material.albedo_texture = vp_texture
		material.cull_mode = BaseMaterial3D.CULL_BACK
		canvas_mesh.material_override = material
	elif art_texture:
		var material := StandardMaterial3D.new()
		material.albedo_texture = art_texture
		material.cull_mode = BaseMaterial3D.CULL_BACK
		canvas_mesh.material_override = material
	else:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.3, 0.3, 0.35)
		canvas_mesh.material_override = material


func _update_size() -> void:
	if not canvas_mesh or not frame_mesh:
		return
	
	var canvas_quad := canvas_mesh.mesh as QuadMesh
	if canvas_quad:
		canvas_quad.size = painting_size


func _update_visuals() -> void:
	if Engine.is_editor_hint():
		return
	
	if completed_indicator:
		completed_indicator.visible = (current_state == State.COMPLETED)
#endregion


#region INPUT
func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	
	# Exit minigame with ESC
	if active and event.is_action_pressed("ui_cancel"):
		_exit_minigame(IMiniGame.Result.CANCEL)
		get_viewport().set_input_as_handled()
		return
	
	# Forward input to subviewport when active
	if active and subviewport:
		_forward_input(event)


func _forward_input(event: InputEvent) -> void:
	if event is InputEventKey:
		subviewport.push_input(event)
	elif event is InputEventMouseButton or event is InputEventMouseMotion:
		# Convert mouse position to viewport coordinates
		var vp_size = subviewport.size
		var screen_size = get_viewport().get_visible_rect().size
		
		var new_event: InputEvent
		if event is InputEventMouseButton:
			new_event = event.duplicate()
			new_event.position = event.position * Vector2(vp_size) / screen_size
		elif event is InputEventMouseMotion:
			new_event = event.duplicate()
			new_event.position = event.position * Vector2(vp_size) / screen_size
		
		subviewport.push_input(new_event)
#endregion


#region INTERACTION
func can_interact() -> bool:
	return current_state == State.AVAILABLE


func show_tooltip() -> void:
	var hud = get_tree().get_first_node_in_group("hud") as HUD
	if hud:
		hud.show_interaction_prompt("[E] Interact")


func hide_tooltip() -> void:
	var hud = get_tree().get_first_node_in_group("hud") as HUD
	if hud:
		hud.hide_interaction_prompt()


func interact() -> void:
	match current_state:
		State.AVAILABLE:
			_start_minigame()
		State.IN_PROGRESS:
			interaction_blocked.emit(painting_id, "Minigame already in progress")
		State.COMPLETED:
			interaction_blocked.emit(painting_id, "Already completed")


func try_interact() -> bool:
	if current_state == State.AVAILABLE:
		interact()
		return true
	return false
#endregion


#region MINIGAME LIFECYCLE
func _start_minigame() -> void:
	if not player_camera:
		var player = get_tree().get_first_node_in_group("player") as FlyingCamera
		if player:
			player_camera = player.get_node("Camera3D")
	
	if not player_camera:
		push_error("Painting: Player camera not found")
		return
	
	# Load minigame scene
	var scene_path: String = MiniGameManagerClass.MINIGAME_SCENES.get(minigame_type, "")
	if scene_path.is_empty():
		push_error("Painting: No scene for minigame type")
		return
	
	var packed_scene := load(scene_path) as PackedScene
	if not packed_scene:
		push_error("Painting: Failed to load minigame scene: " + scene_path)
		return
	
	# Instantiate minigame in subviewport
	current_minigame = packed_scene.instantiate() as IMiniGame
	if not current_minigame:
		push_error("Painting: Scene is not an IMiniGame")
		return
	
	current_minigame.setup(painting_id, difficulty, {})
	current_minigame.finished.connect(_on_minigame_finished)
	subviewport.add_child(current_minigame)
	
	# Update state
	current_state = State.ZOOMING_IN
	
	# Show viewport texture on canvas
	_update_art()
	
	# Store original camera state
	original_camera_transform = player_camera.global_transform
	original_fov = player_camera.fov
	
	# Disable player movement
	var player = get_tree().get_first_node_in_group("player") as FlyingCamera
	if player:
		player.set_physics_process(false)
		player.set_process_input(false)
	
	# Zoom camera to painting
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(player_camera, "global_transform", camera_anchor.global_transform, transition_time)
	tween.parallel().tween_property(player_camera, "fov", zoom_fov, transition_time)
	
	tween.finished.connect(_on_zoom_in_finished)
	
	# Hide tooltip
	hide_tooltip()
	
	# Notify GameManager
	if GameManager:
		GameManager.change_state(GameManager.State.MINIGAME)
	
	minigame_started.emit(painting_id, minigame_type, difficulty)


func _on_zoom_in_finished() -> void:
	current_state = State.IN_PROGRESS
	active = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_minigame_finished(result: IMiniGame.Result) -> void:
	_exit_minigame(result)


func _exit_minigame(result: IMiniGame.Result) -> void:
	if current_state != State.IN_PROGRESS and current_state != State.ZOOMING_IN:
		return
	
	active = false
	current_state = State.ZOOMING_OUT
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Zoom camera back
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(player_camera, "global_transform", original_camera_transform, transition_time)
	tween.parallel().tween_property(player_camera, "fov", original_fov, transition_time)
	
	tween.finished.connect(_on_zoom_out_finished.bind(result))


func _on_zoom_out_finished(result: IMiniGame.Result) -> void:
	# Cleanup minigame
	if current_minigame:
		current_minigame.queue_free()
		current_minigame = null
	
	# Restore art texture
	_update_art()
	
	# Re-enable player
	var player = get_tree().get_first_node_in_group("player") as FlyingCamera
	if player:
		player.set_physics_process(true)
		player.set_process_input(true)
	
	# Notify GameManager
	if GameManager:
		GameManager.change_state(GameManager.State.PLAYING)
	
	# Handle result
	minigame_finished.emit(painting_id, result)
	
	match result:
		IMiniGame.Result.WIN:
			if one_shot_on_win:
				current_state = State.COMPLETED
				if GameManager:
					GameManager.heal_painting(painting_id)
				painting_completed.emit(painting_id)
			else:
				current_state = State.AVAILABLE
		_:
			current_state = State.AVAILABLE
#endregion


#region UTILITY
func force_complete() -> void:
	current_state = State.COMPLETED
	if GameManager:
		GameManager.heal_painting(painting_id)
	painting_completed.emit(painting_id)


func reset() -> void:
	current_state = State.AVAILABLE
	if GameManager:
		GameManager.healed_paintings.erase(painting_id)
#endregion
