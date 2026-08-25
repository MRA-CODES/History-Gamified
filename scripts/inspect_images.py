import os
import struct

def get_image_size(file_path):
    with open(file_path, 'rb') as f:
        data = f.read(32)
        if data[:8] == b'\x89PNG\r\n\x1a\n':
            w, h = struct.unpack('>LL', data[16:24])
            return w, h
        elif data[:2] == b'\xff\xd8':
            f.seek(0)
            data = f.read()
            # Parse JPEG markers
            i = 2
            while i < len(data):
                if data[i] != 0xFF:
                    i += 1
                    continue
                marker = data[i+1]
                if marker in (0xC0, 0xC1, 0xC2, 0xC3):
                    h, w = struct.unpack('>HH', data[i+5:i+9])
                    return w, h
                elif marker in (0xD8, 0xD9):
                    i += 2
                else:
                    length = struct.unpack('>H', data[i+2:i+4])[0]
                    i += 2 + length
    return None, None

img_dir = 'data/educational/images'
for f in sorted(os.listdir(img_dir)):
    if f.endswith(('.jpg', '.png', '.webp')):
        p = os.path.join(img_dir, f)
        w, h = get_image_size(p)
        if w and h:
            print(f"{f:40s}: {w}x{h} (aspect: {w/h:.2f})")
