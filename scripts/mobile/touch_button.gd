extends Control
class_name TouchActionButton

# -----------------------------------------------------------------------------
# Touch Action Button
# -----------------------------------------------------------------------------
# Clean, circular touch button that triggers standard Godot InputMap actions:
# - Jump (tap action)
# - Sprint (hold or toggle)
# - Interact (tap action for doors and exhibits)
# -----------------------------------------------------------------------------

@export var action_name: String = "jump"
@export var button_label: String = "JUMP"
@export var is_toggle_button: bool = false
@export var base_color: Color = Color(0.12, 0.15, 0.2, 0.55)
@export var active_color: Color = Color(0.85, 0.65, 0.2, 0.8)
@export var pressed_color: Color = Color(1.0, 1.0, 1.0, 0.85)

var is_pressed_state: bool = false
var is_toggled_active: bool = false
var touch_index: int = -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _draw() -> void:
	var radius = min(size.x, size.y) * 0.46
	var center = size * 0.5
	
	# Current background fill
	var fill_c = base_color
	if is_pressed_state:
		fill_c = pressed_color
	elif is_toggled_active:
		fill_c = active_color
		
	# Draw filled circle with subtle border
	draw_circle(center, radius, fill_c)
	draw_arc(center, radius, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.4), 2.0, true)
	
	# Draw text label
	var font = ThemeDB.fallback_font
	var font_size = int(radius * 0.42)
	var text_c = Color.BLACK if is_pressed_state else Color.WHITE
	
	var string_size = font.get_string_size(button_label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos = center + Vector2(-string_size.x * 0.5, font_size * 0.35)
	draw_string(font, text_pos, button_label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_c)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			touch_index = event.index
			_on_press_start()
			accept_event()
		elif not event.pressed and event.index == touch_index:
			touch_index = -1
			_on_press_end()
			accept_event()

func _on_press_start() -> void:
	is_pressed_state = true
	
	if is_toggle_button:
		is_toggled_active = not is_toggled_active
		if is_toggled_active:
			Input.action_press(action_name)
		else:
			Input.action_release(action_name)
	else:
		Input.action_press(action_name)
		# Parse action event to notify input listeners
		var ev = InputEventAction.new()
		ev.action = action_name
		ev.pressed = true
		Input.parse_input_event(ev)
		
	queue_redraw()

func _on_press_end() -> void:
	is_pressed_state = false
	
	if not is_toggle_button:
		Input.action_release(action_name)
		var ev = InputEventAction.new()
		ev.action = action_name
		ev.pressed = false
		Input.parse_input_event(ev)
		
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED or what == NOTIFICATION_DISABLED:
		if not is_visible_in_tree():
			if is_pressed_state or (is_toggle_button and is_toggled_active):
				is_pressed_state = false
				is_toggled_active = false
				Input.action_release(action_name)
				queue_redraw()
