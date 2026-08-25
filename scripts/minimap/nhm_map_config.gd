# -----------------------------------------------------------------------------
# nhm_map_config.gd
# Specific floor configuration and architectural blueprints for the Natural History Museum.
# -----------------------------------------------------------------------------
class_name NHMMapConfig
extends RefCounted

const MapFloorData = preload("res://scripts/minimap/map_floor_data.gd")

static func create_nhm_floors() -> Array:
	var floors: Array = []
	
	# -------------------------------------------------------------------------
	# 1. Exterior Plaza
	# -------------------------------------------------------------------------
	var plaza = MapFloorData.new("exterior_plaza", "Exterior - Museum Plaza", "Plaza", -10.0, 10.0, true)
	plaza.world_bounds = Rect2(Vector2(-35.0, 18.0), Vector2(70.0, 50.0))
	plaza.floor_accent_color = Color(0.35, 0.70, 0.95, 1.0)
	plaza.layout_elements = [
		{
			"type": "rect",
			"rect": Rect2(Vector2(-30.0, 22.0), Vector2(60.0, 42.0)),
			"label": "Waterhouse Plaza & Gardens",
			"color": Color(0.12, 0.16, 0.22, 0.9)
		},
		{
			"type": "rect",
			"rect": Rect2(Vector2(-12.0, 20.0), Vector2(24.0, 12.0)),
			"label": "Grand Entrance Steps",
			"color": Color(0.18, 0.24, 0.32, 0.95)
		},
		{
			"type": "portal",
			"rect": Rect2(Vector2(-4.0, 31.0), Vector2(8.0, 3.0)),
			"label": "Hintze Hall Main Portal",
			"color": Color(0.9, 0.7, 0.2, 1.0)
		}
	]
	floors.append(plaza)
	
	# -------------------------------------------------------------------------
	# 2. Ground Floor (Hintze Hall)
	# -------------------------------------------------------------------------
	var ground = MapFloorData.new("ground_floor", "Ground Floor - Hintze Hall", "Ground", 0.0, 6.5, false)
	ground.world_bounds = Rect2(Vector2(-18.0, -35.0), Vector2(36.0, 60.0))
	ground.floor_accent_color = Color(0.95, 0.75, 0.25, 1.0)
	ground.layout_elements = [
		# Main Nave boundary
		{
			"type": "rect",
			"rect": Rect2(Vector2(-16.0, -32.0), Vector2(32.0, 54.0)),
			"label": "Hintze Hall Grand Nave",
			"color": Color(0.10, 0.12, 0.16, 0.92)
		},
		# Central aisle
		{
			"type": "hall",
			"rect": Rect2(Vector2(-5.0, -20.0), Vector2(10.0, 40.0)),
			"label": "Central Promenade",
			"color": Color(0.14, 0.17, 0.24, 0.85)
		},
		# Whale skeleton outline
		{
			"type": "whale_outline",
			"rect": Rect2(Vector2(-3.5, -8.0), Vector2(7.0, 16.0)),
			"label": "Hope the Whale (Suspended Above)",
			"color": Color(0.25, 0.55, 0.85, 0.4)
		},
		# West Alcoves (Paleontology & Mammals)
		{
			"type": "room",
			"rect": Rect2(Vector2(-15.5, 4.0), Vector2(9.0, 12.0)),
			"label": "West Alcove (Mammoth & Hypsilophodon)",
			"color": Color(0.16, 0.20, 0.28, 0.9)
		},
		# East Alcoves (Comparative Anatomy & Giraffe)
		{
			"type": "room",
			"rect": Rect2(Vector2(6.5, 4.0), Vector2(9.0, 12.0)),
			"label": "East Alcove (Giraffe Specimen)",
			"color": Color(0.16, 0.20, 0.28, 0.9)
		},
		# Grand Staircase base
		{
			"type": "stairs",
			"rect": Rect2(Vector2(-7.0, -26.0), Vector2(14.0, 8.0)),
			"label": "Grand Central Staircase",
			"color": Color(0.22, 0.26, 0.35, 0.95)
		},
		# Entrance Foyer
		{
			"type": "portal",
			"rect": Rect2(Vector2(-6.0, 18.0), Vector2(12.0, 5.0)),
			"label": "South Entrance Foyer",
			"color": Color(0.20, 0.25, 0.35, 0.9)
		}
	]
	floors.append(ground)
	
	# -------------------------------------------------------------------------
	# 3. 1st Floor (Galleries & Balcony)
	# -------------------------------------------------------------------------
	var first = MapFloorData.new("first_floor", "1st Floor - Galleries & Balcony", "1st Floor", 6.5, 13.0, false)
	first.world_bounds = Rect2(Vector2(-18.0, -35.0), Vector2(36.0, 60.0))
	first.floor_accent_color = Color(0.45, 0.85, 0.55, 1.0) # Emerald
	first.layout_elements = [
		# Outer building envelope
		{
			"type": "rect",
			"rect": Rect2(Vector2(-16.0, -32.0), Vector2(32.0, 54.0)),
			"label": "1st Floor Perimeter Gallery",
			"color": Color(0.09, 0.11, 0.15, 0.92)
		},
		# Central Atrium Void (Hole looking down to ground floor)
		{
			"type": "void",
			"rect": Rect2(Vector2(-7.0, -18.0), Vector2(14.0, 36.0)),
			"label": "Hintze Hall Central Void (Open Air)",
			"color": Color(0.05, 0.06, 0.08, 0.6)
		},
		# West Gallery (Birds & Ornithology)
		{
			"type": "room",
			"rect": Rect2(Vector2(-15.5, -15.0), Vector2(8.0, 30.0)),
			"label": "West Gallery (Hummingbird Cabinet)",
			"color": Color(0.14, 0.19, 0.25, 0.9)
		},
		# East Gallery (Mineralogy)
		{
			"type": "room",
			"rect": Rect2(Vector2(7.5, -15.0), Vector2(8.0, 30.0)),
			"label": "East Gallery (Cranbourne Meteorite)",
			"color": Color(0.14, 0.19, 0.25, 0.9)
		},
		# Darwin Staircase Upper Landing (Darwin Statue & Dodo)
		{
			"type": "room",
			"rect": Rect2(Vector2(-14.0, -30.0), Vector2(28.0, 11.0)),
			"label": "North Landing (Darwin Statue & Dodo)",
			"color": Color(0.18, 0.24, 0.32, 0.95)
		},
		# South Bridge Walkway (Richard Owen)
		{
			"type": "hall",
			"rect": Rect2(Vector2(-8.0, 18.0), Vector2(16.0, 6.0)),
			"label": "South Bridge Walkway (Richard Owen Statue)",
			"color": Color(0.18, 0.24, 0.32, 0.95)
		}
	]
	floors.append(first)
	
	# -------------------------------------------------------------------------
	# 4. 2nd Floor (Upper Mezzanine & Vault)
	# -------------------------------------------------------------------------
	var second = MapFloorData.new("second_floor", "2nd Floor - Mezzanine & Vault", "2nd Floor", 13.0, 30.0, false)
	second.world_bounds = Rect2(Vector2(-18.0, -35.0), Vector2(36.0, 60.0))
	second.floor_accent_color = Color(0.85, 0.45, 0.90, 1.0) # Violet / Amethyst
	second.layout_elements = [
		# Outer building envelope
		{
			"type": "rect",
			"rect": Rect2(Vector2(-16.0, -32.0), Vector2(32.0, 54.0)),
			"label": "2nd Floor Upper Mezzanine",
			"color": Color(0.08, 0.10, 0.14, 0.92)
		},
		# Large Atrium Void
		{
			"type": "void",
			"rect": Rect2(Vector2(-8.5, -20.0), Vector2(17.0, 40.0)),
			"label": "Upper Atrium Void",
			"color": Color(0.04, 0.05, 0.07, 0.6)
		},
		# Upper Mezzanine South Wall (Giant Sequoia Cross-Section)
		{
			"type": "room",
			"rect": Rect2(Vector2(-9.0, 19.0), Vector2(18.0, 6.0)),
			"label": "Upper Mezzanine (Giant Sequoia Slice)",
			"color": Color(0.20, 0.16, 0.28, 0.95)
		},
		# West Upper Gallery (Blaschka Glass Models)
		{
			"type": "room",
			"rect": Rect2(Vector2(-15.5, -15.0), Vector2(6.5, 28.0)),
			"label": "West Upper Gallery (Blaschka Glass Models)",
			"color": Color(0.16, 0.14, 0.25, 0.9)
		},
		# East Upper Gallery (The Vault)
		{
			"type": "room",
			"rect": Rect2(Vector2(9.0, -15.0), Vector2(6.5, 28.0)),
			"label": "The Vault Gallery",
			"color": Color(0.22, 0.14, 0.28, 0.9)
		},
		# Central Cathedral Architecture Vista Arch
		{
			"type": "hall",
			"rect": Rect2(Vector2(-6.0, 13.0), Vector2(12.0, 5.0)),
			"label": "Cathedral Architecture Vista Arch",
			"color": Color(0.18, 0.16, 0.26, 0.95)
		}
	]
	floors.append(second)
	
	return floors
