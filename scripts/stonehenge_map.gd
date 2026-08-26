extends Node3D

const StonehengeRimData = preload("res://scripts/stonehenge_rim_data.gd")

# -----------------------------------------------------------------------------
# Node References
# -----------------------------------------------------------------------------
@onready var stonehenge_model: Node3D = $StonehengeModel
@onready var plains_ring: MeshInstance3D = $SurroundingPlainsRing
@onready var player: Node3D = $Player
@onready var fade_rect: ColorRect = $UI/FadeOverlay
@onready var pause_menu: Control = $UI/PauseMenu
@onready var bottom_hint: Control = $UI/BottomHint

@onready var btn_resume: Button = $UI/PauseMenu/CenterContainer/Panel/Margin/VBox/BtnResume
@onready var btn_restart: Button = $UI/PauseMenu/CenterContainer/Panel/Margin/VBox/BtnRestart
@onready var btn_main_menu: Button = $UI/PauseMenu/CenterContainer/Panel/Margin/VBox/BtnMainMenu
@onready var btn_quit: Button = $UI/PauseMenu/CenterContainer/Panel/Margin/VBox/BtnQuit

# State
var is_paused: bool = false
var is_transitioning: bool = false
var noise: FastNoiseLite = null

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------
func _ready() -> void:
	# 0. Configure player locomotion
	if player:
		player.allow_stair_animation = false
		
	# 1. Initialize rolling landscape noise
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = 4289
	noise.frequency = 0.006
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.35
	
	# 2. Generate conforming terrain starting exactly at the Stonehenge GLB boundary
	_generate_conforming_terrain()
	
	# 3. Add 3D waving grass billboards outside the monument perimeter
	_populate_surrounding_3d_grass()
	
	# 4. Generate 1:1 solid Trimesh collisions for Stonehenge stones and terrain
	_generate_trimesh_collisions(stonehenge_model)
	
	# 5. Fade in on scene start
	if fade_rect:
		fade_rect.modulate.a = 1.0
		fade_rect.visible = true
		var tween = create_tween()
		tween.tween_property(fade_rect, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	# 6. Setup Pause Menu
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
		
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if is_transitioning:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_toggle_pause_menu()
		get_viewport().set_input_as_handled()

# -----------------------------------------------------------------------------
# Elevation Conformity Function
# -----------------------------------------------------------------------------
func _get_conforming_height(radius: float, angle: float) -> float:
	var boundary_info = StonehengeRimData.get_boundary_at_angle(angle)
	var bound_r = boundary_info.x
	var bound_y = boundary_info.y
	
	# Transition zone from boundary outward (45 meters)
	var dist_out = max(0.0, radius - bound_r)
	var blend_t = clampf(dist_out / 45.0, 0.0, 1.0)
	var smooth_t = blend_t * blend_t * (3.0 - 2.0 * blend_t) # Smooth Hermite curve
	
	var px = cos(angle) * radius
	var pz = sin(angle) * radius
	var landscape_h = noise.get_noise_2d(px, pz) * 6.5 - 0.2
	
	# Start at exact boundary elevation and blend smoothly outward
	return lerp(bound_y - 0.02, landscape_h, smooth_t)

# -----------------------------------------------------------------------------
# 3D Conforming Procedural Terrain Generator
# -----------------------------------------------------------------------------
func _generate_conforming_terrain() -> void:
	if not plains_ring:
		return
		
	# 1. Setup PBR Grass Material matching photogrammetry turf
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	
	var albedo_path = "res://assets/environment/buildings/Map 2-StoneHenge/meadow_ground_albedo.jpg"
	var normal_path = "res://assets/environment/buildings/Map 2-StoneHenge/meadow_ground_normal.jpg"
	
	var img_albedo = Image.load_from_file(ProjectSettings.globalize_path(albedo_path))
	if img_albedo:
		var tex_albedo = ImageTexture.create_from_image(img_albedo)
		mat.albedo_texture = tex_albedo
		
	var img_normal = Image.load_from_file(ProjectSettings.globalize_path(normal_path))
	if img_normal:
		var tex_normal = ImageTexture.create_from_image(img_normal)
		mat.normal_enabled = true
		mat.normal_texture = tex_normal
		mat.normal_scale = 0.4
		
	mat.roughness = 0.95
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	plains_ring.material_override = mat
	
	# 2. Build Conforming Mesh from Boundary Outward
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var outer_r = 750.0
	var ring_steps = 40
	var radial_steps = 128
	
	for ring in range(ring_steps):
		var t1 = float(ring) / float(ring_steps)
		var t2 = float(ring + 1) / float(ring_steps)
		
		# Exponential radial distribution: dense rings near boundary, sparser at horizon
		var factor1 = pow(t1, 1.35)
		var factor2 = pow(t2, 1.35)
		
		for rad in range(radial_steps):
			var a1 = (float(rad) / radial_steps) * TAU
			var a2 = (float(rad + 1) / radial_steps) * TAU
			
			# Sample exact GLB boundary at angles a1 and a2
			var bound1 = StonehengeRimData.get_boundary_at_angle(a1)
			var bound2 = StonehengeRimData.get_boundary_at_angle(a2)
			
			# Ring 0 starts with a tight 30cm underlap directly at the GLB perimeter
			var r_start1 = bound1.x - 0.3
			var r_start2 = bound2.x - 0.3
			
			var r1_1 = lerp(r_start1, outer_r, factor1)
			var r1_2 = lerp(r_start2, outer_r, factor1)
			
			var r2_1 = lerp(r_start1, outer_r, factor2)
			var r2_2 = lerp(r_start2, outer_r, factor2)
			
			var x1_1 = cos(a1) * r1_1
			var z1_1 = sin(a1) * r1_1
			var y1_1 = _get_conforming_height(r1_1, a1)
			
			var x1_2 = cos(a2) * r1_2
			var z1_2 = sin(a2) * r1_2
			var y1_2 = _get_conforming_height(r1_2, a2)
			
			var x2_1 = cos(a1) * r2_1
			var z2_1 = sin(a1) * r2_1
			var y2_1 = _get_conforming_height(r2_1, a1)
			
			var x2_2 = cos(a2) * r2_2
			var z2_2 = sin(a2) * r2_2
			var y2_2 = _get_conforming_height(r2_2, a2)
			
			var p1 = Vector3(x1_1, y1_1, z1_1)
			var p2 = Vector3(x1_2, y1_2, z1_2)
			var p3 = Vector3(x2_1, y2_1, z2_1)
			var p4 = Vector3(x2_2, y2_2, z2_2)
			
			var uv1 = Vector2(x1_1, z1_1) / 10.0
			var uv2 = Vector2(x1_2, z1_2) / 10.0
			var uv3 = Vector2(x2_1, z2_1) / 10.0
			var uv4 = Vector2(x2_2, z2_2) / 10.0
			
			# Quad Triangle 1
			st.set_uv(uv1)
			st.add_vertex(p1)
			st.set_uv(uv3)
			st.add_vertex(p3)
			st.set_uv(uv4)
			st.add_vertex(p4)
			
			# Quad Triangle 2
			st.set_uv(uv1)
			st.add_vertex(p1)
			st.set_uv(uv4)
			st.add_vertex(p4)
			st.set_uv(uv2)
			st.add_vertex(p2)
			
	st.generate_normals()
	st.generate_tangents()
	var terrain_mesh = st.commit()
	plains_ring.mesh = terrain_mesh
	
	# Solid collision matching conforming terrain
	var trimesh = terrain_mesh.create_trimesh_shape()
	if trimesh:
		var sb = StaticBody3D.new()
		var cs = CollisionShape3D.new()
		cs.shape = trimesh
		sb.add_child(cs)
		plains_ring.add_child(sb)

# -----------------------------------------------------------------------------
# 3D Waving Grass Blades
# -----------------------------------------------------------------------------
func _populate_surrounding_3d_grass() -> void:
	var foliage_node = get_node_or_null("Foliage")
	if foliage_node:
		foliage_node.queue_free()
		
	foliage_node = Node3D.new()
	foliage_node.name = "Foliage"
	add_child(foliage_node)
	
	var grass_mat = StandardMaterial3D.new()
	var blade_path = "res://assets/environment/buildings/Map 2-StoneHenge/grass_blade_diffuse.png"
	var img_blade = Image.load_from_file(ProjectSettings.globalize_path(blade_path))
	if img_blade:
		var tex_blade = ImageTexture.create_from_image(img_blade)
		grass_mat.albedo_texture = tex_blade
		
	grass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	grass_mat.alpha_scissor_threshold = 0.45
	grass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	grass_mat.roughness = 0.95
	grass_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for blade_idx in range(3):
		var ang = float(blade_idx) * (PI / 3.0)
		var hw = 0.65
		var h = 0.85
		
		var dx = cos(ang) * hw
		var dz = sin(ang) * hw
		
		var v1 = Vector3(-dx, 0.0, -dz)
		var v2 = Vector3(dx, 0.0, dz)
		var v3 = Vector3(dx, h, dz)
		var v4 = Vector3(-dx, h, -dz)
		
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0, 1))
		st.add_vertex(v1)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(1, 0))
		st.add_vertex(v3)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(1, 1))
		st.add_vertex(v2)
		
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0, 1))
		st.add_vertex(v1)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(v4)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(1, 0))
		st.add_vertex(v3)
		
	st.generate_normals()
	var tuft_mesh = st.commit()
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = tuft_mesh
	
	var tuft_count = 650
	mm.instance_count = tuft_count
	
	var rng = RandomNumberGenerator.new()
	rng.seed = 9411
	
	for i in range(tuft_count):
		var ang = rng.randf_range(0, TAU)
		var bound_r = StonehengeRimData.get_boundary_at_angle(ang).x
		var dist = rng.randf_range(bound_r + 4.0, bound_r + 90.0)
		
		var gx = cos(ang) * dist
		var gz = sin(ang) * dist
		var gy = _get_conforming_height(dist, ang)
		
		var s = rng.randf_range(0.8, 1.35)
		var rot_y = rng.randf_range(0, TAU)
		var t = Transform3D().rotated(Vector3.UP, rot_y).scaled(Vector3(s, s, s))
		t.origin = Vector3(gx, gy, gz)
		mm.set_instance_transform(i, t)
		
	var mmi = MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = grass_mat
	foliage_node.add_child(mmi)

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
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if bottom_hint: bottom_hint.visible = true

func _on_restart_pressed() -> void:
	_toggle_pause_menu()
	if player:
		player.global_position = Vector3(0.0, 1.2, 24.0)
		player.velocity = Vector3.ZERO

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
