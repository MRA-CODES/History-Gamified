extends Node3D

# -----------------------------------------------------------------------------
# Node References
# -----------------------------------------------------------------------------
@onready var exterior: Node3D = $Exterior
@onready var interior: Node3D = $Interior
@onready var player: Node3D = $Player
@onready var transition_rect: ColorRect = $TransitionOverlay/ColorRect
@onready var enter_trigger: Area3D = $Triggers/EnterInteriorTrigger
@onready var exit_trigger: Area3D = $Triggers/ExitExteriorTrigger

# List of internal scan meshes in the exterior GLB (pillars, internal arches, colonnades, cavity caps)
const EXTERIOR_INTERNAL_MESHES: Array[String] = [
	"Object_2",   # Internal cavity cap
	"Object_17",  # Internal upper floor cavity
	"Object_23",  # Internal nave ceiling rib arches
	"Object_24",  # Internal backdrop card
	"Object_25",  # Internal colonnade / pillar arches
	"Object_26",  # Internal aisle vaulting
	"Object_27",  # Internal side chapel walls
	"Object_33"   # Internal wall fragment
]

var is_inside: bool = false
var is_transitioning: bool = false
var transition_tween: Tween = null

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------
func _ready() -> void:
	# 1. Clean the exterior model: remove all internal pillars, colonnades, and internal walls
	_filter_exterior_internal_geometry()
	
	# 2. Setup transition overlay
	if transition_rect:
		transition_rect.modulate.a = 0.0
		transition_rect.visible = true
		
	# 3. Determine initial zone based on player starting position
	if player and player.global_position.z < 33.0:
		is_inside = true
		exterior.visible = false
		interior.visible = true
	else:
		is_inside = false
		exterior.visible = true
		interior.visible = false
		
	# 4. Connect triggers
	if enter_trigger:
		enter_trigger.body_entered.connect(_on_enter_interior_entered)
	if exit_trigger:
		exit_trigger.body_entered.connect(_on_exit_exterior_entered)
		
	# 5. Initialize educational monument system
	_setup_educational_system()

func _setup_educational_system() -> void:
	if not has_node("MonumentPopupUI"):
		var popup_scene = load("res://ui/monument_popup.tscn")
		if popup_scene:
			var popup_inst = popup_scene.instantiate()
			popup_inst.name = "MonumentPopupUI"
			add_child(popup_inst)
			
	if not has_node("MuseumExhibits"):
		var exhibits_scene = load("res://scenes/exhibits/museum_exhibits.tscn")
		if exhibits_scene:
			var exhibits_inst = exhibits_scene.instantiate()
			exhibits_inst.name = "MuseumExhibits"
			add_child(exhibits_inst)

func _process(_delta: float) -> void:
	# Continuous position-based fallback to guarantee correct environment state
	if not player or is_transitioning:
		return
		
	var pz = player.global_position.z
	if not is_inside and pz < 31.0:
		# Player is inside vestibule/hall but state was outside -> transition to inside
		_set_zone(true, false)
	elif is_inside and pz > 34.5:
		# Player is out on plaza but state was inside -> transition to outside
		_set_zone(false, false)

# -----------------------------------------------------------------------------
# Zone Triggers
# -----------------------------------------------------------------------------
func _on_enter_interior_entered(body: Node3D) -> void:
	if body == player and not is_inside:
		_set_zone(true, true)

func _on_exit_exterior_entered(body: Node3D) -> void:
	if body == player and is_inside:
		_set_zone(false, true)

# -----------------------------------------------------------------------------
# Environment Transition Handler
# -----------------------------------------------------------------------------
func _set_zone(enter_interior: bool, use_fade: bool) -> void:
	if is_inside == enter_interior and not is_transitioning:
		return
		
	is_inside = enter_interior
	
	if not use_fade or not transition_rect:
		_apply_visibility(enter_interior)
		return
		
	is_transitioning = true
	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()
		
	transition_tween = create_tween()
	# Fast cinematic fade out
	transition_tween.tween_property(transition_rect, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Switch environment visibility at peak of fade
	transition_tween.tween_callback(func(): _apply_visibility(enter_interior))
	# Cinematic fade in
	transition_tween.tween_property(transition_rect, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	transition_tween.tween_callback(func(): is_transitioning = false)

func _apply_visibility(to_inside: bool) -> void:
	if to_inside:
		# INSIDE: Completely hide the exterior building. No external pillars, walls, or blockades exist.
		exterior.visible = false
		interior.visible = true
	else:
		# OUTSIDE: Show the exterior church facade and hide the interior.
		exterior.visible = true
		interior.visible = false

# -----------------------------------------------------------------------------
# Exterior Geometry Cleaning
# -----------------------------------------------------------------------------
func _filter_exterior_internal_geometry() -> void:
	if not exterior:
		return
	for target in EXTERIOR_INTERNAL_MESHES:
		_traverse_and_hide_node(exterior, target)

func _traverse_and_hide_node(node: Node, target_name: String) -> void:
	if node.name == target_name or node.name.begins_with(target_name + "_") or node.name.begins_with(target_name + "@"):
		if "visible" in node:
			node.visible = false
		if node is GeometryInstance3D:
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_traverse_and_hide_node(child, target_name)
