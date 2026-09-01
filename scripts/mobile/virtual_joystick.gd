extends Control
class_name CustomVirtualJoystick

# -----------------------------------------------------------------------------
# Virtual Analog Joystick for Mobile Movement
# -----------------------------------------------------------------------------
# Dispatches standard InputMap actions:
# move_forward, move_backward, move_left, move_right
# -----------------------------------------------------------------------------

@export var max_radius: float = 70.0
@export var deadzone: float = 0.15
@export var base_color: Color = Color(1.0, 1.0, 1.0, 0.18)
@export var knob_color: Color = Color(1.0, 1.0, 1.0, 0.45)
@export var border_color: Color = Color(1.0, 1.0, 1.0, 0.35)

var touch_index: int = -1
var joystick_center: Vector2 = Vector2.ZERO
var knob_position: Vector2 = Vector2.ZERO
var current_output: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Center joystick in its rect
	joystick_center = size * 0.5
	knob_position = joystick_center
	queue_redraw()

func _draw() -> void:
	# 1. Base outer ring
	draw_circle(joystick_center, max_radius, base_color)
	draw_arc(joystick_center, max_radius, 0.0, TAU, 32, border_color, 2.0, true)
	
	# 2. Subtle directional guide marks
	var mark_color = Color(1.0, 1.0, 1.0, 0.25)
	for i in range(4):
		var ang = float(i) * (PI * 0.5)
		var dir = Vector2(cos(ang), sin(ang))
		draw_line(joystick_center + dir * (max_radius * 0.6), joystick_center + dir * (max_radius * 0.9), mark_color, 1.5)

	# 3. Draggable Knob
	draw_circle(knob_position, max_radius * 0.42, knob_color)
	draw_arc(knob_position, max_radius * 0.42, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.7), 2.0, true)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			touch_index = event.index
			_update_knob(event.position)
		elif not event.pressed and event.index == touch_index:
			_reset_joystick()
			
	elif event is InputEventScreenDrag:
		if event.index == touch_index:
			_update_knob(event.position)

func _update_knob(touch_pos: Vector2) -> void:
	var offset = touch_pos - joystick_center
	var dist = offset.length()
	
	if dist > max_radius:
		offset = offset.normalized() * max_radius
		
	knob_position = joystick_center + offset
	
	var norm_dist = offset.length() / max_radius
	if norm_dist < deadzone:
		current_output = Vector2.ZERO
	else:
		# Map normalized range [deadzone..1.0] -> [0.0..1.0]
		var scaled_mag = (norm_dist - deadzone) / (1.0 - deadzone)
		current_output = offset.normalized() * scaled_mag
		
	_dispatch_input_actions()
	queue_redraw()

func _reset_joystick() -> void:
	touch_index = -1
	knob_position = joystick_center
	current_output = Vector2.ZERO
	_release_all_actions()
	queue_redraw()

func _dispatch_input_actions() -> void:
	# Horizontal (X): Left (-) / Right (+)
	if current_output.x < -0.05:
		Input.action_press("move_left", -current_output.x)
		Input.action_release("move_right")
	elif current_output.x > 0.05:
		Input.action_press("move_right", current_output.x)
		Input.action_release("move_left")
	else:
		Input.action_release("move_left")
		Input.action_release("move_right")
		
	# Vertical (Y): Screen Up (-) = Move Forward, Screen Down (+) = Move Backward
	if current_output.y < -0.05:
		Input.action_press("move_forward", -current_output.y)
		Input.action_release("move_backward")
	elif current_output.y > 0.05:
		Input.action_press("move_backward", current_output.y)
		Input.action_release("move_forward")
	else:
		Input.action_release("move_forward")
		Input.action_release("move_backward")

func _release_all_actions() -> void:
	Input.action_release("move_forward")
	Input.action_release("move_backward")
	Input.action_release("move_left")
	Input.action_release("move_right")

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED or what == NOTIFICATION_DISABLED:
		if not is_visible_in_tree():
			_reset_joystick()
