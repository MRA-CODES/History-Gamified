extends Node3D
class_name ChurchDoor

# -----------------------------------------------------------------------------
# State
# -----------------------------------------------------------------------------
@export var auto_open_on_approach: bool = true
@export var open_duration: float = 1.2

var is_open: bool = false
var is_animating: bool = false
var player_in_range: bool = false

# -----------------------------------------------------------------------------
# Node References
# -----------------------------------------------------------------------------
@onready var left_pivot: Node3D = $LeftPivot
@onready var right_pivot: Node3D = $RightPivot
@onready var door_collision: CollisionShape3D = $DoorCollision/CollisionShape3D
@onready var interaction_area: Area3D = $InteractionArea

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------
func _ready() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

func _input(event: InputEvent) -> void:
	if player_in_range and not is_animating:
		var interact_pressed = event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E)
		if interact_pressed:
			toggle_door()

# -----------------------------------------------------------------------------
# Area Callbacks
# -----------------------------------------------------------------------------
func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		player_in_range = true
		if auto_open_on_approach and not is_open and not is_animating:
			open_door()

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		player_in_range = false

# -----------------------------------------------------------------------------
# Door Operations
# -----------------------------------------------------------------------------
func toggle_door() -> void:
	if is_open:
		close_door()
	else:
		open_door()

func open_door() -> void:
	if is_open or is_animating:
		return
	is_animating = true
	
	# Disable collision immediately when opening so player can walk through
	if door_collision:
		door_collision.set_deferred("disabled", true)
		
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Left door opens inward into vestibule (negative Y rotation around left hinge)
	tween.tween_property(left_pivot, "rotation:y", deg_to_rad(-95.0), open_duration)
	# Right door opens inward into vestibule (positive Y rotation around right hinge)
	tween.tween_property(right_pivot, "rotation:y", deg_to_rad(95.0), open_duration)
	
	await tween.finished
	is_open = true
	is_animating = false

func close_door() -> void:
	if not is_open or is_animating:
		return
	is_animating = true
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(left_pivot, "rotation:y", 0.0, open_duration)
	tween.tween_property(right_pivot, "rotation:y", 0.0, open_duration)
	
	await tween.finished
	if door_collision:
		door_collision.set_deferred("disabled", false)
	is_open = false
	is_animating = false
