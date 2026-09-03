# -----------------------------------------------------------------------------
# bake_terrain_scene.gd
# -----------------------------------------------------------------------------
extends Node3D

func _ready() -> void:
	print("==================================================")
	print("BAKER SCENE STARTED - EXECUTING TERRAIN GENERATION")
	print("==================================================")
	
	# Load assets
	var assets_path = "res://assets/terrain/MAp 4- TAJ MAHAL_Terrain/taj_mahal_terrain_assets.tres"
	var assets: Terrain3DAssets = load(assets_path)
	print("Loaded assets: ", assets != null)
	
	# Load heightmap
	var heightmap_path = "res://assets/terrain/MAp 4- TAJ MAHAL_Terrain/agra_heightmap.png.png"
	var global_h = ProjectSettings.globalize_path(heightmap_path)
	var height_img = Image.load_from_file(global_h)
	print("Loaded height image: ", height_img != null, " (", height_img.get_width(), "x", height_img.get_height(), ")")
	
	var w = height_img.get_width()
	var h = height_img.get_height()
	
	# Load control map
	var bin_path = ProjectSettings.globalize_path("res://assets/terrain/MAp 4- TAJ MAHAL_Terrain/agra_controlmap.bin")
	var file = FileAccess.open(bin_path, FileAccess.READ)
	var ctrl_buffer = file.get_buffer(w * h * 4)
	file.close()
	var control_img = Image.create_from_data(w, h, false, Image.FORMAT_RF, ctrl_buffer)
	print("Loaded control image: ", control_img != null)
	
	# Create Terrain3D node
	var terrain = Terrain3D.new()
	terrain.name = "Terrain3D"
	terrain.data_directory = "res://data/terrain/map4"
	terrain.assets = assets
	terrain.collision_enabled = true
	terrain.collision_mask = 3
	
	var mat = Terrain3DMaterial.new()
	mat.show_checkered = false
	mat.world_background = Terrain3DMaterial.NONE
	mat.auto_shader = false
	mat.blend_sharpness = 0.85
	terrain.material = mat
	
	add_child(terrain)
	
	var data: Terrain3DData = terrain.data
	print("Terrain3DData pointer: ", data != null)
	
	# Import images into Terrain3DData
	var import_pos = Vector3(-float(w) * 0.5, 0.0, -float(h) * 0.5)
	print("Calling data.import_images with import_pos=", import_pos, " offset=-10.0 scale=45.0")
	data.import_images([height_img, control_img, null], import_pos, -10.0, 45.0)
	
	# Force map compilation
	data.update_maps(Terrain3DRegion.TYPE_MAX, true, false)
	
	# Save directory
	print("Calling data.save_directory('res://data/terrain/map4')...")
	data.save_directory("res://data/terrain/map4")
	
	print("Active regions count: ", data.get_regions_active().size())
	for reg in data.get_regions_active():
		print("  Region: ", reg.get_location())
		
	var ground_y = data.get_height(Vector3(0, 0, 0))
	print("Central plinth ground height: ", ground_y)
	
	print("==================================================")
	print("BAKING COMPLETED SUCCESSFULLY!")
	print("==================================================")
	
	# Wait 1 sec and quit
	await get_tree().create_timer(1.0).timeout
	get_tree().quit(0)
