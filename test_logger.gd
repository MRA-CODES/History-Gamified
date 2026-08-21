extends Node

func _ready():
	print("--- INSPECTING CHURCH_EXTERIOR.TSCN ---")
	var root = get_tree().current_scene
	print("Current scene name:", root.name if root else "null")
	if root:
		for c in root.get_children():
			print("Child:", c.name, "Visible:", c.get("visible"), "Type:", c.get_class())
			if c.name == "CityEnvironment":
				print("  City Environment Child Count:", c.get_child_count())
				for sub in c.get_children():
					print("    Group:", sub.name, "Count:", sub.get_child_count(), "Visible:", sub.get("visible"))
