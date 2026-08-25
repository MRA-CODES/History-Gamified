import struct
import json
import os

def inspect_nhm():
    with open('assets/environment/buildings/NHM London.glb', 'rb') as f:
        magic, ver, length = struct.unpack('<4sII', f.read(12))
        chunk_len, chunk_type = struct.unpack('<I4s', f.read(8))
        data = json.loads(f.read(chunk_len).decode('utf-8'))
        chunk2_len, chunk2_type = struct.unpack('<I4s', f.read(8))
        bin_data = f.read(chunk2_len)

    print("=== Materials in GLB ===")
    materials = data.get('materials', [])
    for i, m in enumerate(materials):
        print(f"Mat {i}: name='{m.get('name')}'")

    print("\n=== Images / Textures ===")
    images = data.get('images', [])
    for i, img in enumerate(images):
        print(f"Image {i}: name='{img.get('name')}'")

    accessors = data.get('accessors', [])
    buffer_views = data.get('bufferViews', [])
    meshes = data.get('meshes', [])
    scale_m = 1.4285714626312256

    print("\n=== Meshes & Primitives Bounding Boxes ===")
    for m_idx, mesh in enumerate(meshes):
        m_name = mesh.get('name', f'Mesh_{m_idx}')
        for p_idx, prim in enumerate(mesh.get('primitives', [])):
            mat_idx = prim.get('material')
            mat_name = materials[mat_idx].get('name') if mat_idx is not None and mat_idx < len(materials) else 'None'
            pos_idx = prim.get('attributes', {}).get('POSITION')
            if pos_idx is not None:
                acc = accessors[pos_idx]
                bv = buffer_views[acc['bufferView']]
                off = bv.get('byteOffset', 0) + acc.get('byteOffset', 0)
                cnt = acc['count']
                raw = bin_data[off : off + cnt * 12]
                xs, ys, zs = [], [], []
                for i in range(cnt):
                    x, y, z = struct.unpack('<3f', raw[i*12:(i+1)*12])
                    # World space
                    wx = - (scale_m * x)
                    wy = (-scale_m * y) + 2.1
                    wz = - (-scale_m * z) - 2.0
                    xs.append(wx)
                    ys.append(wy)
                    zs.append(wz)
                print(f"Mesh {m_idx} ('{m_name}') Prim {p_idx} Mat='{mat_name}' Verts={cnt}: X=[{min(xs):.2f}, {max(xs):.2f}], Y=[{min(ys):.2f}, {max(ys):.2f}], Z=[{min(zs):.2f}, {max(zs):.2f}]")

if __name__ == '__main__':
    inspect_nhm()
