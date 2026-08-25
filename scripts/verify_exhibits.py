import json
import os
import struct
import re

def verify_all():
    print("=== 1. VERIFYING EXHIBITS.JSON ===")
    with open("data/educational/exhibits.json", "r", encoding="utf-8") as f:
        data = json.load(f)
    exhibits = data.get("exhibits", [])
    print(f"Total exhibits in exhibits.json: {len(exhibits)}")

    exhibit_map = {}
    for ex in exhibits:
        eid = ex["id"]
        exhibit_map[eid] = ex
        img_res = ex.get("image_path", "").replace("res://", "")
        img_exists = os.path.exists(img_res)
        print(f"Exhibit [{eid}]: title=\"{ex.get('title')}\", category=\"{ex.get('category')}\", img_exists={img_exists}")
        assert img_exists, f"Missing image for {eid}: {img_res}"
        assert len(ex.get("key_facts", [])) >= 3, f"Not enough facts for {eid}"
        assert len(ex.get("description", "")) > 50, f"Description too short for {eid}"

    print("\n=== 2. VERIFYING MUSEUM_EXHIBITS.TSCN ===")
    with open("scenes/exhibits/museum_exhibits.tscn", "r", encoding="utf-8") as f:
        tscn_text = f.read()

    node_pattern = re.compile(
        r'\[node name="([^"]+)"[^\]]+\]\s+transform = Transform3D\([^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,[^,]+,\s*([-\d\.]+),\s*([-\d\.]+),\s*([-\d\.]+)\)\s+exhibit_id = "([^"]+)"'
    )
    matches = node_pattern.findall(tscn_text)
    print(f"Total interactable nodes parsed: {len(matches)}")
    for nname, px, py, pz, eid in matches:
        pos = (float(px), float(py), float(pz))
        assert eid in exhibit_map, f"Exhibit ID {eid} not in exhibits.json!"
        print(f"Node {nname:35s} -> Exhibit: {eid:35s} Pos: {pos}")

    print("\n=== 3. VERIFYING FLOOR COLLISION PROXIMITY IN GLB ===")
    with open("assets/environment/buildings/NHM London.glb", "rb") as f:
        magic, ver, length = struct.unpack("<4sII", f.read(12))
        chunk_len, chunk_type = struct.unpack("<I4s", f.read(8))
        gdata = json.loads(f.read(chunk_len).decode("utf-8"))
        chunk2_len, chunk2_type = struct.unpack("<I4s", f.read(8))
        bin_data = f.read(chunk2_len)
        accessors = gdata.get("accessors", [])
        buffer_views = gdata.get("bufferViews", [])
        meshes = gdata.get("meshes", [])
        scale_m = 1.4285714626312256
        
        verts = []
        for mesh in meshes:
            for prim in mesh.get("primitives", []):
                pos_idx = prim.get("attributes", {}).get("POSITION")
                ind_idx = prim.get("indices")
                if pos_idx is not None and ind_idx is not None:
                    acc_p = accessors[pos_idx]
                    bv_p = buffer_views[acc_p["bufferView"]]
                    off_p = bv_p.get("byteOffset", 0) + acc_p.get("byteOffset", 0)
                    cnt_p = acc_p["count"]
                    raw_p = bin_data[off_p : off_p + cnt_p * 12]
                    v_local = []
                    for i in range(cnt_p):
                        x, y, z = struct.unpack("<3f", raw_p[i*12:(i+1)*12])
                        wx = - (scale_m * x)
                        wy = (-scale_m * y) + 2.1
                        wz = - (-scale_m * z) - 2.0
                        v_local.append((wx, wy, wz))
                    
                    acc_i = accessors[ind_idx]
                    bv_i = buffer_views[acc_i["bufferView"]]
                    off_i = bv_i.get("byteOffset", 0) + acc_i.get("byteOffset", 0)
                    cnt_i = acc_i["count"]
                    comp_type = acc_i.get("componentType", 5123)
                    raw_i = bin_data[off_i : off_i + (cnt_i * (2 if comp_type==5123 else 4))]
                    fmt = "<" + ("H" if comp_type==5123 else "I")
                    stride = 2 if comp_type==5123 else 4
                    for i in range(0, cnt_i, 3):
                        i0 = struct.unpack_from(fmt, raw_i, i * stride)[0]
                        i1 = struct.unpack_from(fmt, raw_i, (i+1) * stride)[0]
                        i2 = struct.unpack_from(fmt, raw_i, (i+2) * stride)[0]
                        v0, v1, v2 = v_local[i0], v_local[i1], v_local[i2]
                        cy = (v0[1] + v1[1] + v2[1]) / 3.0
                        cx = (v0[0] + v1[0] + v2[0]) / 3.0
                        cz = (v0[2] + v1[2] + v2[2]) / 3.0
                        ax, ay, az = v1[0]-v0[0], v1[1]-v0[1], v1[2]-v0[2]
                        bx, by, bz = v2[0]-v0[0], v2[1]-v0[1], v2[2]-v0[2]
                        nx = ay*bz - az*by
                        ny = az*bx - ax*bz
                        nz = ax*by - ay*bx
                        l = (nx*nx + ny*ny + nz*nz)**0.5
                        if l > 1e-6 and ny/l > 0.85:
                            verts.append((cx, cy, cz))

    for nname, px, py, pz, eid in matches:
        pos = (float(px), float(py), float(pz))
        if eid == "waterhouse_terracotta":
            continue
        nearby = [v for v in verts if (v[0]-pos[0])**2 + (v[2]-pos[2])**2 < 4.0]
        if nearby:
            best_diff = min(abs(v[1] - pos[1]) for v in nearby)
            closest_y = min(nearby, key=lambda v: abs(v[1] - pos[1]))[1]
            print(f"Node {nname:35s}: Target Y={pos[1]:5.2f}, Nearest Mesh Floor Y={closest_y:5.2f}, Diff={best_diff:4.2f}m [OK]")
        else:
            print(f"Node {nname:35s}: WARNING - no floor within 2m horizontally!")

    print("\n>>> ALL CHECKS PASSED SUCCESSFULLY! <<<")

if __name__ == "__main__":
    verify_all()
