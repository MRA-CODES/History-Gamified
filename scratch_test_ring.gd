extends Node3D

func _ready():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var inner_r = 31.5
	var outer_r = 500.0
	var segments = 64
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.49, 0.20, 1.0)
	mat.roughness = 0.95
	st.set_material(mat)
	
	for i in range(segments):
		var a1 = (float(i) / segments) * TAU
		var a2 = (float(i + 1) / segments) * TAU
		
		var p1_in = Vector3(cos(a1) * inner_r, -0.2, sin(a1) * inner_r)
		var p2_in = Vector3(cos(a2) * inner_r, -0.2, sin(a2) * inner_r)
		var p1_out = Vector3(cos(a1) * outer_r, -0.5, sin(a1) * outer_r)
		var p2_out = Vector3(cos(a2) * outer_r, -0.5, sin(a2) * outer_r)
		
		# Quad 1: p1_in, p1_out, p2_out
		st.set_normal(Vector3.UP)
		st.add_vertex(p1_in)
		st.set_normal(Vector3.UP)
		st.add_vertex(p1_out)
		st.set_normal(Vector3.UP)
		st.add_vertex(p2_out)
		
		# Quad 2: p1_in, p2_out, p2_in
		st.set_normal(Vector3.UP)
		st.add_vertex(p1_in)
		st.set_normal(Vector3.UP)
		st.add_vertex(p2_out)
		st.set_normal(Vector3.UP)
		st.add_vertex(p2_in)
		
	var mesh = st.commit()
	print("Annular mesh created successfully! Surfaces:", mesh.get_surface_count())
	quit()
