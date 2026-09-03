# -----------------------------------------------------------------------------
# agra_world.gd
# Map 4: Agra World (Taj Mahal & Yamuna River Valley)
# -----------------------------------------------------------------------------
extends Node3D

# -----------------------------------------------------------------------------
# Constants & Paths
# -----------------------------------------------------------------------------
const HEIGHTMAP_PATH := "res://assets/terrain/MAp 4- TAJ MAHAL_Terrain/agra_heightmap.png.png"
const TAJ_MAHAL_MODEL_PATH := "res://assets/environment/buildings/Map 4 - Taj Mahal_Buildings/TajMahal (lowpoly).glb"

# PBR Texture Paths
const TEX_SAND_DIFF := "res://assets/textures/Map -4 TAJ MAHAL_Textures/river_sand/gravelly_sand_diff_2k.jpg"
const TEX_SAND_NORM := "res://assets/textures/Map -4 TAJ MAHAL_Textures/river_sand/gravelly_sand_nor_gl_2k.jpg"
const TEX_SAND_ROUGH := "res://assets/textures/Map -4 TAJ MAHAL_Textures/river_sand/gravelly_sand_rough_2k.jpg"
const TEX_SAND_AO := "res://assets/textures/Map -4 TAJ MAHAL_Textures/river_sand/gravelly_sand_ao_2k.jpg"

const TEX_GRASS_DIFF := "res://assets/textures/Map -4 TAJ MAHAL_Textures/grass/leafy_grass_diff_2k.jpg"
const TEX_GRASS_NORM := "res://assets/textures/Map -4 TAJ MAHAL_Textures/grass/leafy_grass_nor_gl_2k.jpg"
const TEX_GRASS_ROUGH := "res://assets/textures/Map -4 TAJ MAHAL_Textures/grass/leafy_grass_rough_2k.jpg"
const TEX_GRASS_AO := "res://assets/textures/Map -4 TAJ MAHAL_Textures/grass/leafy_grass_ao_2k.jpg"

const TEX_WALKWAYS_DIFF := "res://assets/textures/Map -4 TAJ MAHAL_Textures/walkways/PavingStones092_2K-JPG_Color.jpg"
const TEX_WALKWAYS_NORM := "res://assets/textures/Map -4 TAJ MAHAL_Textures/walkways/PavingStones092_2K-JPG_NormalGL.jpg"
const TEX_WALKWAYS_ROUGH := "res://assets/textures/Map -4 TAJ MAHAL_Textures/walkways/PavingStones092_2K-JPG_Roughness.jpg"
const TEX_WALKWAYS_AO := "res://assets/textures/Map -4 TAJ MAHAL_Textures/walkways/PavingStones092_2K-JPG_AmbientOcclusion.jpg"

const TEX_SANDSTONE_DIFF := "res://assets/textures/Map -4 TAJ MAHAL_Textures/red_sandstone/red_sandstone_pavement_diff_2k.jpg"
const TEX_SANDSTONE_NORM := "res://assets/textures/Map -4 TAJ MAHAL_Textures/red_sandstone/red_sandstone_pavement_nor_gl_2k.jpg"
const TEX_SANDSTONE_ROUGH := "res://assets/textures/Map -4 TAJ MAHAL_Textures/red_sandstone/red_sandstone_pavement_rough_2k.jpg"
const TEX_SANDSTONE_AO := "res://assets/textures/Map -4 TAJ MAHAL_Textures/red_sandstone/red_sandstone_pavement_ao_2k.jpg"

const TEX_MARBLE_DIFF := "res://assets/textures/Map -4 TAJ MAHAL_Textures/marble/marble_tiles_diff_2k.jpg"
const TEX_MARBLE_NORM := "res://assets/textures/Map -4 TAJ MAHAL_Textures/marble/marble_tiles_nor_gl_2k.jpg"
const TEX_MARBLE_ROUGH := "res://assets/textures/Map -4 TAJ MAHAL_Textures/marble/marble_tiles_rough_2k.jpg"
const TEX_MARBLE_AO := "res://assets/textures/Map -4 TAJ MAHAL_Textures/marble/marble_tiles_ao_2k.jpg"

const CONTROLMAP_BIN_PATH := "res://assets/terrain/MAp 4- TAJ MAHAL_Terrain/agra_controlmap.bin"
const ASSETS_TRES_PATH := "res://assets/terrain/MAp 4- TAJ MAHAL_Terrain/taj_mahal_terrain_assets.tres"

# 1:1 Real-world Taj Mahal scale (73m dome height / 372.6 model units)
const TAJ_SCALE := Vector3(0.196, 0.196, 0.196)

# Vegetation & Water Constants
const CYPRESS_MODEL_PATH: String = "res://assets/environment/buildings/Map 4 - Taj Mahal_Buildings/tree_cypress.glb"
const TEX_CYPRESS_LEAVES: String = "res://assets/environment/buildings/Map 4 - Taj Mahal_Buildings/tree_cypress_0.jpg"
const TEX_CYPRESS_TRUNK: String = "res://assets/environment/buildings/Map 4 - Taj Mahal_Buildings/tree_cypress_1.jpg"
const GRASS_SHADER_PATH: String = "res://shaders/grass_foliage.gdshader"
const WATER_SHADER_PATH: String = "res://shaders/water_realistic.gdshader"

# -----------------------------------------------------------------------------
# Node References
# -----------------------------------------------------------------------------
@onready var sun_light: DirectionalLight3D = $SunLight
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var taj_mahal_root: Node3D = $TajMahalContainer
@onready var overview_camera: Camera3D = get_node_or_null("OverviewCamera") as Camera3D
@onready var player: CharacterBody3D = get_node_or_null("Player") as CharacterBody3D
@onready var ui_root: CanvasLayer = $UI
@onready var fade_rect: ColorRect = $UI/FadeOverlay
@onready var pause_menu: Control = $UI/PauseMenu

@onready var btn_resume: Button = $UI/PauseMenu/CenterContainer/Panel/Margin/VBox/BtnResume
@onready var btn_restart: Button = $UI/PauseMenu/CenterContainer/Panel/Margin/VBox/BtnRestart
@onready var btn_main_menu: Button = $UI/PauseMenu/CenterContainer/Panel/Margin/VBox/BtnMainMenu
@onready var btn_quit: Button = $UI/PauseMenu/CenterContainer/Panel/Margin/VBox/BtnQuit

var is_paused: bool = false
var is_transitioning: bool = false
var is_freecam: bool = false
var freecam_speed: float = 35.0
var freecam_rot_x: float = -0.15
var freecam_rot_y: float = 0.0
var terrain_node: Node = null

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------
func _ready() -> void:
	print("AgraWorld: Initializing 1:1 commercial map setup...")
	
	# 1. Setup UI & Fade In
	_setup_ui()
	
	# 2. Setup or Configure Terrain3D
	_setup_terrain()
	
	# 3. Instantiate Taj Mahal model at 1:1 scale and position on plinth
	_setup_taj_mahal_monument()
	
	# 4. Position Player on the Charbagh entrance promenade
	_setup_player()
	
	# 5. Symmetrical Cypress Trees & Procedural Waving Grass Scattering
	_setup_vegetation()
	
	# 6. Realistic Water Systems (Yamuna River & Charbagh Reflecting Pools)
	_setup_water_systems()
	
	# 7. AAA Realism Lighting & Atmosphere (SDFGI, SSAO, SSIL, Volumetric Fog)
	_setup_lighting_and_atmosphere()
	
	# 8. Generate Trimesh Collision for all building structures
	if taj_mahal_root:
		_generate_trimesh_collisions(taj_mahal_root)
		print("AgraWorld: Trimesh collision generated for Taj Mahal complex.")

func _setup_player() -> void:
	if not player:
		return
	
	# Capture mouse by default for 3rd person exploration
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Calculate ground elevation on southern Charbagh promenade aligned with Taj Mahal
	var start_pos: Vector3 = Vector3(-125.844, 0.0, 40.0)
	var ground_y: float = 33.2
	if terrain_node and ("data" in terrain_node) and terrain_node.data:
		var q_y: float = terrain_node.data.get_height(start_pos)
		if not is_nan(q_y) and abs(q_y) < 50.0:
			ground_y = q_y
			
	player.global_position = Vector3(-125.844, ground_y + 1.2, 40.0)
	player.rotation = Vector3(0.0, PI, 0.0) # Face North towards Taj Mahal
	print("AgraWorld: Player placed at Charbagh promenade (", -125.844, ", ", ground_y + 1.2, ", 40.0) facing Taj Mahal.")

func _physics_process(delta: float) -> void:
	# Fallback out-of-bounds safety check for Player
	if player and not is_freecam:
		if player.global_position.y < 28.0:
			player.global_position = Vector3(-125.844, 34.5, 40.0)
			player.velocity = Vector3.ZERO
			
	if is_paused or not is_freecam or not overview_camera:
		return
		
	var input_dir: Vector3 = Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		input_dir -= overview_camera.global_transform.basis.z
	if Input.is_key_pressed(KEY_S):
		input_dir += overview_camera.global_transform.basis.z
	if Input.is_key_pressed(KEY_A):
		input_dir -= overview_camera.global_transform.basis.x
	if Input.is_key_pressed(KEY_D):
		input_dir += overview_camera.global_transform.basis.x
	if Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_SPACE):
		input_dir += Vector3.UP
	if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_CTRL):
		input_dir -= Vector3.UP
		
	var speed_mult: float = 3.0 if Input.is_key_pressed(KEY_SHIFT) else 1.0
	if input_dir.length_squared() > 0.001:
		overview_camera.global_position += input_dir.normalized() * (freecam_speed * speed_mult * delta)

func _unhandled_input(event: InputEvent) -> void:
	if is_transitioning:
		return
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_toggle_pause_menu()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_V or event.keycode == KEY_C:
			_toggle_freecam()
			get_viewport().set_input_as_handled()
			
	if is_freecam and not is_paused and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if overview_camera:
			freecam_rot_y -= event.relative.x * 0.003
			freecam_rot_x -= event.relative.y * 0.003
			freecam_rot_x = clampf(freecam_rot_x, -1.4, 1.4)
			overview_camera.rotation = Vector3(freecam_rot_x, freecam_rot_y, 0.0)
			get_viewport().set_input_as_handled()

func _toggle_freecam() -> void:
	is_freecam = not is_freecam
	if is_freecam:
		if player and player.has_node("CameraPivot/SpringArm3D/Camera3D"):
			var p_cam: Camera3D = player.get_node("CameraPivot/SpringArm3D/Camera3D") as Camera3D
			if p_cam: p_cam.current = false
		if overview_camera:
			overview_camera.current = true
			if player:
				overview_camera.global_position = player.global_position + Vector3(0.0, 10.0, 15.0)
				overview_camera.look_at(Vector3(0.0, 12.0, 0.0))
				freecam_rot_x = overview_camera.rotation.x
				freecam_rot_y = overview_camera.rotation.y
		if player:
			player.is_movement_enabled = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		print("AgraWorld: FreeCam Mode Activated (Fly around with WASD + Mouse).")
	else:
		if overview_camera:
			overview_camera.current = false
		if player and player.has_node("CameraPivot/SpringArm3D/Camera3D"):
			var p_cam: Camera3D = player.get_node("CameraPivot/SpringArm3D/Camera3D") as Camera3D
			if p_cam: p_cam.current = true
		if player:
			player.is_movement_enabled = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		print("AgraWorld: Player 3rd-Person Mode Activated.")

# -----------------------------------------------------------------------------
# Safe Cross-Platform Texture Loader
# -----------------------------------------------------------------------------
func _safe_load_texture(res_path: String) -> Texture2D:
	if ResourceLoader.exists(res_path):
		var res = load(res_path)
		if res is Texture2D:
			return res
	var global_path = ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(global_path):
		var img = Image.load_from_file(global_path)
		if img:
			return ImageTexture.create_from_image(img)
	return null

# -----------------------------------------------------------------------------
# Terrain3D Setup
# -----------------------------------------------------------------------------
func _setup_terrain() -> void:
	# Find or create Terrain3D node
	if has_node("Terrain3D"):
		terrain_node = get_node("Terrain3D")
	elif ClassDB.class_exists("Terrain3D"):
		terrain_node = ClassDB.instantiate("Terrain3D")
		terrain_node.name = "Terrain3D"
		add_child(terrain_node)
	
	if not terrain_node:
		print("AgraWorld: Terrain3D not found or class unavailable.")
		return
		
	# Enable collision & disable checkered debug view
	if "collision_enabled" in terrain_node:
		terrain_node.collision_enabled = true
	if "collision_mask" in terrain_node:
		terrain_node.collision_mask = 3
	if "show_checkered" in terrain_node:
		terrain_node.show_checkered = false

	# Add solid physical ground collision body beneath gardens to prevent falling through
	var ground_col: StaticBody3D = get_node_or_null("GardenCollisionFloor") as StaticBody3D
	if not ground_col:
		ground_col = StaticBody3D.new()
		ground_col.name = "GardenCollisionFloor"
		var cs: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(600.0, 4.0, 600.0)
		cs.shape = box
		cs.position = Vector3(-125.844, 30.5, 30.0)
		ground_col.add_child(cs)
		add_child(ground_col)

	# 1. Force Texture Array & Material Compilation
	if "material" in terrain_node and terrain_node.material:
		var mat: Terrain3DMaterial = terrain_node.material as Terrain3DMaterial
		if mat:
			mat.show_checkered = false
			mat.world_background = 0 # Terrain3DMaterial.NONE
			mat.auto_shader = false
			mat.blend_sharpness = 0.85

	# 2. Assign the 5 Terrain3DTextureAsset slots into Terrain3DAssets
	var assets: Terrain3DAssets = null
	if ResourceLoader.exists(ASSETS_TRES_PATH):
		assets = load(ASSETS_TRES_PATH) as Terrain3DAssets
	elif ClassDB.class_exists("Terrain3DAssets") and ClassDB.class_exists("Terrain3DTextureAsset"):
		assets = ClassDB.instantiate("Terrain3DAssets") as Terrain3DAssets
		
		# Slot 0 (River Sand)
		var ta_sand: Resource = _create_texture_asset("River Sand", 0, TEX_SAND_DIFF, TEX_SAND_NORM, 0.12, 1.2, 0.95, Color(0.9, 0.85, 0.78, 1))
		if ta_sand: assets.set_texture(0, ta_sand)
		
		# Slot 1 (Lawn Grass)
		var ta_grass: Resource = _create_texture_asset("Lawn Grass", 1, TEX_GRASS_DIFF, TEX_GRASS_NORM, 0.1, 1.5, 0.85, Color(0.72, 0.82, 0.65, 1))
		if ta_grass: assets.set_texture(1, ta_grass)
		
		# Slot 2 (Walkways)
		var ta_walkways: Resource = _create_texture_asset("Walkways", 2, TEX_WALKWAYS_DIFF, TEX_WALKWAYS_NORM, 0.08, 1.5, 0.75, Color(0.95, 0.92, 0.88, 1))
		if ta_walkways: assets.set_texture(2, ta_walkways)
		
		# Slot 3 (Red Sandstone)
		var ta_sandstone: Resource = _create_texture_asset("Red Sandstone", 3, TEX_SANDSTONE_DIFF, TEX_SANDSTONE_NORM, 0.07, 1.4, 0.8, Color(0.9, 0.75, 0.7, 1))
		if ta_sandstone: assets.set_texture(3, ta_sandstone)
		
		# Slot 4 (Marble)
		var ta_marble: Resource = _create_texture_asset("Marble", 4, TEX_MARBLE_DIFF, TEX_MARBLE_NORM, 0.05, 1.0, 0.4, Color(0.98, 0.98, 0.98, 1))
		if ta_marble: assets.set_texture(4, ta_marble)
		
	if assets:
		if assets.has_method("save"):
			assets.save()
		ResourceSaver.save(assets, ASSETS_TRES_PATH)
		if assets.has_method("update_texture_list"):
			assets.update_texture_list()
		if "assets" in terrain_node:
			terrain_node.assets = assets

	# 3. Add & Allocate Active Region and import boosted heightmap
	_import_heightmap_to_terrain()

func _create_texture_asset(asset_name: String, asset_id: int, diff_path: String, norm_path: String, uv_s: float, ao_s: float, rough: float, col: Color) -> Resource:
	if not ClassDB.class_exists("Terrain3DTextureAsset"):
		return null
	var ta = ClassDB.instantiate("Terrain3DTextureAsset")
	ta.name = asset_name
	ta.id = asset_id
	ta.albedo_color = col
	ta.albedo_texture = _safe_load_texture(diff_path)
	ta.normal_texture = _safe_load_texture(norm_path)
	ta.normal_depth = 1.0
	ta.ao_strength = ao_s
	ta.roughness = rough
	ta.uv_scale = uv_s
	ta.detiling_rotation = 0.15
	return ta

func _import_heightmap_to_terrain() -> void:
	if not terrain_node or not ("data" in terrain_node):
		return
		
	var data = terrain_node.data
	if not data:
		return
		
	# Ensure active region Vector2i(0, 0) is allocated so physical geometry exists
	if data.has_method("has_region") and not data.has_region(Vector2i(0, 0)):
		if data.has_method("add_region_blank"):
			data.add_region_blank(Vector2i(0, 0))
			print("AgraWorld: Allocated active region Vector2i(0, 0) in Terrain3DData.")
	
	var global_path = ProjectSettings.globalize_path(HEIGHTMAP_PATH)
	var height_img: Image = null
	if FileAccess.file_exists(global_path):
		height_img = Image.load_from_file(global_path)
	elif ResourceLoader.exists(HEIGHTMAP_PATH):
		var res = load(HEIGHTMAP_PATH)
		if res is Texture2D:
			height_img = res.get_image()
			
	if not height_img:
		print("AgraWorld: Failed to load heightmap.")
		return
		
	var w: int = height_img.get_width()
	var h: int = height_img.get_height()
	print("AgraWorld: Loaded heightmap (", w, "x", h, ")")
	
	# Load pre-baked binary control splatmap if exists, or generate dynamically
	var control_img: Image = _get_or_generate_control_map(height_img, w, h)
	
	# Height vertical scale boost: scale = 45.0m, offset = -10.0m for distinct trench & plinth visibility
	if data and data.has_method("import_images"):
		var import_pos: Vector3 = Vector3(-float(w) * 0.5, 0.0, -float(h) * 0.5)
		data.import_images([height_img, control_img, null], import_pos, -10.0, 45.0)
		if data.has_method("update_maps"):
			data.update_maps(3, true, false)
		if data.has_method("save_directory"):
			data.save_directory("res://data/terrain/map4")
			print("AgraWorld: Saved persistent region files to res://data/terrain/map4")
		print("AgraWorld: Successfully imported heightmap (Scale: 45.0m, Offset: -10.0m) and updated maps.")

func _encode_terrain_slot(slot_id: int) -> float:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(4)
	bytes.encode_u32(0, (slot_id & 0x1F) << 27)
	return bytes.decode_float(0)

func _get_or_generate_control_map(h_img: Image, w: int, h: int) -> Image:
	var control_img: Image = null
	var bin_global_path: String = ProjectSettings.globalize_path(CONTROLMAP_BIN_PATH)
	
	if FileAccess.file_exists(bin_global_path):
		var file: FileAccess = FileAccess.open(bin_global_path, FileAccess.READ)
		if file:
			var buffer: PackedByteArray = file.get_buffer(w * h * 4)
			file.close()
			if buffer.size() == w * h * 4:
				control_img = Image.create_from_data(w, h, false, Image.FORMAT_RF, buffer)
				print("AgraWorld: Loaded splatmap control map from binary cache (", w, "x", h, ").")
				return control_img
				
	# Generate control image on the fly
	print("AgraWorld: Generating splatmap control map in memory...")
	control_img = Image.create_empty(w, h, false, Image.FORMAT_RF)
	
	const SLOT_SAND: int = 0
	const SLOT_GRASS: int = 1
	const SLOT_WALKWAY: int = 2
	const SLOT_SANDSTONE: int = 3
	const SLOT_MARBLE: int = 4
	
	var float_sand: float = _encode_terrain_slot(SLOT_SAND)
	var float_grass: float = _encode_terrain_slot(SLOT_GRASS)
	var float_walk: float = _encode_terrain_slot(SLOT_WALKWAY)
	var float_sandstone: float = _encode_terrain_slot(SLOT_SANDSTONE)
	var float_marble: float = _encode_terrain_slot(SLOT_MARBLE)
	
	var mid_x: int = w / 2
	var mid_y: int = h / 2
	
	for y in range(h):
		var world_z: int = y - mid_y
		for x in range(w):
			var world_x: int = x - mid_x
			var h_pixel: float = h_img.get_pixel(x, y).r
			var f_val: float = float_grass
			
			# River valley / low elevation to the north
			if world_z < -215 or h_pixel < 0.847: # ~216 / 255
				f_val = float_sand
			# Northern Terrace (Taj Mahal plinth + Mosque + Jawab) centered at Z = -165
			elif world_z >= -215 and world_z <= -115 and abs(world_x) <= 155:
				if abs(world_x) <= 52 and abs(world_z - (-165)) <= 52:
					f_val = float_marble # Central mausoleum marble plinth
				else:
					f_val = float_sandstone # East and West sandstone wings
			# Charbagh Gardens (Z in [-115, 145], X in [-145, 145])
			elif world_z > -115 and world_z <= 145 and abs(world_x) <= 145:
				# Central Square Lotus Pool at (0, 0)
				if abs(world_x) <= 14 and abs(world_z) <= 14:
					f_val = float_marble
				# Central North-South Water Canal and Promenades
				elif abs(world_x) <= 9:
					f_val = float_walk
				# Central East-West Water Canal and Promenades
				elif abs(world_z) <= 9:
					f_val = float_walk
				# Perimeter Walkways
				elif abs(world_x) >= 135 or abs(world_z) >= 135:
					f_val = float_walk
				# Subdividing quadrant paths
				elif abs(abs(world_x) - 72) <= 3 or abs(abs(world_z) - 72) <= 3:
					f_val = float_walk
				else:
					f_val = float_grass
			# Southern Great Gate & Forecourt (Z > 145)
			elif world_z > 145 and world_z <= 260 and abs(world_x) <= 160:
				if abs(world_x) <= 18:
					f_val = float_walk
				else:
					f_val = float_sandstone
			else:
				f_val = float_grass
					
			control_img.set_pixel(x, y, Color(f_val, 0, 0, 1))
			
	return control_img

# -----------------------------------------------------------------------------
# Taj Mahal Monument Setup
# -----------------------------------------------------------------------------
func _setup_taj_mahal_monument() -> void:
	if not taj_mahal_root:
		return
		
	# Target plinth coordinates on the northern sandstone riverfront terrace
	const TAJ_PLINTH_POS: Vector3 = Vector3(-125.844, 32.840, -131.457)
		
	# Check if model already instanced as child
	var existing_model: Node3D = taj_mahal_root.get_node_or_null("TajMahalModel") as Node3D
	if not existing_model:
		var scene_res = load(TAJ_MAHAL_MODEL_PATH)
		if scene_res is PackedScene:
			var instance: Node3D = scene_res.instantiate() as Node3D
			instance.name = "TajMahalModel"
			taj_mahal_root.add_child(instance)
			existing_model = instance
			
	if existing_model:
		# Apply 1:1 real-world scale
		existing_model.scale = TAJ_SCALE
		
		# Set to exact aligned plinth coordinate
		existing_model.position = TAJ_PLINTH_POS
		print("AgraWorld: Taj Mahal instanced on Northern Terrace (", TAJ_PLINTH_POS.x, ", ", TAJ_PLINTH_POS.y, ", ", TAJ_PLINTH_POS.z, ")")

# -----------------------------------------------------------------------------
# Trimesh Collision Generation
# -----------------------------------------------------------------------------
func _generate_trimesh_collisions(node: Node) -> void:
	if not node:
		return
	_traverse_and_add_trimesh(node)

func _traverse_and_add_trimesh(n: Node) -> void:
	if n is MeshInstance3D and n.mesh:
		var has_static_body: bool = false
		for child in n.get_children():
			if child is StaticBody3D:
				has_static_body = true
				break
		if not has_static_body:
			var trimesh_shape: Shape3D = n.mesh.create_trimesh_shape()
			if trimesh_shape:
				var static_body: StaticBody3D = StaticBody3D.new()
				var col_shape: CollisionShape3D = CollisionShape3D.new()
				col_shape.shape = trimesh_shape
				static_body.add_child(col_shape)
				n.add_child(static_body)
	for child in n.get_children():
		_traverse_and_add_trimesh(child)

# -----------------------------------------------------------------------------
# UI & Pause Menu
# -----------------------------------------------------------------------------
func _setup_ui() -> void:
	if fade_rect:
		fade_rect.modulate.a = 1.0
		fade_rect.visible = true
		var tween: Tween = create_tween()
		tween.tween_property(fade_rect, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
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

func _toggle_pause_menu() -> void:
	is_paused = not is_paused
	if pause_menu:
		pause_menu.visible = is_paused
	if is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	if fade_rect:
		var tween: Tween = create_tween()
		tween.tween_property(fade_rect, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func():
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		)
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

# -----------------------------------------------------------------------------
# Vegetation Scattering (Cypress Avenues & Procedural Grass)
# -----------------------------------------------------------------------------
func _setup_vegetation() -> void:
	_setup_cypress_trees()
	_setup_procedural_grass()

func _setup_cypress_trees() -> void:
	var foliage_root: Node3D = get_node_or_null("Foliage") as Node3D
	if not foliage_root:
		foliage_root = Node3D.new()
		foliage_root.name = "Foliage"
		add_child(foliage_root)
		
	if not ResourceLoader.exists(CYPRESS_MODEL_PATH):
		return
		
	var tree_scene = load(CYPRESS_MODEL_PATH)
	if not tree_scene is PackedScene:
		return
		
	var leaves_tex: Texture2D = _safe_load_texture(TEX_CYPRESS_LEAVES)
	var trunk_tex: Texture2D = _safe_load_texture(TEX_CYPRESS_TRUNK)
	
	# Leaves Material with Alpha Scissor and SSS Backlight
	var leaves_mat: StandardMaterial3D = StandardMaterial3D.new()
	leaves_mat.albedo_texture = leaves_tex
	leaves_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	leaves_mat.alpha_scissor_threshold = 0.5
	leaves_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaves_mat.backlight_enabled = true
	leaves_mat.backlight = Color(0.25, 0.45, 0.18, 1.0)
	leaves_mat.roughness = 0.85
	
	# Trunk Material
	var trunk_mat: StandardMaterial3D = StandardMaterial3D.new()
	trunk_mat.albedo_texture = trunk_tex
	trunk_mat.roughness = 0.9
	
	# Extract meshes from tree instance
	var dummy_tree: Node3D = tree_scene.instantiate() as Node3D
	var leaves_mesh: Mesh = null
	var trunk_mesh: Mesh = null
	
	for child in dummy_tree.get_children():
		if child is MeshInstance3D and child.mesh:
			if "Leaves" in child.name or child.name == "Object_0" or leaves_mesh == null:
				if leaves_mesh == null:
					leaves_mesh = child.mesh
				else:
					trunk_mesh = child.mesh
			elif trunk_mesh == null:
				trunk_mesh = child.mesh
	dummy_tree.queue_free()
	
	if not leaves_mesh:
		return
		
	# Symmetrical avenue coordinates around the Taj Mahal axis
	var center_x: float = -125.844
	var tree_coords: Array[Vector2] = []
	
	# 1. Central North-South Promenade Avenue
	for z in range(-105, 185, 9):
		if z >= 25 and z <= 55:
			continue
		tree_coords.append(Vector2(center_x - 5.5, float(z)))
		tree_coords.append(Vector2(center_x + 5.5, float(z)))
		
	# 2. Central East-West Promenade Avenue
	for x_off in range(-135, 140, 9):
		if abs(x_off) <= 15:
			continue
		tree_coords.append(Vector2(center_x + float(x_off), 40.0 - 5.5))
		tree_coords.append(Vector2(center_x + float(x_off), 40.0 + 5.5))
		
	# 3. Perimeter Garden Walkways
	for z in range(-105, 185, 14):
		tree_coords.append(Vector2(center_x - 135.0, float(z)))
		tree_coords.append(Vector2(center_x + 135.0, float(z)))
		
	for x_off in range(-135, 140, 14):
		tree_coords.append(Vector2(center_x + float(x_off), 180.0))
		tree_coords.append(Vector2(center_x + float(x_off), -105.0))
		
	var tree_count: int = tree_coords.size()
	print("AgraWorld: Instantiating ", tree_count, " symmetrical cypress trees via MultiMeshInstance3D...")
	
	# Create Leaves MultiMesh
	var mm_leaves: MultiMesh = MultiMesh.new()
	mm_leaves.transform_format = MultiMesh.TRANSFORM_3D
	mm_leaves.mesh = leaves_mesh
	mm_leaves.instance_count = tree_count
	
	var mmi_leaves: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mmi_leaves.name = "CypressLeavesMultiMesh"
	mmi_leaves.multimesh = mm_leaves
	mmi_leaves.material_override = leaves_mat
	foliage_root.add_child(mmi_leaves)
	
	# Create Trunk MultiMesh
	var mm_trunk: MultiMesh = null
	if trunk_mesh and trunk_mesh != leaves_mesh:
		mm_trunk = MultiMesh.new()
		mm_trunk.transform_format = MultiMesh.TRANSFORM_3D
		mm_trunk.mesh = trunk_mesh
		mm_trunk.instance_count = tree_count
		
		var mmi_trunk: MultiMeshInstance3D = MultiMeshInstance3D.new()
		mmi_trunk.name = "CypressTrunkMultiMesh"
		mmi_trunk.multimesh = mm_trunk
		mmi_trunk.material_override = trunk_mat
		foliage_root.add_child(mmi_trunk)
		
	for i in range(tree_count):
		var pos_2d: Vector2 = tree_coords[i]
		var ground_h: float = 33.0
		if terrain_node and ("data" in terrain_node) and terrain_node.data:
			var q_h: float = terrain_node.data.get_height(Vector3(pos_2d.x, 0.0, pos_2d.y))
			if not is_nan(q_h) and abs(q_h) < 50.0:
				ground_h = q_h
				
		var t_pos: Vector3 = Vector3(pos_2d.x, ground_h, pos_2d.y)
		var scale_factor: float = 0.018 + float((i * 17) % 7) * 0.0005
		var rot_y: float = float((i * 31) % 360) * (PI / 180.0)
		
		var t_xform: Transform3D = Transform3D()
		t_xform = t_xform.scaled(Vector3(scale_factor, scale_factor, scale_factor))
		t_xform = t_xform.rotated(Vector3.UP, rot_y)
		t_xform.origin = t_pos
		
		mm_leaves.set_instance_transform(i, t_xform)
		if mm_trunk:
			mm_trunk.set_instance_transform(i, t_xform)

func _setup_procedural_grass() -> void:
	var foliage_root: Node3D = get_node_or_null("Foliage") as Node3D
	if not foliage_root:
		foliage_root = Node3D.new()
		foliage_root.name = "Foliage"
		add_child(foliage_root)
		
	var shader_res = load(GRASS_SHADER_PATH)
	if not shader_res:
		return
		
	var grass_mat: ShaderMaterial = ShaderMaterial.new()
	grass_mat.shader = shader_res
	
	var grass_tex: Texture2D = _safe_load_texture(TEX_GRASS_DIFF)
	if grass_tex:
		grass_mat.set_shader_parameter("grass_texture", grass_tex)
		
	# Build 3-plane cross grass tuft mesh
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for blade_idx in range(3):
		var ang: float = float(blade_idx) * (PI / 3.0)
		var hw: float = 0.55
		var h: float = 0.85
		var dir: Vector3 = Vector3(cos(ang), 0.0, sin(ang)) * hw
		
		var p1: Vector3 = -dir
		var p2: Vector3 = dir
		var p3: Vector3 = -dir + Vector3(0.0, h, 0.0)
		var p4: Vector3 = dir + Vector3(0.0, h, 0.0)
		
		st.set_uv(Vector2(0.0, 1.0))
		st.add_vertex(p1)
		st.set_uv(Vector2(1.0, 1.0))
		st.add_vertex(p2)
		st.set_uv(Vector2(1.0, 0.0))
		st.add_vertex(p4)
		
		st.set_uv(Vector2(0.0, 1.0))
		st.add_vertex(p1)
		st.set_uv(Vector2(1.0, 0.0))
		st.add_vertex(p4)
		st.set_uv(Vector2(0.0, 0.0))
		st.add_vertex(p3)
		
	st.generate_normals()
	var grass_mesh: ArrayMesh = st.commit()
	
	# Generate grass tuft positions across 16 lawn beds in the Charbagh grid
	var center_x: float = -125.844
	var grass_positions: Array[Vector2] = []
	
	var x_ranges: Array[Vector2] = [
		Vector2(center_x - 130.0, center_x - 15.0),
		Vector2(center_x + 15.0, center_x + 130.0)
	]
	var z_ranges: Array[Vector2] = [
		Vector2(-95.0, 25.0),
		Vector2(55.0, 170.0)
	]
	
	var step: float = 2.8
	for xr in x_ranges:
		var curr_x: float = xr.x
		while curr_x <= xr.y:
			for zr in z_ranges:
				var curr_z: float = zr.x
				while curr_z <= zr.y:
					var dx_mid: float = abs(curr_x - (xr.x + xr.y) * 0.5)
					var dz_mid: float = abs(curr_z - (zr.x + zr.y) * 0.5)
					if dx_mid > 3.0 and dz_mid > 3.0:
						var jitter_x: float = float((int(curr_x * 13.0 + curr_z * 7.0) % 100)) * 0.015 - 0.75
						var jitter_z: float = float((int(curr_x * 7.0 + curr_z * 17.0) % 100)) * 0.015 - 0.75
						grass_positions.append(Vector2(curr_x + jitter_x, curr_z + jitter_z))
					curr_z += step
			curr_x += step
			
	var grass_count: int = grass_positions.size()
	print("AgraWorld: Instantiating ", grass_count, " procedural waving grass tufts via MultiMeshInstance3D...")
	
	var mm_grass: MultiMesh = MultiMesh.new()
	mm_grass.transform_format = MultiMesh.TRANSFORM_3D
	mm_grass.mesh = grass_mesh
	mm_grass.instance_count = grass_count
	
	var mmi_grass: MultiMeshInstance3D = MultiMeshInstance3D.new()
	mmi_grass.name = "GrassMultiMeshInstance"
	mmi_grass.multimesh = mm_grass
	mmi_grass.material_override = grass_mat
	foliage_root.add_child(mmi_grass)
	
	for i in range(grass_count):
		var pos_2d: Vector2 = grass_positions[i]
		var ground_h: float = 33.0
		if terrain_node and ("data" in terrain_node) and terrain_node.data:
			var q_h: float = terrain_node.data.get_height(Vector3(pos_2d.x, 0.0, pos_2d.y))
			if not is_nan(q_h) and abs(q_h) < 50.0:
				ground_h = q_h
				
		var g_scale: float = 0.85 + float((i * 19) % 30) * 0.01
		var g_rot: float = float((i * 47) % 360) * (PI / 180.0)
		
		var gx: Transform3D = Transform3D()
		gx = gx.scaled(Vector3(g_scale, g_scale, g_scale))
		gx = gx.rotated(Vector3.UP, g_rot)
		gx.origin = Vector3(pos_2d.x, ground_h, pos_2d.y)
		mm_grass.set_instance_transform(i, gx)

# -----------------------------------------------------------------------------
# Water Systems (Yamuna River & Charbagh Reflecting Pools)
# -----------------------------------------------------------------------------
func _setup_water_systems() -> void:
	var water_root: Node3D = get_node_or_null("WaterBodies") as Node3D
	if not water_root:
		water_root = Node3D.new()
		water_root.name = "WaterBodies"
		add_child(water_root)
		
	if not ResourceLoader.exists(WATER_SHADER_PATH):
		return
		
	var shader_res = load(WATER_SHADER_PATH)
	if not shader_res is Shader:
		return
		
	# 1. Northern Yamuna River Water System
	_setup_yamuna_river(water_root, shader_res)
	
	# 2. Central Charbagh Reflecting Pools & Canals System
	_setup_reflecting_pools(water_root, shader_res)

func _setup_yamuna_river(parent: Node3D, shader: Shader) -> void:
	var river_mat: ShaderMaterial = ShaderMaterial.new()
	river_mat.shader = shader
	
	# Murky green-blue natural river absorption colors
	river_mat.set_shader_parameter("shallow_color", Color(0.22, 0.46, 0.42, 0.78))
	river_mat.set_shader_parameter("deep_color", Color(0.06, 0.22, 0.25, 0.96))
	river_mat.set_shader_parameter("depth_distance", 5.5)
	river_mat.set_shader_parameter("absorption_strength", 1.4)
	river_mat.set_shader_parameter("wave_speed1", Vector2(0.035, 0.015))
	river_mat.set_shader_parameter("wave_speed2", Vector2(-0.02, 0.025))
	river_mat.set_shader_parameter("wave_scale1", 0.04)
	river_mat.set_shader_parameter("wave_scale2", 0.07)
	river_mat.set_shader_parameter("foam_distance", 0.75)
	river_mat.set_shader_parameter("foam_color", Color(0.88, 0.94, 0.96, 0.85))
	river_mat.set_shader_parameter("fresnel_power", 3.2)
	river_mat.set_shader_parameter("refraction_strength", 0.03)
	
	var river_mesh: PlaneMesh = PlaneMesh.new()
	river_mesh.size = Vector2(1400.0, 500.0)
	river_mesh.subdivide_width = 48
	river_mesh.subdivide_depth = 32
	
	var river_instance: MeshInstance3D = MeshInstance3D.new()
	river_instance.name = "YamunaRiver"
	river_instance.mesh = river_mesh
	river_instance.material_override = river_mat
	
	# Position in northern riverbed depression
	var river_y: float = 27.2
	river_instance.position = Vector3(-125.844, river_y, -360.0)
	parent.add_child(river_instance)
	print("AgraWorld: Yamuna river water plane initialized at Y=", river_y)

func _setup_reflecting_pools(parent: Node3D, shader: Shader) -> void:
	var pool_mat: ShaderMaterial = ShaderMaterial.new()
	pool_mat.shader = shader
	
	# Clean turquoise reflecting fountain colors
	pool_mat.set_shader_parameter("shallow_color", Color(0.16, 0.72, 0.78, 0.65))
	pool_mat.set_shader_parameter("deep_color", Color(0.04, 0.36, 0.50, 0.92))
	pool_mat.set_shader_parameter("depth_distance", 2.2)
	pool_mat.set_shader_parameter("absorption_strength", 2.2)
	pool_mat.set_shader_parameter("wave_speed1", Vector2(0.012, 0.016))
	pool_mat.set_shader_parameter("wave_speed2", Vector2(-0.014, 0.01))
	pool_mat.set_shader_parameter("wave_scale1", 0.16)
	pool_mat.set_shader_parameter("wave_scale2", 0.24)
	pool_mat.set_shader_parameter("foam_distance", 0.3)
	pool_mat.set_shader_parameter("foam_color", Color(0.95, 0.98, 1.0, 0.9))
	pool_mat.set_shader_parameter("fresnel_power", 4.0)
	pool_mat.set_shader_parameter("refraction_strength", 0.02)
	
	var center_x: float = -125.844
	var canal_y: float = 32.1
	
	# 1. Central Square Lotus Pool (al-Hawd al-Kawthar)
	var lotus_mesh: PlaneMesh = PlaneMesh.new()
	lotus_mesh.size = Vector2(26.0, 26.0)
	lotus_mesh.subdivide_width = 8
	lotus_mesh.subdivide_depth = 8
	
	var lotus_instance: MeshInstance3D = MeshInstance3D.new()
	lotus_instance.name = "LotusReflectingPool"
	lotus_instance.mesh = lotus_mesh
	lotus_instance.material_override = pool_mat
	lotus_instance.position = Vector3(center_x, canal_y, 40.0)
	parent.add_child(lotus_instance)
	
	# 2. Central North-South Canals
	var ns_mesh: PlaneMesh = PlaneMesh.new()
	ns_mesh.size = Vector2(8.5, 125.0)
	ns_mesh.subdivide_depth = 24
	
	# North Canal (leading toward Taj Mahal)
	var north_canal: MeshInstance3D = MeshInstance3D.new()
	north_canal.name = "NorthCanal"
	north_canal.mesh = ns_mesh
	north_canal.material_override = pool_mat
	north_canal.position = Vector3(center_x, canal_y, -36.0)
	parent.add_child(north_canal)
	
	# South Canal (leading toward Great Gate)
	var south_canal: MeshInstance3D = MeshInstance3D.new()
	south_canal.name = "SouthCanal"
	south_canal.mesh = ns_mesh
	south_canal.material_override = pool_mat
	south_canal.position = Vector3(center_x, canal_y, 116.0)
	parent.add_child(south_canal)
	
	# 3. Central East-West Canals
	var ew_mesh: PlaneMesh = PlaneMesh.new()
	ew_mesh.size = Vector2(125.0, 8.5)
	ew_mesh.subdivide_width = 24
	
	# West Canal
	var west_canal: MeshInstance3D = MeshInstance3D.new()
	west_canal.name = "WestCanal"
	west_canal.mesh = ew_mesh
	west_canal.material_override = pool_mat
	west_canal.position = Vector3(center_x - 76.0, canal_y, 40.0)
	parent.add_child(west_canal)
	
	# East Canal
	var east_canal: MeshInstance3D = MeshInstance3D.new()
	east_canal.name = "EastCanal"
	east_canal.mesh = ew_mesh
	east_canal.material_override = pool_mat
	east_canal.position = Vector3(center_x + 76.0, canal_y, 40.0)
	parent.add_child(east_canal)
	
	print("AgraWorld: Charbagh reflecting pools and cross-canals initialized at Y=", canal_y)

# -----------------------------------------------------------------------------
# AAA Realism Lighting & Atmosphere
# -----------------------------------------------------------------------------
func _setup_lighting_and_atmosphere() -> void:
	# 1. Warm Golden-Hour Directional Sun Light
	if sun_light:
		sun_light.light_color = Color(1.0, 0.92, 0.78, 1.0)
		sun_light.light_energy = 1.45
		sun_light.light_volumetric_fog_energy = 1.6
		sun_light.light_angular_distance = 0.65
		sun_light.shadow_enabled = true
		sun_light.shadow_bias = 0.02
		sun_light.shadow_normal_bias = 1.5
		sun_light.shadow_blur = 1.2
		sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		sun_light.directional_shadow_split_1 = 0.08
		sun_light.directional_shadow_split_2 = 0.20
		sun_light.directional_shadow_split_3 = 0.50
		sun_light.directional_shadow_blend_splits = true
		sun_light.directional_shadow_max_distance = 500.0
		sun_light.directional_shadow_pancake_size = 35.0
		
	# 2. WorldEnvironment Configuration (SDFGI, SSAO, SSIL, Volumetric Fog)
	if world_env and world_env.environment:
		var env: Environment = world_env.environment
		
		# Tonemapping & Color Grading
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		env.tonemap_exposure = 1.08
		env.tonemap_white = 1.0
		
		# Ambient Lighting
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_color = Color(0.98, 0.92, 0.84, 1.0)
		env.ambient_light_sky_contribution = 0.75
		env.ambient_light_energy = 0.85
		
		# Screen-Space Ambient Occlusion (SSAO)
		env.ssao_enabled = true
		env.ssao_radius = 2.5
		env.ssao_intensity = 2.2
		env.ssao_power = 1.5
		env.ssao_detail = 0.5
		env.ssao_horizon = 0.06
		env.ssao_sharpness = 0.98
		env.ssao_light_affect = 0.6
		env.ssao_ao_channel_affect = 0.5
		
		# Screen-Space Indirect Lighting (SSIL)
		env.ssil_enabled = true
		env.ssil_radius = 5.0
		env.ssil_intensity = 1.2
		env.ssil_sharpness = 0.9
		env.ssil_normal_rejection = 1.0
		
		# Signed Distance Field Global Illumination (SDFGI)
		env.sdfgi_enabled = true
		env.sdfgi_use_occlusion = true
		env.sdfgi_read_sky_light = true
		env.sdfgi_cascades = 6
		env.sdfgi_min_cell_size = 0.4
		env.sdfgi_cascade0_distance = 12.8
		env.sdfgi_max_distance = 819.2
		env.sdfgi_y_scale = Environment.SDFGI_Y_SCALE_100_PERCENT
		env.sdfgi_energy = 1.15
		
		# Subtle Bloom & Glow
		env.glow_enabled = true
		env.glow_normalized = true
		env.glow_intensity = 0.35
		env.glow_bloom = 0.12
		
		# Volumetric Fog & Atmospheric River Mist
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.003
		env.volumetric_fog_albedo = Color(0.92, 0.94, 0.98, 1.0)
		env.volumetric_fog_emission = Color(0.12, 0.15, 0.20, 1.0)
		env.volumetric_fog_emission_energy = 0.3
		env.volumetric_fog_anisotropy = 0.35
		env.volumetric_fog_length = 350.0
		env.volumetric_fog_detail_spread = 2.0
		env.volumetric_fog_ambient_inject = 0.2
		env.volumetric_fog_sky_affect = 0.15
		
		# Atmospheric Height Mist
		env.fog_enabled = true
		env.fog_light_color = Color(0.92, 0.94, 0.98, 1.0)
		env.fog_density = 0.001
		env.fog_height = 32.0
		env.fog_height_density = -0.06
		
		print("AgraWorld: AAA Realism Environment & Lighting configured (SDFGI, SSAO, SSIL, Volumetric Fog).")
