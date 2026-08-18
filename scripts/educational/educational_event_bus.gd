# -----------------------------------------------------------------------------
# educational_event_bus.gd
# Central decoupled event broker for the historical monument & exhibit system.
# -----------------------------------------------------------------------------
class_name EducationalEventBus
extends Node

signal prompt_shown(exhibit_dict: Dictionary, key_hint: String)
signal prompt_hidden()
signal popup_opened(exhibit_dict: Dictionary)
signal popup_closed()

# Global database of loaded exhibits
static var _exhibits_cache: Dictionary = {}
static var _instance: EducationalEventBus = null

func _init() -> void:
	if _instance == null:
		_instance = self
	load_exhibits_data()

func _enter_tree() -> void:
	if _instance == null:
		_instance = self

static func get_instance() -> EducationalEventBus:
	return get_or_create()

static func get_or_create() -> EducationalEventBus:
	if _instance == null or not is_instance_valid(_instance):
		_instance = EducationalEventBus.new()
		_instance.name = "EducationalEventBusSingleton"
		var main_loop = Engine.get_main_loop()
		if main_loop is SceneTree:
			var tree = main_loop as SceneTree
			if tree.root and not tree.root.has_node("EducationalEventBusSingleton"):
				tree.root.call_deferred("add_child", _instance)
	return _instance

static func load_exhibits_data(json_path: String = "res://data/educational/exhibits.json") -> void:
	if not _exhibits_cache.is_empty():
		return
	
	if not FileAccess.file_exists(json_path):
		push_warning("[EducationalEventBus] Exhibits JSON not found at: %s" % json_path)
		return
		
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		push_error("[EducationalEventBus] Failed to open: %s" % json_path)
		return
		
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(json_str)
	if err != OK:
		push_error("[EducationalEventBus] Failed to parse exhibits JSON: %s" % json.get_error_message())
		return
		
	var parsed = json.get_data()
	if parsed is Dictionary and parsed.has("exhibits"):
		for item in parsed["exhibits"]:
			if item is Dictionary and item.has("id"):
				_exhibits_cache[item["id"]] = item
				
	print("[EducationalEventBus] Loaded %d historical exhibits into registry." % _exhibits_cache.size())

static func get_exhibit_data(exhibit_id: String) -> Dictionary:
	if _exhibits_cache.is_empty():
		load_exhibits_data()
	return _exhibits_cache.get(exhibit_id, {})

static func show_prompt(exhibit_dict: Dictionary, key_hint: String = "E") -> void:
	var bus = get_or_create()
	if bus:
		bus.prompt_shown.emit(exhibit_dict, key_hint)

static func hide_prompt() -> void:
	var bus = get_or_create()
	if bus:
		bus.prompt_hidden.emit()

static func open_popup(exhibit_dict: Dictionary) -> void:
	var bus = get_or_create()
	if bus:
		bus.popup_opened.emit(exhibit_dict)

static func close_popup() -> void:
	var bus = get_or_create()
	if bus:
		bus.popup_closed.emit()
