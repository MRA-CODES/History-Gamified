extends SceneTree

func _init():
	var scene = load("res://assets/environment/buildings/Map 2-StoneHenge/StoneHenge Big.glb").instantiate()
	root.add_child(scene)
	
	# Find all meshes and print their AABB
	print("--- INSTANTIATED GLB MESHES ---")
	_inspect_node(scene, 0)
	quit()

func _inspect_node(node: Node, depth: int):
	var indent = "  ".repeat(depth)
	if node is VisualInstance3D:
		var aabb = node.get_aabb()
		print(indent + node.name + " (" + node.get_class() + ") AABB: " + str(aabb) + " GlobalPos: " + str(node.global_position))
	else:
		print(indent + node.name + " (" + node.get_class() + ")")
	for c in node.get_children():
		_inspect_node(c, depth + 1)
