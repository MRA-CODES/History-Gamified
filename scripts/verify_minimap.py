import os
import re

def check_minimap():
    files_to_check = [
        "scripts/minimap/map_floor_data.gd",
        "scripts/minimap/nhm_map_config.gd",
        "scripts/minimap/map_manager.gd",
        "scenes/minimap/minimap_hud.gd",
        "scenes/minimap/full_map_view.gd",
        "scenes/minimap/blueprint_canvas.gd",
        "scenes/minimap/minimap.tscn",
        "scenes/church_exterior.tscn",
        "scripts/church_exterior.gd"
    ]
    
    print("=== Checking Minimap System Files ===")
    for path in files_to_check:
        if os.path.exists(path):
            print(f"[OK] Found {path} ({os.path.getsize(path)} bytes)")
        else:
            print(f"[ERROR] Missing {path}")
            return False
            
    # Check scene connections in minimap.tscn
    with open("scenes/minimap/minimap.tscn", "r", encoding="utf-8") as f:
        content = f.read()
        assert 'ExtResource("1_manager")' in content
        assert 'ExtResource("2_hud")' in content
        assert 'ExtResource("3_fullmap")' in content
        assert 'ExtResource("4_canvas")' in content
        print("[OK] minimap.tscn has all expected script resources")

    # Check church_exterior.tscn
    with open("scenes/church_exterior.tscn", "r", encoding="utf-8") as f:
        church_tscn = f.read()
        assert 'path="res://scenes/minimap/minimap.tscn"' in church_tscn
        assert '[node name="MinimapUI"' in church_tscn
        print("[OK] church_exterior.tscn has MinimapUI instanced correctly")

    print("\n>>> ALL MINIMAP INTEGRITY CHECKS PASSED! <<<")
    return True

if __name__ == "__main__":
    check_minimap()
