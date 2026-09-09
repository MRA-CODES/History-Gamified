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

# 1:1 Real-world Taj Mahal scale (rescaled uniformly to 0.88x survey proportion)
const TAJ_SCALE := Vector3(0.17248, 0.17248, 0.17248)

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

	# 4. Riverfront Chameli Farsh Terrace Foundation & Retaining Balustrade (1000ft x 400ft at Y = 34.50m)
	_setup_chameli_farsh()
	
	# 5. Outer Ground Skirt & Forecourt (Eliminates voids beyond perimeter)
	_setup_outer_ground_skirt()

	# 6. Red Sandstone Perimeter Battlement Walls (Enclosing 304.8m x 304.8m Charbagh)
	_setup_perimeter_walls()

	# 7. Corner Octagonal Watchtowers (Burj with pillared chattris & marble domes)
	_setup_corner_burjs()

	# 8. The Great Gate (Darwaza-i Rauza - Monumental 46m x 22m x 30m Southern Gateway)
	_setup_great_gate()

	# 9. Twin Flanking Sunken Ablution Basins (Hauz: 14m x 14m sunken marble reflecting pools)
	_setup_ablution_basins()

	# 10. High-Detail Procedural Twin Monuments (Mosque West & Mehman Khana East)
	_setup_twin_flanking_monuments()
	
	# 11. Instantiate Taj Mahal model at 1:1 scale and position flush on plinth (Y = 34.50m)
	_setup_taj_mahal_monument()
	
	# 12. Twin Lateral Plinth Access Staircases (Re-anchored to Y = 34.50m)
	_setup_plinth_staircases()
	
	# 13. Position Player on the Charbagh entrance promenade
	_setup_player()
	
	# 14. Symmetrical Cypress Trees (Southern Charbagh avenue)
	_setup_vegetation()
	
	# 15. Realistic Water Systems (Yamuna River & Southern Reflection Canal)
	_setup_water_systems()
	
	# 16. AAA Realism Lighting & Atmosphere (PhysicalSky, ACES, Warm Sun, Volumetric Fog)
	_setup_lighting_and_atmosphere()
	
	# 17. Generate Trimesh Collision for all building structures
	if taj_mahal_root:
		_generate_trimesh_collisions(taj_mahal_root)
		print("AgraWorld: Trimesh collision generated for Taj Mahal complex.")

func _setup_player() -> void:
	if not player:
		return
	
	# Capture mouse by default for 3rd person exploration
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Position player close to the Taj Mahal monument & Grand Steps (Z = -48.0m) facing North
	var spawn_x: float = 0.0 # Centered on the central promenade axis facing the monument
	var spawn_z: float = -48.0 # Promenade threshold in front of the southern grand steps
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
# Taj Mahal Monument Setup (Elevated Flush onto Chameli Farsh at Y = 34.50m)
# -----------------------------------------------------------------------------
func _setup_taj_mahal_monument() -> void:
	if not taj_mahal_root:
		return
		
	# Target plinth coordinates elevated to sit flush atop Chameli Farsh (Y = 34.50m)
	const TAJ_PLINTH_POS: Vector3 = Vector3(0.0, 34.50, -131.457)
		
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
		print("AgraWorld: Taj Mahal instanced flush on Chameli Farsh (", TAJ_PLINTH_POS.x, ", ", TAJ_PLINTH_POS.y, ", ", TAJ_PLINTH_POS.z, ")")

# -----------------------------------------------------------------------------
# Twin Lateral Plinth Access Staircases (Re-anchored to Chameli Farsh at Y = 34.50m)
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
	
	# 3. Flight Parameters Calibrated to 0.88x Taj Plinth:
	# Base ground: Y = 34.50m (flush with Chameli Farsh terrace deck)
	# Top deck: Y = 42.31m (flush with boundary parapet wall of the elevated 0.88x Taj Mahal plinth)
	# Total rise = 7.81m
	# 22 steps: rise ~0.355m, tread ~0.5377m
	var base_y: float = 34.50
	var target_top_y: float = 42.31
	var total_rise: float = target_top_y - base_y # 7.81m
	var num_steps: int = 22
	var total_run_x: float = 11.83 # Calibrated staircase length for 0.88x footprint
	var step_tread_x: float = total_run_x / float(num_steps) # ~0.5377m
	var step_rise: float = total_rise / float(num_steps) # ~0.355m
	var step_width_z: float = 3.87 # Width fitting the 0.88x recessed alcove pocket
	var wall_z: float = -79.71 # South plinth wall at 0.88x scale
	var center_z: float = wall_z + (step_width_z * 0.5) # -77.775m
	
	# Build flights for both left and right plinth recess pockets
	var stair_configs: Array[Dictionary] = [
		{"name": "PlinthStairs_Left", "end_x": -12.94, "dir_x": 1.0},
		{"name": "PlinthStairs_Right", "end_x": 12.94, "dir_x": -1.0}
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
		var trans_len: float = 1.40 # Short 1.4m transition ramp onto terrace floor
		var terrace_floor_y: float = 41.40 # Calibrated 0.88x terrace deck floor
		var drop_to_floor: float = target_top_y - terrace_floor_y # ~0.91m
		
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
			var s_bottom: float = terrace_floor_y - 0.70
			var step_h: float = s_top - s_bottom
			var t_mesh: BoxMesh = BoxMesh.new()
			t_mesh.size = Vector3(trans_step_len + 0.02, step_h, step_width_z)
			var t_inst: MeshInstance3D = MeshInstance3D.new()
			t_inst.name = "TerraceTransitionStep_%d" % t
			t_inst.mesh = t_mesh
			t_inst.material_override = plinth_mat
			var cur_tx: float = end_x + (crest_len + (float(t) + 0.5) * trans_step_len) * dir_x
			t_inst.position = Vector3(cur_tx, s_bottom + step_h * 0.5, center_z)
			stairs_container.add_child(t_inst)
		
		# Dedicated StairRampCollider: Smooth continuous invisible collision ramp spanning threshold to terrace landing
		var col_body: StaticBody3D = StaticBody3D.new()
		col_body.name = "StairRampCollider"
		col_body.collision_layer = 1
		col_body.collision_mask = 1
		
		# 1. Main flight collision ramp (Chameli Farsh ground to top crest)
		var col_shape: CollisionShape3D = CollisionShape3D.new()
		var ramp_box: BoxShape3D = BoxShape3D.new()
		var ramp_thickness: float = 0.40
		var ramp_hypotenuse: float = sqrt(total_run_x * total_run_x + total_rise * total_rise) # ~14.18m
		ramp_box.size = Vector3(ramp_hypotenuse + 0.30, ramp_thickness, step_width_z + 0.10)
		col_shape.shape = ramp_box
		
		var slope_angle: float = atan2(total_rise, total_run_x) # ~33.43 deg gentle slope
		var str_angle: float = slope_angle * dir_x
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
		var trans_hypotenuse: float = sqrt(trans_len * trans_len + drop_to_floor * drop_to_floor) # ~1.67m
		trans_pad_box.size = Vector3(trans_hypotenuse + 0.20, trans_thickness, step_width_z + 0.10)
		trans_pad_shape.shape = trans_pad_box
		
		var trans_slope: float = atan2(drop_to_floor, trans_len) # ~33.0 deg
		var trans_angle: float = trans_slope * (-dir_x) # Slopes down as X moves further into terrace
		var trans_y_shift: float = (trans_thickness * 0.5) / cos(trans_slope)
		var trans_mid_x: float = end_x + (crest_len + trans_len * 0.5) * dir_x
		var trans_mid_y: float = (target_top_y + terrace_floor_y) * 0.5 - trans_y_shift + 0.03
		
		trans_pad_shape.position = Vector3(trans_mid_x, trans_mid_y, center_z)
		trans_pad_shape.rotation = Vector3(0.0, 0.0, trans_angle)
		col_body.add_child(trans_pad_shape)
		
		stairs_container.add_child(col_body)
		
		add_child(stairs_container)
		
	print("AgraWorld: Re-anchored White Marble Plinth Stairs (Base Y = 34.50m, Top Y = 43.38m) initialized.")

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
	
	# Northern Section (Z = -52.5m to 70m, length 122.5m, center Z = 8.75m)
	var parterre_mesh_n: PlaneMesh = PlaneMesh.new()
	parterre_mesh_n.size = Vector2(3.9, 122.5)
	
	var parterre_left_n: MeshInstance3D = MeshInstance3D.new()
	parterre_left_n.name = "Parterre_Left_North"
	parterre_left_n.mesh = parterre_mesh_n
	parterre_left_n.material_override = parterre_mat
	parterre_left_n.position = Vector3(center_x - 3.55, 33.21, 8.75)
	surfaces_root.add_child(parterre_left_n)
	
	var parterre_right_n: MeshInstance3D = MeshInstance3D.new()
	parterre_right_n.name = "Parterre_Right_North"
	parterre_right_n.mesh = parterre_mesh_n
	parterre_right_n.material_override = parterre_mat
	parterre_right_n.position = Vector3(center_x + 3.55, 33.21, 8.75)
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
	curb_edge_box_n.size = Vector3(0.18, 0.12, 122.5)
	
	var curb_edge_l_n: MeshInstance3D = MeshInstance3D.new()
	curb_edge_l_n.name = "Curb_Edge_Left_North"
	curb_edge_l_n.mesh = curb_edge_box_n
	curb_edge_l_n.material_override = marble_mat
	curb_edge_l_n.position = Vector3(center_x - 5.5, 33.22, 8.75)
	surfaces_root.add_child(curb_edge_l_n)
	
	var curb_edge_r_n: MeshInstance3D = MeshInstance3D.new()
	curb_edge_r_n.name = "Curb_Edge_Right_North"
	curb_edge_r_n.mesh = curb_edge_box_n
	curb_edge_r_n.material_override = marble_mat
	curb_edge_r_n.position = Vector3(center_x + 5.5, 33.22, 8.75)
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
		{"start": -50.0, "end": 66.0},  # Section 2 (North of Lotus pond up to terrace)
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
	
	# 2. Outer Pedestrian Walkways (South: 134m + North: 122.5m):
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
	walk_n_mesh.size = Vector2(5.0, 122.5)
	
	var walk_left_n: MeshInstance3D = MeshInstance3D.new()
	walk_left_n.name = "Walkway_Pedestrian_Left_North"
	walk_left_n.mesh = walk_n_mesh
	walk_left_n.material_override = walk_mat
	walk_left_n.position = Vector3(center_x - 8.0, 33.20, 8.75)
	surfaces_root.add_child(walk_left_n)
	
	var walk_right_n: MeshInstance3D = MeshInstance3D.new()
	walk_right_n.name = "Walkway_Pedestrian_Right_North"
	walk_right_n.mesh = walk_n_mesh
	walk_right_n.material_override = walk_mat
	walk_right_n.position = Vector3(center_x + 8.0, 33.20, 8.75)
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
	
	print("AgraWorld: Full-length promenade and Charbagh ground surfaces created.")

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
	
	# Plant trees along both Section 2 (North: Z = -50m to 66m) and Section 1 (South: Z = 88m to 220m), spaced every 5.5m
	var z_ranges: Array[Dictionary] = [
		{"start": -50.0, "end": 66.0},
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
	# Section 2 (North): Reflecting Canal (3.2m wide, Z = -52.5m to 70m, length 122.5m)
	# -------------------------------------------------------------------------
	var canal_mesh_n: PlaneMesh = PlaneMesh.new()
	canal_mesh_n.size = Vector2(3.2, 122.5)
	canal_mesh_n.subdivide_depth = 24
	
	var central_pool_n: MeshInstance3D = MeshInstance3D.new()
	central_pool_n.name = "CentralReflectingPool_North"
	central_pool_n.mesh = canal_mesh_n
	central_pool_n.material_override = water_mat
	central_pool_n.position = Vector3(center_x, canal_y, 8.75)
	parent.add_child(central_pool_n)
	
	# White Marble Curbs framing the Northern canal at X = +/- 1.675m
	var curb_box_n: BoxMesh = BoxMesh.new()
	curb_box_n.size = Vector3(0.15, 0.12, 122.5)
	
	var curb_w_n: MeshInstance3D = MeshInstance3D.new()
	curb_w_n.name = "Curb_West_North"
	curb_w_n.mesh = curb_box_n
	curb_w_n.material_override = marble_mat
	curb_w_n.position = Vector3(center_x - 1.675, 33.22, 8.75)
	parent.add_child(curb_w_n)
	
	var curb_e_n: MeshInstance3D = MeshInstance3D.new()
	curb_e_n.name = "Curb_East_North"
	curb_e_n.mesh = curb_box_n
	curb_e_n.material_override = marble_mat
	curb_e_n.position = Vector3(center_x + 1.675, 33.22, 8.75)
	parent.add_child(curb_e_n)
	
	# North Terminal Curb Cap at Z = -52.5m (Framing the approach to Southern Grand Steps)
	var curb_box_cap: BoxMesh = BoxMesh.new()
	curb_box_cap.size = Vector3(3.50, 0.12, 0.15)
	var curb_end_n: MeshInstance3D = MeshInstance3D.new()
	curb_end_n.name = "Curb_End_North"
	curb_end_n.mesh = curb_box_cap
	curb_end_n.material_override = marble_mat
	curb_end_n.position = Vector3(center_x, 33.22, -52.5)
	parent.add_child(curb_end_n)
	
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
# AAA Realism Lighting & Atmosphere (PhysicalSky, ACES, Warm Sun, Volumetric Fog)
# -----------------------------------------------------------------------------
func _setup_lighting_and_atmosphere() -> void:
	# 1. Realistic Warm Sunlight (DirectionalLight3D)
	if sun_light:
		sun_light.light_color = Color(1.0, 0.95, 0.88, 1.0) # Warm sunlight
		sun_light.light_energy = 1.0
		sun_light.light_indirect_energy = 0.5
		sun_light.light_volumetric_fog_energy = 0.8
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
		
	# 2. WorldEnvironment Configuration (PhysicalSky, ACES, SSAO, SSR, Volumetric Fog)
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
		
		# Volumetric Fog (density 0.0012, sky_affect 0.5, length 500.0)
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.0012
		env.volumetric_fog_sky_affect = 0.5
		env.volumetric_fog_albedo = Color(0.92, 0.94, 0.98, 1.0)
		env.volumetric_fog_emission = Color(0.12, 0.15, 0.20, 1.0)
		env.volumetric_fog_emission_energy = 0.05
		env.volumetric_fog_anisotropy = 0.35
		env.volumetric_fog_length = 500.0
		
		# Regular height fog disabled to eliminate whiteout
		env.fog_enabled = false
		
		print("AgraWorld: PhysicalSky + ACES + Warm Sun + 0.0012 Volumetric Fog successfully configured.")

# -----------------------------------------------------------------------------
# Material Helpers for Architectural Boundaries
# -----------------------------------------------------------------------------
func _get_sandstone_material(uv_scale: Vector3 = Vector3(0.35, 0.35, 0.35), use_triplanar: bool = true) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	var diff: Texture2D = _safe_load_texture(TEX_SANDSTONE_DIFF)
	var norm: Texture2D = _safe_load_texture(TEX_SANDSTONE_NORM)
	var rough: Texture2D = _safe_load_texture(TEX_SANDSTONE_ROUGH)
	if diff:
		mat.albedo_texture = diff
	mat.albedo_color = Color(0.64, 0.24, 0.18, 1.0) # Authentic imperial terracotta red
	if norm:
		mat.normal_enabled = true
		mat.normal_texture = norm
		mat.normal_scale = 1.2
	if rough:
		mat.roughness_texture = rough
	mat.roughness = 0.82
	mat.uv1_triplanar = use_triplanar
	mat.uv1_scale = uv_scale
	return mat

func _get_gate_marble_material(uv_scale: Vector3 = Vector3(2.0, 2.0, 1.0)) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	var diff: Texture2D = _safe_load_texture(TEX_MARBLE_DIFF)
	var norm: Texture2D = _safe_load_texture(TEX_MARBLE_NORM)
	if diff:
		mat.albedo_texture = diff
	mat.albedo_color = Color(0.96, 0.96, 0.95, 1.0)
	if norm:
		mat.normal_enabled = true
		mat.normal_texture = norm
	mat.uv1_scale = uv_scale
	mat.roughness = 0.25
	return mat

func _get_finial_material() -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.78, 0.28, 1.0) # Authentic turned brass/gold
	mat.metallic = 0.9
	mat.roughness = 0.2
	return mat

func _get_dark_niche_material() -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.08, 0.07, 1.0) # Deep shadowed recess
	mat.roughness = 0.95
	return mat

# -----------------------------------------------------------------------------
# Red Sandstone Perimeter Battlement Walls (Enclosing 304.8m x 304.8m Charbagh)
# -----------------------------------------------------------------------------
func _setup_perimeter_walls() -> void:
	var old_node = get_node_or_null("PerimeterWalls")
	if old_node:
		old_node.queue_free()
		
	var walls_root: Node3D = Node3D.new()
	walls_root.name = "PerimeterWalls"
	add_child(walls_root)
	
	var wall_mat: StandardMaterial3D = _get_sandstone_material(Vector3(4.0, 15.0, 1.0))
	var coping_mat: StandardMaterial3D = _get_sandstone_material(Vector3(2.0, 2.0, 1.0))
	
	var wall_height: float = 7.5
	var wall_thick: float = 1.8
	var base_y: float = 33.15
	var center_y: float = base_y + wall_height * 0.5 # 36.90m
	
	# East Wall: X = +152.4m, Z: -74.0m to 230.8m (304.8m length, center Z = 78.4m)
	_build_wall_segment(walls_root, "EastWall", Vector3(152.4, center_y, 78.4), Vector3(wall_thick, wall_height, 304.8), wall_mat, coping_mat, true)
	
	# West Wall: X = -152.4m, Z: -74.0m to 230.8m (304.8m length, center Z = 78.4m)
	_build_wall_segment(walls_root, "WestWall", Vector3(-152.4, center_y, 78.4), Vector3(wall_thick, wall_height, 304.8), wall_mat, coping_mat, true)
	
	# South Wall West Wing: Z = 230.8m, X: -152.4m to -23.0m (129.4m length, center X = -87.7m)
	_build_wall_segment(walls_root, "SouthWall_WestWing", Vector3(-87.7, center_y, 230.8), Vector3(129.4, wall_height, wall_thick), wall_mat, coping_mat, false)
	
	# South Wall East Wing: Z = 230.8m, X: +23.0m to +152.4m (129.4m length, center X = +87.7m)
	_build_wall_segment(walls_root, "SouthWall_EastWing", Vector3(87.7, center_y, 230.8), Vector3(129.4, wall_height, wall_thick), wall_mat, coping_mat, false)
	
	print("AgraWorld: Perimeter battlement walls constructed (East, West, South wings with crenelated parapets).")

func _build_wall_segment(parent: Node3D, seg_name: String, pos: Vector3, size: Vector3, wall_mat: Material, coping_mat: Material, is_ns_axis: bool) -> void:
	var seg_node: Node3D = Node3D.new()
	seg_node.name = seg_name
	
	# Wall body
	var wall_mesh: BoxMesh = BoxMesh.new()
	wall_mesh.size = size
	var wall_inst: MeshInstance3D = MeshInstance3D.new()
	wall_inst.name = "WallBody"
	wall_inst.mesh = wall_mesh
	wall_inst.material_override = wall_mat
	wall_inst.position = pos
	seg_node.add_child(wall_inst)
	
	# Continuous static collision
	var static_body: StaticBody3D = StaticBody3D.new()
	static_body.name = "Collision"
	var col_shape: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = size
	col_shape.shape = box_shape
	col_shape.position = pos
	static_body.add_child(col_shape)
	seg_node.add_child(static_body)
	
	# Overhanging Coping Slab on Top
	var coping_mesh: BoxMesh = BoxMesh.new()
	coping_mesh.size = Vector3(
		size.x + (0.5 if is_ns_axis else 0.0),
		0.40,
		size.z + (0.0 if is_ns_axis else 0.5)
	)
	var coping_inst: MeshInstance3D = MeshInstance3D.new()
	coping_inst.name = "CopingSlab"
	coping_inst.mesh = coping_mesh
	coping_inst.material_override = coping_mat
	coping_inst.position = Vector3(pos.x, pos.y + size.y * 0.5 + 0.20, pos.z)
	seg_node.add_child(coping_inst)
	
	# Crenelated Parapet along the outer top edge
	var parapet_mesh: BoxMesh = BoxMesh.new()
	var parapet_h: float = 0.85
	parapet_mesh.size = Vector3(
		0.45 if is_ns_axis else size.x,
		parapet_h,
		size.z if is_ns_axis else 0.45
	)
	var parapet_inst: MeshInstance3D = MeshInstance3D.new()
	parapet_inst.name = "ParapetRailing"
	parapet_inst.mesh = parapet_mesh
	parapet_inst.material_override = coping_mat
	var offset_x: float = (size.x * 0.5 - 0.22) * (1.0 if pos.x > 0 else -1.0) if is_ns_axis else 0.0
	var offset_z: float = (size.z * 0.5 - 0.22) if not is_ns_axis else 0.0
	parapet_inst.position = Vector3(pos.x + offset_x, pos.y + size.y * 0.5 + 0.40 + parapet_h * 0.5, pos.z + offset_z)
	seg_node.add_child(parapet_inst)
	
	parent.add_child(seg_node)

# -----------------------------------------------------------------------------
# Corner Octagonal Watchtowers (Burj with Pillared Chattris & Marble Domes)
# -----------------------------------------------------------------------------
func _setup_corner_burjs() -> void:
	var old_node = get_node_or_null("CornerBurjs")
	if old_node:
		old_node.queue_free()
		
	var burjs_root: Node3D = Node3D.new()
	burjs_root.name = "CornerBurjs"
	add_child(burjs_root)
	
	var wall_mat: StandardMaterial3D = _get_sandstone_material(Vector3(3.0, 8.0, 1.0))
	var marble_mat: StandardMaterial3D = _get_gate_marble_material(Vector3(1.5, 1.5, 1.0))
	var finial_mat: StandardMaterial3D = _get_finial_material()
	
	# SW Burj: X = -152.4m, Z = 230.8m
	_build_single_burj(burjs_root, "Burj_SouthWest", Vector3(-152.4, 33.15, 230.8), wall_mat, marble_mat, finial_mat)
	
	# SE Burj: X = +152.4m, Z = 230.8m
	_build_single_burj(burjs_root, "Burj_SouthEast", Vector3(152.4, 33.15, 230.8), wall_mat, marble_mat, finial_mat)
	
	print("AgraWorld: Corner Burjs constructed (SW and SE 3-story octagonal sandstone towers with marble chattris).")

func _build_single_burj(parent: Node3D, burj_name: String, base_pos: Vector3, wall_mat: Material, marble_mat: Material, finial_mat: Material) -> void:
	var burj_node: Node3D = Node3D.new()
	burj_node.name = burj_name
	
	var tower_h: float = 15.0
	var tower_r: float = 4.5
	var base_y: float = base_pos.y
	
	# 1. Base Octagonal Podium: diameter 11.0m, height 1.2m
	var plinth_mesh: CylinderMesh = CylinderMesh.new()
	plinth_mesh.radial_segments = 8
	plinth_mesh.top_radius = 5.5
	plinth_mesh.bottom_radius = 5.5
	plinth_mesh.height = 1.2
	var plinth_inst: MeshInstance3D = MeshInstance3D.new()
	plinth_inst.name = "Podium"
	plinth_inst.mesh = plinth_mesh
	plinth_inst.material_override = wall_mat
	plinth_inst.position = Vector3(base_pos.x, base_y + 0.6, base_pos.z)
	plinth_inst.rotation.y = PI / 8.0
	burj_node.add_child(plinth_inst)
	
	# 2. Tower Shaft (3-story octagonal cylinder): height 15.0m
	var shaft_mesh: CylinderMesh = CylinderMesh.new()
	shaft_mesh.radial_segments = 8
	shaft_mesh.bottom_radius = tower_r
	shaft_mesh.top_radius = tower_r * 0.94 # Subtle graceful Mughal taper
	shaft_mesh.height = tower_h
	var shaft_inst: MeshInstance3D = MeshInstance3D.new()
	shaft_inst.name = "OctagonalShaft"
	shaft_inst.mesh = shaft_mesh
	shaft_inst.material_override = wall_mat
	shaft_inst.position = Vector3(base_pos.x, base_y + tower_h * 0.5, base_pos.z)
	shaft_inst.rotation.y = PI / 8.0
	burj_node.add_child(shaft_inst)
	
	# 3. Decorative Story Molding Rings (at Y = base_y + 5.0m and base_y + 10.0m)
	for ring_y in [base_y + 5.0, base_y + 10.0]:
		var ring_mesh: CylinderMesh = CylinderMesh.new()
		ring_mesh.radial_segments = 8
		ring_mesh.top_radius = tower_r + 0.35
		ring_mesh.bottom_radius = tower_r + 0.35
		ring_mesh.height = 0.40
		var ring_inst: MeshInstance3D = MeshInstance3D.new()
		ring_inst.name = "StoryBelt"
		ring_inst.mesh = ring_mesh
		ring_inst.material_override = wall_mat
		ring_inst.position = Vector3(base_pos.x, ring_y, base_pos.z)
		ring_inst.rotation.y = PI / 8.0
		burj_node.add_child(ring_inst)
		
	# 4. Overhanging Balcony Cornice (Chhajja) at top of shaft: Y = base_y + tower_h
	var deck_y: float = base_y + tower_h
	var chhajja_mesh: CylinderMesh = CylinderMesh.new()
	chhajja_mesh.radial_segments = 8
	chhajja_mesh.bottom_radius = tower_r * 0.94
	chhajja_mesh.top_radius = 5.6
	chhajja_mesh.height = 0.60
	var chhajja_inst: MeshInstance3D = MeshInstance3D.new()
	chhajja_inst.name = "BalconyChhajja"
	chhajja_inst.mesh = chhajja_mesh
	chhajja_inst.material_override = wall_mat
	chhajja_inst.position = Vector3(base_pos.x, deck_y + 0.30, base_pos.z)
	chhajja_inst.rotation.y = PI / 8.0
	burj_node.add_child(chhajja_inst)
	
	# Balcony Parapet
	var parapet_ring: CylinderMesh = CylinderMesh.new()
	parapet_ring.radial_segments = 8
	parapet_ring.bottom_radius = 5.4
	parapet_ring.top_radius = 5.4
	parapet_ring.height = 0.90
	var parapet_inst: MeshInstance3D = MeshInstance3D.new()
	parapet_inst.name = "BalconyParapet"
	parapet_inst.mesh = parapet_ring
	parapet_inst.material_override = wall_mat
	parapet_inst.position = Vector3(base_pos.x, deck_y + 0.60 + 0.45, base_pos.z)
	parapet_inst.rotation.y = PI / 8.0
	burj_node.add_child(parapet_inst)
	
	# 5. Upper Pillared Chattri (8 Slender Columns supporting Marble Dome)
	var chattri_base_y: float = deck_y + 0.60
	var col_h: float = 3.6
	var col_r: float = 0.22
	var col_spread: float = 3.6
	for i in range(8):
		var angle: float = float(i) * (PI / 4.0) + (PI / 8.0)
		var col_mesh: CylinderMesh = CylinderMesh.new()
		col_mesh.radial_segments = 8
		col_mesh.top_radius = col_r
		col_mesh.bottom_radius = col_r
		col_mesh.height = col_h
		var col_inst: MeshInstance3D = MeshInstance3D.new()
		col_inst.name = "ChattriCol_%d" % i
		col_inst.mesh = col_mesh
		col_inst.material_override = wall_mat
		col_inst.position = Vector3(
			base_pos.x + cos(angle) * col_spread,
			chattri_base_y + col_h * 0.5,
			base_pos.z + sin(angle) * col_spread
		)
		burj_node.add_child(col_inst)
		
	# Chattri Eaves Roof Slab
	var eaves_y: float = chattri_base_y + col_h
	var eaves_mesh: CylinderMesh = CylinderMesh.new()
	eaves_mesh.radial_segments = 8
	eaves_mesh.bottom_radius = 4.4
	eaves_mesh.top_radius = 4.1
	eaves_mesh.height = 0.45
	var eaves_inst: MeshInstance3D = MeshInstance3D.new()
	eaves_inst.name = "ChattriEaves"
	eaves_inst.mesh = eaves_mesh
	eaves_inst.material_override = wall_mat
	eaves_inst.position = Vector3(base_pos.x, eaves_y + 0.225, base_pos.z)
	eaves_inst.rotation.y = PI / 8.0
	burj_node.add_child(eaves_inst)
	
	# 6. Bulbous White Marble Dome
	var dome_mesh: SphereMesh = SphereMesh.new()
	dome_mesh.radial_segments = 24
	dome_mesh.rings = 16
	dome_mesh.radius = 3.2
	dome_mesh.height = 4.2
	var dome_inst: MeshInstance3D = MeshInstance3D.new()
	dome_inst.name = "MarbleDome"
	dome_inst.mesh = dome_mesh
	dome_inst.material_override = marble_mat
	dome_inst.position = Vector3(base_pos.x, eaves_y + 0.45 + 1.8, base_pos.z)
	burj_node.add_child(dome_inst)
	
	# 7. Brass / Golden Kalasa Finial
	var finial_mesh: CylinderMesh = CylinderMesh.new()
	finial_mesh.radial_segments = 8
	finial_mesh.bottom_radius = 0.22
	finial_mesh.top_radius = 0.02
	finial_mesh.height = 2.4
	var finial_inst: MeshInstance3D = MeshInstance3D.new()
	finial_inst.name = "Finial"
	finial_inst.mesh = finial_mesh
	finial_inst.material_override = finial_mat
	finial_inst.position = Vector3(base_pos.x, eaves_y + 0.45 + 4.2 + 1.0, base_pos.z)
	burj_node.add_child(finial_inst)
	
	# Static Collision Body
	var static_body: StaticBody3D = StaticBody3D.new()
	static_body.name = "Collision"
	var col_shape: CollisionShape3D = CollisionShape3D.new()
	var cyl_shape: CylinderShape3D = CylinderShape3D.new()
	cyl_shape.radius = tower_r + 0.2
	cyl_shape.height = tower_h
	col_shape.shape = cyl_shape
	col_shape.position = Vector3(base_pos.x, base_y + tower_h * 0.5, base_pos.z)
	static_body.add_child(col_shape)
	burj_node.add_child(static_body)
	
	parent.add_child(burj_node)

# -----------------------------------------------------------------------------
# The Great Gate (Darwaza-i Rauza - Monumental 46m x 22m x 30m Southern Gateway)
# -----------------------------------------------------------------------------
func _setup_great_gate() -> void:
	var old_node = get_node_or_null("GreatGate")
	if old_node:
		old_node.queue_free()
		
	var gate_root: Node3D = Node3D.new()
	gate_root.name = "GreatGate"
	add_child(gate_root)
	
	var sand_mat: StandardMaterial3D = _get_sandstone_material(Vector3(6.0, 6.0, 1.0))
	var marble_mat: StandardMaterial3D = _get_gate_marble_material(Vector3(2.0, 2.0, 1.0))
	var dark_mat: StandardMaterial3D = _get_dark_niche_material()
	var finial_mat: StandardMaterial3D = _get_finial_material()
	
	# Overall gate coordinates:
	# Center: X = 0.0, Z = 230.8m
	# Dimensions: Width = 46m (X: -23 to +23), Depth = 22m (Z: 219.8 to 241.8), Height = 30m (Y: 33.15 to 63.15)
	# Portal opening: Width = 14m (X: -7 to +7), Height = 20m (Y: 33.15 to 53.15)
	var gate_z: float = 230.8
	var base_y: float = 33.15
	var gate_h: float = 30.0
	var portal_w: float = 14.0
	var portal_h: float = 20.0
	var wing_w: float = 16.0 # (46.0 - 14.0) / 2
	var gate_depth: float = 22.0
	
	# -------------------------------------------------------------------------
	# 1. Main Structural Masses
	# -------------------------------------------------------------------------
	# West Wing Mass: X = -15.0m
	var wing_mesh: BoxMesh = BoxMesh.new()
	wing_mesh.size = Vector3(wing_w, gate_h, gate_depth)
	
	var west_wing: MeshInstance3D = MeshInstance3D.new()
	west_wing.name = "WestWingMass"
	west_wing.mesh = wing_mesh
	west_wing.material_override = sand_mat
	west_wing.position = Vector3(-15.0, base_y + gate_h * 0.5, gate_z)
	gate_root.add_child(west_wing)
	
	# East Wing Mass: X = +15.0m
	var east_wing: MeshInstance3D = MeshInstance3D.new()
	east_wing.name = "EastWingMass"
	east_wing.mesh = wing_mesh
	east_wing.material_override = sand_mat
	east_wing.position = Vector3(15.0, base_y + gate_h * 0.5, gate_z)
	gate_root.add_child(east_wing)
	
	# Upper Arch Bridge Mass (above portal from Y = base_y + portal_h to base_y + gate_h)
	var bridge_h: float = gate_h - portal_h # 10.0m
	var bridge_mesh: BoxMesh = BoxMesh.new()
	bridge_mesh.size = Vector3(portal_w, bridge_h, gate_depth)
	
	var bridge_inst: MeshInstance3D = MeshInstance3D.new()
	bridge_inst.name = "UpperArchBridge"
	bridge_inst.mesh = bridge_mesh
	bridge_inst.material_override = sand_mat
	bridge_inst.position = Vector3(0.0, base_y + portal_h + bridge_h * 0.5, gate_z)
	gate_root.add_child(bridge_inst)
	
	# -------------------------------------------------------------------------
	# 2. Walk-Through Passage Vault & Floor
	# -------------------------------------------------------------------------
	# Smooth pedestrian tunnel floor at Y = 33.18m
	var floor_mesh: BoxMesh = BoxMesh.new()
	floor_mesh.size = Vector3(portal_w, 0.20, gate_depth)
	var floor_inst: MeshInstance3D = MeshInstance3D.new()
	floor_inst.name = "TunnelFloor"
	floor_inst.mesh = floor_mesh
	floor_inst.material_override = sand_mat
	floor_inst.position = Vector3(0.0, base_y + 0.10, gate_z)
	gate_root.add_child(floor_inst)
	
	# Pointed Vault Ceiling chamfers (angles softening the upper portal corners)
	var vault_chamfer_mesh: BoxMesh = BoxMesh.new()
	vault_chamfer_mesh.size = Vector3(3.0, 3.0, gate_depth)
	
	var chamfer_left: MeshInstance3D = MeshInstance3D.new()
	chamfer_left.name = "VaultChamfer_Left"
	chamfer_left.mesh = vault_chamfer_mesh
	chamfer_left.material_override = sand_mat
	chamfer_left.position = Vector3(-5.5, base_y + portal_h - 1.2, gate_z)
	chamfer_left.rotation.z = PI / 4.0
	gate_root.add_child(chamfer_left)
	
	var chamfer_right: MeshInstance3D = MeshInstance3D.new()
	chamfer_right.name = "VaultChamfer_Right"
	chamfer_right.mesh = vault_chamfer_mesh
	chamfer_right.material_override = sand_mat
	chamfer_right.position = Vector3(5.5, base_y + portal_h - 1.2, gate_z)
	chamfer_right.rotation.z = -PI / 4.0
	gate_root.add_child(chamfer_right)
	
	# -------------------------------------------------------------------------
	# 3. Facade Pishtaq Framing & Mughal Arched Niches (North & South)
	# -------------------------------------------------------------------------
	var facades: Array[Dictionary] = [
		{"name": "NorthFacade", "z": gate_z - gate_depth * 0.5, "sign": -1.0},
		{"name": "SouthFacade", "z": gate_z + gate_depth * 0.5, "sign": 1.0}
	]
	
	for fac in facades:
		var f_z: float = fac["z"]
		var f_sign: float = fac["sign"]
		var f_offset_z: float = f_z + 0.08 * f_sign
		
		# White Marble Calligraphic Pishtaq Rectangular Frame
		# Left vertical band
		var band_v: BoxMesh = BoxMesh.new()
		band_v.size = Vector3(1.4, 25.0, 0.20)
		var band_l: MeshInstance3D = MeshInstance3D.new()
		band_l.name = fac["name"] + "_MarbleBand_L"
		band_l.mesh = band_v
		band_l.material_override = marble_mat
		band_l.position = Vector3(-7.7, base_y + 12.5, f_offset_z)
		gate_root.add_child(band_l)
		
		# Right vertical band
		var band_r: MeshInstance3D = MeshInstance3D.new()
		band_r.name = fac["name"] + "_MarbleBand_R"
		band_r.mesh = band_v
		band_r.material_override = marble_mat
		band_r.position = Vector3(7.7, base_y + 12.5, f_offset_z)
		gate_root.add_child(band_r)
		
		# Top horizontal band
		var band_h: BoxMesh = BoxMesh.new()
		band_h.size = Vector3(16.8, 1.4, 0.20)
		var band_top: MeshInstance3D = MeshInstance3D.new()
		band_top.name = fac["name"] + "_MarbleBand_Top"
		band_top.mesh = band_h
		band_top.material_override = marble_mat
		band_top.position = Vector3(0.0, base_y + 24.3, f_offset_z)
		gate_root.add_child(band_top)
		
		# Marble Spandrel Arabesque Reliefs (triangular rosette accents flanking arch apex)
		for sp_sign in [-1.0, 1.0]:
			var sp_mesh: BoxMesh = BoxMesh.new()
			sp_mesh.size = Vector3(2.5, 2.5, 0.18)
			var sp_inst: MeshInstance3D = MeshInstance3D.new()
			sp_inst.name = fac["name"] + "_Spandrel_" + ("L" if sp_sign < 0 else "R")
			sp_inst.mesh = sp_mesh
			sp_inst.material_override = marble_mat
			sp_inst.position = Vector3(sp_sign * 5.0, base_y + 21.0, f_offset_z)
			sp_inst.rotation.z = PI / 4.0
			gate_root.add_child(sp_inst)
			
		# Tiered Recessed Mughal Arched Niches (Jharokhas) on Left and Right Wings
		for wing_x in [-15.0, 15.0]:
			for tier in [0, 1]:
				var niche_y: float = base_y + 6.5 + float(tier) * 11.0 # Tier 0 at 39.65m, Tier 1 at 50.65m
				# Niche dark recess
				var niche_mesh: BoxMesh = BoxMesh.new()
				niche_mesh.size = Vector3(5.5, 8.0, 0.6)
				var niche_inst: MeshInstance3D = MeshInstance3D.new()
				niche_inst.name = fac["name"] + "_Niche_%d_%d" % [int(wing_x), tier]
				niche_inst.mesh = niche_mesh
				niche_inst.material_override = dark_mat
				niche_inst.position = Vector3(wing_x, niche_y, f_z - 0.2 * f_sign)
				gate_root.add_child(niche_inst)
				
				# Niche Marble Framing Border
				var n_frame: BoxMesh = BoxMesh.new()
				n_frame.size = Vector3(5.9, 8.4, 0.15)
				var n_frame_inst: MeshInstance3D = MeshInstance3D.new()
				n_frame_inst.name = fac["name"] + "_NicheFrame_%d_%d" % [int(wing_x), tier]
				n_frame_inst.mesh = n_frame
				n_frame_inst.material_override = marble_mat
				n_frame_inst.position = Vector3(wing_x, niche_y, f_offset_z)
				gate_root.add_child(n_frame_inst)

	# -------------------------------------------------------------------------
	# 4. Roofline Parapet & 11 Domed Cupolas (Chattris)
	# -------------------------------------------------------------------------
	var roof_y: float = base_y + gate_h # 63.15m
	
	# Parapet Wall surrounding gate roof
	var parapet_box: BoxMesh = BoxMesh.new()
	parapet_box.size = Vector3(46.0, 1.20, gate_depth)
	var parapet_inst: MeshInstance3D = MeshInstance3D.new()
	parapet_inst.name = "RoofParapet"
	parapet_inst.mesh = parapet_box
	parapet_inst.material_override = sand_mat
	parapet_inst.position = Vector3(0.0, roof_y + 0.60, gate_z)
	gate_root.add_child(parapet_inst)
	
	# 11 Miniature Domed Chattris aligned along the North and South parapet rooflines
	# Spaced from X = -18.0m to +18.0m (step 3.6m)
	for side_z in [gate_z - gate_depth * 0.5 + 0.6, gate_z + gate_depth * 0.5 - 0.6]:
		for i in range(11):
			var cupola_x: float = -18.0 + float(i) * 3.6
			_build_roofline_cupola(gate_root, "RoofCupola_%d_%d" % [int(side_z), i], Vector3(cupola_x, roof_y + 1.20, side_z), marble_mat, finial_mat)
			
	# -------------------------------------------------------------------------
	# 5. Four Corner Octagonal Turrets (Guldastas)
	# -------------------------------------------------------------------------
	var turret_h: float = 34.0 # Projects 4.0m above main 30m roofline (reaches Y = 67.15m)
	var turret_r: float = 1.8
	var turret_offsets: Array[Vector2] = [
		Vector2(-23.0, gate_z - gate_depth * 0.5), # NW
		Vector2(23.0, gate_z - gate_depth * 0.5),  # NE
		Vector2(-23.0, gate_z + gate_depth * 0.5), # SW
		Vector2(23.0, gate_z + gate_depth * 0.5)   # SE
	]
	
	for t_idx in range(turret_offsets.size()):
		var t_pos: Vector2 = turret_offsets[t_idx]
		var t_node: Node3D = Node3D.new()
		t_node.name = "CornerTurret_%d" % t_idx
		
		# Octagonal shaft
		var t_shaft: CylinderMesh = CylinderMesh.new()
		t_shaft.radial_segments = 8
		t_shaft.bottom_radius = turret_r
		t_shaft.top_radius = turret_r * 0.95
		t_shaft.height = turret_h
		var t_inst: MeshInstance3D = MeshInstance3D.new()
		t_inst.name = "Shaft"
		t_inst.mesh = t_shaft
		t_inst.material_override = sand_mat
		t_inst.position = Vector3(t_pos.x, base_y + turret_h * 0.5, t_pos.y)
		t_inst.rotation.y = PI / 8.0
		t_node.add_child(t_inst)
		
		# Turret Overhanging Chhajja Balcony
		var t_top_y: float = base_y + turret_h
		var t_chhajja: CylinderMesh = CylinderMesh.new()
		t_chhajja.radial_segments = 8
		t_chhajja.bottom_radius = turret_r
		t_chhajja.top_radius = 2.4
		t_chhajja.height = 0.4
		var tch_inst: MeshInstance3D = MeshInstance3D.new()
		tch_inst.name = "Chhajja"
		tch_inst.mesh = t_chhajja
		tch_inst.material_override = sand_mat
		tch_inst.position = Vector3(t_pos.x, t_top_y + 0.2, t_pos.y)
		tch_inst.rotation.y = PI / 8.0
		t_node.add_child(tch_inst)
		
		# Miniature Pillared Pavilion (6 pillars)
		for p in range(6):
			var p_angle: float = float(p) * (PI / 3.0)
			var p_mesh: CylinderMesh = CylinderMesh.new()
			p_mesh.radial_segments = 6
			p_mesh.top_radius = 0.12
			p_mesh.bottom_radius = 0.12
			p_mesh.height = 2.0
			var p_inst: MeshInstance3D = MeshInstance3D.new()
			p_inst.name = "Pillar_%d" % p
			p_inst.mesh = p_mesh
			p_inst.material_override = marble_mat
			p_inst.position = Vector3(
				t_pos.x + cos(p_angle) * 1.5,
				t_top_y + 0.4 + 1.0,
				t_pos.y + sin(p_angle) * 1.5
			)
			t_node.add_child(p_inst)
			
		# White Marble Dome
		var t_dome: SphereMesh = SphereMesh.new()
		t_dome.radial_segments = 16
		t_dome.rings = 12
		t_dome.radius = 1.6
		t_dome.height = 2.2
		var td_inst: MeshInstance3D = MeshInstance3D.new()
		td_inst.name = "Dome"
		td_inst.mesh = t_dome
		td_inst.material_override = marble_mat
		td_inst.position = Vector3(t_pos.x, t_top_y + 2.4 + 1.0, t_pos.y)
		t_node.add_child(td_inst)
		
		# Golden Finial
		var t_finial: CylinderMesh = CylinderMesh.new()
		t_finial.radial_segments = 6
		t_finial.bottom_radius = 0.10
		t_finial.top_radius = 0.02
		t_finial.height = 1.8
		var tf_inst: MeshInstance3D = MeshInstance3D.new()
		tf_inst.name = "Finial"
		tf_inst.mesh = t_finial
		tf_inst.material_override = finial_mat
		tf_inst.position = Vector3(t_pos.x, t_top_y + 2.4 + 2.2 + 0.7, t_pos.y)
		t_node.add_child(tf_inst)
		
		# Static Collision for turret
		var t_col_body: StaticBody3D = StaticBody3D.new()
		var t_col_shape: CollisionShape3D = CollisionShape3D.new()
		var t_cyl: CylinderShape3D = CylinderShape3D.new()
		t_cyl.radius = turret_r
		t_cyl.height = turret_h
		t_col_shape.shape = t_cyl
		t_col_shape.position = Vector3(t_pos.x, base_y + turret_h * 0.5, t_pos.y)
		t_col_body.add_child(t_col_shape)
		t_node.add_child(t_col_body)
		
		gate_root.add_child(t_node)

	# -------------------------------------------------------------------------
	# 6. Physical Colliders (Leaving Open Central Walk-Through Passage)
	# -------------------------------------------------------------------------
	var gate_col_body: StaticBody3D = StaticBody3D.new()
	gate_col_body.name = "GateStructuralCollision"
	
	# West Wing Collider
	var cs_west: CollisionShape3D = CollisionShape3D.new()
	var box_west: BoxShape3D = BoxShape3D.new()
	box_west.size = Vector3(wing_w, gate_h, gate_depth)
	cs_west.shape = box_west
	cs_west.position = Vector3(-15.0, base_y + gate_h * 0.5, gate_z)
	gate_col_body.add_child(cs_west)
	
	# East Wing Collider
	var cs_east: CollisionShape3D = CollisionShape3D.new()
	var box_east: BoxShape3D = BoxShape3D.new()
	box_east.size = Vector3(wing_w, gate_h, gate_depth)
	cs_east.shape = box_east
	cs_east.position = Vector3(15.0, base_y + gate_h * 0.5, gate_z)
	gate_col_body.add_child(cs_east)
	
	# Upper Bridge Collider (above 20m portal ceiling)
	var cs_bridge: CollisionShape3D = CollisionShape3D.new()
	var box_bridge: BoxShape3D = BoxShape3D.new()
	box_bridge.size = Vector3(portal_w, bridge_h, gate_depth)
	cs_bridge.shape = box_bridge
	cs_bridge.position = Vector3(0.0, base_y + portal_h + bridge_h * 0.5, gate_z)
	gate_col_body.add_child(cs_bridge)
	
	# Walkway Floor Collider under portal
	var cs_floor: CollisionShape3D = CollisionShape3D.new()
	var box_floor: BoxShape3D = BoxShape3D.new()
	box_floor.size = Vector3(portal_w, 1.0, gate_depth)
	cs_floor.shape = box_floor
	cs_floor.position = Vector3(0.0, base_y - 0.5, gate_z)
	gate_col_body.add_child(cs_floor)
	
	gate_root.add_child(gate_col_body)
	print("AgraWorld: The Great Gate (Darwaza-i Rauza: 46m x 22m x 30m) constructed with walk-through portal.")

func _build_roofline_cupola(parent: Node3D, cupola_name: String, pos: Vector3, marble_mat: Material, finial_mat: Material) -> void:
	var cupola: Node3D = Node3D.new()
	cupola.name = cupola_name
	
	# 4 Slender Columns
	var col_h: float = 1.3
	var col_r: float = 0.08
	for i in range(4):
		var ang: float = float(i) * (PI / 2.0) + (PI / 4.0)
		var c_mesh: CylinderMesh = CylinderMesh.new()
		c_mesh.radial_segments = 6
		c_mesh.top_radius = col_r
		c_mesh.bottom_radius = col_r
		c_mesh.height = col_h
		var c_inst: MeshInstance3D = MeshInstance3D.new()
		c_inst.mesh = c_mesh
		c_inst.material_override = marble_mat
		c_inst.position = Vector3(pos.x + cos(ang) * 0.65, pos.y + col_h * 0.5, pos.z + sin(ang) * 0.65)
		cupola.add_child(c_inst)
		
	# Cupola Roof Cornice
	var cornice_mesh: BoxMesh = BoxMesh.new()
	cornice_mesh.size = Vector3(1.6, 0.15, 1.6)
	var cornice_inst: MeshInstance3D = MeshInstance3D.new()
	cornice_inst.mesh = cornice_mesh
	cornice_inst.material_override = marble_mat
	cornice_inst.position = Vector3(pos.x, pos.y + col_h + 0.075, pos.z)
	cupola.add_child(cornice_inst)
	
	# Marble Dome
	var dome_mesh: SphereMesh = SphereMesh.new()
	dome_mesh.radial_segments = 12
	dome_mesh.rings = 8
	dome_mesh.radius = 0.65
	dome_mesh.height = 0.95
	var dome_inst: MeshInstance3D = MeshInstance3D.new()
	dome_inst.mesh = dome_mesh
	dome_inst.material_override = marble_mat
	dome_inst.position = Vector3(pos.x, pos.y + col_h + 0.15 + 0.40, pos.z)
	cupola.add_child(dome_inst)
	
	# Mini Brass Finial
	var fin_mesh: CylinderMesh = CylinderMesh.new()
	fin_mesh.radial_segments = 6
	fin_mesh.bottom_radius = 0.06
	fin_mesh.top_radius = 0.01
	fin_mesh.height = 0.60
	var fin_inst: MeshInstance3D = MeshInstance3D.new()
	fin_inst.mesh = fin_mesh
	fin_inst.material_override = finial_mat
	fin_inst.position = Vector3(pos.x, pos.y + col_h + 0.15 + 0.95 + 0.25, pos.z)
	cupola.add_child(fin_inst)
	
	parent.add_child(cupola)

# -----------------------------------------------------------------------------
# Outer Ground Skirt & Southern Forecourt (Eliminating Empty Voids Beyond Walls)
# -----------------------------------------------------------------------------
func _setup_outer_ground_skirt() -> void:
	var old_node = get_node_or_null("OuterGroundSkirt")
	if old_node:
		old_node.queue_free()
		
	var skirt_root: Node3D = Node3D.new()
	skirt_root.name = "OuterGroundSkirt"
	add_child(skirt_root)
	
	var grass_diff: Texture2D = _safe_load_texture(TEX_GRASS_DIFF)
	var grass_norm: Texture2D = _safe_load_texture(TEX_GRASS_NORM)
	var sand_diff: Texture2D = _safe_load_texture(TEX_SANDSTONE_DIFF)
	var sand_norm: Texture2D = _safe_load_texture(TEX_SANDSTONE_NORM)
	
	# Outer Grass Ground Material
	var outer_grass_mat: StandardMaterial3D = StandardMaterial3D.new()
	if grass_diff:
		outer_grass_mat.albedo_texture = grass_diff
	outer_grass_mat.albedo_color = Color(0.32, 0.50, 0.20, 1.0)
	if grass_norm:
		outer_grass_mat.normal_enabled = true
		outer_grass_mat.normal_texture = grass_norm
	outer_grass_mat.uv1_scale = Vector3(50.0, 50.0, 1.0)
	outer_grass_mat.roughness = 0.85
	
	# Forecourt Sandstone Pavement Material
	var forecourt_mat: StandardMaterial3D = StandardMaterial3D.new()
	if sand_diff:
		forecourt_mat.albedo_texture = sand_diff
	forecourt_mat.albedo_color = Color(0.85, 0.50, 0.42, 1.0)
	if sand_norm:
		forecourt_mat.normal_enabled = true
		forecourt_mat.normal_texture = sand_norm
	forecourt_mat.uv1_scale = Vector3(20.0, 20.0, 1.0)
	forecourt_mat.roughness = 0.80
	
	# 1. Jilaukhana Southern Forecourt Plaza (immediately south of Great Gate from Z = 241.8 to 360.0)
	var forecourt_mesh: PlaneMesh = PlaneMesh.new()
	forecourt_mesh.size = Vector2(240.0, 120.0)
	var forecourt_inst: MeshInstance3D = MeshInstance3D.new()
	forecourt_inst.name = "SouthernForecourtPlaza"
	forecourt_inst.mesh = forecourt_mesh
	forecourt_inst.material_override = forecourt_mat
	forecourt_inst.position = Vector3(0.0, 33.16, 301.0) # Z center of [241.8, 360] is ~301m
	skirt_root.add_child(forecourt_inst)
	
	# Solid Static Collision for Forecourt
	var fc_col_body: StaticBody3D = StaticBody3D.new()
	var fc_col_shape: CollisionShape3D = CollisionShape3D.new()
	var fc_box: BoxShape3D = BoxShape3D.new()
	fc_box.size = Vector3(240.0, 2.0, 120.0)
	fc_col_shape.shape = fc_box
	fc_col_shape.position = Vector3(0.0, 32.16, 301.0)
	fc_col_body.add_child(fc_col_shape)
	skirt_root.add_child(fc_col_body)
	
	# 2. Large Outer Surrounding Ground Planes (Eliminates voids / checkered terrain outside walls)
	var skirts: Array[Dictionary] = [
		{"name": "Skirt_South", "size": Vector2(900.0, 300.0), "pos": Vector3(0.0, 33.05, 510.0)},
		{"name": "Skirt_West", "size": Vector2(400.0, 700.0), "pos": Vector3(-352.4, 33.05, 80.0)},
		{"name": "Skirt_East", "size": Vector2(400.0, 700.0), "pos": Vector3(352.4, 33.05, 80.0)}
	]
	
	for s in skirts:
		var p_mesh: PlaneMesh = PlaneMesh.new()
		p_mesh.size = s["size"]
		var p_inst: MeshInstance3D = MeshInstance3D.new()
		p_inst.name = s["name"]
		p_inst.mesh = p_mesh
		p_inst.material_override = outer_grass_mat
		p_inst.position = s["pos"]
		skirt_root.add_child(p_inst)
		
		# Add static floor collision
		var sk_body: StaticBody3D = StaticBody3D.new()
		var sk_col: CollisionShape3D = CollisionShape3D.new()
		var sk_box: BoxShape3D = BoxShape3D.new()
		sk_box.size = Vector3(s["size"].x, 2.0, s["size"].y)
		sk_col.shape = sk_box
		sk_col.position = Vector3(s["pos"].x, 32.05, s["pos"].z)
		sk_body.add_child(sk_col)
		skirt_root.add_child(sk_body)
		
	print("AgraWorld: Outer ground skirt and southern forecourt initialized.")

# -----------------------------------------------------------------------------
# Additional Architectural Materials
# -----------------------------------------------------------------------------
func _get_mosque_sandstone_material(uv_scale: Vector3 = Vector3(0.35, 0.35, 0.35)) -> StandardMaterial3D:
	return _get_sandstone_material(uv_scale, true)

func _get_dome_marble_material() -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	var diff: Texture2D = _safe_load_texture(TEX_MARBLE_DIFF)
	var norm: Texture2D = _safe_load_texture(TEX_MARBLE_NORM)
	if diff:
		mat.albedo_texture = diff
	mat.albedo_color = Color(0.96, 0.96, 0.94, 1.0) # Pure luminous off-white
	if norm:
		mat.normal_enabled = true
		mat.normal_texture = norm
	mat.roughness = 0.22
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.4
	mat.clearcoat_roughness = 0.15
	mat.metallic = 0.02
	mat.uv1_scale = Vector3(2.0, 2.0, 1.0)
	return mat

func _get_water_material() -> StandardMaterial3D:
	var water_mat: StandardMaterial3D = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.08, 0.28, 0.35, 0.95)
	water_mat.roughness = 0.02
	water_mat.metallic = 0.05
	water_mat.clearcoat_enabled = true
	water_mat.clearcoat = 1.0
	water_mat.clearcoat_roughness = 0.02
	return water_mat

# -----------------------------------------------------------------------------
# Riverfront Chameli Farsh Terrace Foundation & Retaining Balustrade
# -----------------------------------------------------------------------------
func _setup_chameli_farsh() -> void:
	var old_node = get_node_or_null("ChameliFarsh")
	if old_node:
		old_node.queue_free()
		
	var terrace_root: Node3D = Node3D.new()
	terrace_root.name = "ChameliFarsh"
	add_child(terrace_root)
	
	var sand_mat: StandardMaterial3D = _get_sandstone_material(Vector3(0.35, 0.35, 0.35), true)
	
	# Authentic Survey Dimensions: 304.8m along X (X: -152.4 to +152.4), 139.9m along Z (Z: -195.9 to -56.0)
	# Extended forward along Z by 18.0m into Charbagh garden (creating wide ceremonial stone apron in front of Taj plinth)
	# Terrace deck height: Y = 34.50m (elevated 1.35m above Charbagh turf at Y = 33.15m)
	var deck_y: float = 34.50
	var slab_thick: float = 2.0
	var slab_y: float = deck_y - slab_thick * 0.5 # 33.50m
	var center_z: float = -125.95 # (-56.0 + -195.9) * 0.5
	var terrace_depth_z: float = 139.9
	
	# 1. Main Elevated Terrace Foundation Slab (304.8m x 139.9m)
	var terrace_mesh: BoxMesh = BoxMesh.new()
	terrace_mesh.size = Vector3(304.8, slab_thick, terrace_depth_z)
	var terrace_inst: MeshInstance3D = MeshInstance3D.new()
	terrace_inst.name = "TerraceDeck"
	terrace_inst.mesh = terrace_mesh
	terrace_inst.material_override = sand_mat
	terrace_inst.position = Vector3(0.0, slab_y, center_z)
	terrace_root.add_child(terrace_inst)
	
	# Solid Static Floor Collision for Chameli Farsh
	var terrace_body: StaticBody3D = StaticBody3D.new()
	terrace_body.name = "DeckCollision"
	var terrace_col: CollisionShape3D = CollisionShape3D.new()
	var terrace_shape: BoxShape3D = BoxShape3D.new()
	terrace_shape.size = Vector3(304.8, slab_thick, terrace_depth_z)
	terrace_col.shape = terrace_shape
	terrace_col.position = Vector3(0.0, slab_y, center_z)
	terrace_body.add_child(terrace_col)
	terrace_root.add_child(terrace_body)
	
	# 2. Southern Retaining Border Curbs along Z = -56.0m (Flanking the 18m Grand Steps opening)
	# West Wing: X = -152.4m to -9.0m (width 143.4m, center X = -80.7m)
	# East Wing: X = +9.0m to +152.4m (width 143.4m, center X = +80.7m)
	var curb_w: float = 143.4
	var curb_mesh: BoxMesh = BoxMesh.new()
	curb_mesh.size = Vector3(curb_w, 1.40, 0.60)
	
	var curb_w_inst: MeshInstance3D = MeshInstance3D.new()
	curb_w_inst.name = "SouthRetainingCurb_West"
	curb_w_inst.mesh = curb_mesh
	curb_w_inst.material_override = sand_mat
	curb_w_inst.position = Vector3(-80.7, 33.80, -56.0)
	terrace_root.add_child(curb_w_inst)
	
	var curb_e_inst: MeshInstance3D = MeshInstance3D.new()
	curb_e_inst.name = "SouthRetainingCurb_East"
	curb_e_inst.mesh = curb_mesh
	curb_e_inst.material_override = sand_mat
	curb_e_inst.position = Vector3(80.7, 33.80, -56.0)
	terrace_root.add_child(curb_e_inst)
	
	# Physical Colliders for Southern Retaining Curbs
	var curb_col_body: StaticBody3D = StaticBody3D.new()
	curb_col_body.name = "SouthCurbsCollision"
	for cx in [-80.7, 80.7]:
		var cs: CollisionShape3D = CollisionShape3D.new()
		var cbox: BoxShape3D = BoxShape3D.new()
		cbox.size = Vector3(curb_w, 1.40, 0.60)
		cs.shape = cbox
		cs.position = Vector3(cx, 33.80, -56.0)
		curb_col_body.add_child(cs)
	terrace_root.add_child(curb_col_body)
	
	# 3. Broad Monumental Red Sandstone Southern Grand Flight of Steps
	# Width: 18.0m (spanning the width of the central walkway approach)
	# Rise: Elevating from garden level (Y = 33.15m) flush onto Chameli Farsh (Y = 34.50m) -> 1.35m rise
	# Steps: 9 low, graceful treads (depth 0.38m, riser 0.15m) spanning Z = -52.58m to Z = -56.0m (run 3.42m)
	var stair_w: float = 18.0
	var num_steps: int = 9
	var step_d: float = 0.38
	var step_h: float = 0.15
	var stair_start_z: float = -52.58
	
	var stairs_node: Node3D = Node3D.new()
	stairs_node.name = "SouthernGrandSteps"
	
	for s in range(num_steps):
		var s_mesh: BoxMesh = BoxMesh.new()
		var s_height: float = step_h * float(s + 1)
		s_mesh.size = Vector3(stair_w, s_height, step_d + 0.02)
		var s_inst: MeshInstance3D = MeshInstance3D.new()
		s_inst.name = "GrandStep_%d" % s
		s_inst.mesh = s_mesh
		s_inst.material_override = sand_mat
		var s_z: float = stair_start_z - (float(s) + 0.5) * step_d
		s_inst.position = Vector3(0.0, 33.15 + s_height * 0.5, s_z)
		stairs_node.add_child(s_inst)
		
	# Dedicated Invisible Inclined StaticBody3D Ramp Collider over Southern Grand Steps
	var grand_ramp_body: StaticBody3D = StaticBody3D.new()
	grand_ramp_body.name = "EntranceRampCollider"
	grand_ramp_body.collision_layer = 1
	grand_ramp_body.collision_mask = 1
	
	var total_stair_run: float = float(num_steps) * step_d # 3.42m
	var total_stair_rise: float = float(num_steps) * step_h # 1.35m
	var stair_hyp: float = sqrt(total_stair_run * total_stair_run + total_stair_rise * total_stair_rise) # ~3.676m
	var ramp_thick: float = 0.30
	
	var r_cs: CollisionShape3D = CollisionShape3D.new()
	var r_box: BoxShape3D = BoxShape3D.new()
	r_box.size = Vector3(stair_w + 0.20, ramp_thick, stair_hyp + 0.15)
	r_cs.shape = r_box
	
	var slope_ang: float = atan2(total_stair_rise, total_stair_run) # ~21.53 deg gentle slope
	var y_offset: float = (ramp_thick * 0.5) / cos(slope_ang)
	var mid_y: float = 33.15 + (total_stair_rise * 0.5) - y_offset + 0.02
	var mid_z: float = (stair_start_z + -56.0) * 0.5
	
	r_cs.position = Vector3(0.0, mid_y, mid_z)
	r_cs.rotation = Vector3(-slope_ang, 0.0, 0.0) # Slopes upward towards North (-Z)
	grand_ramp_body.add_child(r_cs)
	stairs_node.add_child(grand_ramp_body)
	terrace_root.add_child(stairs_node)
	
	# 3. Northern Riverfront 12m Retaining Wall (Z = -195.9m dropping into Yamuna riverbed)
	var river_wall_h: float = 12.0
	var river_wall_mesh: BoxMesh = BoxMesh.new()
	river_wall_mesh.size = Vector3(304.8, river_wall_h, 2.0)
	var river_wall_inst: MeshInstance3D = MeshInstance3D.new()
	river_wall_inst.name = "NorthernRiverfrontRetainingWall"
	river_wall_inst.mesh = river_wall_mesh
	river_wall_inst.material_override = sand_mat
	river_wall_inst.position = Vector3(0.0, deck_y - river_wall_h * 0.5, -195.9)
	terrace_root.add_child(river_wall_inst)
	
	var rw_col_body: StaticBody3D = StaticBody3D.new()
	rw_col_body.name = "RiverWallCollision"
	var rw_cs: CollisionShape3D = CollisionShape3D.new()
	var rw_box: BoxShape3D = BoxShape3D.new()
	rw_box.size = Vector3(304.8, river_wall_h, 2.0)
	rw_cs.shape = rw_box
	rw_cs.position = Vector3(0.0, deck_y - river_wall_h * 0.5, -195.9)
	rw_col_body.add_child(rw_cs)
	terrace_root.add_child(rw_col_body)
	
	# 4. Continuous Pierced Jali Balustrade (height 1.1m along Z = -195.7m)
	var balustrade_h: float = 1.10
	var balustrade_mesh: BoxMesh = BoxMesh.new()
	balustrade_mesh.size = Vector3(304.8, balustrade_h, 0.35)
	var balustrade_inst: MeshInstance3D = MeshInstance3D.new()
	balustrade_inst.name = "RiverfrontJaliBalustrade"
	balustrade_inst.mesh = balustrade_mesh
	balustrade_inst.material_override = sand_mat
	balustrade_inst.position = Vector3(0.0, deck_y + balustrade_h * 0.5, -195.7)
	terrace_root.add_child(balustrade_inst)
	
	# Balustrade decorative pier posts every 6.0m
	var num_piers: int = 51
	for p in range(num_piers):
		var p_x: float = -152.4 + float(p) * (304.8 / float(num_piers - 1))
		var pier_mesh: BoxMesh = BoxMesh.new()
		pier_mesh.size = Vector3(0.50, balustrade_h + 0.15, 0.45)
		var p_inst: MeshInstance3D = MeshInstance3D.new()
		p_inst.mesh = pier_mesh
		p_inst.material_override = sand_mat
		p_inst.position = Vector3(p_x, deck_y + (balustrade_h + 0.15) * 0.5, -195.7)
		terrace_root.add_child(p_inst)
		
	# Balustrade collision
	var b_col_body: StaticBody3D = StaticBody3D.new()
	b_col_body.name = "BalustradeCollision"
	var b_cs: CollisionShape3D = CollisionShape3D.new()
	var b_box: BoxShape3D = BoxShape3D.new()
	b_box.size = Vector3(304.8, balustrade_h, 0.35)
	b_cs.shape = b_box
	b_cs.position = Vector3(0.0, deck_y + balustrade_h * 0.5, -195.7)
	b_col_body.add_child(b_cs)
	terrace_root.add_child(b_col_body)
	
	# 5. Northern Riverfront Corner Burjs (NW and NE corners)
	var marble_mat: StandardMaterial3D = _get_gate_marble_material()
	var finial_mat: StandardMaterial3D = _get_finial_material()
	_build_terrace_burj(terrace_root, "Burj_NorthWest", Vector3(-152.4, deck_y, -195.9), sand_mat, marble_mat, finial_mat)
	_build_terrace_burj(terrace_root, "Burj_NorthEast", Vector3(152.4, deck_y, -195.9), sand_mat, marble_mat, finial_mat)
	
	print("AgraWorld: Riverfront Chameli Farsh terrace foundation (1000ft x 400ft at Y = 34.50m) and retaining wall created.")

func _build_terrace_burj(parent: Node3D, burj_name: String, pos: Vector3, wall_mat: Material, marble_mat: Material, finial_mat: Material) -> void:
	var burj: Node3D = Node3D.new()
	burj.name = burj_name
	
	var base_y: float = pos.y
	var tower_r: float = 4.2
	var shaft_h: float = 8.0
	
	# Substructure shaft dropping to riverbed
	var drop_h: float = 12.0
	var sub_mesh: CylinderMesh = CylinderMesh.new()
	sub_mesh.radial_segments = 8
	sub_mesh.top_radius = tower_r
	sub_mesh.bottom_radius = tower_r + 0.8
	sub_mesh.height = drop_h
	var sub_inst: MeshInstance3D = MeshInstance3D.new()
	sub_inst.mesh = sub_mesh
	sub_inst.material_override = wall_mat
	sub_inst.position = Vector3(pos.x, base_y - drop_h * 0.5, pos.z)
	sub_inst.rotation.y = PI / 8.0
	burj.add_child(sub_inst)
	
	# Terrace level octagonal shaft
	var shaft_mesh: CylinderMesh = CylinderMesh.new()
	shaft_mesh.radial_segments = 8
	shaft_mesh.bottom_radius = tower_r
	shaft_mesh.top_radius = tower_r * 0.95
	shaft_mesh.height = shaft_h
	var shaft_inst: MeshInstance3D = MeshInstance3D.new()
	shaft_inst.mesh = shaft_mesh
	shaft_inst.material_override = wall_mat
	shaft_inst.position = Vector3(pos.x, base_y + shaft_h * 0.5, pos.z)
	shaft_inst.rotation.y = PI / 8.0
	burj.add_child(shaft_inst)
	
	# Balcony chhajja cornice
	var chhajja_y: float = base_y + shaft_h
	var ch_mesh: CylinderMesh = CylinderMesh.new()
	ch_mesh.radial_segments = 8
	ch_mesh.bottom_radius = tower_r * 0.95
	ch_mesh.top_radius = 5.2
	ch_mesh.height = 0.5
	var ch_inst: MeshInstance3D = MeshInstance3D.new()
	ch_inst.mesh = ch_mesh
	ch_inst.material_override = wall_mat
	ch_inst.position = Vector3(pos.x, chhajja_y + 0.25, pos.z)
	ch_inst.rotation.y = PI / 8.0
	burj.add_child(ch_inst)
	
	# Chattri pavilion (8 columns)
	var col_h: float = 3.2
	for i in range(8):
		var ang: float = float(i) * (PI / 4.0) + (PI / 8.0)
		var c_mesh: CylinderMesh = CylinderMesh.new()
		c_mesh.radial_segments = 6
		c_mesh.top_radius = 0.18
		c_mesh.bottom_radius = 0.18
		c_mesh.height = col_h
		var c_inst: MeshInstance3D = MeshInstance3D.new()
		c_inst.mesh = c_mesh
		c_inst.material_override = marble_mat
		c_inst.position = Vector3(pos.x + cos(ang) * 3.4, chhajja_y + 0.5 + col_h * 0.5, pos.z + sin(ang) * 3.4)
		burj.add_child(c_inst)
		
	# Chattri roof & marble dome
	var roof_y: float = chhajja_y + 0.5 + col_h
	var dome_mesh: SphereMesh = SphereMesh.new()
	dome_mesh.radial_segments = 20
	dome_mesh.rings = 14
	dome_mesh.radius = 2.8
	dome_mesh.height = 3.6
	var dome_inst: MeshInstance3D = MeshInstance3D.new()
	dome_inst.mesh = dome_mesh
	dome_inst.material_override = marble_mat
	dome_inst.position = Vector3(pos.x, roof_y + 1.5, pos.z)
	burj.add_child(dome_inst)
	
	# Finial
	var fin_mesh: CylinderMesh = CylinderMesh.new()
	fin_mesh.radial_segments = 6
	fin_mesh.bottom_radius = 0.18
	fin_mesh.top_radius = 0.02
	fin_mesh.height = 2.0
	var fin_inst: MeshInstance3D = MeshInstance3D.new()
	fin_inst.mesh = fin_mesh
	fin_inst.material_override = finial_mat
	fin_inst.position = Vector3(pos.x, roof_y + 3.6 + 0.8, pos.z)
	burj.add_child(fin_inst)
	
	# Static collision
	var b_col: StaticBody3D = StaticBody3D.new()
	var b_shape: CollisionShape3D = CollisionShape3D.new()
	var cyl: CylinderShape3D = CylinderShape3D.new()
	cyl.radius = tower_r
	cyl.height = shaft_h + drop_h
	b_shape.shape = cyl
	b_shape.position = Vector3(pos.x, base_y + (shaft_h - drop_h) * 0.5, pos.z)
	b_col.add_child(b_shape)
	burj.add_child(b_col)
	
	parent.add_child(burj)

# -----------------------------------------------------------------------------
# Twin Flanking Sunken Ablution Basins (Hauz)
# -----------------------------------------------------------------------------
func _setup_ablution_basins() -> void:
	var old_node = get_node_or_null("AblutionBasins")
	if old_node:
		old_node.queue_free()
		
	var basins_root: Node3D = Node3D.new()
	basins_root.name = "AblutionBasins"
	add_child(basins_root)
	
	var marble_mat: StandardMaterial3D = _get_gate_marble_material()
	marble_mat.roughness = 0.15
	var water_mat: StandardMaterial3D = _get_water_material()
	var floor_mat: StandardMaterial3D = _get_sandstone_material(Vector3(0.35, 0.35, 0.35), true)
	
	# In the 50m open courtyards between each building and the Taj plinth (aligned to Taj plinth center Z = -131.457m)
	# West Hauz: centered at X = -75.0m, Z = -131.457m
	_build_single_hauz(basins_root, "Hauz_West", Vector3(-75.0, 34.50, -131.457), marble_mat, water_mat, floor_mat)
	
	# East Hauz: centered at X = +75.0m, Z = -131.457m
	_build_single_hauz(basins_root, "Hauz_East", Vector3(75.0, 34.50, -131.457), marble_mat, water_mat, floor_mat)
	
	print("AgraWorld: Twin flanking sunken marble ablution pools (Hauz: 12m x 12m) initialized in 50m courtyards.")

func _build_single_hauz(parent: Node3D, hauz_name: String, center_pos: Vector3, marble_mat: Material, water_mat: Material, floor_mat: Material) -> void:
	var hauz_node: Node3D = Node3D.new()
	hauz_node.name = hauz_name
	
	var size: float = 12.0 # 12.0m x 12.0m survey dimension
	var recess_d: float = 0.45 # Recessed 0.45m into Chameli Farsh
	var curb_w: float = 0.40 # Framed by polished white marble curbs (width 0.4m)
	var curb_lip: float = 0.12 # 0.12m above terrace floor
	var base_y: float = center_pos.y # 34.50m
	var floor_y: float = base_y - recess_d # 34.05m
	var water_y: float = base_y - 0.12 # 34.38m (active screen-space reflecting water)
	
	# 1. Sunken Basin Floor (12m x 12m)
	var floor_mesh: PlaneMesh = PlaneMesh.new()
	floor_mesh.size = Vector2(size, size)
	var floor_inst: MeshInstance3D = MeshInstance3D.new()
	floor_inst.name = "BasinFloor"
	floor_inst.mesh = floor_mesh
	floor_inst.material_override = floor_mat
	floor_inst.position = Vector3(center_pos.x, floor_y, center_pos.z)
	hauz_node.add_child(floor_inst)
	
	# 2. Reflecting Pool Water Surface (11.2m x 11.2m)
	var water_mesh: PlaneMesh = PlaneMesh.new()
	water_mesh.size = Vector2(size - curb_w * 2.0, size - curb_w * 2.0)
	var water_inst: MeshInstance3D = MeshInstance3D.new()
	water_inst.name = "WaterSurface"
	water_inst.mesh = water_mesh
	water_inst.material_override = water_mat
	water_inst.position = Vector3(center_pos.x, water_y, center_pos.z)
	hauz_node.add_child(water_inst)
	
	# 3. Raised Polished White Marble Coping Curbs (width 0.4m)
	var curb_total_h: float = recess_d + curb_lip # 0.57m
	var curb_mesh_ns: BoxMesh = BoxMesh.new()
	curb_mesh_ns.size = Vector3(size, curb_total_h, curb_w)
	
	var curb_mesh_ew: BoxMesh = BoxMesh.new()
	curb_mesh_ew.size = Vector3(curb_w, curb_total_h, size - curb_w * 2.0)
	
	var curb_center_y: float = floor_y + curb_total_h * 0.5
	
	# North Curb
	var cn: MeshInstance3D = MeshInstance3D.new()
	cn.name = "Curb_North"
	cn.mesh = curb_mesh_ns
	cn.material_override = marble_mat
	cn.position = Vector3(center_pos.x, curb_center_y, center_pos.z - size * 0.5 + curb_w * 0.5)
	hauz_node.add_child(cn)
	
	# South Curb
	var cs: MeshInstance3D = MeshInstance3D.new()
	cs.name = "Curb_South"
	cs.mesh = curb_mesh_ns
	cs.material_override = marble_mat
	cs.position = Vector3(center_pos.x, curb_center_y, center_pos.z + size * 0.5 - curb_w * 0.5)
	hauz_node.add_child(cs)
	
	# West Curb
	var cw: MeshInstance3D = MeshInstance3D.new()
	cw.name = "Curb_West"
	cw.mesh = curb_mesh_ew
	cw.material_override = marble_mat
	cw.position = Vector3(center_pos.x - size * 0.5 + curb_w * 0.5, curb_center_y, center_pos.z)
	hauz_node.add_child(cw)
	
	# East Curb
	var ce: MeshInstance3D = MeshInstance3D.new()
	ce.name = "Curb_East"
	ce.mesh = curb_mesh_ew
	ce.material_override = marble_mat
	ce.position = Vector3(center_pos.x + size * 0.5 - curb_w * 0.5, curb_center_y, center_pos.z)
	hauz_node.add_child(ce)
	
	# Physical Colliders for Curbs
	var col_body: StaticBody3D = StaticBody3D.new()
	col_body.name = "HauzCollision"
	
	# Floor collider
	var f_cs: CollisionShape3D = CollisionShape3D.new()
	var f_box: BoxShape3D = BoxShape3D.new()
	f_box.size = Vector3(size, 0.40, size)
	f_cs.shape = f_box
	f_cs.position = Vector3(center_pos.x, floor_y - 0.20, center_pos.z)
	col_body.add_child(f_cs)
	
	# Curb colliders
	for c_trans in [
		Vector3(center_pos.x, curb_center_y, center_pos.z - size * 0.5 + curb_w * 0.5),
		Vector3(center_pos.x, curb_center_y, center_pos.z + size * 0.5 - curb_w * 0.5)
	]:
		var cs_shape: CollisionShape3D = CollisionShape3D.new()
		var box_s: BoxShape3D = BoxShape3D.new()
		box_s.size = Vector3(size, curb_total_h, curb_w)
		cs_shape.shape = box_s
		cs_shape.position = c_trans
		col_body.add_child(cs_shape)
		
	for c_trans in [
		Vector3(center_pos.x - size * 0.5 + curb_w * 0.5, curb_center_y, center_pos.z),
		Vector3(center_pos.x + size * 0.5 - curb_w * 0.5, curb_center_y, center_pos.z)
	]:
		var cs_shape: CollisionShape3D = CollisionShape3D.new()
		var box_s: BoxShape3D = BoxShape3D.new()
		box_s.size = Vector3(curb_w, curb_total_h, size - curb_w * 2.0)
		cs_shape.shape = box_s
		cs_shape.position = c_trans
		col_body.add_child(cs_shape)
		
	hauz_node.add_child(col_body)
	parent.add_child(hauz_node)

# -----------------------------------------------------------------------------
# High-Detail Procedural Twin Flanking Monuments (Mosque West & Mehman Khana East)
# -----------------------------------------------------------------------------
func _setup_twin_flanking_monuments() -> void:
	var old_node = get_node_or_null("TwinFlankingMonuments")
	if old_node:
		old_node.queue_free()
		
	var mon_root: Node3D = Node3D.new()
	mon_root.name = "TwinFlankingMonuments"
	add_child(mon_root)
	
	# Master PBR Materials
	var wall_mat: StandardMaterial3D = _get_mosque_sandstone_material(Vector3(0.35, 0.35, 0.35))
	var dome_mat: StandardMaterial3D = _get_dome_marble_material()
	var marble_trim: StandardMaterial3D = _get_gate_marble_material(Vector3(1.5, 1.5, 1.0))
	var dark_mat: StandardMaterial3D = _get_dark_niche_material()
	var finial_mat: StandardMaterial3D = _get_finial_material()
	
	# 1. The Mosque (West Structure): Centered at X = -122.0m, Z aligned to Taj plinth center (-131.457m), rotated Y = +90 deg (facing East toward Taj Mahal)
	_build_flanking_monument(mon_root, "Mosque_West", Vector3(-122.0, 34.50, -131.457), PI * 0.5, wall_mat, dome_mat, marble_trim, dark_mat, finial_mat)
	
	# 2. Mehman Khana / Jawab (East Structure): Centered at X = +122.0m, Z aligned to Taj plinth center (-131.457m), rotated Y = -90 deg (facing West toward Taj Mahal)
	_build_flanking_monument(mon_root, "MehmanKhana_East", Vector3(122.0, 34.50, -131.457), -PI * 0.5, wall_mat, dome_mat, marble_trim, dark_mat, finial_mat)
	
	print("AgraWorld: High-Detail Procedural Twin Monuments (Mosque West at X=-122m & Mehman Khana East at X=+122m) created.")

func _build_flanking_monument(parent: Node3D, mon_name: String, pos: Vector3, rot_y: float, wall_mat: Material, dome_mat: Material, marble_mat: Material, dark_mat: Material, finial_mat: Material) -> void:
	var mon_node: Node3D = Node3D.new()
	mon_node.name = mon_name
	mon_node.position = pos
	mon_node.rotation.y = rot_y
	
	# In local space:
	# Local X: facade width (total 76m: central hall 44m, wings 16m each)
	# Local Y: height (base at 0, roof at 18m, pishtaq at 22m, center dome at 30m)
	# Local Z: depth (front facade facing +Z, rear facing -Z)
	
	# -------------------------------------------------------------------------
	# 1. CSGCombiner3D for Massing & Subtracted Vaulted Iwan
	# -------------------------------------------------------------------------
	var csg: CSGCombiner3D = CSGCombiner3D.new()
	csg.name = "CSGAssembly"
	csg.use_collision = true
	
	# Central Prayer Hall Block: 44m wide, 22m deep, 18m high
	var c_box: CSGBox3D = CSGBox3D.new()
	c_box.name = "CentralHall"
	c_box.size = Vector3(44.0, 18.0, 22.0)
	c_box.position = Vector3(0.0, 9.0, 0.0)
	c_box.material_override = wall_mat
	csg.add_child(c_box)
	
	# Central Pishtaq Portal (projects forward by 2.0m, rises to 22.0m height)
	# Width 18.0m, height 22.0m, depth 4.0m (from Z = 9.0 to 13.0m)
	var p_box: CSGBox3D = CSGBox3D.new()
	p_box.name = "PishtaqPortal"
	p_box.size = Vector3(18.0, 22.0, 4.0)
	p_box.position = Vector3(0.0, 11.0, 11.0)
	p_box.material_override = wall_mat
	csg.add_child(p_box)
	
	# Subtractive Vaulted Central Iwan Recess (depth 2.5m, width 12m, height 16m)
	var iwan: CSGBox3D = CSGBox3D.new()
	iwan.name = "IwanRecess"
	iwan.operation = CSGShape3D.OPERATION_SUBTRACTION
	iwan.size = Vector3(12.0, 16.0, 2.6)
	iwan.position = Vector3(0.0, 8.0, 11.7)
	csg.add_child(iwan)
	
	# Subtractive Pointed Arch Chamfers inside Iwan apex
	var chamfer_l: CSGBox3D = CSGBox3D.new()
	chamfer_l.operation = CSGShape3D.OPERATION_SUBTRACTION
	chamfer_l.size = Vector3(3.5, 3.5, 2.7)
	chamfer_l.position = Vector3(-4.8, 14.5, 11.7)
	chamfer_l.rotation.z = PI / 4.0
	csg.add_child(chamfer_l)
	
	var chamfer_r: CSGBox3D = CSGBox3D.new()
	chamfer_r.operation = CSGShape3D.OPERATION_SUBTRACTION
	chamfer_r.size = Vector3(3.5, 3.5, 2.7)
	chamfer_r.position = Vector3(4.8, 14.5, 11.7)
	chamfer_r.rotation.z = -PI / 4.0
	csg.add_child(chamfer_r)
	
	# Left Side Wing: 16m wide, 18m deep, 14m high (front face at Z = 7.0m)
	var w_left: CSGBox3D = CSGBox3D.new()
	w_left.name = "WingLeft"
	w_left.size = Vector3(16.0, 14.0, 18.0)
	w_left.position = Vector3(-30.0, 7.0, -2.0)
	w_left.material_override = wall_mat
	csg.add_child(w_left)
	
	# Right Side Wing: 16m wide, 18m deep, 14m high
	var w_right: CSGBox3D = CSGBox3D.new()
	w_right.name = "WingRight"
	w_right.size = Vector3(16.0, 14.0, 18.0)
	w_right.position = Vector3(30.0, 7.0, -2.0)
	w_right.material_override = wall_mat
	csg.add_child(w_right)
	
	# Subtractive Cusped Pointed-Arch Niches on Side Wings (two stacked tiers, depth 0.6m)
	for side_x in [-30.0, 30.0]:
		# Lower tier niche (width 5m, height 6m, depth 0.6m)
		var n_low: CSGBox3D = CSGBox3D.new()
		n_low.operation = CSGShape3D.OPERATION_SUBTRACTION
		n_low.size = Vector3(5.0, 6.0, 0.65)
		n_low.position = Vector3(side_x, 4.0, 6.7)
		csg.add_child(n_low)
		
		# Upper tier niche (width 4.5m, height 4.5m, depth 0.6m)
		var n_up: CSGBox3D = CSGBox3D.new()
		n_up.operation = CSGShape3D.OPERATION_SUBTRACTION
		n_up.size = Vector3(4.5, 4.5, 0.65)
		n_up.position = Vector3(side_x, 10.5, 6.7)
		csg.add_child(n_up)
		
	mon_node.add_child(csg)
	
	# -------------------------------------------------------------------------
	# 2. Continuous 0.8m Wide White Marble Rectangular Inlay Borders (Khatt Bands)
	# -------------------------------------------------------------------------
	var band_thick: float = 0.80
	# Left vertical border band
	var b_vl: BoxMesh = BoxMesh.new()
	b_vl.size = Vector3(band_thick, 17.5, 0.20)
	var b_vl_inst: MeshInstance3D = MeshInstance3D.new()
	b_vl_inst.name = "PishtaqBand_L"
	b_vl_inst.mesh = b_vl
	b_vl_inst.material_override = marble_mat
	b_vl_inst.position = Vector3(-6.4, 8.75, 13.05)
	mon_node.add_child(b_vl_inst)
	
	# Right vertical border band
	var b_vr: BoxMesh = BoxMesh.new()
	b_vr.size = Vector3(band_thick, 17.5, 0.20)
	var b_vr_inst: MeshInstance3D = MeshInstance3D.new()
	b_vr_inst.name = "PishtaqBand_R"
	b_vr_inst.mesh = b_vr
	b_vr_inst.material_override = marble_mat
	b_vr_inst.position = Vector3(6.4, 8.75, 13.05)
	mon_node.add_child(b_vr_inst)
	
	# Top horizontal border band
	var b_top: BoxMesh = BoxMesh.new()
	b_top.size = Vector3(13.6, band_thick, 0.20)
	var b_top_inst: MeshInstance3D = MeshInstance3D.new()
	b_top_inst.name = "PishtaqBand_Top"
	b_top_inst.mesh = b_top
	b_top_inst.material_override = marble_mat
	b_top_inst.position = Vector3(0.0, 17.15, 13.05)
	mon_node.add_child(b_top_inst)
	
	# Outer Pishtaq Crest Frame
	var b_crest: BoxMesh = BoxMesh.new()
	b_crest.size = Vector3(18.2, 0.80, 0.25)
	var b_cr_inst: MeshInstance3D = MeshInstance3D.new()
	b_cr_inst.name = "PishtaqCrest"
	b_cr_inst.mesh = b_crest
	b_cr_inst.material_override = marble_mat
	b_cr_inst.position = Vector3(0.0, 21.60, 13.05)
	mon_node.add_child(b_cr_inst)
	
	# Spandrel Rosettes (flanking pointed arch apex)
	for sp_x in [-4.2, 4.2]:
		var sp_mesh: BoxMesh = BoxMesh.new()
		sp_mesh.size = Vector3(1.8, 1.8, 0.18)
		var sp_inst: MeshInstance3D = MeshInstance3D.new()
		sp_inst.mesh = sp_mesh
		sp_inst.material_override = marble_mat
		sp_inst.position = Vector3(sp_x, 15.5, 13.05)
		sp_inst.rotation.z = PI / 4.0
		mon_node.add_child(sp_inst)
		
	# Shadowed Back Wall in Iwan
	var iwan_back: BoxMesh = BoxMesh.new()
	iwan_back.size = Vector3(11.8, 15.8, 0.2)
	var ib_inst: MeshInstance3D = MeshInstance3D.new()
	ib_inst.name = "IwanBack"
	ib_inst.mesh = iwan_back
	ib_inst.material_override = dark_mat
	ib_inst.position = Vector3(0.0, 8.0, 10.45)
	mon_node.add_child(ib_inst)
	
	# Wing Niche Marble Trims
	for side_x in [-30.0, 30.0]:
		# Lower frame
		var nf_l: BoxMesh = BoxMesh.new()
		nf_l.size = Vector3(5.4, 6.4, 0.15)
		var nf_l_inst: MeshInstance3D = MeshInstance3D.new()
		nf_l_inst.mesh = nf_l
		nf_l_inst.material_override = marble_mat
		nf_l_inst.position = Vector3(side_x, 4.0, 7.05)
		mon_node.add_child(nf_l_inst)
		
		# Upper frame
		var nf_u: BoxMesh = BoxMesh.new()
		nf_u.size = Vector3(4.9, 4.9, 0.15)
		var nf_u_inst: MeshInstance3D = MeshInstance3D.new()
		nf_u_inst.mesh = nf_u
		nf_u_inst.material_override = marble_mat
		nf_u_inst.position = Vector3(side_x, 10.5, 7.05)
		mon_node.add_child(nf_u_inst)
		
	# -------------------------------------------------------------------------
	# 3. Roof Cornice: Continuous Projecting Sandstone Eaves (Chajja Overhang of 0.6m)
	# -------------------------------------------------------------------------
	# Wing Chajja Eaves at Y = 14.0m, projecting 0.6m forward to Z = 7.3m
	for side_x in [-30.0, 30.0]:
		var ch_w_mesh: BoxMesh = BoxMesh.new()
		ch_w_mesh.size = Vector3(16.8, 0.25, 0.60)
		var ch_w_inst: MeshInstance3D = MeshInstance3D.new()
		ch_w_inst.name = "WingChajja_%d" % int(side_x)
		ch_w_inst.mesh = ch_w_mesh
		ch_w_inst.material_override = wall_mat
		ch_w_inst.position = Vector3(side_x, 13.9, 7.3)
		mon_node.add_child(ch_w_inst)
		
	# Central Hall Chajja Eaves at Y = 18.0m flanking the Pishtaq
	for side_x in [-15.5, 15.5]:
		var ch_c_mesh: BoxMesh = BoxMesh.new()
		ch_c_mesh.size = Vector3(13.0, 0.25, 0.60)
		var ch_c_inst: MeshInstance3D = MeshInstance3D.new()
		ch_c_inst.name = "CentralHallChajja_%d" % int(side_x)
		ch_c_inst.mesh = ch_c_mesh
		ch_c_inst.material_override = wall_mat
		ch_c_inst.position = Vector3(side_x, 17.9, 11.3)
		mon_node.add_child(ch_c_inst)
		
	# -------------------------------------------------------------------------
	# 4. Triple Bulbous White Makrana Marble Onion Domes with Turned Brass Finials
	# -------------------------------------------------------------------------
	var roof_y: float = 18.0
	
	# Center Dome: drum height 3.0m (radius 5.2m), bulbous dome max radius 6.2m, height 9.0m
	var c_drum_mesh: CylinderMesh = CylinderMesh.new()
	c_drum_mesh.radial_segments = 24
	c_drum_mesh.top_radius = 5.2
	c_drum_mesh.bottom_radius = 5.2
	c_drum_mesh.height = 3.0
	var c_drum: MeshInstance3D = MeshInstance3D.new()
	c_drum.name = "CenterDrum"
	c_drum.mesh = c_drum_mesh
	c_drum.material_override = dome_mat
	c_drum.position = Vector3(0.0, roof_y + 1.5, 0.0)
	mon_node.add_child(c_drum)
	
	var c_dome_mesh: SphereMesh = SphereMesh.new()
	c_dome_mesh.radial_segments = 24
	c_dome_mesh.rings = 16
	c_dome_mesh.radius = 6.2
	c_dome_mesh.height = 8.5
	var c_dome: MeshInstance3D = MeshInstance3D.new()
	c_dome.name = "CenterDome"
	c_dome.mesh = c_dome_mesh
	c_dome.material_override = dome_mat
	c_dome.position = Vector3(0.0, roof_y + 3.0 + 3.5, 0.0)
	c_dome.scale = Vector3(1.0, 1.25, 1.0)
	mon_node.add_child(c_dome)
	
	var c_apex_mesh: CylinderMesh = CylinderMesh.new()
	c_apex_mesh.radial_segments = 12
	c_apex_mesh.bottom_radius = 1.6
	c_apex_mesh.top_radius = 0.05
	c_apex_mesh.height = 2.4
	var c_apex: MeshInstance3D = MeshInstance3D.new()
	c_apex.mesh = c_apex_mesh
	c_apex.material_override = dome_mat
	c_apex.position = Vector3(0.0, roof_y + 3.0 + 7.5, 0.0)
	mon_node.add_child(c_apex)
	
	# Slender turned brass/gold finial atop center dome spike
	var c_finial_mesh: CylinderMesh = CylinderMesh.new()
	c_finial_mesh.radial_segments = 8
	c_finial_mesh.bottom_radius = 0.18
	c_finial_mesh.top_radius = 0.02
	c_finial_mesh.height = 3.5
	var c_fin: MeshInstance3D = MeshInstance3D.new()
	c_fin.mesh = c_finial_mesh
	c_fin.material_override = finial_mat
	c_fin.position = Vector3(0.0, roof_y + 3.0 + 8.7 + 1.5, 0.0)
	mon_node.add_child(c_fin)
	
	# Flanking Domes (Left: X = -13.0m, Right: X = +13.0m)
	for d_x in [-13.0, 13.0]:
		var f_drum_mesh: CylinderMesh = CylinderMesh.new()
		f_drum_mesh.radial_segments = 20
		f_drum_mesh.top_radius = 4.0
		f_drum_mesh.bottom_radius = 4.0
		f_drum_mesh.height = 2.5
		var f_drum: MeshInstance3D = MeshInstance3D.new()
		f_drum.name = "FlankDrum_%d" % int(d_x)
		f_drum.mesh = f_drum_mesh
		f_drum.material_override = dome_mat
		f_drum.position = Vector3(d_x, roof_y + 1.25, 0.0)
		mon_node.add_child(f_drum)
		
		var f_dome_mesh: SphereMesh = SphereMesh.new()
		f_dome_mesh.radial_segments = 20
		f_dome_mesh.rings = 14
		f_dome_mesh.radius = 4.8
		f_dome_mesh.height = 6.8
		var f_dome: MeshInstance3D = MeshInstance3D.new()
		f_dome.name = "FlankDome_%d" % int(d_x)
		f_dome.mesh = f_dome_mesh
		f_dome.material_override = dome_mat
		f_dome.position = Vector3(d_x, roof_y + 2.5 + 2.8, 0.0)
		f_dome.scale = Vector3(1.0, 1.22, 1.0)
		mon_node.add_child(f_dome)
		
		var f_apex_mesh: CylinderMesh = CylinderMesh.new()
		f_apex_mesh.radial_segments = 8
		f_apex_mesh.bottom_radius = 1.2
		f_apex_mesh.top_radius = 0.04
		f_apex_mesh.height = 2.0
		var f_apex: MeshInstance3D = MeshInstance3D.new()
		f_apex.mesh = f_apex_mesh
		f_apex.material_override = dome_mat
		f_apex.position = Vector3(d_x, roof_y + 2.5 + 6.0, 0.0)
		mon_node.add_child(f_apex)
		
		# Slender turned brass/gold finials atop flanking dome spikes
		var f_fin_mesh: CylinderMesh = CylinderMesh.new()
		f_fin_mesh.radial_segments = 6
		f_fin_mesh.bottom_radius = 0.14
		f_fin_mesh.top_radius = 0.02
		f_fin_mesh.height = 2.5
		var f_fin: MeshInstance3D = MeshInstance3D.new()
		f_fin.mesh = f_fin_mesh
		f_fin.material_override = finial_mat
		f_fin.position = Vector3(d_x, roof_y + 2.5 + 7.0 + 1.1, 0.0)
		mon_node.add_child(f_fin)
		
	# -------------------------------------------------------------------------
	# 5. Corner Minarets: 4-Tiered Octagonal Turrets & Chattris at All Outer Corners
	# -------------------------------------------------------------------------
	# 4 Turrets: 2 Front Outer Corners (Z = 7.0m) and 2 Rear Outer Corners (Z = -11.0m)
	var turret_corners: Array[Vector2] = [
		Vector2(-38.0, 7.0),   # Front-Left
		Vector2(38.0, 7.0),    # Front-Right
		Vector2(-38.0, -11.0), # Rear-Left
		Vector2(38.0, -11.0)   # Rear-Right
	]
	
	for tc in turret_corners:
		var t_x: float = tc.x
		var tur_z: float = tc.y
		var tur_node: Node3D = Node3D.new()
		tur_node.name = "CornerTurret_%d_%d" % [int(t_x), int(tur_z)]
		
		var tur_r: float = 1.6
		var tur_h: float = 24.0
		
		# 4-stage octagonal shaft
		var tur_shaft: CylinderMesh = CylinderMesh.new()
		tur_shaft.radial_segments = 8
		tur_shaft.bottom_radius = tur_r
		tur_shaft.top_radius = tur_r * 0.94
		tur_shaft.height = tur_h
		var tur_inst: MeshInstance3D = MeshInstance3D.new()
		tur_inst.mesh = tur_shaft
		tur_inst.material_override = wall_mat
		tur_inst.position = Vector3(t_x, tur_h * 0.5, tur_z)
		tur_inst.rotation.y = PI / 8.0
		tur_node.add_child(tur_inst)
		
		# Story molding rings (4 tiers: 6m, 12m, 18m)
		for ring_y in [6.0, 12.0, 18.0]:
			var tr_mesh: CylinderMesh = CylinderMesh.new()
			tr_mesh.radial_segments = 8
			tr_mesh.top_radius = tur_r + 0.25
			tr_mesh.bottom_radius = tur_r + 0.25
			tr_mesh.height = 0.35
			var tr_inst: MeshInstance3D = MeshInstance3D.new()
			tr_inst.mesh = tr_mesh
			tr_inst.material_override = wall_mat
			tr_inst.position = Vector3(t_x, ring_y, tur_z)
			tr_inst.rotation.y = PI / 8.0
			tur_node.add_child(tr_inst)
			
		# Overhanging balcony chhajja
		var tch_mesh: CylinderMesh = CylinderMesh.new()
		tch_mesh.radial_segments = 8
		tch_mesh.bottom_radius = tur_r * 0.94
		tch_mesh.top_radius = 2.3
		tch_mesh.height = 0.50
		var tch_inst: MeshInstance3D = MeshInstance3D.new()
		tch_inst.mesh = tch_mesh
		tch_inst.material_override = wall_mat
		tch_inst.position = Vector3(t_x, tur_h + 0.25, tur_z)
		tch_inst.rotation.y = PI / 8.0
		tur_node.add_child(tch_inst)
		
		# 8-pillared open chattri pavilion
		var tc_h: float = 2.6
		for i in range(8):
			var ang: float = float(i) * (PI / 4.0) + (PI / 8.0)
			var tc_col: CylinderMesh = CylinderMesh.new()
			tc_col.radial_segments = 6
			tc_col.top_radius = 0.12
			tc_col.bottom_radius = 0.12
			tc_col.height = tc_h
			var tc_inst: MeshInstance3D = MeshInstance3D.new()
			tc_inst.mesh = tc_col
			tc_inst.material_override = marble_mat
			tc_inst.position = Vector3(t_x + cos(ang) * 1.5, tur_h + 0.5 + tc_h * 0.5, tur_z + sin(ang) * 1.5)
			tur_node.add_child(tc_inst)
			
		# Chattri marble dome
		var td_mesh: SphereMesh = SphereMesh.new()
		td_mesh.radial_segments = 16
		td_mesh.rings = 10
		td_mesh.radius = 1.8
		td_mesh.height = 2.4
		var td_inst: MeshInstance3D = MeshInstance3D.new()
		td_inst.mesh = td_mesh
		td_inst.material_override = marble_mat
		td_inst.position = Vector3(t_x, tur_h + 0.5 + tc_h + 1.0, tur_z)
		tur_node.add_child(td_inst)
		
		# Slender turned brass finial atop chattri dome
		var tfin_mesh: CylinderMesh = CylinderMesh.new()
		tfin_mesh.radial_segments = 6
		tfin_mesh.bottom_radius = 0.10
		tfin_mesh.top_radius = 0.01
		tfin_mesh.height = 1.8
		var tfin_inst: MeshInstance3D = MeshInstance3D.new()
		tfin_inst.mesh = tfin_mesh
		tfin_inst.material_override = finial_mat
		tfin_inst.position = Vector3(t_x, tur_h + 0.5 + tc_h + 2.4 + 0.7, tur_z)
		tur_node.add_child(tfin_inst)
		
		# Turret physical collider
		var t_col_body: StaticBody3D = StaticBody3D.new()
		var t_cs: CollisionShape3D = CollisionShape3D.new()
		var t_cyl: CylinderShape3D = CylinderShape3D.new()
		t_cyl.radius = tur_r + 0.1
		t_cyl.height = tur_h
		t_cs.shape = t_cyl
		t_cs.position = Vector3(t_x, tur_h * 0.5, tur_z)
		t_col_body.add_child(t_cs)
		tur_node.add_child(t_col_body)
		
		mon_node.add_child(tur_node)
		
	# -------------------------------------------------------------------------
	# 6. Rear Connecting Enclosure Wall (Sealing to Terrace Outer Perimeter at X = +/- 152.4m)
	# -------------------------------------------------------------------------
	# Extends from local Z = -11.0m back to Z = -30.4m (19.4m depth) to seal outer terrace perimeter
	var rear_wall_mesh: BoxMesh = BoxMesh.new()
	rear_wall_mesh.size = Vector3(76.0, 7.5, 19.4)
	var rear_wall_inst: MeshInstance3D = MeshInstance3D.new()
	rear_wall_inst.name = "RearEnclosureWall"
	rear_wall_inst.mesh = rear_wall_mesh
	rear_wall_inst.material_override = wall_mat
	rear_wall_inst.position = Vector3(0.0, 3.75, -20.7)
	mon_node.add_child(rear_wall_inst)
	
	var rw_col: StaticBody3D = StaticBody3D.new()
	rw_col.name = "RearWallCollision"
	var rw_shape: CollisionShape3D = CollisionShape3D.new()
	var rw_box: BoxShape3D = BoxShape3D.new()
	rw_box.size = Vector3(76.0, 7.5, 19.4)
	rw_shape.shape = rw_box
	rw_shape.position = Vector3(0.0, 3.75, -20.7)
	rw_col.add_child(rw_shape)
	mon_node.add_child(rw_col)
	
	parent.add_child(mon_node)


