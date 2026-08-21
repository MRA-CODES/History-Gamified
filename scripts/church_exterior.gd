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

func _ready() -> void:
	# 1. Automatically generate exact 1:1 Trimesh collisions for all interior meshes
	_generate_interior_trimesh_collisions()
	
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

func _input(event: InputEvent) -> void:
	if is_transitioning:
		return
		
	var enter_pressed = event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER))
	if enter_pressed:
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
