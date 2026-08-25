# -----------------------------------------------------------------------------
# full_map_view.gd
# Interactive full-screen museum floorplan overlay with floor selectors, exhibit cards, and navigation.
# -----------------------------------------------------------------------------
class_name FullMapView
extends Control

const MapFloorData = preload("res://scripts/minimap/map_floor_data.gd")
const MapManager = preload("res://scripts/minimap/map_manager.gd")

@export var map_manager: Node = null

var selected_floor_index: int = 1
var hovered_exhibit_id: String = ""
var selected_exhibit_dict: Dictionary = {}
var pulse_time: float = 0.0

@onready var blueprint_canvas: Control = $MainPanel/Margin/VBox/Content/MapArea/BlueprintCanvas
@onready var floor_tabs_container: HBoxContainer = $MainPanel/Margin/VBox/Header/FloorTabs
@onready var sidebar_card: PanelContainer = $MainPanel/Margin/VBox/Content/Sidebar/ExhibitCard
@onready var card_title: Label = $MainPanel/Margin/VBox/Content/Sidebar/ExhibitCard/Margin/VBox/TitleLabel
@onready var card_category: Label = $MainPanel/Margin/VBox/Content/Sidebar/ExhibitCard/Margin/VBox/CategoryLabel
@onready var card_image: TextureRect = $MainPanel/Margin/VBox/Content/Sidebar/ExhibitCard/Margin/VBox/ImageFrame/ExhibitImage
@onready var card_desc: Label = $MainPanel/Margin/VBox/Content/Sidebar/ExhibitCard/Margin/VBox/ScrollContainer/DescriptionLabel
@onready var card_placeholder: Label = $MainPanel/Margin/VBox/Content/Sidebar/PlaceholderLabel
@onready var close_btn: Button = $MainPanel/Margin/VBox/Header/CloseButton

func _ready() -> void:
	visible = false
	if not map_manager:
		map_manager = get_node_or_null("../MapManager")
		
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)
		
	if map_manager:
		map_manager.full_map_toggled.connect(_on_map_toggled)
		map_manager.floor_changed.connect(_on_active_floor_changed)
		
	_setup_floor_tabs()

func _process(delta: float) -> void:
	if not visible:
		return
	pulse_time += delta
	if blueprint_canvas:
		blueprint_canvas.queue_redraw()

func _input(event: InputEvent) -> void:
	# Hotkey 'M' or Escape to toggle / close full map
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_M:
			if map_manager:
				map_manager.toggle_full_map()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and visible:
			if map_manager:
				map_manager.close_full_map()
				get_viewport().set_input_as_handled()

func _on_map_toggled(is_open: bool) -> void:
	visible = is_open
	if is_open:
		if map_manager:
			selected_floor_index = map_manager.active_floor_index
		_update_floor_tab_highlights()
		_clear_card_selection()
		if blueprint_canvas:
			blueprint_canvas.queue_redraw()

func _on_active_floor_changed(new_floor: MapFloorData) -> void:
	if visible and map_manager:
		selected_floor_index = map_manager.active_floor_index
		_update_floor_tab_highlights()
		if blueprint_canvas:
			blueprint_canvas.queue_redraw()

func _on_close_pressed() -> void:
	if map_manager:
		map_manager.close_full_map()

func _setup_floor_tabs() -> void:
	if not floor_tabs_container or not map_manager:
		return
		
	# Clear children
	for child in floor_tabs_container.get_children():
		child.queue_free()
		
	for i in range(map_manager.floors.size()):
		var floor_data = map_manager.floors[i]
		var btn = Button.new()
		btn.text = " " + floor_data.short_name + " "
		btn.custom_minimum_size = Vector2(110, 36)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(func(): _select_floor(i))
		floor_tabs_container.add_child(btn)
		
	_update_floor_tab_highlights()

func _select_floor(index: int) -> void:
	selected_floor_index = index
	_update_floor_tab_highlights()
	_clear_card_selection()
	if blueprint_canvas:
		blueprint_canvas.queue_redraw()

func _update_floor_tab_highlights() -> void:
	if not floor_tabs_container:
		return
	var buttons = floor_tabs_container.get_children()
	for i in range(buttons.size()):
		if buttons[i] is Button:
			if i == selected_floor_index:
				buttons[i].modulate = Color(1.2, 1.1, 0.6, 1.0)
			else:
				buttons[i].modulate = Color(0.7, 0.7, 0.7, 1.0)

func _clear_card_selection() -> void:
	selected_exhibit_dict.clear()
	if sidebar_card:
		sidebar_card.visible = false
	if card_placeholder:
		card_placeholder.visible = true

func _show_exhibit_card(ex_dict: Dictionary) -> void:
	selected_exhibit_dict = ex_dict
	var data = ex_dict.get("data", {})
	if data.is_empty():
		data = EducationalEventBus.get_exhibit_data(ex_dict.get("id", ""))
		
	if sidebar_card:
		sidebar_card.visible = true
	if card_placeholder:
		card_placeholder.visible = false
		
	if card_title:
		card_title.text = data.get("title", ex_dict.get("id", "Exhibit"))
	if card_category:
		card_category.text = data.get("category", "Natural History")
	if card_desc:
		card_desc.text = data.get("description", "Click 'Learn More' when nearby to inspect.")
		
	if card_image:
		var img_path = data.get("image_path", "")
		if not img_path.is_empty() and ResourceLoader.exists(img_path):
			card_image.texture = load(img_path)
		else:
			card_image.texture = null

# -----------------------------------------------------------------------------
# Blueprint Canvas Drawing & Mouse Interaction
# -----------------------------------------------------------------------------
func draw_blueprint_on_canvas(canvas: Control) -> void:
	if not map_manager or map_manager.floors.is_empty():
		return
		
	var floor_data = map_manager.floors[clampi(selected_floor_index, 0, map_manager.floors.size() - 1)]
	if not floor_data:
		return
		
	var canvas_rect = canvas.get_rect()
	var pad = 40.0
	var draw_area = Rect2(Vector2(pad, pad), canvas_rect.size - Vector2(pad * 2, pad * 2))
	
	# Background Blueprint Grid
	canvas.draw_rect(draw_area, Color(0.04, 0.06, 0.09, 0.95), true)
	canvas.draw_rect(draw_area, Color(0.25, 0.45, 0.65, 0.4), false, 2.0)
	
	# Grid Lines
	var grid_step = 30.0
	var gx = draw_area.position.x
	while gx < draw_area.end.x:
		canvas.draw_line(Vector2(gx, draw_area.position.y), Vector2(gx, draw_area.end.y), Color(1, 1, 1, 0.03), 1.0)
		gx += grid_step
	var gy = draw_area.position.y
	while gy < draw_area.end.y:
		canvas.draw_line(Vector2(draw_area.position.x, gy), Vector2(draw_area.end.x, gy), Color(1, 1, 1, 0.03), 1.0)
		gy += grid_step
		
	# Transform mapping: world (X, Z) -> canvas (X, Y)
	var world_bounds = floor_data.world_bounds
	var scale_x = draw_area.size.x / world_bounds.size.x
	var scale_y = draw_area.size.y / world_bounds.size.y
	var base_scale = minf(scale_x, scale_y) * 0.92
	
	var map_center = draw_area.get_center()
	var world_center_x = world_bounds.position.x + world_bounds.size.x * 0.5
	var world_center_z = world_bounds.position.y + world_bounds.size.y * 0.5
	
	var world_to_screen = func(world_x: float, world_z: float) -> Vector2:
		var ox = (world_x - world_center_x) * base_scale
		var oy = (world_z - world_center_z) * base_scale
		return map_center + Vector2(ox, oy)
		
	# Draw Layout Elements
	for el in floor_data.layout_elements:
		var r: Rect2 = el.get("rect", Rect2())
		var col: Color = el.get("color", Color(0.15, 0.2, 0.3, 0.9))
		var p1 = world_to_screen.call(r.position.x, r.position.y)
		var p2 = world_to_screen.call(r.end.x, r.end.y)
		var elem_screen_rect = Rect2(p1, p2 - p1)
		
		canvas.draw_rect(elem_screen_rect, col, true)
		canvas.draw_rect(elem_screen_rect, Color(floor_data.floor_accent_color.r, floor_data.floor_accent_color.g, floor_data.floor_accent_color.b, 0.5), false, 1.5)
		
		var label = el.get("label", "")
		if not label.is_empty() and elem_screen_rect.size.x > 50 and elem_screen_rect.size.y > 20:
			var font = canvas.get_theme_default_font()
			if font:
				canvas.draw_string(font, elem_screen_rect.position + Vector2(6, 16), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.5))
				
	# Draw Exhibits on this floor
	var exhibits = map_manager.get_exhibits_for_floor(floor_data)
	var mouse_pos = canvas.get_local_mouse_position()
	var new_hovered_id = ""
	
	for ex in exhibits:
		var pos: Vector3 = ex.get("pos", Vector3.ZERO)
		var pt = world_to_screen.call(pos.x, pos.z)
		var ex_id = ex.get("id", "")
		var is_hovered = (pt.distance_squared_to(mouse_pos) < 18.0 * 18.0)
		
		if is_hovered:
			new_hovered_id = ex_id
			
		var marker_col = floor_data.floor_accent_color
		var pulse = (sin(pulse_time * 5.0) + 1.0) * 0.5
		
		if is_hovered:
			canvas.draw_circle(pt, 12.0 + pulse * 3.0, Color(marker_col.r, marker_col.g, marker_col.b, 0.35))
			canvas.draw_circle(pt, 8.0, Color.WHITE)
			canvas.draw_circle(pt, 6.0, marker_col)
		else:
			canvas.draw_circle(pt, 7.0 + pulse * 1.5, Color(marker_col.r, marker_col.g, marker_col.b, 0.3))
			canvas.draw_circle(pt, 5.0, marker_col)
			canvas.draw_circle(pt, 2.5, Color.WHITE)
			
		# Exhibit Label
		var data = ex.get("data", {})
		var title = data.get("title", ex_id)
		var font = canvas.get_theme_default_font()
		if font:
			var text_color = Color(1.0, 1.0, 0.8, 1.0) if is_hovered else Color(0.85, 0.85, 0.85, 0.8)
			canvas.draw_string(font, pt + Vector2(10, 4), title, HORIZONTAL_ALIGNMENT_LEFT, 200, 12, text_color)
			
	hovered_exhibit_id = new_hovered_id
	
	# Draw Player if on this floor
	var active_floor = map_manager.get_active_floor()
	if active_floor and active_floor.floor_id == floor_data.floor_id:
		var p_pos = map_manager.get_player_world_pos()
		var p_rot = map_manager.get_player_rotation_y()
		var ppt = world_to_screen.call(p_pos.x, p_pos.z)
		
		var arrow_dir = Vector2.UP.rotated(-p_rot)
		var p_size = 9.0
		var tip = ppt + arrow_dir * (p_size * 1.4)
		var left = ppt + arrow_dir.rotated(deg_to_rad(140)) * p_size
		var right = ppt + arrow_dir.rotated(deg_to_rad(-140)) * p_size
		
		# Glowing aura around player
		canvas.draw_circle(ppt, 14.0, Color(0.2, 0.8, 1.0, 0.25))
		var poly = PackedVector2Array([tip, left, ppt, right])
		canvas.draw_colored_polygon(poly, Color(0.2, 0.9, 1.0, 1.0))
		canvas.draw_polyline(poly, Color.WHITE, 2.0, true)
		
		var font = canvas.get_theme_default_font()
		if font:
			canvas.draw_string(font, ppt + Vector2(12, -8), "YOU (Player)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.4, 0.9, 1.0, 1.0))

func handle_canvas_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not hovered_exhibit_id.is_empty() and map_manager:
			for ex in map_manager.discovered_exhibits:
				if ex.get("id") == hovered_exhibit_id:
					_show_exhibit_card(ex)
					break
