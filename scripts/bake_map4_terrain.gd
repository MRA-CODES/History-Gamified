# -----------------------------------------------------------------------------
# bake_map4_terrain.gd
# -----------------------------------------------------------------------------
extends SceneTree

func _init() -> void:
	print(">>> STARTING MAP 4 TERRAIN BAKER <<<")
	var assets: Terrain3DAssets = load("res://assets/terrain/MAp 4- TAJ MAHAL_Terrain/taj_mahal_terrain_assets.tres")
	var h_img: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/terrain/MAp 4- TAJ MAHAL_Terrain/agra_heightmap.png.png"))
	var w = h_img.get_width()
	var h = h_img.get_height()
	
	var bin_file = FileAccess.open(ProjectSettings.globalize_path("res://assets/terrain/MAp 4- TAJ MAHAL_Terrain/agra_controlmap.bin"), FileAccess.READ)
	var ctrl_buffer = bin_file.get_buffer(w * h * 4)
	bin_file.close()
	var ctrl_img = Image.create_from_data(w, h, false, Image.FORMAT_RF, ctrl_buffer)
	
	var terrain = Terrain3D.new()
	terrain.data_directory = "res://data/terrain/map4"
	terrain.assets = assets
	terrain.collision_enabled = true
	
	var mat = Terrain3DMaterial.new()
	mat.show_checkered = false
	mat.world_background = Terrain3DMaterial.NONE
	mat.auto_shader = false
	mat.blend_sharpness = 0.85
	terrain.material = mat
	
	root.add_child(terrain)
	
	var data: Terrain3DData = terrain.data
	var import_pos = Vector3(-float(w) * 0.5, 0.0, -float(h) * 0.5)
	data.import_images([h_img, ctrl_img, null], import_pos, -10.0, 45.0)
	data.update_maps(Terrain3DRegion.TYPE_MAX, true, false)
	
	print(">>> SAVING DIRECTORY <<<")
	data.save_directory("res://data/terrain/map4")
	print(">>> TERRAIN BAKING DONE <<<")
	quit(0)
