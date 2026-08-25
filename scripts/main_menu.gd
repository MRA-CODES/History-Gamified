extends Control

# -----------------------------------------------------------------------------
# Node References
# -----------------------------------------------------------------------------
@onready var fade_rect: ColorRect = $FadeOverlay/ColorRect
@onready var card_victorian: Control = $MainContainer/GridContainer/Card_Victorian
@onready var card_stonehenge: Control = $MainContainer/GridContainer/Card_Stonehenge
@onready var settings_modal: Control = $SettingsModal
@onready var about_modal: Control = $AboutModal
@onready var locked_toast: Label = $LockedToast

# Audio / state
var is_transitioning: bool = false

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------
func _ready() -> void:
	# 1. Setup fade in on scene start
	if fade_rect:
		fade_rect.modulate.a = 1.0
		fade_rect.visible = true
		var tween = create_tween()
		tween.tween_property(fade_rect, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 2. Hide modals
	if settings_modal:
		settings_modal.visible = false
	if about_modal:
		about_modal.visible = false
	if locked_toast:
		locked_toast.visible = false
		locked_toast.modulate.a = 0.0
		
	# 3. Connect Card 1: Victorian Museum
	if card_victorian:
		var btn = card_victorian.get_node_or_null("CardButton")
		if btn:
			btn.pressed.connect(_on_victorian_card_pressed)
			btn.mouse_entered.connect(func(): _on_card_hover(card_victorian, true))
			btn.mouse_exited.connect(func(): _on_card_hover(card_victorian, false))

	# 4. Connect Card 2: Stonehenge
	if card_stonehenge:
		var btn = card_stonehenge.get_node_or_null("CardButton")
		if btn:
			btn.pressed.connect(_on_stonehenge_card_pressed)
			btn.mouse_entered.connect(func(): _on_card_hover(card_stonehenge, true))
			btn.mouse_exited.connect(func(): _on_card_hover(card_stonehenge, false))

	# 5. Connect Locked Cards (Cards 3 through 6)
	var grid = $MainContainer/GridContainer
	if grid:
		for i in range(3, 7):
			var card_node = grid.get_node_or_null("Card_Locked_" + str(i))
			if card_node:
				var btn = card_node.get_node_or_null("CardButton")
				if btn:
					btn.pressed.connect(func(): _on_locked_card_pressed(card_node.get_node_or_null("TitleLabel")))

# -----------------------------------------------------------------------------
# Card Actions & Hover Effects
# -----------------------------------------------------------------------------
func _on_card_hover(card: Control, is_hovered: bool) -> void:
	if not card:
		return
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var target_scale = Vector2(1.03, 1.03) if is_hovered else Vector2(1.0, 1.0)
	tween.tween_property(card, "scale", target_scale, 0.2)
	
	var border = card.get_node_or_null("BorderGlow")
	if border:
		var target_alpha = 1.0 if is_hovered else 0.5
		tween.tween_property(border, "modulate:a", target_alpha, 0.2)

func _on_victorian_card_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	# Smooth fade to black and load Victorian Museum scene
	if fade_rect:
		var tween = create_tween()
		tween.tween_property(fade_rect, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func():
			get_tree().change_scene_to_file("res://scenes/church_exterior.tscn")
		)
	else:
		get_tree().change_scene_to_file("res://scenes/church_exterior.tscn")

func _on_stonehenge_card_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	# Smooth fade to black and load Stonehenge scene
	if fade_rect:
		var tween = create_tween()
		tween.tween_property(fade_rect, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func():
			get_tree().change_scene_to_file("res://scenes/stonehenge_map.tscn")
		)
	else:
		get_tree().change_scene_to_file("res://scenes/stonehenge_map.tscn")

func _on_locked_card_pressed(title_node: Label) -> void:
	var map_name = title_node.text if title_node else "This Era"
	_show_toast(map_name + " is currently Locked (Coming Soon in future expansion)")

func _show_toast(message: String) -> void:
	if not locked_toast:
		return
	locked_toast.text = message
	locked_toast.visible = true
	var tween = create_tween()
	tween.tween_property(locked_toast, "modulate:a", 1.0, 0.2)
	tween.tween_interval(2.0)
	tween.tween_property(locked_toast, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): locked_toast.visible = false)

# -----------------------------------------------------------------------------
# Top & Bottom Buttons
# -----------------------------------------------------------------------------
func _on_settings_pressed() -> void:
	if settings_modal:
		settings_modal.visible = true

func _on_close_settings_pressed() -> void:
	if settings_modal:
		settings_modal.visible = false

func _on_about_pressed() -> void:
	if about_modal:
		about_modal.visible = true

func _on_close_about_pressed() -> void:
	if about_modal:
		about_modal.visible = false

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
