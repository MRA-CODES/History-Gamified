# -----------------------------------------------------------------------------
# monument_interactable.gd
# Modular 3D interaction trigger zone for historical monuments and museum artifacts.
# -----------------------------------------------------------------------------
class_name MonumentInteractable
extends Area3D

const EducationalEventBus = preload("res://scripts/educational/educational_event_bus.gd")

signal interacted(exhibit_dict: Dictionary)

@export var exhibit_id: String = "dippy_diplodocus"
@export var prompt_override: String = ""
@export var key_hint: String = "E"
@export var auto_open_on_approach: bool = false
@export var show_3d_marker: bool = true

var player_is_nearby: bool = false
var current_exhibit_data: Dictionary = {}

@onready var marker_visual: Node3D = get_node_or_null("MarkerVisual")

func _ready() -> void:
	# Default collision setup: mask 3 (detects layer 1 and layer 2)
	collision_layer = 0
	collision_mask = 3
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Fetch exhibit info
	current_exhibit_data = EducationalEventBus.get_exhibit_data(exhibit_id)
	
	if marker_visual:
		marker_visual.visible = show_3d_marker
	
	print("[MonumentInteractable] Initialized for '%s' at %s" % [exhibit_id, global_position])

func _process(delta: float) -> void:
	# Subtle floating animation for marker if present
	if marker_visual and marker_visual.visible:
		marker_visual.rotation.y += delta * 1.5

func _unhandled_input(event: InputEvent) -> void:
	if not player_is_nearby:
		return
		
	var interact_pressed = event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E)
	if interact_pressed:
		get_viewport().set_input_as_handled()
		trigger_inspection()

func trigger_inspection() -> void:
	if current_exhibit_data.is_empty():
		current_exhibit_data = EducationalEventBus.get_exhibit_data(exhibit_id)
		
	print("[MonumentInteractable] Triggering inspection for: ", exhibit_id)
	interacted.emit(current_exhibit_data)
	EducationalEventBus.open_popup(current_exhibit_data)

func _on_body_entered(body: Node3D) -> void:
	# Check if body is player
	if body is CharacterBody3D or body.is_in_group("player") or "player" in body.name.to_lower():
		player_is_nearby = true
		if current_exhibit_data.is_empty():
			current_exhibit_data = EducationalEventBus.get_exhibit_data(exhibit_id)
			
		print("[MonumentInteractable] Player entered zone for: ", current_exhibit_data.get("title", exhibit_id))
		EducationalEventBus.show_prompt(current_exhibit_data, key_hint)
		
		if auto_open_on_approach:
			trigger_inspection()

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D or body.is_in_group("player") or "player" in body.name.to_lower():
		player_is_nearby = false
		print("[MonumentInteractable] Player exited zone for: ", exhibit_id)
		EducationalEventBus.hide_prompt()
