import struct
import json
import os
import math

def search_features():
    with open('assets/environment/buildings/NHM London.glb', 'rb') as f:
        magic, ver, length = struct.unpack('<4sII', f.read(12))
        chunk_len, chunk_type = struct.unpack('<I4s', f.read(8))
        data = json.loads(f.read(chunk_len).decode('utf-8'))
        chunk2_len, chunk2_type = struct.unpack('<I4s', f.read(8))
        bin_data = f.read(chunk2_len)

    accessors = data.get('accessors', [])
    buffer_views = data.get('bufferViews', [])
    meshes = data.get('meshes', [])
    scale_m = 1.4285714626312256

    verts = []
    for mesh in meshes:
        for prim in mesh.get('primitives', []):
            pos_idx = prim.get('attributes', {}).get('POSITION')
            ind_idx = prim.get('indices')
            if pos_idx is not None and ind_idx is not None:
                acc_p = accessors[pos_idx]
                bv_p = buffer_views[acc_p['bufferView']]
                off_p = bv_p.get('byteOffset', 0) + acc_p.get('byteOffset', 0)
                cnt_p = acc_p['count']
                raw_p = bin_data[off_p : off_p + cnt_p * 12]
                v_local = []
                for i in range(cnt_p):
                    x, y, z = struct.unpack('<3f', raw_p[i*12:(i+1)*12])
                    wx = - (scale_m * x)
                    wy = (-scale_m * y) + 2.1
                    wz = - (-scale_m * z) - 2.0
                    v_local.append((wx, wy, wz))
                
                acc_i = accessors[ind_idx]
                bv_i = buffer_views[acc_i['bufferView']]
                off_i = bv_i.get('byteOffset', 0) + acc_i.get('byteOffset', 0)
                cnt_i = acc_i['count']
                comp_type = acc_i.get('componentType', 5123)
                raw_i = bin_data[off_i : off_i + (cnt_i * (2 if comp_type==5123 else 4))]
                fmt = '<' + ('H' if comp_type==5123 else 'I')
                stride = 2 if comp_type==5123 else 4
                for i in range(0, cnt_i, 3):
                    i0 = struct.unpack_from(fmt, raw_i, i * stride)[0]
                    i1 = struct.unpack_from(fmt, raw_i, (i+1) * stride)[0]
                    i2 = struct.unpack_from(fmt, raw_i, (i+2) * stride)[0]
                    v0, v1, v2 = v_local[i0], v_local[i1], v_local[i2]
                    cy = (v0[1] + v1[1] + v2[1]) / 3.0
                    cx = (v0[0] + v1[0] + v2[0]) / 3.0
                    cz = (v0[2] + v1[2] + v2[2]) / 3.0
                    verts.append((cx, cy, cz))

    print(f"Loaded {len(verts)} surface patches.")

    # 1. Check Ground Floor alcoves (bays along East and West sides at Y ~ 3.0 to 5.0)
    # The main hall is from Z = 20 (entrance) to Z = -15 (stairs).
    # West alcoves: X in [-14, -6], Z in [-15, 20]
    # East alcoves: X in [6, 14], Z in [-15, 20]
    print("\n=== Ground Floor Alcoves / Bays (Y ~ 3.0 - 5.5) ===")
    for side, x_range in [('West (Left)', (-14.0, -5.0)), ('East (Right)', (5.0, 14.0))]:
        print(f"\n--- Ground Floor {side} ---")
        for z_s in range(-15, 20, 5):
            in_bay = [v for v in verts if 3.0 <= v[1] <= 6.0 and x_range[0] <= v[0] <= x_range[1] and z_s <= v[2] < z_s + 5]
            if in_bay:
                xs = [v[0] for v in in_bay]
                ys = [v[1] for v in in_bay]
                zs = [v[2] for v in in_bay]
                # Look for elevated objects (tables / pedestals / models inside the bay)
                elevated = [v for v in in_bay if v[1] > 3.8]
                print(f"  Bay Z [{z_s:3d} to {z_s+5:3d}]: count={len(in_bay):5d}, X=[{min(xs):.1f}, {max(xs):.1f}], Y=[{min(ys):.1f}, {max(ys):.1f}], Elevated(>3.8m)={len(elevated)}")

    # 2. Check 1st Floor East & West galleries (Y ~ 10.0 - 12.0)
    print("\n=== 1st Floor Bays / Corridors (Y ~ 10.0 - 12.0) ===")
    for side, x_range in [('West (Left)', (-14.0, -6.0)), ('East (Right)', (6.0, 14.0))]:
        print(f"\n--- 1st Floor {side} ---")
        for z_s in range(-25, 25, 5):
            in_bay = [v for v in verts if 10.0 <= v[1] <= 12.0 and x_range[0] <= v[0] <= x_range[1] and z_s <= v[2] < z_s + 5]
            if in_bay:
                xs = [v[0] for v in in_bay]
                ys = [v[1] for v in in_bay]
                elevated = [v for v in in_bay if v[1] > 10.6]
                print(f"  Bay Z [{z_s:3d} to {z_s+5:3d}]: count={len(in_bay):5d}, X=[{min(xs):.1f}, {max(xs):.1f}], Y=[{min(ys):.1f}, {max(ys):.1f}], Elevated(>10.6m)={len(elevated)}")

    # 3. Check 2nd Floor stairs and landings (Y ~ 13.0 to 17.5)
    print("\n=== 2nd Floor Staircases & Landings (Y ~ 13.0 - 17.5) ===")
    for z_s in range(-30, 30, 5):
        in_area = [v for v in verts if 13.0 <= v[1] <= 17.5 and z_s <= v[2] < z_s + 5]
        if in_area:
            xs = [v[0] for v in in_area]
            ys = [v[1] for v in in_area]
            print(f"  Z [{z_s:3d} to {z_s+5:3d}]: count={len(in_area):5d}, X=[{min(xs):.1f}, {max(xs):.1f}], Y=[{min(ys):.1f}, {max(ys):.1f}]")

    # 4. Check Tree Bark location: Look for large circular / vertical wall structure at North end or upper floors
    print("\n=== Scanning for Tree Bark / Sequoia Slice ===")
    # Look at back wall Z < -20 at various heights Y from 8 to 22
    for y_s in range(8, 22, 2):
        in_wall = [v for v in verts if y_s <= v[1] < y_s + 2 and -8.0 <= v[0] <= 8.0 and v[2] < -24.0]
        if in_wall:
            xs = [v[0] for v in in_wall]
            zs = [v[2] for v in in_wall]
            print(f"  Y [{y_s:2d} to {y_s+2:2d}]: count={len(in_wall):5d}, X=[{min(xs):.1f}, {max(xs):.1f}], Z=[{min(zs):.1f}, {max(zs):.1f}]")

if __name__ == '__main__':
    search_features()
