# -----------------------------------------------------------------------------
# minimap_hud.gd
# Compact rotating circular HUD minimap rendered in the top-left corner.
# The map geometry rotates with the player's look direction while the player arrow remains pointing forward.
# -----------------------------------------------------------------------------
class_name MinimapHUD
extends Control

const MapFloorData = preload("res://scripts/minimap/map_floor_data.gd")
const MapManager = preload("res://scripts/minimap/map_manager.gd")

@export var map_manager: Node = null
@export var radar_radius: float = 65.0 # Reduced size
@export var zoom_scale: float = 4.0   # Pixels per world meter

var current_floor: MapFloorData = null
var is_hovered: bool = false
var pulse_time: float = 0.0

@onready var floor_label: Label = $FloorBadge/MarginContainer/FloorLabel
@onready var hint_label: Label = $HintLabel

func _ready() -> void:
	if not map_manager:
		map_manager = get_node_or_null("../MapManager")
		
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	if map_manager:
		map_manager.floor_changed.connect(_on_floor_changed)
		current_floor = map_manager.get_active_floor()
		_update_floor_badge()

func _process(delta: float) -> void:
	pulse_time += delta
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if map_manager:
			map_manager.open_full_map()
			accept_event()

func _on_mouse_entered() -> void:
	is_hovered = true
	if hint_label:
		hint_label.modulate.a = 1.0

func _on_mouse_exited() -> void:
	is_hovered = false
	if hint_label:
		hint_label.modulate.a = 0.75

func _on_floor_changed(new_floor: MapFloorData) -> void:
	current_floor = new_floor
	_update_floor_badge()
	queue_redraw()

func _update_floor_badge() -> void:
	if floor_label and current_floor:
		floor_label.text = current_floor.short_name

func _draw() -> void:
	var center = Vector2(radar_radius + 10.0, radar_radius + 22.0)
	var radius = radar_radius
	
	# 1. Outer glow when hovered
	if is_hovered:
		draw_circle(center, radius + 5.0, Color(0.95, 0.75, 0.30, 0.25))
		
	# 2. Main circular radar background
	draw_circle(center, radius, Color(0.06, 0.08, 0.12, 0.92))
	
	# 3. Concentric radar distance rings
	draw_arc(center, radius * 0.35, 0, TAU, 32, Color(1, 1, 1, 0.06), 1.0)
	draw_arc(center, radius * 0.70, 0, TAU, 48, Color(1, 1, 1, 0.08), 1.0)
	
	# Subtle Crosshairs
	draw_line(center - Vector2(radius * 0.85, 0), center + Vector2(radius * 0.85, 0), Color(1, 1, 1, 0.05), 1.0)
	draw_line(center - Vector2(0, radius * 0.85), center + Vector2(0, radius * 0.85), Color(1, 1, 1, 0.05), 1.0)
	
	if not map_manager or not current_floor:
		_draw_border(center, radius)
		return
		
	var player_pos_3d = map_manager.get_player_world_pos()
	var player_rot_y = map_manager.get_player_rotation_y()
	
	# 4. Draw floor blueprint elements ROTATED around player
	for el in current_floor.layout_elements:
		var el_rect: Rect2 = el.get("rect", Rect2())
		var el_col: Color = el.get("color", Color(0.2, 0.25, 0.35, 0.5))
		el_col.a = 0.35
		
		var corners = [
			Vector2(el_rect.position.x, el_rect.position.y),
			Vector2(el_rect.end.x, el_rect.position.y),
			Vector2(el_rect.end.x, el_rect.end.y),
			Vector2(el_rect.position.x, el_rect.end.y)
		]
		
		var poly = PackedVector2Array()
		for pt in corners:
			var raw_rel = Vector2(pt.x - player_pos_3d.x, pt.y - player_pos_3d.z) * zoom_scale
			var rot_pt = center + raw_rel.rotated(player_rot_y)
			poly.append(rot_pt)
			
		# Check approximate bounding center
		var poly_center = (poly[0] + poly[2]) * 0.5
		if center.distance_squared_to(poly_center) < (radius * 2.0) * (radius * 2.0):
			draw_colored_polygon(poly, el_col)
			draw_polyline(poly + PackedVector2Array([poly[0]]), Color(el_col.r, el_col.g, el_col.b, 0.55), 1.0)
			
	# 5. Draw exhibit markers ROTATED around player
	var exhibits = map_manager.get_exhibits_for_floor(current_floor)
	for ex in exhibits:
		var ex_pos: Vector3 = ex.get("pos", Vector3.ZERO)
		var raw_rel = Vector2(ex_pos.x - player_pos_3d.x, ex_pos.z - player_pos_3d.z) * zoom_scale
		var rot_rel = raw_rel.rotated(player_rot_y)
		
		var dist = rot_rel.length()
		var is_clamped = false
		if dist > radius - 7.0:
			rot_rel = rot_rel.normalized() * (radius - 7.0)
			is_clamped = true
			
		var blip_pos = center + rot_rel
		var pulse = (sin(pulse_time * 4.0) + 1.0) * 0.5
		
		var marker_color = Color(0.95, 0.75, 0.20, 0.95) if not is_clamped else Color(0.95, 0.75, 0.20, 0.5)
		draw_circle(blip_pos, 3.5 + (pulse * 1.2 if not is_clamped else 0.0), marker_color)
		draw_circle(blip_pos, 1.8, Color.WHITE)
		
	# 6. Draw Player Indicator in Center (Always pointing FORWARD / UP)
	var arrow_size = 6.0
	var arrow_tip = center + Vector2(0, -arrow_size * 1.3)
	var arrow_left = center + Vector2(-arrow_size * 0.75, arrow_size * 0.8)
	var arrow_right = center + Vector2(arrow_size * 0.75, arrow_size * 0.8)
	
	var points = PackedVector2Array([arrow_tip, arrow_left, center, arrow_right])
	draw_colored_polygon(points, Color(0.2, 0.9, 1.0, 1.0))
	draw_polyline(points, Color.WHITE, 1.5, true)
	
	# 7. Ornate Victorian Circular Compass Rim & Border
	_draw_border(center, radius)
	
	# 8. Rotating Compass North Needle around Rim
	_draw_compass_needle(center, radius, player_rot_y)

func _draw_border(center: Vector2, radius: float) -> void:
	var border_color = Color(0.85, 0.68, 0.25, 0.95) if not is_hovered else Color(1.0, 0.85, 0.40, 1.0)
	var inner_ring_color = Color(0.45, 0.35, 0.15, 0.7)
	
	draw_arc(center, radius + 2.0, 0, TAU, 64, border_color, 2.0)
	draw_arc(center, radius - 2.0, 0, TAU, 64, inner_ring_color, 1.0)
	
	# 8 decorative brass studs around perimeter
	for i in range(8):
		var angle = i * (TAU / 8.0)
		var stud_pos = center + Vector2(cos(angle), sin(angle)) * (radius + 1.0)
		draw_circle(stud_pos, 1.8, border_color)

func _draw_compass_needle(center: Vector2, radius: float, player_rot_y: float) -> void:
	# North indicator rotates on the outer rim corresponding to true north
	var north_dir = Vector2.UP.rotated(player_rot_y)
	var n_tip = center + north_dir * (radius - 2.0)
	var n_base = center + north_dir * (radius - 8.0)
	
	draw_line(n_base, n_tip, Color(0.95, 0.25, 0.25, 0.95), 2.5)
	draw_circle(n_tip, 2.0, Color(1.0, 0.4, 0.4, 1.0))
