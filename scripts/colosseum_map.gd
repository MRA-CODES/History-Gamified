extends Node3D

# -----------------------------------------------------------------------------
# Node References
# -----------------------------------------------------------------------------
@onready var colosseum_model: Node3D = $ColosseumModel
@onready var player: Node3D = $Player
@onready var fade_rect: ColorRect = $UI/FadeOverlay
@onready var pause_menu: Control = $UI/PauseMenu
@onready var bottom_hint: Control = $UI/BottomHint
@onready var exit_hint: PanelContainer = $UI/ExitHint
@onready var exit_label: Label = $UI/ExitHint/ExitLabel

@onready var btn_resume: Button = $UI/PauseMenu/CenterContainer/Panel/Margin/VBox/BtnResume
@onready var btn_restart: Button = $UI/PauseMenu/CenterContainer/Panel/Margin/VBox/BtnRestart
@onready var btn_main_menu: Button = $UI/PauseMenu/CenterContainer/Panel/Margin/VBox/BtnMainMenu
@onready var btn_quit: Button = $UI/PauseMenu/CenterContainer/Panel/Margin/VBox/BtnQuit

# -----------------------------------------------------------------------------
# Spawn & Interaction Coordinates
# -----------------------------------------------------------------------------
# Exterior city plaza facing the Colosseum grand facade:
const SPAWN_EXTERIOR: Vector3 = Vector3(0.0, 0.5, 160.0)

# Interior gladiatorial arena floor:
const SPAWN_INTERIOR: Vector3 = Vector3(0.0, 3.5, 15.0)

# Colosseum outer perimeter wall is at R ≈ 140m.
# Proximity trigger activates when player approaches the exterior walls (R <= 158m):
const ENTER_PROXIMITY_RADIUS: float = 158.0

# State
var is_paused: bool = false
var is_transitioning: bool = false
var is_inside_interior: bool = false

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------
func _ready() -> void:
	# 1. Generate 1:1 solid Trimesh collisions for all Colosseum and city meshes
	if colosseum_model:
		_generate_trimesh_collisions(colosseum_model)
		
	# 2. Position player outside in the city plaza
	if player:
		player.global_position = SPAWN_EXTERIOR
		player.rotation = Vector3.ZERO
		if "camera_rot_y" in player:
			player.camera_rot_y = PI
		var cam_pivot = player.get_node_or_null("CameraPivot")
		if cam_pivot:
			cam_pivot.rotation.y = PI
		is_inside_interior = false
		
	# 3. Setup UI hints
	if exit_hint:
		exit_hint.visible = true
		if exit_label:
			exit_label.text = "✦ Press [ F ] to Enter Colosseum Interior ✦"
		
	# 4. Fade in on scene start
	if fade_rect:
		fade_rect.modulate.a = 1.0
		fade_rect.visible = true
		var tween = create_tween()
		tween.tween_property(fade_rect, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	# 5. Setup Pause Menu initial state
	if pause_menu:
		pause_menu.visible = false
	if btn_resume:
		btn_resume.pressed.connect(_toggle_pause_menu)
	if btn_restart:
		btn_restart.pressed.connect(_on_restart_pressed)
	if btn_main_menu:
		btn_main_menu.pressed.connect(_on_main_menu_pressed)
	if btn_quit:
		btn_quit.pressed.connect(_on_quit_pressed)
		
	# 6. Capture mouse for free look
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(_delta: float) -> void:
	if not player or is_transitioning or is_paused:
		return
		
	var player_pos = player.global_position
	var current_radius = Vector2(player_pos.x, player_pos.z).length()
	
	if not is_inside_interior:
		# When outside and anywhere near the Colosseum exterior structure:
		if current_radius <= ENTER_PROXIMITY_RADIUS:
			if exit_hint: exit_hint.visible = true
			if exit_label: exit_label.text = "✦ Press [ F ] to Enter Colosseum Interior ✦"
		else:
			if exit_hint: exit_hint.visible = false
	else:
		# When inside the Colosseum interior:
		if exit_hint: exit_hint.visible = true
		if exit_label: exit_label.text = "✦ Press [ F ] to Exit to Rome City ✦"

func _unhandled_input(event: InputEvent) -> void:
	if is_transitioning:
		return
		
	# Press F to enter or exit
	if event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_F:
		if is_inside_interior:
			_transition_to_exterior()
			get_viewport().set_input_as_handled()
			return
		elif player:
			var current_radius = Vector2(player.global_position.x, player.global_position.z).length()
			if current_radius <= ENTER_PROXIMITY_RADIUS:
				_transition_to_interior()
				get_viewport().set_input_as_handled()
				return
			
	# Toggle Pause Menu when pressing Escape
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_toggle_pause_menu()
		get_viewport().set_input_as_handled()

# -----------------------------------------------------------------------------
# Seamless Gate / Wall Transitions
# -----------------------------------------------------------------------------
func _transition_to_interior() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	if fade_rect:
		var tween = create_tween()
		tween.tween_property(fade_rect, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func():
			player.global_position = SPAWN_INTERIOR
			player.velocity = Vector3.ZERO
			player.rotation = Vector3.ZERO
			is_inside_interior = true
			if exit_hint:
				exit_hint.visible = true
			if exit_label:
				exit_label.text = "✦ Press [ F ] to Exit to Rome City ✦"
		)
		tween.tween_property(fade_rect, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func():
			is_transitioning = false
		)
	else:
		player.global_position = SPAWN_INTERIOR
		player.velocity = Vector3.ZERO
		player.rotation = Vector3.ZERO
		is_inside_interior = true
		if exit_hint:
			exit_hint.visible = true
		if exit_label:
			exit_label.text = "✦ Press [ F ] to Exit to Rome City ✦"
		is_transitioning = false

func _transition_to_exterior() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	if fade_rect:
		var tween = create_tween()
		tween.tween_property(fade_rect, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func():
			player.global_position = SPAWN_EXTERIOR
			player.velocity = Vector3.ZERO
			player.rotation = Vector3.ZERO
			if "camera_rot_y" in player:
				player.camera_rot_y = PI
			var cam_pivot = player.get_node_or_null("CameraPivot")
			if cam_pivot:
				cam_pivot.rotation.y = PI
			is_inside_interior = false
			if exit_hint:
				exit_hint.visible = true
			if exit_label:
				exit_label.text = "✦ Press [ F ] to Enter Colosseum Interior ✦"
		)
		tween.tween_property(fade_rect, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func():
			is_transitioning = false
		)
	else:
		player.global_position = SPAWN_EXTERIOR
		player.velocity = Vector3.ZERO
		player.rotation = Vector3.ZERO
		if "camera_rot_y" in player:
			player.camera_rot_y = PI
		var cam_pivot = player.get_node_or_null("CameraPivot")
		if cam_pivot:
			cam_pivot.rotation.y = PI
		is_inside_interior = false
		if exit_hint:
			exit_hint.visible = true
		if exit_label:
			exit_label.text = "✦ Press [ F ] to Enter Colosseum Interior ✦"
		is_transitioning = false

# -----------------------------------------------------------------------------
# Pause Menu Logic
# -----------------------------------------------------------------------------
func _toggle_pause_menu() -> void:
	is_paused = not is_paused
	if pause_menu:
		pause_menu.visible = is_paused
	if is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if bottom_hint: bottom_hint.visible = false
		if exit_hint: exit_hint.visible = false
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if bottom_hint: bottom_hint.visible = true
		if exit_hint: exit_hint.visible = true

func _on_restart_pressed() -> void:
	_toggle_pause_menu()
	if player:
		player.global_position = SPAWN_EXTERIOR
		player.velocity = Vector3.ZERO
		player.rotation = Vector3.ZERO
		if "camera_rot_y" in player:
			player.camera_rot_y = PI
		var cam_pivot = player.get_node_or_null("CameraPivot")
		if cam_pivot:
			cam_pivot.rotation.y = PI
		is_inside_interior = false
		if exit_hint:
			exit_hint.visible = true
		if exit_label:
			exit_label.text = "✦ Press [ F ] to Enter Colosseum Interior ✦"

func _on_main_menu_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if fade_rect:
		var tween = create_tween()
		tween.tween_property(fade_rect, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func():
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		)
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

# -----------------------------------------------------------------------------
# Trimesh Collision Generation
# -----------------------------------------------------------------------------
func _generate_trimesh_collisions(node: Node) -> void:
	if not node:
		return
	_traverse_and_add_trimesh(node)

func _traverse_and_add_trimesh(n: Node) -> void:
	if n is MeshInstance3D and n.mesh:
		var has_static_body = false
		for child in n.get_children():
			if child is StaticBody3D:
				has_static_body = true
				break
		if not has_static_body:
			var trimesh_shape = n.mesh.create_trimesh_shape()
			if trimesh_shape:
				var static_body = StaticBody3D.new()
				var col_shape = CollisionShape3D.new()
				col_shape.shape = trimesh_shape
				static_body.add_child(col_shape)
				n.add_child(static_body)
	for child in n.get_children():
		_traverse_and_add_trimesh(child)
