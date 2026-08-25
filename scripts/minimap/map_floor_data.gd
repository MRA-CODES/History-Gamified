# -----------------------------------------------------------------------------
# map_floor_data.gd
# Data structure describing an individual floor level for the minimap system.
# -----------------------------------------------------------------------------
class_name MapFloorData
extends RefCounted

var floor_id: String = ""
var display_name: String = ""
var short_name: String = ""
var min_y: float = -999.0
var max_y: float = 999.0
var is_exterior: bool = false

# World boundary in (X, Z) space corresponding to this floor's coordinate mapping
# position = Vector2(min_x, min_z), size = Vector2(span_x, span_z)
var world_bounds: Rect2 = Rect2(Vector2(-20, -35), Vector2(40, 60))

# Visual rooms / architectural elements drawn on this floor blueprint
# Each element is a dict: { "type": "rect"|"arch"|"hall"|"stairs", "rect": Rect2, "label": String, "color": Color }
var layout_elements: Array = []

# Color themes for floor visualization
var floor_accent_color: Color = Color(0.85, 0.65, 0.25, 1.0) # Gold / Bronze
var background_color: Color = Color(0.08, 0.10, 0.14, 0.92)

func _init(p_id: String = "", p_name: String = "", p_short: String = "", p_min_y: float = -999.0, p_max_y: float = 999.0, p_exterior: bool = false) -> void:
	floor_id = p_id
	display_name = p_name
	short_name = p_short
	min_y = p_min_y
	max_y = p_max_y
	is_exterior = p_exterior

func is_elevation_in_range(y: float, p_is_inside: bool) -> bool:
	if is_exterior and p_is_inside:
		return false
	if not is_exterior and not p_is_inside:
		return false
	return y >= min_y and y < max_y

func world_to_map_normalized(world_pos_3d: Vector3) -> Vector2:
	var wx = world_pos_3d.x
	var wz = world_pos_3d.z
	
	var norm_x = (wx - world_bounds.position.x) / world_bounds.size.x
	var norm_y = (wz - world_bounds.position.y) / world_bounds.size.y
	return Vector2(clampf(norm_x, 0.0, 1.0), clampf(norm_y, 0.0, 1.0))

func map_normalized_to_world(norm_pos: Vector2) -> Vector3:
	var wx = world_bounds.position.x + (norm_pos.x * world_bounds.size.x)
	var wz = world_bounds.position.y + (norm_pos.y * world_bounds.size.y)
	var mid_y = (min_y + max_y) * 0.5
	return Vector3(wx, mid_y, wz)
