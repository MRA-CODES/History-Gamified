import struct
import json
import os

def inspect_exact_locations():
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
                    ax, ay, az = v1[0]-v0[0], v1[1]-v0[1], v1[2]-v0[2]
                    bx, by, bz = v2[0]-v0[0], v2[1]-v0[1], v2[2]-v0[2]
                    nx = ay*bz - az*by
                    ny = az*bx - ax*bz
                    nz = ax*by - ay*bx
                    l = (nx*nx + ny*ny + nz*nz)**0.5
                    if l > 1e-6 and ny/l > 0.85:
                        verts.append((cx, cy, cz))

    print("=== 1. Ground Floor Bays Detail (Mammoth, Dinosaur, Giraffe) ===")
    # Find tables / display pedestals inside ground floor alcoves
    # Ground floor is Y ~ 3.2. Tables/pedestals are at Y ~ 3.8 - 4.5.
    for side, x_min, x_max in [('WEST ALCOVES (Left)', -14.0, -8.0), ('EAST ALCOVES (Right)', 8.0, 14.0)]:
        print(f"\n--- {side} ---")
        for z in range(-15, 20, 3):
            pts = [v for v in verts if x_min <= v[0] <= x_max and abs(v[2] - z) <= 1.5]
            if pts:
                y_min = min(v[1] for v in pts)
                y_max = max(v[1] for v in pts)
                # Elevated surfaces (tables/pedestals):
                tables = [v for v in pts if 3.5 <= v[1] <= 4.8]
                if tables:
                    avg_x = sum(v[0] for v in tables)/len(tables)
                    avg_y = sum(v[1] for v in tables)/len(tables)
                    avg_z = sum(v[2] for v in tables)/len(tables)
                    print(f"  Pedestal/Table at Z={z:2d}: Center=({avg_x:5.2f}, {avg_y:5.2f}, {avg_z:5.2f}), Floor Y={y_min:.2f}")

    print("\n=== 2. 1st Floor East Gallery (Meteorite Table & Adjacent Table) ===")
    # Around Z = -15 to +5 on East gallery (X ~ 8 to 14, Y ~ 10.2 to 11.5)
    for z in range(-15, 10, 2):
        tables = [v for v in verts if 8.0 <= v[0] <= 14.0 and abs(v[2] - z) <= 1.0 and 10.0 <= v[1] <= 11.5]
        if tables:
            avg_x = sum(v[0] for v in tables)/len(tables)
            avg_y = sum(v[1] for v in tables)/len(tables)
            avg_z = sum(v[2] for v in tables)/len(tables)
            print(f"  1st Floor East at Z={z:2d}: count={len(tables):4d}, Pos=({avg_x:5.2f}, {avg_y:5.2f}, {avg_z:5.2f})")

    print("\n=== 3. 1st Floor West Gallery (Hummingbirds & Dodo Locations) ===")
    for z in range(-20, 20, 2):
        tables = [v for v in verts if -14.0 <= v[0] <= -8.0 and abs(v[2] - z) <= 1.0 and 10.0 <= v[1] <= 11.5]
        if tables:
            avg_x = sum(v[0] for v in tables)/len(tables)
            avg_y = sum(v[1] for v in tables)/len(tables)
            avg_z = sum(v[2] for v in tables)/len(tables)
            print(f"  1st Floor West at Z={z:2d}: count={len(tables):4d}, Pos=({avg_x:5.2f}, {avg_y:5.2f}, {avg_z:5.2f})")

    print("\n=== 4. 2nd Floor Stairs Plain Area / Landings ===")
    # Let's inspect the stairs connecting 1st floor to 2nd floor
    # Look for horizontal flat surfaces between Y=12.0 and Y=17.0
    for y_lvl in [12.0, 13.0, 13.5, 14.0, 14.5, 15.0, 15.5, 16.0, 16.5, 16.8]:
        sub = [v for v in verts if abs(v[1] - y_lvl) <= 0.25]
        if len(sub) > 50:
            xs = [v[0] for v in sub]
            zs = [v[2] for v in sub]
            print(f"  Floor/Landing Y ~ {y_lvl:4.1f}: count={len(sub):5d}, X=[{min(xs):5.1f}, {max(xs):5.1f}], Z=[{min(zs):5.1f}, {max(zs):5.1f}]")

    print("\n=== 5. Tree Bark Exact Walkable Position ===")
    # Look at the North wall top mezzanine where the tree bark is mounted
    # Tree bark is at Z ~ -27 to -28. Walkway in front of it:
    front_bark = [v for v in verts if abs(v[0]) <= 3.0 and -27.0 <= v[2] <= -21.0 and 9.5 <= v[1] <= 17.5]
    for y_range in [(10.0, 11.0), (16.0, 17.0)]:
        pts = [v for v in front_bark if y_range[0] <= v[1] <= y_range[1]]
        if pts:
            avg_x = sum(v[0] for v in pts)/len(pts)
            avg_y = sum(v[1] for v in pts)/len(pts)
            avg_z = sum(v[2] for v in pts)/len(pts)
            print(f"  Front of Tree Bark at Y in [{y_range[0]}, {y_range[1]}]: ({avg_x:.2f}, {avg_y:.2f}, {avg_z:.2f})")

if __name__ == '__main__':
    inspect_exact_locations()
