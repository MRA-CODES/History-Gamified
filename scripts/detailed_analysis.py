import struct
import json

def run_detailed_analysis():
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
                    if l > 1e-6 and ny/l > 0.6:
                        verts.append((cx, cy, cz))

    print("=================================================================")
    print("ANALYSIS 1: Tree Bark and Hall Architecture (Stairs in front)")
    print("=================================================================")
    # Old Tree Bark: (0, 10.3, -27)
    # Old Hall Architecture: (0, 16.7, 22.8)
    # User says:
    # "1. Place the tree bark marker in place of the hall architecture marker and place the hall architecture marker on the stares in front of the tree bark marker."
    # Let's inspect the stairs leading down from (0, 16.7, 22.8) towards the hall (Z < 22.8)
    print("Walkable stairs in front of (0, 16.7, 22.8) at Z between 12 and 22, Y between 10 and 17:")
    for z in range(12, 24):
        step_pts = [v for v in verts if abs(v[0]) <= 3.5 and abs(v[2] - z) <= 0.6 and 10.0 <= v[1] <= 17.5]
        if step_pts:
            avg_x = sum(v[0] for v in step_pts)/len(step_pts)
            avg_y = sum(v[1] for v in step_pts)/len(step_pts)
            avg_z = sum(v[2] for v in step_pts)/len(step_pts)
            print(f"  Stairs Z ~ {z:2d}: count={len(step_pts):3d}, Pos=({avg_x:5.2f}, {avg_y:5.2f}, {avg_z:5.2f})")

    print("\n=================================================================")
    print("ANALYSIS 2: Marine Glass Models (Opposite direction by 20 steps)")
    print("=================================================================")
    # Old position: (-12.3, 16.95, 8.5) (2nd floor West gallery)
    # Moving opposite direction by 20 steps: Z = 8.5 - 20 = -11.5
    print("2nd floor West gallery points near Z = -11.5 (X ~ -12.3, Y ~ 16.9):")
    for z in range(-16, -6, 2):
        sub = [v for v in verts if -14.0 <= v[0] <= -10.0 and abs(v[2] - z) <= 1.0 and 16.0 <= v[1] <= 18.0]
        if sub:
            avg_x = sum(v[0] for v in sub)/len(sub)
            avg_y = sum(v[1] for v in sub)/len(sub)
            avg_z = sum(v[2] for v in sub)/len(sub)
            print(f"  West Gallery 2nd floor at Z={z:3d}: count={len(sub):4d}, Pos=({avg_x:5.2f}, {avg_y:5.2f}, {avg_z:5.2f})")

    print("\n=================================================================")
    print("ANALYSIS 3: Dodo marker (End of stairs left from Charles Darwin)")
    print("=================================================================")
    # Charles Darwin: (0, 7.2, -23.5)
    # Looking at Darwin (from hall Z > -23.5 facing North Z < -23.5):
    # Left from Charles Darwin = West (X < 0) or player's left when looking from Darwin statue?
    # When you stand at Charles Darwin statue (0, 7.2, -23.5) looking at Darwin (facing North, Z -> -), Left is West (X < 0, e.g. X ~ -6 to -12).
    # When looking FROM Charles Darwin statue towards the hall (facing South, Z -> +), Left is East (X > 0).
    # But usually "left from Darwin statue" in museum context means the left staircase next to Darwin (West stairs).
    # Let's inspect the stairs going up to the left and right of Darwin:
    print("Stairs flanking Darwin statue (Z ~ -28 to -18, Y ~ 7.0 to 11.0):")
    for side, x_min, x_max in [("West Stairs (Left when facing Darwin)", -14.0, -4.0), ("East Stairs (Right when facing Darwin)", 4.0, 14.0)]:
        print(f"\n--- {side} ---")
        for z in range(-28, -16, 2):
            sub = [v for v in verts if x_min <= v[0] <= x_max and abs(v[2] - z) <= 1.0 and 6.5 <= v[1] <= 11.5]
            if sub:
                avg_x = sum(v[0] for v in sub)/len(sub)
                avg_y = sum(v[1] for v in sub)/len(sub)
                avg_z = sum(v[2] for v in sub)/len(sub)
                print(f"  Stairs Z={z:3d}: count={len(sub):4d}, Pos=({avg_x:5.2f}, {avg_y:5.2f}, {avg_z:5.2f})")

    print("\n--- Landing at TOP/END of stairs to the Left (West) of Darwin ---")
    # Top/end of the West stairs around Z=-22 to -28, Y ~ 10.3 to 10.6, X ~ -8 to -12:
    for z in range(-28, -14, 2):
        landing = [v for v in verts if -13.5 <= v[0] <= -6.0 and abs(v[2] - z) <= 1.0 and 9.5 <= v[1] <= 11.0]
        if landing:
            avg_x = sum(v[0] for v in landing)/len(landing)
            avg_y = sum(v[1] for v in landing)/len(landing)
            avg_z = sum(v[2] for v in landing)/len(landing)
            print(f"  Landing West Z={z:3d}: count={len(landing):4d}, Pos=({avg_x:5.2f}, {avg_y:5.2f}, {avg_z:5.2f})")

    print("\n=================================================================")
    print("ANALYSIS 4: Mammoth, Dinosaur, Giraffe, and Ceiling Panels")
    print("=================================================================")
    # Painted ceiling panels is currently at (5.5, 3, 10).
    # User says:
    # "4. The marker of the mammoth bones should be near the ceiling panels marker and beside it should be the small dinosaur marker. And opposite side should be the giraffe statue."
    # Let's inspect the ground floor layout near Z = 10 (and across Z = 5 to 15) on both West and East sides.
    for side, x_min, x_max in [("West Side (Alcove)", -14.0, -4.0), ("Center", -4.0, 4.0), ("East Side (Alcove)", 4.0, 14.0)]:
        print(f"\n--- Ground Floor {side} (Z from 0 to 18) ---")
        for z in range(0, 18, 2):
            sub = [v for v in verts if x_min <= v[0] <= x_max and abs(v[2] - z) <= 1.0 and 2.5 <= v[1] <= 4.5]
            if sub:
                avg_x = sum(v[0] for v in sub)/len(sub)
                avg_y = sum(v[1] for v in sub)/len(sub)
                avg_z = sum(v[2] for v in sub)/len(sub)
                print(f"  Z={z:2d}: count={len(sub):4d}, Floor/Table Pos=({avg_x:5.2f}, {avg_y:5.2f}, {avg_z:5.2f})")

if __name__ == '__main__':
    run_detailed_analysis()
