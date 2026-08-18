import struct
import json
import os

def inspect_glb(path):
    print(f"=== Inspecting {path} ===")
    if not os.path.exists(path):
        print("File does not exist")
        return
    with open(path, "rb") as f:
        magic, ver, length = struct.unpack("<4sII", f.read(12))
        chunk_len, chunk_type = struct.unpack("<I4s", f.read(8))
        json_bytes = f.read(chunk_len)
        data = json.loads(json_bytes.decode("utf-8"))
        nodes = data.get("nodes", [])
        meshes = data.get("meshes", [])
        print(f"Total nodes: {len(nodes)}, Total meshes: {len(meshes)}")
        for i, node in enumerate(nodes):
            name = node.get("name", f"node_{i}")
            trans = node.get("translation", [0, 0, 0])
            mesh_idx = node.get("mesh", None)
            mesh_name = meshes[mesh_idx].get("name", "") if mesh_idx is not None else ""
            print(f"Node {i}: '{name}' (mesh: '{mesh_name}') translation={trans}")

if __name__ == "__main__":
    inspect_glb("assets/environment/buildings/NHM London.glb")
    print("\n")
    inspect_glb("assets/environment/buildings/Exterior NHM London .glb")
