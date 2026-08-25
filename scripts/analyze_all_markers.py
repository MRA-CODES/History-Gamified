import struct
import json
import os

def analyze():
    with open('assets/environment/buildings/NHM London.glb', 'rb') as f:
        magic, ver, length = struct.unpack('<4sII', f.read(12))
        chunk_len, chunk_type = struct.unpack('<I4s', f.read(8))
        data = json.loads(f.read(chunk_len).decode('utf-8'))
        chunk2_len, chunk2_type = struct.unpack('<I4s', f.read(8))
        bin_data = f.read(chunk2_len)

    print("Materials in GLB:")
    for i, m in enumerate(data.get('materials', [])):
        print(f"  Mat {i}: {m.get('name', '')}")

    accessors = data.get('accessors', [])
    buffer_views = data.get('bufferViews', [])
    meshes = data.get('meshes', [])
    scale_m = 1.4285714626312256

    verts = []
    # Also collect faces and materials
    mat_verts = {}
    for mesh in meshes:
        for prim in mesh.get('primitives', []):
            pos_idx = prim.get('attributes', {}).get('POSITION')
            ind_idx = prim.get('indices')
            mat_idx = prim.get('material')
            if pos_idx is not None and ind_idx is not None:
                acc_p = accessors[pos_idx]
                bv_p = buffer_views[acc_p['bufferView']]
                off_p = bv_p.get('byteOffset', 0) + acc_p.get('byteOffset', 0)
                cnt_p = acc_p['count']
                raw_p = bin_data[off_p : off_p + cnt_p * 12]
                v_local = []
                for i in range(cnt_p):
                    x, y, z = struct.unpack('<3f', raw_p[i*12:(i+1)*12])
                    # In church_exterior.tscn:
                    # Interior transform: basis rot 180 around Y: x' = -x, y' = y, z' = -z
                    # InteriorMesh scale: 1.4285714626312256
                    # Interior origin: (0, 2.1, -2)
                    wx = - (scale_m * x)
                    wy = (-scale_m * y) + 2.1  # Note: GLB may be oriented
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
                    if l > 1e-6 and ny/l > 0.7:  # walkable surface
                        verts.append((cx, cy, cz))
                    
                    if mat_idx is not None:
                        if mat_idx not in mat_verts:
                            mat_verts[mat_idx] = []
                        mat_verts[mat_idx].append((cx, cy, cz))

    print(f"Total walkable surface points: {len(verts)}")
    return verts, mat_verts, data

if __name__ == '__main__':
    analyze()
