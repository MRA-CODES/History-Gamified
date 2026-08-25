# -----------------------------------------------------------------------------
# monument_popup.gd
# Interactive Historical Monument & Artifact UI Controller with Laura / ElevenLabs / TTS audio narration.
# -----------------------------------------------------------------------------
extends CanvasLayer

const EducationalEventBus = preload("res://scripts/educational/educational_event_bus.gd")

# -----------------------------------------------------------------------------
# Node References
# -----------------------------------------------------------------------------
@onready var prompt_container: Control = $PromptContainer
@onready var prompt_label: Label = $PromptContainer/PanelContainer/MarginContainer/HBoxContainer/PromptLabel
@onready var prompt_key_badge: Label = $PromptContainer/PanelContainer/MarginContainer/HBoxContainer/KeyBadge

@onready var modal_backdrop: ColorRect = $ModalBackdrop
@onready var modal_panel: Control = $ModalPanel

@onready var category_badge: Label = $ModalPanel/MarginContainer/VBoxContainer/Header/TopRow/CategoryBadge
@onready var title_label: Label = $ModalPanel/MarginContainer/VBoxContainer/Header/TitleLabel
@onready var subtitle_label: Label = $ModalPanel/MarginContainer/VBoxContainer/Header/SubtitleLabel
@onready var close_btn: Button = $ModalPanel/MarginContainer/VBoxContainer/Header/TopRow/CloseButton

@onready var image_frame: PanelContainer = $ModalPanel/MarginContainer/VBoxContainer/ImageFrame
@onready var artifact_image: TextureRect = $ModalPanel/MarginContainer/VBoxContainer/ImageFrame/ArtifactImage

@onready var desc_label: RichTextLabel = $ModalPanel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/DescriptionLabel
@onready var facts_container: VBoxContainer = $ModalPanel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/FactsContainer

@onready var audio_bar: PanelContainer = $ModalPanel/MarginContainer/VBoxContainer/AudioBar
@onready var play_audio_btn: Button = $ModalPanel/MarginContainer/VBoxContainer/AudioBar/MarginContainer/HBoxContainer/PlayAudioButton
@onready var stop_audio_btn: Button = $ModalPanel/MarginContainer/VBoxContainer/AudioBar/MarginContainer/HBoxContainer/StopAudioButton
@onready var audio_status_label: Label = $ModalPanel/MarginContainer/VBoxContainer/AudioBar/MarginContainer/HBoxContainer/AudioStatusLabel
@onready var source_btn: Button = $ModalPanel/MarginContainer/VBoxContainer/Footer/SourceButton

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

# -----------------------------------------------------------------------------
# State
# -----------------------------------------------------------------------------
var is_modal_open: bool = false
var is_prompt_visible: bool = false
var current_data: Dictionary = {}
var open_time: float = 0.0

# Audio state
var is_audio_playing: bool = false
var is_audio_paused: bool = false
var is_using_elevenlabs_file: bool = false
var current_utterance_id: int = 0

# -----------------------------------------------------------------------------
# Lifecycle
# -----------------------------------------------------------------------------
func _ready() -> void:
	# Initial visibility
	prompt_container.modulate.a = 0.0
	prompt_container.visible = false
	
	modal_backdrop.modulate.a = 0.0
	modal_backdrop.visible = false
	
	modal_panel.scale = Vector2(0.85, 0.85)
	modal_panel.modulate.a = 0.0
	modal_panel.visible = false
	
	# Connect UI buttons
	if close_btn:
		close_btn.pressed.connect(close_modal)
	if play_audio_btn:
		play_audio_btn.pressed.connect(_on_toggle_audio_pressed)
	if stop_audio_btn:
		stop_audio_btn.pressed.connect(stop_audio_narration)
	if source_btn:
		source_btn.pressed.connect(_on_source_btn_pressed)
	if audio_stream_player:
		audio_stream_player.finished.connect(_on_audio_stream_finished)
		
	# Connect to event bus
	_connect_event_bus()

func _connect_event_bus() -> void:
	var bus = EducationalEventBus.get_or_create()
	bus.prompt_shown.connect(_on_prompt_shown)
	bus.prompt_hidden.connect(_on_prompt_hidden)
	bus.popup_opened.connect(_on_popup_opened)
	bus.popup_closed.connect(_on_popup_closed)

func _process(_delta: float) -> void:
	# Check TTS speaking status if using native TTS
	if is_audio_playing and not is_using_elevenlabs_file:
		if not DisplayServer.tts_is_speaking():
			_on_audio_stream_finished()

func _input(event: InputEvent) -> void:
	if not is_modal_open:
		return
		
	# Prevent closing on the exact frame it opened
	if (Time.get_ticks_msec() / 1000.0) - open_time < 0.25:
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_E:
			get_viewport().set_input_as_handled()
			close_modal()

# -----------------------------------------------------------------------------
# Prompt Banner
# -----------------------------------------------------------------------------
func _on_prompt_shown(data: Dictionary, key_hint: String) -> void:
	if is_modal_open:
		return
		
	current_data = data
	var title = data.get("title", "Monument / Exhibit")
	prompt_label.text = "Examine: %s" % title
	prompt_key_badge.text = " [ %s ] " % key_hint
	
	is_prompt_visible = true
	prompt_container.visible = true
	
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(prompt_container, "modulate:a", 1.0, 0.2).from(0.0)

func _on_prompt_hidden() -> void:
	if not is_prompt_visible:
		return
		
	is_prompt_visible = false
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(prompt_container, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func(): prompt_container.visible = false)

# -----------------------------------------------------------------------------
# Modal Logic
# -----------------------------------------------------------------------------
func _on_popup_opened(data: Dictionary) -> void:
	current_data = data
	open_modal()

func _on_popup_closed() -> void:
	if is_modal_open:
		close_modal()

func open_modal() -> void:
	if is_modal_open:
		return
	is_modal_open = true
	open_time = Time.get_ticks_msec() / 1000.0
	
	# Hide prompt
	_on_prompt_hidden()
	
	# Populate fields
	_populate_modal_data()
	
	# Release mouse & disable player look/movement
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_toggle_player_controls(false)
	
	# Audio setup reset
	_reset_audio_state()
	
	# Animate Modal In
	modal_backdrop.visible = true
	modal_panel.visible = true
	modal_panel.pivot_offset = modal_panel.size * 0.5
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal_backdrop, "modulate:a", 1.0, 0.25)
	tween.tween_property(modal_panel, "modulate:a", 1.0, 0.25)
	tween.tween_property(modal_panel, "scale", Vector2.ONE, 0.25)

func close_modal() -> void:
	if not is_modal_open:
		return
	is_modal_open = false
	
	# Stop audio narration
	stop_audio_narration()
	
	# Restore mouse capture & player movement
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_toggle_player_controls(true)
	
	# Notify event bus
	EducationalEventBus.close_popup()
	
	# Animate Modal Out
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(modal_backdrop, "modulate:a", 0.0, 0.2)
	tween.tween_property(modal_panel, "modulate:a", 0.0, 0.2)
	tween.tween_property(modal_panel, "scale", Vector2(0.9, 0.9), 0.2)
	tween.chain().tween_callback(func():
		modal_backdrop.visible = false
		modal_panel.visible = false
	)

func _populate_modal_data() -> void:
	category_badge.text = "🏛️ " + current_data.get("category", "MUSEUM EXHIBIT").to_upper()
	title_label.text = current_data.get("title", "Historical Monument")
	subtitle_label.text = current_data.get("subtitle_or_era", "")
	
	# Image loading
	artifact_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artifact_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var img_path = current_data.get("image_path", "")
	if not img_path.is_empty() and ResourceLoader.exists(img_path):
		artifact_image.texture = load(img_path)
		image_frame.visible = true
	elif not img_path.is_empty() and FileAccess.file_exists(img_path):
		var img = Image.load_from_file(img_path)
		if img:
			artifact_image.texture = ImageTexture.create_from_image(img)
			image_frame.visible = true
		else:
			image_frame.visible = false
	else:
		image_frame.visible = false
	
	# Exact Description text
	var description_text = current_data.get("description", "No historical description available.")
	desc_label.text = description_text
	
	# Clear old facts
	for child in facts_container.get_children():
		child.queue_free()
		
	# Populate key facts
	var facts = current_data.get("key_facts", [])
	if facts.is_empty():
		facts_container.visible = false
	else:
		facts_container.visible = true
		for fact in facts:
			var fact_row = HBoxContainer.new()
			fact_row.add_theme_constant_override("separation", 10)
			
			var bullet = Label.new()
			bullet.text = "✦"
			bullet.add_theme_color_override("font_color", Color(0.95, 0.8, 0.35, 1.0))
			
			var fact_lbl = Label.new()
			fact_lbl.text = str(fact)
			fact_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			fact_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fact_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.92, 1.0))
			
			fact_row.add_child(bullet)
			fact_row.add_child(fact_lbl)
			facts_container.add_child(fact_row)
			
	# Source link
	var src_name = current_data.get("source_name", "Wikipedia")
	source_btn.text = "🔗 Source: %s" % src_name
	source_btn.visible = not current_data.get("source_url", "").is_empty()

# -----------------------------------------------------------------------------
# Read Aloud / ElevenLabs (Laura Voice) & TTS Audio
# -----------------------------------------------------------------------------
func _reset_audio_state() -> void:
	is_audio_playing = false
	is_audio_paused = false
	is_using_elevenlabs_file = false
	play_audio_btn.text = "🔊 Read Aloud (Laura)"
	stop_audio_btn.visible = false
	
	var audio_path = current_data.get("audio_narration_path", "")
	if not audio_path.is_empty() and ResourceLoader.exists(audio_path):
		is_using_elevenlabs_file = true
		audio_status_label.text = "🎙️ Laura Voiceover Ready"
	else:
		is_using_elevenlabs_file = false
		audio_status_label.text = "🎙️ Voice Guide Ready"

func _on_toggle_audio_pressed() -> void:
	if is_audio_playing:
		if is_audio_paused:
			resume_audio_narration()
		else:
			pause_audio_narration()
	else:
		start_audio_narration()

func start_audio_narration() -> void:
	var audio_path = current_data.get("audio_narration_path", "")
	# Read the EXACT description that is displayed in the popup
	var narration_text = current_data.get("description", "")
	
	# Priority 1: High Quality Pre-rendered Audio (ElevenLabs Laura file)
	if not audio_path.is_empty() and ResourceLoader.exists(audio_path):
		var stream = load(audio_path)
		if stream is AudioStream:
			is_using_elevenlabs_file = true
			audio_stream_player.stream = stream
			audio_stream_player.play()
			is_audio_playing = true
			is_audio_paused = false
			play_audio_btn.text = "⏸️ Pause Narration"
			stop_audio_btn.visible = true
			audio_status_label.text = "▶️ Playing Laura's Narration..."
			return
			
	# Priority 2: Built-in Text-To-Speech (reads the exact description text)
	if not narration_text.is_empty():
		is_using_elevenlabs_file = false
		var voices = DisplayServer.tts_get_voices()
		var selected_voice = ""
		if not voices.is_empty():
			selected_voice = voices[0]["id"]
			# Prefer natural English female voices (Zira / Laura / Hazel / Catherine)
			for v in voices:
				var v_name = v.get("name", "").to_lower()
				var v_id = v.get("id", "").to_lower()
				var v_lang = v.get("language", "").to_lower()
				if "en" in v_lang or "en" in v_id:
					if "zira" in v_name or "laura" in v_name or "female" in v_name or "natural" in v_name:
						selected_voice = v["id"]
						break
					selected_voice = v["id"]
					
		DisplayServer.tts_stop()
		DisplayServer.tts_speak(narration_text, selected_voice, 50, 1.0, 1.0, current_utterance_id, true)
		current_utterance_id += 1
		is_audio_playing = true
		is_audio_paused = false
		play_audio_btn.text = "⏸️ Pause Narration"
		stop_audio_btn.visible = true
		audio_status_label.text = "▶️ Reading Aloud Exact Text..."

func pause_audio_narration() -> void:
	is_audio_paused = true
	play_audio_btn.text = "▶️ Resume Narration"
	audio_status_label.text = "⏸️ Narration Paused"
	
	if is_using_elevenlabs_file:
		audio_stream_player.stream_paused = true
	else:
		DisplayServer.tts_pause()

func resume_audio_narration() -> void:
	is_audio_paused = false
	play_audio_btn.text = "⏸️ Pause Narration"
	audio_status_label.text = "▶️ Playing Narration..."
	
	if is_using_elevenlabs_file:
		audio_stream_player.stream_paused = false
	else:
		DisplayServer.tts_resume()

func stop_audio_narration() -> void:
	is_audio_playing = false
	is_audio_paused = false
	play_audio_btn.text = "🔊 Read Aloud (Laura)"
	stop_audio_btn.visible = false
	audio_status_label.text = "🎙️ Narration Stopped"
	
	if audio_stream_player and audio_stream_player.playing:
		audio_stream_player.stop()
		audio_stream_player.stream_paused = false
		
	DisplayServer.tts_stop()

func _on_audio_stream_finished() -> void:
	is_audio_playing = false
	is_audio_paused = false
	play_audio_btn.text = "🔊 Read Aloud Again"
	stop_audio_btn.visible = false
	audio_status_label.text = "✅ Narration Complete"

func _on_source_btn_pressed() -> void:
	var url = current_data.get("source_url", "")
	if not url.is_empty():
		OS.shell_open(url)

# -----------------------------------------------------------------------------
# Player Input Safety Lock
# -----------------------------------------------------------------------------
func _toggle_player_controls(enabled: bool) -> void:
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if p.has_method("set_movement_enabled"):
			p.set_movement_enabled(enabled)
		elif p.has_method("set_physics_process"):
			p.set_physics_process(enabled)
			p.set_process_unhandled_input(enabled)
