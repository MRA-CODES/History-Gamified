extends Node3D

func _ready():
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = 1337
	noise.frequency = 0.008
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.4
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var inner_r = 49.0
	var outer_r = 650.0
	var radial_steps = 80
	var ring_steps = 16
	
	print("Generating Salisbury plain 3D terrain mesh...")
	# Sample heights
	for ring in range(ring_steps):
		var t1 = float(ring) / float(ring_steps)
		var t2 = float(ring + 1) / float(ring_steps)
		
		# Smooth radial curve from inner to outer
		var r1 = lerp(inner_r, outer_r, pow(t1, 1.3))
		var r2 = lerp(inner_r, outer_r, pow(t2, 1.3))
		
		# Inner edge has 0 noise weight to match Stonehenge edge; outer has full rolling hills
		var w1 = clampf((r1 - inner_r) / 40.0, 0.0, 1.0)
		var w2 = clampf((r2 - inner_r) / 40.0, 0.0, 1.0)
		
		for rad in range(radial_steps):
			var a1 = (float(rad) / radial_steps) * TAU
			var a2 = (float(rad + 1) / radial_steps) * TAU
			
			var x1_1 = cos(a1) * r1
			var z1_1 = sin(a1) * r1
			var y1_1 = -0.2 + (noise.get_noise_2d(x1_1, z1_1) * 8.0 - 0.5) * w1
			
			var x1_2 = cos(a2) * r1
			var z1_2 = sin(a2) * r1
			var y1_2 = -0.2 + (noise.get_noise_2d(x1_2, z1_2) * 8.0 - 0.5) * w1
			
			var x2_1 = cos(a1) * r2
			var z2_1 = sin(a1) * r2
			var y2_1 = -0.2 + (noise.get_noise_2d(x2_1, z2_1) * 8.0 - 0.5) * w2
			
			var x2_2 = cos(a2) * r2
			var z2_2 = sin(a2) * r2
			var y2_2 = -0.2 + (noise.get_noise_2d(x2_2, z2_2) * 8.0 - 0.5) * w2
			
			var p1 = Vector3(x1_1, y1_1, z1_1)
			var p2 = Vector3(x1_2, y1_2, z1_2)
			var p3 = Vector3(x2_1, y2_1, z2_1)
			var p4 = Vector3(x2_2, y2_2, z2_2)
			
			# Triangle 1: p1, p3, p4
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(x1_1, z1_1) * 0.05)
			st.add_vertex(p1)
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(x2_1, z2_1) * 0.05)
			st.add_vertex(p3)
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(x2_2, z2_2) * 0.05)
			st.add_vertex(p4)
			
			# Triangle 2: p1, p4, p2
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(x1_1, z1_1) * 0.05)
			st.add_vertex(p1)
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(x2_2, z2_2) * 0.05)
			st.add_vertex(p4)
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(x1_2, z1_2) * 0.05)
			st.add_vertex(p2)
			
	st.generate_normals()
	var mesh = st.commit()
	print("Generated mesh with surfaces:", mesh.get_surface_count(), "Faces:", mesh.get_faces().size())
	quit()
