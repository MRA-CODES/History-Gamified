import json
import struct
import math

def test_proposed_coordinates():
    # Proposed coordinates:
    proposed = {
        "waterhouse_terracotta": (0.0, 3.0, 37.0),
        "hope_blue_whale": (0.0, 3.0, 0.0),
        "charles_darwin_statue": (0.0, 7.2, -23.5),
        "painted_ceiling_panels": (0.0, 3.2, 10.0),
        "ground_mammoth_model": (-10.5, 3.35, 9.0),
        "ground_dinosaur_model": (-10.5, 3.35, 11.5),
        "ground_giraffe_model": (10.5, 3.35, 9.0),
        "giant_sequoia_slice": (0.0, 16.7, 22.8),
        "hintze_hall_cathedral_architecture": (0.0, 14.3, 16.5),
        "richard_owen_statue": (0.0, 10.22, 22.4),
        "victorian_hummingbird_cabinet": (-12.0, 10.3, -7.5),
        "dodo_skeleton": (-10.5, 10.1, -23.5),
        "cranbourne_meteorite": (11.8, 10.4, -11.5),
        "cursed_amethyst": (12.5, 17.1, -8.5),
        "blaschka_glass_models": (-12.0, 17.0, -11.5)
    }

    print("Checking for duplicate or overlapping positions:")
    items = list(proposed.items())
    for i in range(len(items)):
        for j in range(i+1, len(items)):
            id1, p1 = items[i]
            id2, p2 = items[j]
            dist = math.sqrt((p1[0]-p2[0])**2 + (p1[1]-p2[1])**2 + (p1[2]-p2[2])**2)
            if dist < 2.0:
                print(f"  WARNING: {id1} and {id2} are close: dist={dist:.2f}m")
            else:
                print(f"  OK: {id1} <-> {id2}: dist={dist:.2f}m")

    print("\nChecking mesh floor contact for all proposed markers:")
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
                    if l > 1e-6 and ny/l > 0.5:
                        verts.append((cx, cy, cz))

    for eid, pos in proposed.items():
        if eid == "waterhouse_terracotta":
            continue
        nearby = [v for v in verts if (v[0]-pos[0])**2 + (v[2]-pos[2])**2 < 3.5]
        if nearby:
            closest_v = min(nearby, key=lambda v: abs(v[1]-pos[1]))
            diff = abs(closest_v[1] - pos[1])
            print(f"  {eid:35s}: Target=({pos[0]:5.2f}, {pos[1]:5.2f}, {pos[2]:5.2f}), Nearest Floor Y={closest_v[1]:5.2f} (diff={diff:.2f}m) [OK]")
        else:
            print(f"  {eid:35s}: WARNING: No floor within radius 1.87m!")

if __name__ == '__main__':
    test_proposed_coordinates()
