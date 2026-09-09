@tool
extends Node3D

## Procedural Roman Stone Road, Grand Plaza & Colosseum Void Sealing Collar
const MATERIAL_PATH: String = "res://assets/materials/roman_stone_road.tres"

@export var road_elevation: float = 0.1
@export var inner_radius: float = 120.0
@export var outer_radius: float = 480.0
@export var skirt_depth: float = 6.0
@export var segments: int = 128

var mesh_instance: MeshInstance3D = null
var static_body: StaticBody3D = null

func _ready() -> void:
	# Check if already generated in this node
	if get_node_or_null("RoadMesh") != null:
		return
	_build_ground_system()

func _build_ground_system() -> void:
	var stone_mat: Material = load(MATERIAL_PATH)
	if not stone_mat:
		push_warning("Could not load Roman stone road material from: " + MATERIAL_PATH)
		var fallback_mat = StandardMaterial3D.new()
		fallback_mat.albedo_color = Color(0.78, 0.72, 0.65, 1.0)
		fallback_mat.roughness = 0.85
		stone_mat = fallback_mat

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(stone_mat)

	var angles: Array[float] = []
	for i in range(segments):
		angles.append(i * (TAU / float(segments)))

	# Concentric rings spanning under Colosseum wall (137-142m) to outer city
	var radii: Array[float] = [
		inner_radius,        # 120m: tucked safely under arcade promenade
		136.0,               # 136m: outer wall interior footing
		146.0,               # 146m: outer wall exterior footing (seals perimeter void)
		175.0,               # 175m: grand pedestrian promenade
		230.0,               # 230m: forum avenue ring
		330.0,               # 330m: district road ring
		outer_radius         # 480m: city edge ring
	]

	# Helper to compute world UVs
	var uv_scale = 0.35

	# 1. Top Surface Concentric Rings at road_elevation
	for ring_i in range(radii.size() - 1):
		var r_curr = radii[ring_i]
		var r_next = radii[ring_i + 1]
		
		for j in range(segments):
			var j_next = (j + 1) % segments
			var a1 = angles[j]
			var a2 = angles[j_next]
			
			var p1 = Vector3(r_curr * cos(a1), road_elevation, r_curr * sin(a1))
			var p2 = Vector3(r_curr * cos(a2), road_elevation, r_curr * sin(a2))
			var p3 = Vector3(r_next * cos(a2), road_elevation, r_next * sin(a2))
			var p4 = Vector3(r_next * cos(a1), road_elevation, r_next * sin(a1))
			
			var n = Vector3.UP
			
			# Tri 1: p1 -> p3 -> p2 (CCW when viewed from above +Y)
			st.set_normal(n)
			st.set_uv(Vector2(p1.x * uv_scale, p1.z * uv_scale))
			st.add_vertex(p1)
			
			st.set_normal(n)
			st.set_uv(Vector2(p3.x * uv_scale, p3.z * uv_scale))
			st.add_vertex(p3)
			
			st.set_normal(n)
			st.set_uv(Vector2(p2.x * uv_scale, p2.z * uv_scale))
			st.add_vertex(p2)
			
			# Tri 2: p1 -> p4 -> p3 (CCW when viewed from above +Y)
			st.set_normal(n)
			st.set_uv(Vector2(p1.x * uv_scale, p1.z * uv_scale))
			st.add_vertex(p1)
			
			st.set_normal(n)
			st.set_uv(Vector2(p4.x * uv_scale, p4.z * uv_scale))
			st.add_vertex(p4)
			
			st.set_normal(n)
			st.set_uv(Vector2(p3.x * uv_scale, p3.z * uv_scale))
			st.add_vertex(p3)

	# 2. Outer apron connecting outer circle (480m) to square boundary [-520, 520] x [-520, 520]
	var box_w = 520.0
	var box_pts = [
		Vector2(box_w, box_w), Vector2(0.0, box_w), Vector2(-box_w, box_w), Vector2(-box_w, 0.0),
		Vector2(-box_w, -box_w), Vector2(0.0, -box_w), Vector2(box_w, -box_w), Vector2(box_w, 0.0)
	]
	var r_outer = radii[radii.size() - 1]
	for j in range(segments):
		var j_next = (j + 1) % segments
		var a1 = angles[j]
		var a2 = angles[j_next]
		
		var p_inner1 = Vector3(r_outer * cos(a1), road_elevation, r_outer * sin(a1))
		var p_inner2 = Vector3(r_outer * cos(a2), road_elevation, r_outer * sin(a2))
		
		var sec1 = int(floor((float(j) / float(segments)) * 8.0)) % 8
		var sec2 = int(floor((float(j_next) / float(segments)) * 8.0)) % 8
		var bp1 = box_pts[sec1]
		var bp2 = box_pts[sec2]
		var p_box1 = Vector3(bp1.x, road_elevation, bp1.y)
		var p_box2 = Vector3(bp2.x, road_elevation, bp2.y)
		
		var n = Vector3.UP
		if sec1 == sec2:
			st.set_normal(n)
			st.set_uv(Vector2(p_inner1.x * uv_scale, p_inner1.z * uv_scale))
			st.add_vertex(p_inner1)
			st.set_normal(n)
			st.set_uv(Vector2(p_box1.x * uv_scale, p_box1.z * uv_scale))
			st.add_vertex(p_box1)
			st.set_normal(n)
			st.set_uv(Vector2(p_inner2.x * uv_scale, p_inner2.z * uv_scale))
			st.add_vertex(p_inner2)
		else:
			st.set_normal(n)
			st.set_uv(Vector2(p_inner1.x * uv_scale, p_inner1.z * uv_scale))
			st.add_vertex(p_inner1)
			st.set_normal(n)
			st.set_uv(Vector2(p_box2.x * uv_scale, p_box2.z * uv_scale))
			st.add_vertex(p_box2)
			st.set_normal(n)
			st.set_uv(Vector2(p_inner2.x * uv_scale, p_inner2.z * uv_scale))
			st.add_vertex(p_inner2)

			st.set_normal(n)
			st.set_uv(Vector2(p_inner1.x * uv_scale, p_inner1.z * uv_scale))
			st.add_vertex(p_inner1)
			st.set_normal(n)
			st.set_uv(Vector2(p_box1.x * uv_scale, p_box1.z * uv_scale))
			st.add_vertex(p_box1)
			st.set_normal(n)
			st.set_uv(Vector2(p_box2.x * uv_scale, p_box2.z * uv_scale))
			st.add_vertex(p_box2)

	# 3. Inner Foundation Skirt (Void Seal at r = 120m down to Y = -skirt_depth)
	var y_bot = road_elevation - skirt_depth
	for j in range(segments):
		var j_next = (j + 1) % segments
		var a1 = angles[j]
		var a2 = angles[j_next]
		
		var p_top1 = Vector3(inner_radius * cos(a1), road_elevation, inner_radius * sin(a1))
		var p_top2 = Vector3(inner_radius * cos(a2), road_elevation, inner_radius * sin(a2))
		var p_bot1 = Vector3(inner_radius * cos(a1), y_bot, inner_radius * sin(a1))
		var p_bot2 = Vector3(inner_radius * cos(a2), y_bot, inner_radius * sin(a2))
		
		var n = Vector3(cos(a1), 0.0, sin(a1))
		
		# Tri 1
		st.set_normal(n)
		st.set_uv(Vector2(p_top1.x * uv_scale, p_top1.y * uv_scale))
		st.add_vertex(p_top1)
		st.set_normal(n)
		st.set_uv(Vector2(p_bot2.x * uv_scale, p_bot2.y * uv_scale))
		st.add_vertex(p_bot2)
		st.set_normal(n)
		st.set_uv(Vector2(p_bot1.x * uv_scale, p_bot1.y * uv_scale))
		st.add_vertex(p_bot1)
		
		# Tri 2
		st.set_normal(n)
		st.set_uv(Vector2(p_top1.x * uv_scale, p_top1.y * uv_scale))
		st.add_vertex(p_top1)
		st.set_normal(n)
		st.set_uv(Vector2(p_top2.x * uv_scale, p_top2.y * uv_scale))
		st.add_vertex(p_top2)
		st.set_normal(n)
		st.set_uv(Vector2(p_bot2.x * uv_scale, p_bot2.y * uv_scale))
		st.add_vertex(p_bot2)

	# 4. Under-Foundation Bedrock Slab between r = 120m and r = 146m at y_bot
	var r_foot = 146.0
	for j in range(segments):
		var j_next = (j + 1) % segments
		var a1 = angles[j]
		var a2 = angles[j_next]
		
		var p_in1 = Vector3(inner_radius * cos(a1), y_bot, inner_radius * sin(a1))
		var p_in2 = Vector3(inner_radius * cos(a2), y_bot, inner_radius * sin(a2))
		var p_out1 = Vector3(r_foot * cos(a1), y_bot, r_foot * sin(a1))
		var p_out2 = Vector3(r_foot * cos(a2), y_bot, r_foot * sin(a2))
		
		var n = Vector3.UP
		st.set_normal(n)
		st.set_uv(Vector2(p_in1.x * uv_scale, p_in1.z * uv_scale))
		st.add_vertex(p_in1)
		st.set_normal(n)
		st.set_uv(Vector2(p_out1.x * uv_scale, p_out1.z * uv_scale))
		st.add_vertex(p_out1)
		st.set_normal(n)
		st.set_uv(Vector2(p_out2.x * uv_scale, p_out2.z * uv_scale))
		st.add_vertex(p_out2)

		st.set_normal(n)
		st.set_uv(Vector2(p_in1.x * uv_scale, p_in1.z * uv_scale))
		st.add_vertex(p_in1)
		st.set_normal(n)
		st.set_uv(Vector2(p_out2.x * uv_scale, p_out2.z * uv_scale))
		st.add_vertex(p_out2)
		st.set_normal(n)
		st.set_uv(Vector2(p_in2.x * uv_scale, p_in2.z * uv_scale))
		st.add_vertex(p_in2)

	var mesh: ArrayMesh = st.commit()

	# Create MeshInstance3D
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "RoadMesh"
	mesh_instance.mesh = mesh
	add_child(mesh_instance)

	# Create Solid Collision
	static_body = StaticBody3D.new()
	static_body.name = "RoadStaticBody"
	var col_shape = CollisionShape3D.new()
	col_shape.name = "RoadColShape"
	var trimesh: Shape3D = mesh.create_trimesh_shape()
	if trimesh is ConcavePolygonShape3D:
		trimesh.backface_collision = true
	col_shape.shape = trimesh
	static_body.add_child(col_shape)
	add_child(static_body)
