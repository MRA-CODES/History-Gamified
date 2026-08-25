# -----------------------------------------------------------------------------
# blueprint_canvas.gd
# Helper CanvasItem that delegates drawing and mouse inputs to FullMapView.
# -----------------------------------------------------------------------------
class_name BlueprintCanvas
extends Control

const FullMapView = preload("res://scenes/minimap/full_map_view.gd")

var _full_map_view: FullMapView = null

func _get_full_map() -> FullMapView:
	if not _full_map_view:
		_full_map_view = find_parent("FullMapView") as FullMapView
	return _full_map_view

func _draw() -> void:
	var view = _get_full_map()
	if view:
		view.draw_blueprint_on_canvas(self)

func _gui_input(event: InputEvent) -> void:
	var view = _get_full_map()
	if view:
		view.handle_canvas_input(event)

