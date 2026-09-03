extends CanvasLayer
class_name MobileControlsLayer

# -----------------------------------------------------------------------------
# Mobile Controls Controller
# -----------------------------------------------------------------------------
# Automatically shows touch controls on Android/iOS/Touchscreen devices.
# Completely hidden on Windows/Desktop by default.
# -----------------------------------------------------------------------------

@onready var touch_camera_zone: TouchCameraZone = $TouchCameraZone
@onready var virtual_joystick: CustomVirtualJoystick = $JoystickContainer/VirtualJoystick
@onready var btn_jump: TouchActionButton = $ButtonsContainer/BtnJump
@onready var btn_sprint: TouchActionButton = $ButtonsContainer/BtnSprint
@onready var btn_interact: TouchActionButton = $ButtonsContainer/BtnInteract

# Debug override flag (can be toggled in editor or via F1 for desktop testing)
@export var force_show_in_editor: bool = false

var is_mobile_environment: bool = false

func _ready() -> void:
	# 1. Determine platform and touchscreen presence
	is_mobile_environment = _check_is_mobile()
	
	# 2. Set visibility and processing
	_apply_visibility()
	
	# 3. Connect touch camera zone to parent player if available
	var parent_player = get_parent()
	if parent_player and parent_player is CharacterBody3D and touch_camera_zone:
		touch_camera_zone.set_player(parent_player)

func _check_is_mobile() -> bool:
	if force_show_in_editor:
		return true
		
	# Native Godot checks for touchscreen, mobile OS, or Android/iOS
	if DisplayServer.is_touchscreen_available():
		return true
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		return true
	if OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return true
		
	return false

func _apply_visibility() -> void:
	visible = is_mobile_environment
	
	# If not mobile, ignore mouse clicks on the canvas elements
	var root_control = get_node_or_null("TouchCameraZone")
	if root_control:
		root_control.mouse_filter = Control.MOUSE_FILTER_PASS if is_mobile_environment else Control.MOUSE_FILTER_IGNORE

func _unhandled_input(event: InputEvent) -> void:
	# Optional F1 shortcut for desktop testing of mobile UI
	if event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_F1:
		is_mobile_environment = not is_mobile_environment
		_apply_visibility()
		print("📱 Mobile Touch Controls toggled:", is_mobile_environment)
		get_viewport().set_input_as_handled()
