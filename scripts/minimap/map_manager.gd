# -----------------------------------------------------------------------------
# map_manager.gd
# Central manager handling floor detection, player tracking, POI discovery, and coordinate projection.
# -----------------------------------------------------------------------------
class_name MapManager
extends Node

const MapFloorData = preload("res://scripts/minimap/map_floor_data.gd")
const NHMMapConfig = preload("res://scripts/minimap/nhm_map_config.gd")

signal floor_changed(new_floor: MapFloorData)
signal full_map_toggled(is_open: bool)
signal exhibit_focused(exhibit_id: String)

var floors: Array = []
var active_floor_index: int = 1 # Default to Ground Floor
var player_node: Node3D = null
var is_inside: bool = false
var is_full_map_open: bool = false

# Cached list of discovered exhibit markers: Array of Dictionary { "id": String, "node": Node3D, "pos": Vector3, "floor_id": String, "data": Dictionary }
var discovered_exhibits: Array[Dictionary] = []

func _ready() -> void:
	# Load default Natural History Museum floor set
	floors = NHMMapConfig.create_nhm_floors()
	call_deferred("_discover_scene_elements")

func _process(_delta: float) -> void:
	if not player_node:
		_find_player()
		
	if player_node:
		_update_active_floor()

func set_floors(p_floors: Array) -> void:
	floors = p_floors
	_update_active_floor(true)

func set_player(p_player: Node3D) -> void:
	player_node = p_player

func set_inside_state(p_inside: bool) -> void:
	if is_inside != p_inside:
		is_inside = p_inside
		_update_active_floor(true)

func get_active_floor() -> MapFloorData:
	if floors.is_empty():
		return null
	active_floor_index = clampi(active_floor_index, 0, floors.size() - 1)
	return floors[active_floor_index]

func get_floor_by_id(p_floor_id: String) -> MapFloorData:
	for f in floors:
		if f.floor_id == p_floor_id:
			return f
	return null

func get_player_world_pos() -> Vector3:
	if player_node and is_instance_valid(player_node):
		return player_node.global_position
	return Vector3.ZERO

func get_player_rotation_y() -> float:
	if not player_node or not is_instance_valid(player_node):
		return 0.0
	
	# Prefer camera rotation for first-person/third-person navigation orientation
	var cam = player_node.get_node_or_null("CameraPivot/SpringArm3D/Camera3D")
	if cam and cam is Camera3D:
		return cam.global_rotation.y
	elif "camera_rot_y" in player_node:
		return player_node.camera_rot_y
	return player_node.global_rotation.y

func get_player_normalized_on_floor(p_floor: MapFloorData) -> Vector2:
	if not p_floor or not player_node or not is_instance_valid(player_node):
		return Vector2(0.5, 0.5)
	return p_floor.world_to_map_normalized(player_node.global_position)

func get_exhibits_for_floor(p_floor: MapFloorData) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not p_floor:
		return result
		
	for ex in discovered_exhibits:
		var pos: Vector3 = ex.get("pos", Vector3.ZERO)
		var is_ext = (ex.get("floor_id") == "exterior_plaza")
		if p_floor.is_elevation_in_range(pos.y, not is_ext) or ex.get("floor_id") == p_floor.floor_id:
			result.append(ex)
	return result

func refresh_exhibits() -> void:
	_discover_scene_elements()

func toggle_full_map() -> void:
	is_full_map_open = not is_full_map_open
	full_map_toggled.emit(is_full_map_open)

func open_full_map() -> void:
	if not is_full_map_open:
		is_full_map_open = true
		full_map_toggled.emit(true)

func close_full_map() -> void:
	if is_full_map_open:
		is_full_map_open = false
		full_map_toggled.emit(false)

# -----------------------------------------------------------------------------
# Internal Helpers
# -----------------------------------------------------------------------------
func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0] is Node3D:
		player_node = players[0]
		return
		
	# Fallback search
	var root = get_tree().current_scene
	if root:
		var p = root.get_node_or_null("Player")
		if p and p is Node3D:
			player_node = p

func _update_active_floor(force_emit: bool = false) -> void:
	if floors.is_empty():
		return
		
	var py = player_node.global_position.y if player_node else 3.5
	var pz = player_node.global_position.z if player_node else 0.0
	
	# Determine if outside based on flag or position
	var actually_inside = is_inside
	if not is_inside and pz < 28.0:
		actually_inside = true
	elif is_inside and pz > 33.0:
		actually_inside = false
		
	var new_index = active_floor_index
	
	if not actually_inside:
		# Exterior floor
		for i in range(floors.size()):
			if floors[i].is_exterior:
				new_index = i
				break
	else:
		# Interior floors by elevation
		for i in range(floors.size()):
			if not floors[i].is_exterior and floors[i].is_elevation_in_range(py, true):
				new_index = i
				break
				
	if new_index != active_floor_index or force_emit:
		active_floor_index = new_index
		floor_changed.emit(floors[active_floor_index])

func _discover_scene_elements() -> void:
	discovered_exhibits.clear()
	var root = get_tree().current_scene
	if not root:
		return
		
	_scan_nodes_for_exhibits(root)
	print("[MapManager] Discovered %d exhibits across all floors." % discovered_exhibits.size())

func _scan_nodes_for_exhibits(node: Node) -> void:
	if node is MonumentInteractable or "exhibit_id" in node:
		var ex_id = str(node.get("exhibit_id"))
		if not ex_id.is_empty():
			var pos: Vector3 = node.global_position if node is Node3D else Vector3.ZERO
			var ex_data = EducationalEventBus.get_exhibit_data(ex_id)
			
			# Assign floor based on location and height
			var f_id = "ground_floor"
			if pos.z > 30.0 or ex_id == "waterhouse_terracotta":
				f_id = "exterior_plaza"
			elif pos.y > 13.0:
				f_id = "second_floor"
			elif pos.y > 6.5:
				f_id = "first_floor"
			else:
				f_id = "ground_floor"
				
			discovered_exhibits.append({
				"id": ex_id,
				"node": node,
				"pos": pos,
				"floor_id": f_id,
				"data": ex_data
			})
			
	for child in node.get_children():
		_scan_nodes_for_exhibits(child)
