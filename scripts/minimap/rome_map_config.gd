# -----------------------------------------------------------------------------
# rome_map_config.gd
# Specific floor configuration and architectural blueprints for the Roman Colosseum.
# -----------------------------------------------------------------------------
class_name RomeMapConfig
extends RefCounted

const MapFloorData = preload("res://scripts/minimap/map_floor_data.gd")

static func create_rome_floors() -> Array:
	var floors: Array = []
	
	# -------------------------------------------------------------------------
	# 1. Exterior Plaza & Colosseum Surroundings
	# -------------------------------------------------------------------------
	var plaza = MapFloorData.new("colosseum_exterior", "Exterior - Colosseum Plaza", "Plaza", -10.0, 1.5, true)
	plaza.world_bounds = Rect2(Vector2(-220.0, -220.0), Vector2(440.0, 440.0))
	plaza.floor_accent_color = Color(0.95, 0.78, 0.35, 1.0) # Roman Travertine Gold
	plaza.radar_zoom = 0.75
	plaza.layout_elements = [
		# Outer Amphitheatre Wall Ellipse (approx 142m x 137m radius)
		{
			"type": "ellipse",
			"rect": Rect2(Vector2(-142.0, -137.0), Vector2(284.0, 274.0)),
			"label": "Flavian Amphitheatre (Outer Wall)",
			"color": Color(0.18, 0.22, 0.30, 0.9)
		},
		# Inner Arena Ellipse (approx 83m x 48m radius)
		{
			"type": "ellipse",
			"rect": Rect2(Vector2(-83.0, -48.0), Vector2(166.0, 96.0)),
			"label": "Arena Core",
			"color": Color(0.12, 0.14, 0.18, 0.8)
		},
		# South Entrance Plaza & Player Spawn Avenue
		{
			"type": "rect",
			"rect": Rect2(Vector2(-35.0, 130.0), Vector2(70.0, 60.0)),
			"label": "Grand Entrance Plaza & Spawn",
			"color": Color(0.22, 0.28, 0.38, 0.8)
		},
		# East-West Ceremonial Avenue
		{
			"type": "rect",
			"rect": Rect2(Vector2(-200.0, -15.0), Vector2(400.0, 30.0)),
			"label": "Via Triumphalis Avenue",
			"color": Color(0.15, 0.18, 0.24, 0.6)
		}
	]
	floors.append(plaza)
	
	# -------------------------------------------------------------------------
	# 2. Gladiatorial Arena & Hypogeum
	# -------------------------------------------------------------------------
	var arena = MapFloorData.new("colosseum_arena", "Arena Floor & Hypogeum", "Arena", 1.5, 6.0, false)
	arena.world_bounds = Rect2(Vector2(-130.0, -120.0), Vector2(260.0, 240.0))
	arena.floor_accent_color = Color(0.95, 0.55, 0.22, 1.0) # Crimson Sand
	arena.radar_zoom = 1.1
	arena.layout_elements = [
		# Outer Podium Boundary
		{
			"type": "ellipse",
			"rect": Rect2(Vector2(-95.0, -60.0), Vector2(190.0, 120.0)),
			"label": "Podium Marble Wall",
			"color": Color(0.16, 0.20, 0.28, 0.9)
		},
		# Sand Arena Floor (Harena)
		{
			"type": "ellipse",
			"rect": Rect2(Vector2(-83.0, -48.0), Vector2(166.0, 96.0)),
			"label": "Arena Sand Floor (Harena)",
			"color": Color(0.32, 0.24, 0.14, 0.85)
		},
		# Central Subterranean Hypogeum Corridor
		{
			"type": "rect",
			"rect": Rect2(Vector2(-25.0, -6.0), Vector2(50.0, 12.0)),
			"label": "Hypogeum Subterranean Shafts",
			"color": Color(0.12, 0.10, 0.16, 0.95)
		},
		# East Gate (Porta Triumphalis)
		{
			"type": "portal",
			"rect": Rect2(Vector2(-45.0, 17.0), Vector2(16.0, 16.0)),
			"label": "Porta Triumphalis (Gate of Life)",
			"color": Color(0.95, 0.80, 0.25, 0.95)
		},
		# West Gate (Porta Libitinaria)
		{
			"type": "portal",
			"rect": Rect2(Vector2(29.0, -38.0), Vector2(16.0, 16.0)),
			"label": "Porta Libitinaria (Gate of Death)",
			"color": Color(0.70, 0.25, 0.25, 0.95)
		},
		# Imperial Pulvinar Box (South Podium)
		{
			"type": "room",
			"rect": Rect2(Vector2(-27.0, -35.0), Vector2(16.0, 15.0)),
			"label": "Imperial Pulvinar Box",
			"color": Color(0.48, 0.15, 0.38, 0.95)
		}
	]
	floors.append(arena)
	
	# -------------------------------------------------------------------------
	# 3. Cavea Seating & Upper Colonnade
	# -------------------------------------------------------------------------
	var cavea = MapFloorData.new("colosseum_cavea", "Cavea Seating & Upper Rim", "Cavea", 6.0, 60.0, false)
	cavea.world_bounds = Rect2(Vector2(-160.0, -150.0), Vector2(320.0, 300.0))
	cavea.floor_accent_color = Color(0.85, 0.75, 0.95, 1.0) # Imperial Purple / Marble
	cavea.radar_zoom = 0.8
	cavea.layout_elements = [
		# Attic Rim & Velarium Masts
		{
			"type": "ellipse",
			"rect": Rect2(Vector2(-142.0, -137.0), Vector2(284.0, 274.0)),
			"label": "Attic Colonnade & Velarium Masts",
			"color": Color(0.22, 0.18, 0.28, 0.9)
		},
		# Media Cavea (Citizen Tiers)
		{
			"type": "ellipse",
			"rect": Rect2(Vector2(-115.0, -95.0), Vector2(230.0, 190.0)),
			"label": "Media Cavea (Citizen Tiers)",
			"color": Color(0.18, 0.22, 0.30, 0.85)
		},
		# Ima Cavea (Senatorial Podium)
		{
			"type": "ellipse",
			"rect": Rect2(Vector2(-90.0, -55.0), Vector2(180.0, 110.0)),
			"label": "Ima Cavea & Senatorial Tier",
			"color": Color(0.24, 0.28, 0.36, 0.85)
		},
		# Arena void in center
		{
			"type": "ellipse",
			"rect": Rect2(Vector2(-75.0, -42.0), Vector2(150.0, 84.0)),
			"label": "Arena Void (Open Air)",
			"color": Color(0.08, 0.10, 0.14, 0.95)
		}
	]
	floors.append(cavea)
	
	return floors
