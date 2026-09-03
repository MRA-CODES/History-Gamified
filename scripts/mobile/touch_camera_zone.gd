extends Control
class_name TouchCameraZone

# -----------------------------------------------------------------------------
# Touch Camera Drag Zone
# -----------------------------------------------------------------------------
# Captures touch swipe deltas on the right side of the screen and passes them
# to the Player's camera controller.
# -----------------------------------------------------------------------------

@export var touch_sensitivity: float = 0.0035

var touch_index: int = -1
var last_touch_pos: Vector2 = Vector2.ZERO
var player_ref: Node = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS

func set_player(player_node: Node) -> void:
	player_ref = player_node

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			touch_index = event.index
			last_touch_pos = event.position
			accept_event()
		elif not event.pressed and event.index == touch_index:
			touch_index = -1
			accept_event()
			
	elif event is InputEventScreenDrag:
		if event.index == touch_index:
			var rel = event.position - last_touch_pos
			last_touch_pos = event.position
			_apply_camera_drag(rel)
			accept_event()

func _apply_camera_drag(delta_motion: Vector2) -> void:
	if player_ref and player_ref.has_method("rotate_camera_relative"):
		player_ref.rotate_camera_relative(delta_motion, touch_sensitivity)
	else:
		# Fallback: find player in tree
		var p = get_tree().get_first_node_in_group("player")
		if p and p.has_method("rotate_camera_relative"):
			player_ref = p
			player_ref.rotate_camera_relative(delta_motion, touch_sensitivity)
