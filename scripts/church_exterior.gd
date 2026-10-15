extends Node3D

@onready var exterior: Node3D = $Exterior
@onready var interior: Node3D = $Interior
@onready var city_env: Node3D = $CityEnvironment
@onready var player: Node3D = $Player
@onready var transition_rect: ColorRect = $TransitionOverlay/ColorRect
@onready var prompt_label: Label = $TransitionOverlay/PromptLabel
@onready var enter_trigger: Area3D = $Triggers/EnterInteriorTrigger
@onready var exit_trigger: Area3D = $Triggers/ExitExteriorTrigger

var is_inside: bool = false
var is_transitioning: bool = false
var can_enter: bool = false
var can_exit: bool = false
var is_paused: bool = false
var interior_collisions_generated: bool = false
var pause_menu: Control = null

func _ready() -> void:
	# 1. Setup interior initial state (hidden until entered, avoids rendering & collision overhead)
	if interior:
		interior.visible = false
		
	# 2. Setup transition overlay & prompt
	if transition_rect:
		transition_rect.modulate.a = 0.0
		transition_rect.visible = true
	if prompt_label:
		prompt_label.visible = false
		
	# 3. Always ensure city_env is visible outside
	if city_env:
		city_env.visible = true
		
	# 4. Connect triggers
	if enter_trigger:
		enter_trigger.body_entered.connect(_on_enter_trigger_entered)
		enter_trigger.body_exited.connect(_on_enter_trigger_exited)
	if exit_trigger:
		exit_trigger.body_entered.connect(_on_exit_trigger_entered)
		exit_trigger.body_exited.connect(_on_exit_trigger_exited)
		
	# 5. Initialize educational monument system
	_setup_educational_system()
	
	# 6. Initialize pause menu
	_setup_pause_menu()
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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
			
	if not has_node("MinimapUI"):
		var minimap_scene = load("res://scenes/minimap/minimap.tscn")
		if minimap_scene:
			var minimap_inst = minimap_scene.instantiate()
			minimap_inst.name = "MinimapUI"
			add_child(minimap_inst)
			
	var map_mgr = get_node_or_null("MinimapUI/MapManager")
	if map_mgr:
		map_mgr.set_player(player)
		map_mgr.set_inside_state(is_inside)

func _input(event: InputEvent) -> void:
	if is_transitioning:
		return
		
	if event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_ESCAPE:
		_toggle_pause_menu()
		get_viewport().set_input_as_handled()
		return
		
	var enter_pressed = event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER))
	if enter_pressed and not is_paused:
		if can_enter and not is_inside:
			_teleport_to_interior()
		elif can_exit and is_inside:
			_teleport_to_exterior()

func _on_enter_trigger_entered(body: Node3D) -> void:
	if body == player and not is_inside:
		can_enter = true
		_show_prompt("[ ENTER ] Enter Hintze Hall")

func _on_enter_trigger_exited(body: Node3D) -> void:
	if body == player:
		can_enter = false
		if not can_exit:
			_hide_prompt()

func _on_exit_trigger_entered(body: Node3D) -> void:
	if body == player and is_inside:
		can_exit = true
		_show_prompt("[ ENTER ] Exit to Plaza")

func _on_exit_trigger_exited(body: Node3D) -> void:
	if body == player:
		can_exit = false
		if not can_enter:
			_hide_prompt()

func _show_prompt(msg: String) -> void:
	if prompt_label:
		prompt_label.text = msg
		prompt_label.visible = true

func _hide_prompt() -> void:
	if prompt_label:
		prompt_label.visible = false

func _teleport_to_interior() -> void:
	is_transitioning = true
	can_enter = false
	_hide_prompt()
	
	var tween = create_tween()
	tween.tween_property(transition_rect, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		is_inside = true
		exterior.visible = false
		interior.visible = true
		if not interior_collisions_generated:
			_generate_interior_trimesh_collisions()
			interior_collisions_generated = true
		if city_env:
			city_env.visible = false
		if player:
			player.global_position = Vector3(0.0, 3.2, 16.0)
			player.velocity = Vector3.ZERO
			if "camera_rot_y" in player:
				player.camera_rot_y = 0.0
				player.camera_rot_x = -0.15
			if player.has_node("Visuals"):
				player.get_node("Visuals").rotation.y = 0.0
			if player.has_node("CameraPivot"):
				player.get_node("CameraPivot").rotation.y = 0.0
				var spring = player.get_node("CameraPivot/SpringArm3D")
				if spring:
					spring.rotation.x = -0.15
		var map_mgr = get_node_or_null("MinimapUI/MapManager")
		if map_mgr:
			map_mgr.set_inside_state(true)
	)
	tween.tween_property(transition_rect, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): is_transitioning = false)

func _teleport_to_exterior() -> void:
	is_transitioning = true
	can_exit = false
	_hide_prompt()
	
	var tween = create_tween()
	tween.tween_property(transition_rect, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		is_inside = false
		exterior.visible = true
		interior.visible = false
		if city_env:
			city_env.visible = true
		if player:
			player.global_position = Vector3(0.0, 3.5, 44.0)
			player.velocity = Vector3.ZERO
			if "camera_rot_y" in player:
				player.camera_rot_y = 0.0
				player.camera_rot_x = -0.15
			if player.has_node("Visuals"):
				player.get_node("Visuals").rotation.y = 0.0
			if player.has_node("CameraPivot"):
				player.get_node("CameraPivot").rotation.y = 0.0
				var spring = player.get_node("CameraPivot/SpringArm3D")
				if spring:
					spring.rotation.x = -0.15
		var map_mgr = get_node_or_null("MinimapUI/MapManager")
		if map_mgr:
			map_mgr.set_inside_state(false)
	)
	tween.tween_property(transition_rect, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): is_transitioning = false)

func _generate_interior_trimesh_collisions() -> void:
	if not interior:
		return
	_traverse_and_add_trimesh(interior)

func _traverse_and_add_trimesh(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		var has_static_body = false
		for child in node.get_children():
			if child is StaticBody3D:
				has_static_body = true
				break
		if not has_static_body:
			var trimesh_shape = node.mesh.create_trimesh_shape()
			if trimesh_shape:
				var static_body = StaticBody3D.new()
				var col_shape = CollisionShape3D.new()
				col_shape.shape = trimesh_shape
				static_body.add_child(col_shape)
				node.add_child(static_body)
	for child in node.get_children():
		_traverse_and_add_trimesh(child)

# -----------------------------------------------------------------------------
# Pause Menu Setup & Navigation
# -----------------------------------------------------------------------------
func _setup_pause_menu() -> void:
	var ui_canvas = CanvasLayer.new()
	ui_canvas.name = "PauseMenuCanvas"
	ui_canvas.layer = 110
	add_child(ui_canvas)
	
	pause_menu = Control.new()
	pause_menu.name = "PauseMenu"
	pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_menu.visible = false
	ui_canvas.add_child(pause_menu)
	
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.65)
	pause_menu.add_child(dim)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_menu.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 300)
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.08, 0.09, 0.14, 0.96)
	p_style.border_width_left = 2
	p_style.border_width_top = 2
	p_style.border_width_right = 2
	p_style.border_width_bottom = 2
	p_style.border_color = Color(0.85, 0.7, 0.28, 0.9)
	p_style.corner_radius_top_left = 12
	p_style.corner_radius_top_right = 12
	p_style.corner_radius_bottom_right = 12
	p_style.corner_radius_bottom_left = 12
	panel.add_theme_stylebox_override("panel", p_style)
	center.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 25)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "NATURAL HISTORY MUSEUM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 0.88, 0.45, 1))
	vbox.add_child(title)
	
	var sub = Label.new()
	sub.text = "London, 1881 CE • Victorian Era"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.8, 0.82, 0.88, 0.9))
	vbox.add_child(sub)
	
	var btn_resume = Button.new()
	btn_resume.text = "▶  Resume Exploration"
	btn_resume.custom_minimum_size = Vector2(0, 38)
	btn_resume.pressed.connect(_toggle_pause_menu)
	vbox.add_child(btn_resume)
	
	var btn_restart = Button.new()
	btn_restart.text = "↺  Restart View"
	btn_restart.custom_minimum_size = Vector2(0, 38)
	btn_restart.pressed.connect(func():
		_toggle_pause_menu()
		if player:
			player.global_position = Vector3(0.0, 3.5, 48.0)
			player.velocity = Vector3.ZERO
	)
	vbox.add_child(btn_restart)
	
	var btn_menu = Button.new()
	btn_menu.text = "⟵  Return to Main Menu"
	btn_menu.custom_minimum_size = Vector2(0, 38)
	btn_menu.pressed.connect(_on_main_menu_pressed)
	vbox.add_child(btn_menu)
	
	var btn_quit = Button.new()
	btn_quit.text = "✕  Exit to Desktop"
	btn_quit.custom_minimum_size = Vector2(0, 38)
	btn_quit.pressed.connect(func(): get_tree().quit())
	vbox.add_child(btn_quit)

func _toggle_pause_menu() -> void:
	is_paused = not is_paused
	if pause_menu:
		pause_menu.visible = is_paused
	if is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_main_menu_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if has_node("/root/SceneLoader"):
		get_node("/root/SceneLoader").change_scene_to("res://scenes/main_menu.tscn", "MAIN MENU", "History Gamified")
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

