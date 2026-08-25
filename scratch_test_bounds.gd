extends SceneTree

func _init():
	var scene = load("res://scenes/stonehenge_map.tscn").instantiate()
	root.add_child(scene)
	
	print("--- SCENE NODES ---")
	var model = scene.get_node("StonehengeModel")
	var player = scene.get_node("Player")
	
	print("Model Transform:", model.global_transform)
	print("Player Transform:", player.global_transform)
	
	# Check mesh global bounding boxes
	_print_global_bounds(model)
	quit()

func _print_global_bounds(n: Node):
	if n is MeshInstance3D and n.mesh:
		var aabb = n.mesh.get_aabb()
		var g_trans = n.global_transform
		var center = g_trans * aabb.get_center()
		var p_min = g_trans * aabb.position
		var p_max = g_trans * (aabb.position + aabb.size)
		print(n.name, "Center:", center, "Y range:", min(p_min.y, p_max.y), "to", max(p_min.y, p_max.y))
	for c in n.get_children():
		_print_global_bounds(c)
