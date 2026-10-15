# -----------------------------------------------------------------------------
# scene_loader.gd
# Universal Asynchronous Background Scene Loader & Transition Manager
# -----------------------------------------------------------------------------
extends Node

# -----------------------------------------------------------------------------
# Era Metadata & Historical Curiosities
# -----------------------------------------------------------------------------
const ERA_METADATA: Dictionary = {
	"res://scenes/church_exterior.tscn": {
		"title": "01. NATURAL HISTORY MUSEUM",
		"subtitle": "Victorian Era • London, England • 1881 CE",
		"tips": [
			"Hintze Hall is celebrated as a 'Cathedral to Nature', designed by Alfred Waterhouse.",
			"The Romanesque terracotta architecture was engineered to withstand Victorian London's coal smog.",
			"Look up at the painted ceiling panels celebrating botanical specimens from across the globe."
		]
	},
	"res://scenes/stonehenge_map.tscn": {
		"title": "02. STONEHENGE",
		"subtitle": "Bronze Age Megalithic Wonder • Salisbury Plain, England • ~2500 BCE",
		"tips": [
			"The massive sarsen stones weigh up to 25 tons and were hauled over 20 miles.",
			"The monument is astronomically aligned with the summer and winter solstices.",
			"Smaller bluestones were transported all the way from the Preseli Hills in Wales."
		]
	},
	"res://scenes/colosseum_map.tscn": {
		"title": "03. ROMAN COLOSSEUM",
		"subtitle": "Flavian Amphitheatre • Ancient Rome, Italy • 80 CE",
		"tips": [
			"Capable of seating over 50,000 spectators with 80 arched numbered entrances.",
			"The hypogeum beneath the arena floor contained elaborate elevators and trapdoors.",
			"The arena was inaugurated with 100 days of monumental imperial games."
		]
	},
	"res://scenes/agra_world.tscn": {
		"title": "04. TAJ MAHAL",
		"subtitle": "Mughal Empire • Agra, India • 1632 – 1653 CE",
		"tips": [
			"Constructed from luminous white Makrana marble and imperial red Sikri sandstone.",
			"The Charbagh garden follows a sacred quadripartite plan symbolizing paradise.",
			"Over 20,000 master artisans, calligraphers, and stonemasons contributed to its creation."
		]
	},
	"res://scenes/main_menu.tscn": {
		"title": "HISTORY GAMIFIED",
		"subtitle": "Select an era to explore...",
		"tips": [
			"Explore four faithfully reconstructed historical eras in immersive 3D.",
			"Discover educational exhibits and examine architectural details up close.",
			"Press [Shift] to sprint and [Esc] to access the navigation menu at any time."
		]
	}
}

# -----------------------------------------------------------------------------
# State Variables
# -----------------------------------------------------------------------------
var canvas_layer: CanvasLayer = null
var overlay_root: Control = null
var title_label: Label = null
var subtitle_label: Label = null
var tip_label: Label = null
var progress_bar: ProgressBar = null
var percent_label: Label = null
var spinner: Control = null

var target_scene_path: String = ""
var is_loading: bool = false
var loading_progress: float = 0.0
var target_progress: float = 0.0
var spinner_rotation: float = 0.0
var min_load_time_elapsed: float = 0.0
var min_load_duration: float = 0.35 # Ensures smooth visual transition without jarring cuts

# -----------------------------------------------------------------------------
# Initialization
# -----------------------------------------------------------------------------
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_loading_ui()

func _create_loading_ui() -> void:
	canvas_layer = CanvasLayer.new()
	canvas_layer.name = "SceneLoaderCanvas"
	canvas_layer.layer = 125
	add_child(canvas_layer)
	
	overlay_root = Control.new()
	overlay_root.name = "LoadingOverlay"
	overlay_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_root.visible = false
	overlay_root.modulate.a = 0.0
	canvas_layer.add_child(overlay_root)
	
	# Solid dark backdrop
	var bg: ColorRect = ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.04, 0.07, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_root.add_child(bg)
	
	# Decorative subtle vignette / gold top accent line
	var top_line: ColorRect = ColorRect.new()
	top_line.name = "TopGoldLine"
	top_line.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_line.custom_minimum_size = Vector2(0, 3)
	top_line.color = Color(0.85, 0.70, 0.28, 0.85)
	overlay_root.add_child(top_line)
	
	var bottom_line: ColorRect = ColorRect.new()
	bottom_line.name = "BottomGoldLine"
	bottom_line.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_line.custom_minimum_size = Vector2(0, 3)
	bottom_line.color = Color(0.85, 0.70, 0.28, 0.85)
	overlay_root.add_child(bottom_line)
	
	# Center Content Container
	var center_box: VBoxContainer = VBoxContainer.new()
	center_box.name = "ContentBox"
	center_box.set_anchors_preset(Control.PRESET_CENTER)
	center_box.custom_minimum_size = Vector2(560, 260)
	center_box.add_theme_constant_override("separation", 14)
	center_box.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay_root.add_child(center_box)
	
	# Animated Compass / Ring Icon
	var spinner_container: Control = Control.new()
	spinner_container.name = "SpinnerContainer"
	spinner_container.custom_minimum_size = Vector2(48, 48)
	spinner_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	spinner = Control.new()
	spinner.name = "Spinner"
	spinner.custom_minimum_size = Vector2(36, 36)
	spinner.set_anchors_preset(Control.PRESET_CENTER)
	spinner.pivot_offset = Vector2(18, 18)
	
	var ring_panel: Panel = Panel.new()
	ring_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ring_style: StyleBoxFlat = StyleBoxFlat.new()
	ring_style.bg_color = Color(0, 0, 0, 0)
	ring_style.border_width_left = 3
	ring_style.border_width_top = 3
	ring_style.border_width_right = 1
	ring_style.border_width_bottom = 1
	ring_style.border_color = Color(0.95, 0.80, 0.35, 0.95)
	ring_style.corner_radius_top_left = 18
	ring_style.corner_radius_top_right = 18
	ring_style.corner_radius_bottom_right = 18
	ring_style.corner_radius_bottom_left = 18
	ring_panel.add_theme_stylebox_override("panel", ring_style)
	spinner.add_child(ring_panel)
	spinner_container.add_child(spinner)
	center_box.add_child(spinner_container)
	
	# Era Title
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45, 1.0))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	center_box.add_child(title_label)
	
	# Subtitle / Era Info
	subtitle_label = Label.new()
	subtitle_label.name = "SubtitleLabel"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 14)
	subtitle_label.add_theme_color_override("font_color", Color(0.82, 0.84, 0.88, 0.9))
	center_box.add_child(subtitle_label)
	
	# Divider
	var div: ColorRect = ColorRect.new()
	div.name = "Divider"
	div.custom_minimum_size = Vector2(240, 1)
	div.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	div.color = Color(0.85, 0.70, 0.28, 0.4)
	center_box.add_child(div)
	
	# Historical Tip
	tip_label = Label.new()
	tip_label.name = "TipLabel"
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_label.custom_minimum_size = Vector2(500, 48)
	tip_label.add_theme_font_size_override("font_size", 13)
	tip_label.add_theme_color_override("font_color", Color(0.70, 0.74, 0.80, 0.85))
	center_box.add_child(tip_label)
	
	# Progress Container
	var progress_box: VBoxContainer = VBoxContainer.new()
	progress_box.name = "ProgressBox"
	progress_box.custom_minimum_size = Vector2(460, 28)
	progress_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	progress_box.add_theme_constant_override("separation", 6)
	center_box.add_child(progress_box)
	
	# Themed Progress Bar
	progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.custom_minimum_size = Vector2(460, 8)
	progress_bar.show_percentage = false
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.value = 0.0
	
	var bar_bg: StyleBoxFlat = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.08, 0.10, 0.15, 0.9)
	bar_bg.corner_radius_top_left = 4
	bar_bg.corner_radius_top_right = 4
	bar_bg.corner_radius_bottom_right = 4
	bar_bg.corner_radius_bottom_left = 4
	progress_bar.add_theme_stylebox_override("background", bar_bg)
	
	var bar_fill: StyleBoxFlat = StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.92, 0.76, 0.26, 1.0)
	bar_fill.corner_radius_top_left = 4
	bar_fill.corner_radius_top_right = 4
	bar_fill.corner_radius_bottom_right = 4
	bar_fill.corner_radius_bottom_left = 4
	progress_bar.add_theme_stylebox_override("fill", bar_fill)
	progress_box.add_child(progress_bar)
	
	# Percentage text
	percent_label = Label.new()
	percent_label.name = "PercentLabel"
	percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	percent_label.add_theme_font_size_override("font_size", 12)
	percent_label.add_theme_color_override("font_color", Color(0.85, 0.70, 0.30, 0.9))
	percent_label.text = "Initializing world..."
	progress_box.add_child(percent_label)

# -----------------------------------------------------------------------------
# Public Transition API
# -----------------------------------------------------------------------------
func change_scene_to(scene_path: String, custom_title: String = "", custom_subtitle: String = "", custom_tip: String = "") -> void:
	if is_loading:
		return
	
	target_scene_path = scene_path
	is_loading = true
	loading_progress = 0.0
	target_progress = 0.05
	min_load_time_elapsed = 0.0
	
	# Fetch metadata
	var meta: Dictionary = ERA_METADATA.get(scene_path, {})
	var t_title: String = custom_title if custom_title != "" else meta.get("title", "LOADING ERA")
	var t_sub: String = custom_subtitle if custom_subtitle != "" else meta.get("subtitle", "")
	var t_tip: String = custom_tip
	if t_tip == "":
		var tips_arr: Array = meta.get("tips", [])
		if not tips_arr.is_empty():
			t_tip = tips_arr[randi() % tips_arr.size()]
		else:
			t_tip = "Reconstructing authentic architectural geometry and lighting..."
			
	title_label.text = t_title
	subtitle_label.text = t_sub
	tip_label.text = t_tip
	progress_bar.value = 0.0
	percent_label.text = "Loading destination..."
	
	# Enable input blocking during load
	overlay_root.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_root.visible = true
	
	# Start background loading immediately on worker thread
	_begin_threaded_load()
	
	# Fade in loading screen
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(overlay_root, "modulate:a", 1.0, 0.22)

func _begin_threaded_load() -> void:
	if not ResourceLoader.exists(target_scene_path):
		push_error("[SceneLoader] Scene path does not exist: " + target_scene_path)
		_finish_load_fallback()
		return
		
	var err = ResourceLoader.load_threaded_request(target_scene_path, "", false)
	if err != OK:
		push_warning("[SceneLoader] Threaded request failed with code %d. Using fallback load." % err)
		_finish_load_fallback()

# -----------------------------------------------------------------------------
# Frame Processing & Async Progress Tracking
# -----------------------------------------------------------------------------
func _process(delta: float) -> void:
	if not is_loading:
		return
		
	min_load_time_elapsed += delta
	
	# Animate spinner
	spinner_rotation += delta * 3.5
	if spinner:
		spinner.rotation = spinner_rotation
		
	# Query Threaded Loader
	var progress_arr: Array = []
	var status = ResourceLoader.load_threaded_get_status(target_scene_path, progress_arr)
	
	var raw_p: float = progress_arr[0] if progress_arr.size() > 0 else 0.0
	target_progress = maxf(target_progress, raw_p)
	
	# Smoothly advance progress bar
	loading_progress = move_toward(loading_progress, target_progress, delta * 2.2)
	progress_bar.value = loading_progress
	
	var pct: int = int(clamped_progress(loading_progress) * 100.0)
	percent_label.text = "Loading environment... %d%%" % pct
	
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			# Complete progress once loaded and minimum transition duration has passed
			if loading_progress >= 0.98 and min_load_time_elapsed >= min_load_duration:
				_instantiate_and_swap_scene()
			else:
				target_progress = 1.0
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("[SceneLoader] Asynchronous loading error for: " + target_scene_path)
			_finish_load_fallback()

func clamped_progress(v: float) -> float:
	return clampf(v, 0.0, 1.0)

# -----------------------------------------------------------------------------
# Scene Swap & Graceful Fade-Out
# -----------------------------------------------------------------------------
func _instantiate_and_swap_scene() -> void:
	is_loading = false
	percent_label.text = "Entering world..."
	
	var packed_scene = ResourceLoader.load_threaded_get(target_scene_path) as PackedScene
	if packed_scene:
		get_tree().change_scene_to_packed(packed_scene)
	else:
		get_tree().change_scene_to_file(target_scene_path)
		
	# Allow new scene to initialize and execute _ready()
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Fade out overlay
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(overlay_root, "modulate:a", 0.0, 0.32)
	tween.tween_callback(func():
		overlay_root.visible = false
		overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)

func _finish_load_fallback() -> void:
	is_loading = false
	get_tree().change_scene_to_file(target_scene_path)
	await get_tree().process_frame
	var tween: Tween = create_tween()
	tween.tween_property(overlay_root, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		overlay_root.visible = false
		overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)
