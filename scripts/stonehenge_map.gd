extends Node3D

@onready var stonehenge_model: Node3D = $StonehengeModel
@onready var player: Node3D = $Player
@onready var fade_rect: ColorRect = $UI/FadeOverlay
@onready var btn_menu: Button = $UI/TopHUD/Margin/HBox/BtnMenu

var is_transitioning: bool = false

func _ready() -> void:
	# 1. Generate 1:1 Trimesh collisions for all stones in Stonehenge
	_generate_trimesh_collisions(stonehenge_model)
	
	# 2. Fade in on scene start
	if fade_rect:
		fade_rect.modulate.a = 1.0
		fade_rect.visible = true
		var tween = create_tween()
		tween.tween_property(fade_rect, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	# 3. Connect Return to Menu Button
	if btn_menu:
		btn_menu.pressed.connect(_on_return_to_menu_pressed)
		
	# Capture mouse for free look
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if is_transitioning:
		return
		
	# Return to menu on Escape if mouse is already visible
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		_on_return_to_menu_pressed()

func _on_return_to_menu_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if fade_rect:
		var tween = create_tween()
		tween.tween_property(fade_rect, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func():
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		)
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

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
