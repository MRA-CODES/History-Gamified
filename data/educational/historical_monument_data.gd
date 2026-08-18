# -----------------------------------------------------------------------------
# historical_monument_data.gd
# Custom Godot Resource representing an educational museum exhibit or monument.
# -----------------------------------------------------------------------------
class_name HistoricalMonumentData
extends Resource

@export var id: String = ""
@export var title: String = ""
@export var subtitle_or_era: String = ""
@export var category: String = "Exhibit" # e.g. Paleontology, Victorian Architecture, Zoology
@export_multiline var description: String = ""
@export var key_facts: Array[String] = []
@export var source_name: String = "Wikipedia"
@export var source_url: String = ""
@export var image_path: String = ""
@export var audio_narration_path: String = "" # Path to ElevenLabs .mp3 / .ogg file if available
@export var audio_narration_text: String = "" # Spoken script for ElevenLabs or built-in TTS

static func from_dictionary(dict: Dictionary) -> HistoricalMonumentData:
	var data = HistoricalMonumentData.new()
	data.id = dict.get("id", "")
	data.title = dict.get("title", "Unknown Monument")
	data.subtitle_or_era = dict.get("subtitle_or_era", "")
	data.category = dict.get("category", "Exhibit")
	data.description = dict.get("description", "")
	
	var facts = dict.get("key_facts", [])
	var fact_array: Array[String] = []
	for f in facts:
		fact_array.append(str(f))
	data.key_facts = fact_array
	
	data.source_name = dict.get("source_name", "Wikipedia")
	data.source_url = dict.get("source_url", "")
	data.image_path = dict.get("image_path", "")
	data.audio_narration_path = dict.get("audio_narration_path", "")
	data.audio_narration_text = dict.get("audio_narration_text", data.description)
	return data
