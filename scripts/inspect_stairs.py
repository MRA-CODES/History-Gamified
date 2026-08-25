import struct
import json

def inspect_stairs():
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

    print("=== Walkable Points along Center (X between -4 and 4) ===")
    # Group by Z from -30 to +30 in steps of 2m
    for z_start in range(-30, 30, 2):
        pts = [v for v in verts if abs(v[0]) <= 3.5 and z_start <= v[2] < z_start + 2]
        if pts:
            # Group by distinct Y levels (within 0.8m)
            y_levels = {}
            for p in pts:
                found = False
                for yk in y_levels:
                    if abs(yk - p[1]) < 0.6:
                        y_levels[yk].append(p)
                        found = True
                        break
                if not found:
                    y_levels[p[1]] = [p]
            
            for yk, group in sorted(y_levels.items(), key=lambda item: item[0]):
                avg_x = sum(p[0] for p in group)/len(group)
                avg_y = sum(p[1] for p in group)/len(group)
                avg_z = sum(p[2] for p in group)/len(group)
                print(f"  Z [{z_start:3d}, {z_start+2:3d}]: count={len(group):4d}, Pos=({avg_x:5.2f}, {avg_y:5.2f}, {avg_z:5.2f})")

if __name__ == '__main__':
    inspect_stairs()
