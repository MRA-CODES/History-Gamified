import struct
import json

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

all_verts = []
for mesh in meshes:
    for prim in mesh.get('primitives', []):
        pos_idx = prim.get('attributes', {}).get('POSITION')
        if pos_idx is not None:
            acc = accessors[pos_idx]
            bv = buffer_views[acc['bufferView']]
            off = bv.get('byteOffset', 0) + acc.get('byteOffset', 0)
            cnt = acc['count']
            raw = bin_data[off : off + cnt * 12]
            for i in range(cnt):
                x, y, z = struct.unpack('<3f', raw[i*12:(i+1)*12])
                wx = - (scale_m * x)
                wy = (-scale_m * y) + 2.1
                wz = - (-scale_m * z) - 2.0
                all_verts.append((wx, wy, wz))

# 1st floor North Balcony (behind Darwin, top of stairs):
f1_bark = [v for v in all_verts if abs(v[0]) <= 3.5 and -27.5 <= v[2] <= -25.0 and 10.1 <= v[1] <= 10.6]
if f1_bark:
    print(f"1st Floor North Balcony center: X={sum(v[0] for v in f1_bark)/len(f1_bark):.2f}, Y={sum(v[1] for v in f1_bark)/len(f1_bark):.2f}, Z={sum(v[2] for v in f1_bark)/len(f1_bark):.2f}")

# 2nd floor North Mezzanine (at top of stairs):
f2_bark = [v for v in all_verts if abs(v[0]) <= 3.5 and -28.5 <= v[2] <= -25.0 and 16.0 <= v[1] <= 17.2]
if f2_bark:
    print(f"2nd Floor North Mezzanine center: X={sum(v[0] for v in f2_bark)/len(f2_bark):.2f}, Y={sum(v[1] for v in f2_bark)/len(f2_bark):.2f}, Z={sum(v[2] for v in f2_bark)/len(f2_bark):.2f}")
