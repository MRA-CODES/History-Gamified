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
const CYPRESS_MODEL_PATH: String = "res://assets/environment/props/cypress_tree.glb"
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
	
	# 3. Dedicated PBR Ground Surfaces (50.0 UV Grass & 30.0 UV Paved Walkways)
	_setup_ground_surfaces()
	
	# 4. Instantiate Taj Mahal model at 1:1 scale and position on plinth
	_setup_taj_mahal_monument()
	
	# 5. Twin Lateral Plinth Access Staircases (Smooth player access onto terrace)
	_setup_plinth_staircases()
	
	# 6. Position Player on the Charbagh entrance promenade
	_setup_player()
	
	# 7. Symmetrical Cypress Trees (Southern Charbagh avenue)
	_setup_vegetation()
	
	# 8. Realistic Water Systems (Yamuna River & Southern Reflection Canal)
	_setup_water_systems()
	
	# 9. AAA Realism Lighting & Atmosphere (PhysicalSky, ACES, Warm Sun, 0.0002 Fog)
	_setup_lighting_and_atmosphere()
	
	# 10. Generate Trimesh Collision for all building structures
	if taj_mahal_root:
		_generate_trimesh_collisions(taj_mahal_root)
		print("AgraWorld: Trimesh collision generated for Taj Mahal complex.")

func _setup_player() -> void:
	if not player:
		return
	
	# Capture mouse by default for 3rd person exploration
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Position player close to the Taj Mahal monument (Z = -55.0m) facing North
	var spawn_x: float = 0.0 # Centered on the central promenade axis facing the monument
	var spawn_z: float = -55.0 # Close to the plinth base and staircase entrance
	var ground_y: float = 33.20
	if terrain_node and ("data" in terrain_node) and terrain_node.data:
		var q_y: float = terrain_node.data.get_height(Vector3(spawn_x, 0.0, spawn_z))
		if not is_nan(q_y) and abs(q_y) < 50.0:
			ground_y = max(ground_y, q_y)
			
	player.global_position = Vector3(spawn_x, ground_y + 0.05, spawn_z)
	player.rotation = Vector3(0.0, PI, 0.0) # Face North towards Taj Mahal
	print("AgraWorld: Player placed close to Taj Mahal at (", spawn_x, ", ", ground_y + 0.05, ", ", spawn_z, ") facing North.")

func _physics_process(delta: float) -> void:
	# Fallback out-of-bounds safety check for Player
	if player and not is_freecam:
		if player.global_position.y < 28.0:
			player.global_position = Vector3(0.0, 33.25, -55.0)
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
		cs.position = Vector3(0.0, 31.20, 78.0)
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
		
		# Slot 0 (River Sand) - 8x UV Tiling
		var ta_sand: Resource = _create_texture_asset("River Sand", 0, TEX_SAND_DIFF, TEX_SAND_NORM, 0.96, 1.2, 0.95, Color(1, 1, 1, 1))
		if ta_sand: assets.set_texture(0, ta_sand)
		
		# Slot 1 (Lawn Grass) - 8x UV Tiling
		var ta_grass: Resource = _create_texture_asset("Lawn Grass", 1, TEX_GRASS_DIFF, TEX_GRASS_NORM, 0.80, 1.5, 0.85, Color(1, 1, 1, 1))
		if ta_grass: assets.set_texture(1, ta_grass)
		
		# Slot 2 (Walkways) - 8x UV Tiling
		var ta_walkways: Resource = _create_texture_asset("Walkways", 2, TEX_WALKWAYS_DIFF, TEX_WALKWAYS_NORM, 0.64, 1.5, 0.75, Color(1, 1, 1, 1))
		if ta_walkways: assets.set_texture(2, ta_walkways)
		
		# Slot 3 (Red Sandstone) - 8x UV Tiling
		var ta_sandstone: Resource = _create_texture_asset("Red Sandstone", 3, TEX_SANDSTONE_DIFF, TEX_SANDSTONE_NORM, 0.56, 1.4, 0.8, Color(1, 1, 1, 1))
		if ta_sandstone: assets.set_texture(3, ta_sandstone)
		
		# Slot 4 (Marble) - 8x UV Tiling
		var ta_marble: Resource = _create_texture_asset("Marble", 4, TEX_MARBLE_DIFF, TEX_MARBLE_NORM, 0.40, 1.0, 0.4, Color(1, 1, 1, 1))
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
		
	# Target plinth coordinates on the northern sandstone riverfront terrace (centered at X = 0.0)
	const TAJ_PLINTH_POS: Vector3 = Vector3(0.0, 32.840, -131.457)
		
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
# Twin Lateral Plinth Access Staircases (Flush White Marble Flight & Collision Ramp)
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# Strict Plinth Staircase Replacement (Solid Marble Steps, No Railings, Aligned Flush)
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# Strict Plinth Staircase Replacement (Solid Marble Steps, No Railings, Aligned Flush)
# -----------------------------------------------------------------------------
func _setup_plinth_staircases() -> void:
	# 1. Purge Any Existing Stair Assets
	var old_nodes: Array[String] = ["PlinthStaircases", "PlinthStairs_Left", "PlinthStairs_Right"]
	for node_name in old_nodes:
		var old_node: Node = get_node_or_null(node_name)
		if old_node:
			old_node.queue_free()
			
	# 2. Retrieve Active Material Directly from Adjacent Taj Mahal Plinth Wall Mesh
	var plinth_mat: Material = _get_taj_plinth_material()
	
	# 3. Flight Parameters:
	# Base ground: Y = 33.15m (flush with garden turf)
	# Top deck: Y = 41.72m (flush with the boundary parapet wall of the Taj Mahal plinth)
	# Total rise = 8.57m
	# Number of steps reduced from 42 to 22 (increasing step rise to ~0.39m and tread to ~0.61m)
	var base_y: float = 33.15
	var target_top_y: float = 41.72
	var total_rise: float = target_top_y - base_y # 8.57m
	var num_steps: int = 22
	var total_run_x: float = 13.44 # Preserved total staircase length
	var step_tread_x: float = total_run_x / float(num_steps) # ~0.6109m (increased tread length)
	var step_rise: float = total_rise / float(num_steps) # ~0.3895m (increased step rise height)
	var step_width_z: float = 4.40 # Widened to 4.40m to fill the entire recessed alcove
	var wall_z: float = -72.65
	var center_z: float = wall_z + (step_width_z * 0.5) # -70.45m
	
	# Build flights for both left and right plinth recess pockets
	var stair_configs: Array[Dictionary] = [
		{"name": "PlinthStairs_Left", "end_x": -14.70, "dir_x": 1.0},
		{"name": "PlinthStairs_Right", "end_x": 14.70, "dir_x": -1.0}
	]
	
	for cfg in stair_configs:
		var stairs_container: Node3D = Node3D.new()
		stairs_container.name = cfg["name"]
		
		var end_x: float = cfg["end_x"]
		var dir_x: float = cfg["dir_x"]
		var start_x: float = end_x - (total_run_x * dir_x)
		
		# Build solid visual steps without individual step face colliders
		for step_i in range(num_steps):
			var step_mesh: BoxMesh = BoxMesh.new()
			var s_height: float = step_rise * float(step_i + 1)
			step_mesh.size = Vector3(step_tread_x + 0.02, s_height, step_width_z)
			
			var step_inst: MeshInstance3D = MeshInstance3D.new()
			step_inst.name = "Step_%d" % step_i
			step_inst.mesh = step_mesh
			step_inst.material_override = plinth_mat
			step_inst.rotation = Vector3.ZERO # Rotation locked to (0, 0, 0), zero pitch or roll
			
			var cur_x: float = start_x + (float(step_i) + 0.5) * step_tread_x * dir_x
			var s_y: float = base_y + s_height * 0.5
			step_inst.position = Vector3(cur_x, s_y, center_z)
			stairs_container.add_child(step_inst)
			
		# Top crest threshold over boundary wall (compact 0.5m crest)
		var crest_len: float = 0.50
		var trans_len: float = 1.40 # Short 1.4m transition ramp onto terrace floor (only ~1.9m total extension)
		var terrace_floor_y: float = 40.68
		var drop_to_floor: float = target_top_y - terrace_floor_y # ~1.04m
		
		var crest_mesh: BoxMesh = BoxMesh.new()
		crest_mesh.size = Vector3(crest_len, 0.40, step_width_z)
		var crest_inst: MeshInstance3D = MeshInstance3D.new()
		crest_inst.name = "TopCrestBridge"
		crest_inst.mesh = crest_mesh
		crest_inst.material_override = plinth_mat
		crest_inst.position = Vector3(end_x + (crest_len * 0.5 * dir_x), target_top_y - 0.20, center_z)
		stairs_container.add_child(crest_inst)
		
		# 3 shallow steps on the terrace side descending to terrace floor
		var num_trans_steps: int = 3
		var trans_step_len: float = trans_len / float(num_trans_steps)
		var trans_step_drop: float = drop_to_floor / float(num_trans_steps)
		for t in range(num_trans_steps):
			var s_top: float = target_top_y - trans_step_drop * float(t + 1)
			var step_h: float = s_top - 40.0
			var t_mesh: BoxMesh = BoxMesh.new()
			t_mesh.size = Vector3(trans_step_len + 0.02, step_h, step_width_z)
			var t_inst: MeshInstance3D = MeshInstance3D.new()
			t_inst.name = "TerraceTransitionStep_%d" % t
			t_inst.mesh = t_mesh
			t_inst.material_override = plinth_mat
			var cur_tx: float = end_x + (crest_len + (float(t) + 0.5) * trans_step_len) * dir_x
			t_inst.position = Vector3(cur_tx, 40.0 + step_h * 0.5, center_z)
			stairs_container.add_child(t_inst)
		
		# Dedicated StairRampCollider: Smooth continuous invisible collision ramp spanning threshold to terrace landing
		var col_body: StaticBody3D = StaticBody3D.new()
		col_body.name = "StairRampCollider"
		col_body.collision_layer = 1
		col_body.collision_mask = 1
		
		# 1. Main flight collision ramp (garden ground to top crest)
		var col_shape: CollisionShape3D = CollisionShape3D.new()
		var ramp_box: BoxShape3D = BoxShape3D.new()
		var ramp_thickness: float = 0.40
		var ramp_hypotenuse: float = sqrt(total_run_x * total_run_x + total_rise * total_rise) # ~15.94m
		ramp_box.size = Vector3(ramp_hypotenuse + 0.30, ramp_thickness, step_width_z + 0.10)
		col_shape.shape = ramp_box
		
		var slope_angle: float = atan2(total_rise, total_run_x) # ~32.51 deg gentle slope
		var str_angle: float = slope_angle * dir_x # Positive rotation for Left (+X ascent), negative for Right (-X ascent)
		var y_shift: float = (ramp_thickness * 0.5) / cos(slope_angle)
		
		var mid_x: float = start_x + (total_run_x * 0.5) * dir_x
		var mid_y: float = base_y + (total_rise * 0.5) - y_shift + 0.03
		
		col_shape.position = Vector3(mid_x, mid_y, center_z)
		col_shape.rotation = Vector3(0.0, 0.0, str_angle)
		col_body.add_child(col_shape)
		
		# 2. Crest threshold collision pad
		var crest_pad_shape: CollisionShape3D = CollisionShape3D.new()
		var crest_pad_box: BoxShape3D = BoxShape3D.new()
		crest_pad_box.size = Vector3(crest_len + 0.20, 0.40, step_width_z + 0.10)
		crest_pad_shape.shape = crest_pad_box
		crest_pad_shape.position = Vector3(end_x + (crest_len * 0.5 * dir_x), target_top_y - 0.20, center_z)
		col_body.add_child(crest_pad_shape)
		
		# 3. Bi-directional terrace transition ramp collider (enables walking down without jumping)
		var trans_pad_shape: CollisionShape3D = CollisionShape3D.new()
		var trans_pad_box: BoxShape3D = BoxShape3D.new()
		var trans_thickness: float = 0.35
		var trans_hypotenuse: float = sqrt(trans_len * trans_len + drop_to_floor * drop_to_floor) # ~1.74m
		trans_pad_box.size = Vector3(trans_hypotenuse + 0.20, trans_thickness, step_width_z + 0.10)
		trans_pad_shape.shape = trans_pad_box
		
		var trans_slope: float = atan2(drop_to_floor, trans_len) # ~36.5 deg
		var trans_angle: float = trans_slope * (-dir_x) # Slopes down as X moves further into terrace
		var trans_y_shift: float = (trans_thickness * 0.5) / cos(trans_slope)
		var trans_mid_x: float = end_x + (crest_len + trans_len * 0.5) * dir_x
		var trans_mid_y: float = (target_top_y + terrace_floor_y) * 0.5 - trans_y_shift + 0.03
		
		trans_pad_shape.position = Vector3(trans_mid_x, trans_mid_y, center_z)
		trans_pad_shape.rotation = Vector3(0.0, 0.0, trans_angle)
		col_body.add_child(trans_pad_shape)
		
		stairs_container.add_child(col_body)
		
		add_child(stairs_container)
		
	print("AgraWorld: Widened Solid White Marble Plinth Stairs (4.40m, Corrected Slope Collision) initialized.")

func _get_taj_plinth_material() -> Material:
	if taj_mahal_root:
		var meshes: Array[Node] = taj_mahal_root.find_children("*", "MeshInstance3D", true, false)
		for m in meshes:
			if m is MeshInstance3D and m.mesh:
				var mat: Material = m.get_active_material(0)
				if mat:
					return mat
	# Fallback high-fidelity marble material
	var fallback_mat: StandardMaterial3D = StandardMaterial3D.new()
	var marble_diff: Texture2D = _safe_load_texture(TEX_MARBLE_DIFF)
	var marble_norm: Texture2D = _safe_load_texture(TEX_MARBLE_NORM)
	if marble_diff:
		fallback_mat.albedo_texture = marble_diff
	fallback_mat.albedo_color = Color(0.95, 0.95, 0.95, 1.0)
	if marble_norm:
		fallback_mat.normal_enabled = true
		fallback_mat.normal_texture = marble_norm
	fallback_mat.uv1_scale = Vector3(2.0, 2.0, 1.0)
	fallback_mat.roughness = 0.15
	return fallback_mat

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
# Dedicated PBR Ground Surfaces (True Promenade Hierarchy Centered on X = 0.0)
# -----------------------------------------------------------------------------
func _setup_ground_surfaces() -> void:
	var surfaces_root: Node3D = get_node_or_null("GroundSurfaces") as Node3D
	if not surfaces_root:
		surfaces_root = Node3D.new()
		surfaces_root.name = "GroundSurfaces"
		add_child(surfaces_root)
		
	var grass_diff: Texture2D = _safe_load_texture(TEX_GRASS_DIFF)
	var grass_norm: Texture2D = _safe_load_texture(TEX_GRASS_NORM)
	var walk_diff: Texture2D = _safe_load_texture(TEX_WALKWAYS_DIFF)
	var walk_norm: Texture2D = _safe_load_texture(TEX_WALKWAYS_NORM)
	var sand_diff: Texture2D = _safe_load_texture(TEX_SANDSTONE_DIFF)
	var sand_norm: Texture2D = _safe_load_texture(TEX_SANDSTONE_NORM)
	var marble_diff: Texture2D = _safe_load_texture(TEX_MARBLE_DIFF)
	var marble_norm: Texture2D = _safe_load_texture(TEX_MARBLE_NORM)
	
	# 1. Vibrant Lush Green Grass Lawns (UV Scale Vector3(30.0, 30.0, 1.0), Color(0.35, 0.55, 0.22))
	var grass_mat: StandardMaterial3D = StandardMaterial3D.new()
	grass_mat.albedo_texture = grass_diff
	grass_mat.albedo_color = Color(0.35, 0.55, 0.22, 1.0)
	if grass_norm:
		grass_mat.normal_enabled = true
		grass_mat.normal_texture = grass_norm
		grass_mat.normal_scale = 1.0
	grass_mat.uv1_scale = Vector3(30.0, 30.0, 1.0)
	grass_mat.roughness = 0.80
	
	# Parterre Grass Material (Color(0.35, 0.55, 0.22), roughness 0.80, UV Scale 30.0)
	var parterre_mat: StandardMaterial3D = StandardMaterial3D.new()
	parterre_mat.albedo_texture = grass_diff
	parterre_mat.albedo_color = Color(0.35, 0.55, 0.22, 1.0)
	if grass_norm:
		parterre_mat.normal_enabled = true
		parterre_mat.normal_texture = grass_norm
		parterre_mat.normal_scale = 1.0
	parterre_mat.uv1_scale = Vector3(30.0, 30.0, 1.0)
	parterre_mat.roughness = 0.80
	
	# 2. Main Promenade Pedestrian Walkways (UV Scale 8.0, 40.0, 1.0)
	var walk_mat: StandardMaterial3D = StandardMaterial3D.new()
	walk_mat.albedo_texture = walk_diff
	if walk_norm:
		walk_mat.normal_enabled = true
		walk_mat.normal_texture = walk_norm
		walk_mat.normal_scale = 1.0
	walk_mat.uv1_scale = Vector3(8.0, 40.0, 1.0)
	walk_mat.roughness = 0.75
	
	# 3. Main E-W Crossroad Promenade (UV Scale 40.0, 8.0, 1.0)
	var walk_mat_ew: StandardMaterial3D = StandardMaterial3D.new()
	walk_mat_ew.albedo_texture = walk_diff
	if walk_norm:
		walk_mat_ew.normal_enabled = true
		walk_mat_ew.normal_texture = walk_norm
		walk_mat_ew.normal_scale = 1.0
	walk_mat_ew.uv1_scale = Vector3(40.0, 8.0, 1.0)
	walk_mat_ew.roughness = 0.75
	
	# 4. Northern Red Sandstone River Terrace (Chameli Farsh)
	var sand_mat: StandardMaterial3D = StandardMaterial3D.new()
	sand_mat.albedo_texture = sand_diff
	if sand_norm:
		sand_mat.normal_enabled = true
		sand_mat.normal_texture = sand_norm
		sand_mat.normal_scale = 1.0
	sand_mat.uv1_scale = Vector3(25.0, 25.0, 1.0)
	sand_mat.roughness = 0.80
	
	# White Marble Material for Borders and Inlays
	var marble_mat: StandardMaterial3D = StandardMaterial3D.new()
	if marble_diff:
		marble_mat.albedo_texture = marble_diff
	else:
		marble_mat.albedo_color = Color(0.96, 0.95, 0.92, 1.0)
	if marble_norm:
		marble_mat.normal_enabled = true
		marble_mat.normal_texture = marble_norm
	marble_mat.uv1_scale = Vector3(10.0, 10.0, 1.0)
	marble_mat.roughness = 0.40
	
	# Authentic Mughal 8-Pointed Star Curb Ribbon Material (Light beige sandstone / marble, roughness 0.70)
	var star_ribbon_mat: StandardMaterial3D = StandardMaterial3D.new()
	if walk_diff:
		star_ribbon_mat.albedo_texture = walk_diff
	elif marble_diff:
		star_ribbon_mat.albedo_texture = marble_diff
	star_ribbon_mat.albedo_color = Color(0.95, 0.92, 0.88, 1.0)
	if walk_norm:
		star_ribbon_mat.normal_enabled = true
		star_ribbon_mat.normal_texture = walk_norm
	star_ribbon_mat.uv1_scale = Vector3(4.0, 4.0, 1.0)
	star_ribbon_mat.roughness = 0.70
	
	# Circular Dark Earth Mulch Bed Material
	var mulch_mat: StandardMaterial3D = StandardMaterial3D.new()
	mulch_mat.albedo_color = Color(0.18, 0.14, 0.10, 1.0)
	mulch_mat.roughness = 0.95
	
	var center_x: float = 0.0 # Strictly centered on player and monument axis
	var garden_center_z: float = 78.0 # Center of 304.6m Charbagh square
	
	# Continuous Green Foundation Plinth (320m x 320m at Y = 33.10m sealing all seams)
	var under_plinth: MeshInstance3D = MeshInstance3D.new()
	under_plinth.name = "UnderCrossroadsFiller"
	var under_mesh: PlaneMesh = PlaneMesh.new()
	under_mesh.size = Vector2(320.0, 320.0)
	under_plinth.mesh = under_mesh
	under_plinth.material_override = grass_mat
	under_plinth.position = Vector3(center_x, 33.10, garden_center_z)
	surfaces_root.add_child(under_plinth)
	
	# -------------------------------------------------------------------------
	# True Layered Promenade Hierarchy (Section 1 South + Section 2 North)
	# -------------------------------------------------------------------------
	# 1. Parterre Strips:
	# Southern Section (Z = 86m to 220m, length 134m, center Z = 153m)
	var parterre_mesh_s: PlaneMesh = PlaneMesh.new()
	parterre_mesh_s.size = Vector2(3.9, 134.0)
	
	var parterre_left_s: MeshInstance3D = MeshInstance3D.new()
	parterre_left_s.name = "Parterre_Left_South"
	parterre_left_s.mesh = parterre_mesh_s
	parterre_left_s.material_override = parterre_mat
	parterre_left_s.position = Vector3(center_x - 3.55, 33.21, 153.0)
	surfaces_root.add_child(parterre_left_s)
	
	var parterre_right_s: MeshInstance3D = MeshInstance3D.new()
	parterre_right_s.name = "Parterre_Right_South"
	parterre_right_s.mesh = parterre_mesh_s
	parterre_right_s.material_override = parterre_mat
	parterre_right_s.position = Vector3(center_x + 3.55, 33.21, 153.0)
	surfaces_root.add_child(parterre_right_s)
	
	# Northern Section (Z = -74.3m to 70m, length 144.3m, center Z = -2.15m)
	var parterre_mesh_n: PlaneMesh = PlaneMesh.new()
	parterre_mesh_n.size = Vector2(3.9, 144.3)
	
	var parterre_left_n: MeshInstance3D = MeshInstance3D.new()
	parterre_left_n.name = "Parterre_Left_North"
	parterre_left_n.mesh = parterre_mesh_n
	parterre_left_n.material_override = parterre_mat
	parterre_left_n.position = Vector3(center_x - 3.55, 33.21, -2.15)
	surfaces_root.add_child(parterre_left_n)
	
	var parterre_right_n: MeshInstance3D = MeshInstance3D.new()
	parterre_right_n.name = "Parterre_Right_North"
	parterre_right_n.mesh = parterre_mesh_n
	parterre_right_n.material_override = parterre_mat
	parterre_right_n.position = Vector3(center_x + 3.55, 33.21, -2.15)
	surfaces_root.add_child(parterre_right_n)
	
	# Parterre Outer Marble Curb Edging (X = +/- 5.5m along South and North sections)
	var curb_edge_box_s: BoxMesh = BoxMesh.new()
	curb_edge_box_s.size = Vector3(0.18, 0.12, 134.0)
	
	var curb_edge_l_s: MeshInstance3D = MeshInstance3D.new()
	curb_edge_l_s.name = "Curb_Edge_Left_South"
	curb_edge_l_s.mesh = curb_edge_box_s
	curb_edge_l_s.material_override = marble_mat
	curb_edge_l_s.position = Vector3(center_x - 5.5, 33.22, 153.0)
	surfaces_root.add_child(curb_edge_l_s)
	
	var curb_edge_r_s: MeshInstance3D = MeshInstance3D.new()
	curb_edge_r_s.name = "Curb_Edge_Right_South"
	curb_edge_r_s.mesh = curb_edge_box_s
	curb_edge_r_s.material_override = marble_mat
	curb_edge_r_s.position = Vector3(center_x + 5.5, 33.22, 153.0)
	surfaces_root.add_child(curb_edge_r_s)
	
	var curb_edge_box_n: BoxMesh = BoxMesh.new()
	curb_edge_box_n.size = Vector3(0.18, 0.12, 144.3)
	
	var curb_edge_l_n: MeshInstance3D = MeshInstance3D.new()
	curb_edge_l_n.name = "Curb_Edge_Left_North"
	curb_edge_l_n.mesh = curb_edge_box_n
	curb_edge_l_n.material_override = marble_mat
	curb_edge_l_n.position = Vector3(center_x - 5.5, 33.22, -2.15)
	surfaces_root.add_child(curb_edge_l_n)
	
	var curb_edge_r_n: MeshInstance3D = MeshInstance3D.new()
	curb_edge_r_n.name = "Curb_Edge_Right_North"
	curb_edge_r_n.mesh = curb_edge_box_n
	curb_edge_r_n.material_override = marble_mat
	curb_edge_r_n.position = Vector3(center_x + 5.5, 33.22, -2.15)
	surfaces_root.add_child(curb_edge_r_n)
	
	# -------------------------------------------------------------------------
	# True Mughal Interlocking 8-Pointed Star Curb Ribbon (Full-Length: South & North)
	# -------------------------------------------------------------------------
	var star_pts: Array[Vector2] = [
		Vector2(1.60, 0.0),    # 0: Top tip (facing outer walkway)
		Vector2(0.90, 0.60),   # 1: Valley
		Vector2(1.40, 1.40),   # 2: Top-Right diagonal tip
		Vector2(0.60, 0.90),   # 3: Valley
		Vector2(0.0, 2.75),    # 4: Right connecting tip (X-link to neighbor star)
		Vector2(-0.60, 0.90),  # 5: Valley
		Vector2(-1.40, 1.40),  # 6: Bottom-Right diagonal tip
		Vector2(-0.90, 0.60),  # 7: Valley
		Vector2(-1.60, 0.0),   # 8: Bottom tip (facing central canal)
		Vector2(-0.90, -0.60), # 9: Valley
		Vector2(-1.40, -1.40), # 10: Bottom-Left diagonal tip
		Vector2(-0.60, -0.90), # 11: Valley
		Vector2(0.0, -2.75),   # 12: Left connecting tip (X-link to neighbor star)
		Vector2(0.60, -0.90),  # 13: Valley
		Vector2(1.40, -1.40),  # 14: Top-Left diagonal tip
		Vector2(0.90, -0.60)   # 15: Valley
	]
	
	# Precompute the 16 segment lengths and orientations
	var segment_meshes: Array[BoxMesh] = []
	var segment_offsets: Array[Vector3] = []
	var segment_rotations: Array[float] = []
	var num_pts: int = star_pts.size()
	
	for i in range(num_pts):
		var p1: Vector2 = star_pts[i]
		var p2: Vector2 = star_pts[(i + 1) % num_pts]
		var mid: Vector2 = (p1 + p2) * 0.5
		var diff: Vector2 = p2 - p1
		var seg_len: float = diff.length()
		var seg_angle: float = atan2(diff.x, diff.y)
		
		var b_mesh: BoxMesh = BoxMesh.new()
		b_mesh.size = Vector3(0.25, 0.03, seg_len + 0.06) # 0.25m wide ribbon, 3cm elevated with miter overlap
		segment_meshes.append(b_mesh)
		segment_offsets.append(Vector3(mid.x, 33.25, mid.y))
		segment_rotations.append(seg_angle)
		
	# Circular Mulch Disc (Diameter 0.8m)
	var mulch_mesh: CylinderMesh = CylinderMesh.new()
	mulch_mesh.top_radius = 0.40
	mulch_mesh.bottom_radius = 0.40
	mulch_mesh.height = 0.015
	mulch_mesh.radial_segments = 16
	
	# Place Khatam star inlays along both Section 1 (South) and Section 2 (North)
	var star_idx: int = 0
	var z_ranges: Array[Dictionary] = [
		{"start": -68.0, "end": 66.0},  # Section 2 (North of Lotus pond up to terrace)
		{"start": 88.0, "end": 220.0}   # Section 1 (South of Lotus pond)
	]
	for z_range in z_ranges:
		var node_z: float = z_range["start"]
		while node_z <= z_range["end"]:
			for side_x in [-3.55, 3.55]:
				# 1. Circular Mulch Cutout for Tree Base
				var mulch_inst: MeshInstance3D = MeshInstance3D.new()
				mulch_inst.name = "MulchBed_%d" % star_idx
				mulch_inst.mesh = mulch_mesh
				mulch_inst.material_override = mulch_mat
				mulch_inst.position = Vector3(center_x + side_x, 33.22, node_z)
				surfaces_root.add_child(mulch_inst)
				
				# 2. Authentic Interlocking 8-Pointed Star Curb Ribbon
				var star_root: Node3D = Node3D.new()
				star_root.name = "KhatamStar_%d" % star_idx
				star_root.position = Vector3(center_x + side_x, 0.0, node_z)
				
				for s in range(num_pts):
					var seg_inst: MeshInstance3D = MeshInstance3D.new()
					seg_inst.mesh = segment_meshes[s]
					seg_inst.material_override = star_ribbon_mat
					seg_inst.position = segment_offsets[s]
					seg_inst.rotation.y = segment_rotations[s]
					star_root.add_child(seg_inst)
					
				surfaces_root.add_child(star_root)
				star_idx += 1
			node_z += 5.5
	
	# 2. Outer Pedestrian Walkways (South: 134m + North: 144.3m):
	var walk_s_mesh: PlaneMesh = PlaneMesh.new()
	walk_s_mesh.size = Vector2(5.0, 134.0)
	
	var walk_left_s: MeshInstance3D = MeshInstance3D.new()
	walk_left_s.name = "Walkway_Pedestrian_Left_South"
	walk_left_s.mesh = walk_s_mesh
	walk_left_s.material_override = walk_mat
	walk_left_s.position = Vector3(center_x - 8.0, 33.20, 153.0)
	surfaces_root.add_child(walk_left_s)
	
	var walk_right_s: MeshInstance3D = MeshInstance3D.new()
	walk_right_s.name = "Walkway_Pedestrian_Right_South"
	walk_right_s.mesh = walk_s_mesh
	walk_right_s.material_override = walk_mat
	walk_right_s.position = Vector3(center_x + 8.0, 33.20, 153.0)
	surfaces_root.add_child(walk_right_s)
	
	var walk_n_mesh: PlaneMesh = PlaneMesh.new()
	walk_n_mesh.size = Vector2(5.0, 144.3)
	
	var walk_left_n: MeshInstance3D = MeshInstance3D.new()
	walk_left_n.name = "Walkway_Pedestrian_Left_North"
	walk_left_n.mesh = walk_n_mesh
	walk_left_n.material_override = walk_mat
	walk_left_n.position = Vector3(center_x - 8.0, 33.20, -2.15)
	surfaces_root.add_child(walk_left_n)
	
	var walk_right_n: MeshInstance3D = MeshInstance3D.new()
	walk_right_n.name = "Walkway_Pedestrian_Right_North"
	walk_right_n.mesh = walk_n_mesh
	walk_right_n.material_override = walk_mat
	walk_right_n.position = Vector3(center_x + 8.0, 33.20, -2.15)
	surfaces_root.add_child(walk_right_n)
	
	# 3. Main Central E-W Crossroad Promenade (18.0m wide total x 304.6m long at Y = 33.20m)
	var walk_ew: PlaneMesh = PlaneMesh.new()
	walk_ew.size = Vector2(304.6, 18.0)
	var walk_ew_inst: MeshInstance3D = MeshInstance3D.new()
	walk_ew_inst.name = "Walkway_EW"
	walk_ew_inst.mesh = walk_ew
	walk_ew_inst.material_override = walk_mat_ew
	walk_ew_inst.position = Vector3(center_x, 33.20, garden_center_z)
	surfaces_root.add_child(walk_ew_inst)
	
	# 4. Outer Sunken Lawns (16 Exact Lawns beyond X < -10.5m and X > +10.5m across Charbagh)
	var bed_size: Vector2 = Vector2(62.0, 62.0)
	var quad_offsets_x: Array[float] = [-115.0, -48.0, 48.0, 115.0]
	var quad_offsets_z: Array[float] = [-115.0, -48.0, 48.0, 115.0]
	
	var bed_idx: int = 0
	for ox in quad_offsets_x:
		for oz in quad_offsets_z:
			var bed_mesh: PlaneMesh = PlaneMesh.new()
			bed_mesh.size = bed_size
			var bed_inst: MeshInstance3D = MeshInstance3D.new()
			bed_inst.name = "LawnBed_%d" % bed_idx
			bed_inst.mesh = bed_mesh
			bed_inst.material_override = grass_mat
			bed_inst.position = Vector3(center_x + ox, 33.15, garden_center_z + oz)
			surfaces_root.add_child(bed_inst)
			bed_idx += 1
			
	# Secondary Subdividing Walkways (5.0m wide)
	var sec_walk_w: PlaneMesh = PlaneMesh.new()
	sec_walk_w.size = Vector2(5.0, 304.6)
	var sec_w_inst: MeshInstance3D = MeshInstance3D.new()
	sec_w_inst.name = "SecondaryWalk_West"
	sec_w_inst.mesh = sec_walk_w
	sec_w_inst.material_override = walk_mat
	sec_w_inst.position = Vector3(center_x - 81.5, 33.18, garden_center_z)
	surfaces_root.add_child(sec_w_inst)
	
	var sec_e_inst: MeshInstance3D = MeshInstance3D.new()
	sec_e_inst.name = "SecondaryWalk_East"
	sec_e_inst.mesh = sec_walk_w
	sec_e_inst.material_override = walk_mat
	sec_e_inst.position = Vector3(center_x + 81.5, 33.18, garden_center_z)
	surfaces_root.add_child(sec_e_inst)
	
	var sec_walk_h: PlaneMesh = PlaneMesh.new()
	sec_walk_h.size = Vector2(304.6, 5.0)
	var sec_n_inst: MeshInstance3D = MeshInstance3D.new()
	sec_n_inst.name = "SecondaryWalk_North"
	sec_n_inst.mesh = sec_walk_h
	sec_n_inst.material_override = walk_mat_ew
	sec_n_inst.position = Vector3(center_x, 33.18, garden_center_z - 81.5)
	surfaces_root.add_child(sec_n_inst)
	
	var sec_s_inst: MeshInstance3D = MeshInstance3D.new()
	sec_s_inst.name = "SecondaryWalk_South"
	sec_s_inst.mesh = sec_walk_h
	sec_s_inst.material_override = walk_mat_ew
	sec_s_inst.position = Vector3(center_x, 33.18, garden_center_z + 81.5)
	surfaces_root.add_child(sec_s_inst)
	
	# -------------------------------------------------------------------------
	# Elevated Red Sandstone Terrace Plinth (Chameli Farsh: 304.6m x 114.2m)
	# -------------------------------------------------------------------------
	var terrace_box: BoxMesh = BoxMesh.new()
	terrace_box.size = Vector3(304.6, 1.20, 114.2)
	
	var terrace_inst: MeshInstance3D = MeshInstance3D.new()
	terrace_inst.name = "SandstoneTerracePlinth"
	terrace_inst.mesh = terrace_box
	terrace_inst.material_override = sand_mat
	# Center at Y = 33.80m so top deck is at Y = 34.40m, elevated 1.2m above lawn (Y=33.20m)
	terrace_inst.position = Vector3(center_x, 33.80, -131.4)
	
	# Solid StaticBody3D collision for Chameli Farsh terrace
	var terrace_body: StaticBody3D = StaticBody3D.new()
	var terrace_col: CollisionShape3D = CollisionShape3D.new()
	var terrace_col_shape: BoxShape3D = BoxShape3D.new()
	terrace_col_shape.size = Vector3(304.6, 1.20, 114.2)
	terrace_col.shape = terrace_col_shape
	terrace_body.add_child(terrace_col)
	terrace_inst.add_child(terrace_body)
	surfaces_root.add_child(terrace_inst)
	
	# Red Sandstone Terrace South Retaining Curb (at Z = -74.3m)
	var terrace_curb_box: BoxMesh = BoxMesh.new()
	terrace_curb_box.size = Vector3(304.6, 0.25, 0.40)
	var terrace_curb: MeshInstance3D = MeshInstance3D.new()
	terrace_curb.name = "TerraceSouthCurb"
	terrace_curb.mesh = terrace_curb_box
	terrace_curb.material_override = sand_mat
	terrace_curb.position = Vector3(center_x, 34.42, -74.3)
	surfaces_root.add_child(terrace_curb)
	
	# Central Promenade Transition Steps to Terrace Deck (X = -10.5m to +10.5m at Z = -74.3m)
	var trans_steps_box: BoxMesh = BoxMesh.new()
	trans_steps_box.size = Vector3(21.0, 1.20, 2.0)
	var trans_steps: MeshInstance3D = MeshInstance3D.new()
	trans_steps.name = "TerraceEntranceRamp"
	trans_steps.mesh = trans_steps_box
	trans_steps.material_override = sand_mat
	trans_steps.position = Vector3(center_x, 33.80, -74.3)
	
	var trans_body: StaticBody3D = StaticBody3D.new()
	var trans_col: CollisionShape3D = CollisionShape3D.new()
	var trans_shape: BoxShape3D = BoxShape3D.new()
	trans_shape.size = Vector3(21.0, 1.20, 2.0)
	trans_col.shape = trans_shape
	trans_body.add_child(trans_col)
	trans_steps.add_child(trans_body)
	surfaces_root.add_child(trans_steps)
	
	print("AgraWorld: Full-length promenade and Elevated Red Sandstone Chameli Farsh terrace created.")

# -----------------------------------------------------------------------------
# Vegetation Scattering (Symmetrical Cypress Trees Along Full-Length Walkways)
# -----------------------------------------------------------------------------
func _setup_vegetation() -> void:
	_setup_cypress_trees()

func _setup_cypress_trees() -> void:
	var foliage_root: Node3D = get_node_or_null("Foliage") as Node3D
	if not foliage_root:
		foliage_root = Node3D.new()
		foliage_root.name = "Foliage"
		add_child(foliage_root)
	else:
		for child in foliage_root.get_children():
			child.queue_free()
		
	if not ResourceLoader.exists(CYPRESS_MODEL_PATH):
		print("AgraWorld: Cypress model not found at ", CYPRESS_MODEL_PATH)
		return
		
	var tree_scene = load(CYPRESS_MODEL_PATH)
	if not tree_scene is PackedScene:
		print("AgraWorld: Cypress model is not PackedScene.")
		return
		
	# Two strictly symmetrical rows of cypress trees centered inside parterres at X = +/- 3.55m
	var center_x: float = 0.0 # Active player and monument axis
	var tree_coords: Array[Vector2] = []
	
	# Plant trees along both Section 2 (North: Z = -68m to 66m) and Section 1 (South: Z = 88m to 220m), spaced every 5.5m
	var z_ranges: Array[Dictionary] = [
		{"start": -68.0, "end": 66.0},
		{"start": 88.0, "end": 220.0}
	]
	for z_range in z_ranges:
		var z_curr: float = z_range["start"]
		while z_curr <= z_range["end"]:
			tree_coords.append(Vector2(center_x - 3.55, z_curr))
			tree_coords.append(Vector2(center_x + 3.55, z_curr))
			z_curr += 5.5
		
	var tree_count: int = tree_coords.size()
	print("AgraWorld: Instantiating ", tree_count, " full-length cypress trees at X = +/- 3.55m, Y = 33.25m, scale Vector3(0.55, 0.65, 0.55)...")
	
	for i in range(tree_count):
		var pos_2d: Vector2 = tree_coords[i]
		var tree_inst: Node3D = tree_scene.instantiate() as Node3D
		tree_inst.name = "CypressTree_%d" % i
		tree_inst.position = Vector3(pos_2d.x, 33.25, pos_2d.y)
		
		# Scaled to realistic human scale 4.5m - 5.2m height (Vector3(0.55, 0.65, 0.55) +/- 5% organic variation)
		var scale_var: float = 0.95 + 0.10 * float((i * 17) % 7) / 6.0
		tree_inst.scale = Vector3(0.55 * scale_var, 0.65 * scale_var, 0.55 * scale_var)
		tree_inst.rotation.y = float((i * 53) % 360) * (PI / 180.0)
		
		_enable_tree_shadows(tree_inst)
		foliage_root.add_child(tree_inst)
		
	print("AgraWorld: Full-length human-scale cypress colonnades successfully instantiated.")

func _enable_tree_shadows(node: Node) -> void:
	if node is GeometryInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for child in node.get_children():
		_enable_tree_shadows(child)

# -----------------------------------------------------------------------------
# Water Systems (Yamuna River & Sunken Reflection Canal)
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
		
	# 1. Northern Yamuna River Basin Water System
	_setup_yamuna_river(water_root, shader_res)
	
	# 2. Central Recessed Reflection Canal & Lotus Pool
	_setup_reflecting_pools(water_root, shader_res)

func _setup_yamuna_river(parent: Node3D, shader: Shader) -> void:
	var river_mat: ShaderMaterial = ShaderMaterial.new()
	river_mat.shader = shader
	
	# Deep navy/cyan #1a3d4c water colors with 0.05 roughness
	river_mat.set_shader_parameter("shallow_color", Color(0.102, 0.239, 0.298, 0.82))
	river_mat.set_shader_parameter("deep_color", Color(0.045, 0.125, 0.165, 0.98))
	river_mat.set_shader_parameter("roughness", 0.05)
	river_mat.set_shader_parameter("depth_distance", 4.0)
	river_mat.set_shader_parameter("absorption_strength", 1.6)
	river_mat.set_shader_parameter("wave_speed1", Vector2(0.02, 0.01))
	river_mat.set_shader_parameter("wave_speed2", Vector2(-0.015, 0.02))
	river_mat.set_shader_parameter("wave_scale1", 0.05)
	river_mat.set_shader_parameter("wave_scale2", 0.08)
	river_mat.set_shader_parameter("foam_distance", 0.5)
	river_mat.set_shader_parameter("foam_color", Color(0.85, 0.92, 0.96, 0.75))
	river_mat.set_shader_parameter("fresnel_power", 4.0)
	river_mat.set_shader_parameter("refraction_strength", 0.025)
	
	var river_mesh: PlaneMesh = PlaneMesh.new()
	river_mesh.size = Vector2(1200.0, 350.0)
	river_mesh.subdivide_width = 32
	river_mesh.subdivide_depth = 24
	
	var river_instance: MeshInstance3D = MeshInstance3D.new()
	river_instance.name = "YamunaRiver"
	river_instance.mesh = river_mesh
	river_instance.material_override = river_mat
	
	# Strictly inside the northern Yamuna river depression
	var river_y: float = 26.8
	river_instance.position = Vector3(0.0, river_y, -360.0)
	parent.add_child(river_instance)
	print("AgraWorld: Yamuna river basin water initialized at Y=", river_y)

func _setup_reflecting_pools(parent: Node3D, _shader: Shader) -> void:
	var center_x: float = 0.0 # Strictly centered on active player and monument axis
	var garden_center_z: float = 78.0 # Center of 304.6m Charbagh square
	var canal_y: float = 33.22 # Raised 2cm above base stone slab to eliminate Z-fighting
	
	# High-Gloss Mirror Water Material (Color(0.05, 0.25, 0.35, 0.95), 0.02 roughness, 0.1 metallic, SSR enabled)
	var water_mat: StandardMaterial3D = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.05, 0.25, 0.35, 0.95)
	water_mat.roughness = 0.02
	water_mat.metallic = 0.1
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	water_mat.clearcoat_enabled = true
	water_mat.clearcoat = 1.0
	water_mat.clearcoat_roughness = 0.02
	
	# White Marble Material for Platform and Curbs
	var marble_mat: StandardMaterial3D = StandardMaterial3D.new()
	var marble_diff: Texture2D = _safe_load_texture(TEX_MARBLE_DIFF)
	var marble_norm: Texture2D = _safe_load_texture(TEX_MARBLE_NORM)
	if marble_diff:
		marble_mat.albedo_texture = marble_diff
	else:
		marble_mat.albedo_color = Color(0.96, 0.95, 0.92, 1.0)
	if marble_norm:
		marble_mat.normal_enabled = true
		marble_mat.normal_texture = marble_norm
	marble_mat.uv1_scale = Vector3(10.0, 10.0, 1.0)
	marble_mat.roughness = 0.35
	
	# -------------------------------------------------------------------------
	# Section 1 (South): Reflecting Canal (3.2m wide, Z = 86m to 220m)
	# -------------------------------------------------------------------------
	var canal_mesh_s: PlaneMesh = PlaneMesh.new()
	canal_mesh_s.size = Vector2(3.2, 134.0)
	canal_mesh_s.subdivide_depth = 24
	
	var central_pool_s: MeshInstance3D = MeshInstance3D.new()
	central_pool_s.name = "CentralReflectingPool_South"
	central_pool_s.mesh = canal_mesh_s
	central_pool_s.material_override = water_mat
	central_pool_s.position = Vector3(center_x, canal_y, 153.0)
	parent.add_child(central_pool_s)
	
	# White Marble Curbs framing the Southern canal at X = +/- 1.675m
	var curb_box_s: BoxMesh = BoxMesh.new()
	curb_box_s.size = Vector3(0.15, 0.12, 134.0)
	
	var curb_w_s: MeshInstance3D = MeshInstance3D.new()
	curb_w_s.name = "Curb_West_South"
	curb_w_s.mesh = curb_box_s
	curb_w_s.material_override = marble_mat
	curb_w_s.position = Vector3(center_x - 1.675, 33.22, 153.0)
	parent.add_child(curb_w_s)
	
	var curb_e_s: MeshInstance3D = MeshInstance3D.new()
	curb_e_s.name = "Curb_East_South"
	curb_e_s.mesh = curb_box_s
	curb_e_s.material_override = marble_mat
	curb_e_s.position = Vector3(center_x + 1.675, 33.22, 153.0)
	parent.add_child(curb_e_s)
	
	# -------------------------------------------------------------------------
	# Section 2 (North): Reflecting Canal (3.2m wide, Z = -74.3m to 70m, length 144.3m)
	# -------------------------------------------------------------------------
	var canal_mesh_n: PlaneMesh = PlaneMesh.new()
	canal_mesh_n.size = Vector2(3.2, 144.3)
	canal_mesh_n.subdivide_depth = 24
	
	var central_pool_n: MeshInstance3D = MeshInstance3D.new()
	central_pool_n.name = "CentralReflectingPool_North"
	central_pool_n.mesh = canal_mesh_n
	central_pool_n.material_override = water_mat
	central_pool_n.position = Vector3(center_x, canal_y, -2.15)
	parent.add_child(central_pool_n)
	
	# White Marble Curbs framing the Northern canal at X = +/- 1.675m
	var curb_box_n: BoxMesh = BoxMesh.new()
	curb_box_n.size = Vector3(0.15, 0.12, 144.3)
	
	var curb_w_n: MeshInstance3D = MeshInstance3D.new()
	curb_w_n.name = "Curb_West_North"
	curb_w_n.mesh = curb_box_n
	curb_w_n.material_override = marble_mat
	curb_w_n.position = Vector3(center_x - 1.675, 33.22, -2.15)
	parent.add_child(curb_w_n)
	
	var curb_e_n: MeshInstance3D = MeshInstance3D.new()
	curb_e_n.name = "Curb_East_North"
	curb_e_n.mesh = curb_box_n
	curb_e_n.material_override = marble_mat
	curb_e_n.position = Vector3(center_x + 1.675, 33.22, -2.15)
	parent.add_child(curb_e_n)
	
	# -------------------------------------------------------------------------
	# Central Raised Square Lotus Platform (Hawd al-Kawthar: 16m x 16m at Y = 33.25m)
	# -------------------------------------------------------------------------
	var platform_box: BoxMesh = BoxMesh.new()
	platform_box.size = Vector3(16.0, 0.10, 16.0)
	var platform_inst: MeshInstance3D = MeshInstance3D.new()
	platform_inst.name = "HawdAlKawtharPlatform"
	platform_inst.mesh = platform_box
	platform_inst.material_override = marble_mat
	platform_inst.position = Vector3(center_x, 33.25, garden_center_z)
	parent.add_child(platform_inst)
	
	# Central Sunken Lotus Pool in center of platform (10.0m x 10.0m at Y = 33.31m)
	var lotus_mesh: PlaneMesh = PlaneMesh.new()
	lotus_mesh.size = Vector2(10.0, 10.0)
	var lotus_instance: MeshInstance3D = MeshInstance3D.new()
	lotus_instance.name = "LotusReflectingPool"
	lotus_instance.mesh = lotus_mesh
	lotus_instance.material_override = water_mat
	lotus_instance.position = Vector3(center_x, 33.31, garden_center_z)
	parent.add_child(lotus_instance)
	
	print("AgraWorld: CentralReflectingPool & Hawd al-Kawthar centered on X = 0.0 (3.2m canal, SSR enabled).")

# -----------------------------------------------------------------------------
# AAA Realism Lighting & Atmosphere (PhysicalSky, ACES, Warm Sun, 0.0002 Fog)
# -----------------------------------------------------------------------------
func _setup_lighting_and_atmosphere() -> void:
	# 1. Realistic Warm Sunlight (DirectionalLight3D)
	if sun_light:
		sun_light.light_color = Color(1.0, 0.95, 0.88, 1.0) # Warm sunlight
		sun_light.light_energy = 1.0
		sun_light.light_indirect_energy = 0.5
		sun_light.rotation = Vector3(-0.6, 0.7, 0.0) # Angled golden-hour shadows
		sun_light.shadow_enabled = true
		sun_light.shadow_bias = 0.02
		sun_light.shadow_normal_bias = 1.5
		sun_light.shadow_blur = 1.5
		sun_light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		sun_light.directional_shadow_split_1 = 0.08
		sun_light.directional_shadow_split_2 = 0.20
		sun_light.directional_shadow_split_3 = 0.50
		sun_light.directional_shadow_blend_splits = true
		sun_light.directional_shadow_max_distance = 500.0
		sun_light.directional_shadow_pancake_size = 35.0
		
	# 2. WorldEnvironment Configuration (PhysicalSky, ACES, SSAO, SSR, 0.0002 Fog)
	if world_env and world_env.environment:
		var env: Environment = world_env.environment
		
		# Realistic Sky with PhysicalSkyMaterial
		env.background_mode = Environment.BG_SKY
		var sky: Sky = Sky.new()
		var sky_mat: PhysicalSkyMaterial = PhysicalSkyMaterial.new()
		sky_mat.rayleigh_coefficient = 2.0
		sky_mat.mie_coefficient = 0.005
		sky_mat.turbidity = 10.0
		sky_mat.ground_color = Color(0.25, 0.22, 0.18, 1.0)
		sky.sky_material = sky_mat
		env.sky = sky
		
		# ACES Tonemapping (prevents marble blowout)
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		env.tonemap_exposure = 1.05
		env.tonemap_white = 1.0
		
		# Ambient Lighting from Physical Sky (0.3 energy)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_sky_contribution = 0.5
		env.ambient_light_energy = 0.3
		
		# Screen-Space Ambient Occlusion (SSAO: radius 1.5, intensity 2.0)
		env.ssao_enabled = true
		env.ssao_radius = 1.5
		env.ssao_intensity = 2.0
		env.ssao_power = 1.5
		env.ssao_detail = 0.5
		env.ssao_horizon = 0.06
		env.ssao_sharpness = 0.98
		
		# Screen-Space Indirect Lighting (SSIL)
		env.ssil_enabled = true
		env.ssil_radius = 5.0
		env.ssil_intensity = 1.0
		env.ssil_sharpness = 0.9
		env.ssil_normal_rejection = 1.0
		
		# Screen-Space Reflections (SSR) for water
		env.ssr_enabled = true
		env.ssr_max_steps = 64
		env.ssr_fade_in = 0.15
		env.ssr_fade_out = 2.0
		env.ssr_depth_tolerance = 0.2
		
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
		
		# Subtle Bloom
		env.glow_enabled = true
		env.glow_normalized = true
		env.glow_intensity = 0.20
		env.glow_bloom = 0.06
		
		# Volumetric Fog (density 0.0002 to remove white haze)
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.0002
		env.volumetric_fog_albedo = Color(0.92, 0.94, 0.98, 1.0)
		env.volumetric_fog_emission = Color(0.12, 0.15, 0.20, 1.0)
		env.volumetric_fog_emission_energy = 0.05
		env.volumetric_fog_anisotropy = 0.35
		env.volumetric_fog_length = 400.0
		
		# Regular height fog disabled to eliminate whiteout
		env.fog_enabled = false
		
		print("AgraWorld: PhysicalSky + ACES + Warm Sun + 0.0002 Fog successfully configured.")
