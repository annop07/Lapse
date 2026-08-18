"""สร้างไอคอนแอปจากโทเคน โดยไม่พึ่งเครื่องมือทำภาพภายนอก

ไอคอนคือกระดาษหนึ่งแผ่นกับช่องกำแพงหนึ่งช่อง — สองอย่างที่ทั้งแอปสร้างขึ้นมาจากมัน
ไม่มีไล่สี ไม่มีเงา ไม่มีตัวอักษร ตามกฎเดียวกับที่ใช้ในแอป

รันด้วย python3 tool/make_icon.py
"""

import json
import os
import struct
import zlib

# มาจาก docs/lapse-tokens.json โดยตรง
PAPER = (0xF4, 0xF2, 0xED)

# ไล่โทนกำแพง 5 ขั้น อ่อน→เข้ม
RAMP = [
    (0xE6, 0xE3, 0xDC),
    (0xC2, 0xBE, 0xB4),
    (0x91, 0x8D, 0x83),
    (0x57, 0x54, 0x4D),
    (0x1C, 0x1B, 0x18),
]

# ผืนกำแพงเล็กๆ สามคูณสาม · ตัวเลขคือระดับ ไม่ใช่ค่าสี
# มีทั้งวันที่อ่านหนักและวันที่ว่าง เพราะวันว่างคือข้อเท็จจริง ไม่ใช่ความล้มเหลว
PATCH = [
    [4, 1, 3],
    [2, 4, 0],
    [3, 2, 4],
]

OUT = "ios/Runner/Assets.xcassets/AppIcon.appiconset"

# ขนาดที่ iOS ต้องการ (ชื่อไฟล์, ด้าน)
SIZES = [
    ("Icon-App-20x20@1x.png", 20), ("Icon-App-20x20@2x.png", 40),
    ("Icon-App-20x20@3x.png", 60), ("Icon-App-29x29@1x.png", 29),
    ("Icon-App-29x29@2x.png", 58), ("Icon-App-29x29@3x.png", 87),
    ("Icon-App-40x40@1x.png", 40), ("Icon-App-40x40@2x.png", 80),
    ("Icon-App-40x40@3x.png", 120), ("Icon-App-60x60@2x.png", 120),
    ("Icon-App-60x60@3x.png", 180), ("Icon-App-76x76@1x.png", 76),
    ("Icon-App-76x76@2x.png", 152), ("Icon-App-83.5x83.5@2x.png", 167),
    ("Icon-App-1024x1024@1x.png", 1024),
]


def wall_patch(size):
    """ผืนกำแพงเล็กๆ กลางกระดาษ

    ไอคอนเป็นสี่เหลี่ยมเดี่ยวมาก่อน แต่มันอ่านไม่ออกว่าเป็นแอปอะไร
    และดูเหมือนไอคอนที่โหลดไม่ขึ้น · ผืนกำแพงบอกได้ว่านี่คือแอปอะไร
    โดยยังไม่ต้องใช้ตัวอักษรหรือรูปวาด

    สัดส่วนช่องต่อช่องว่างเป็น 7 ต่อ 2 เท่ากับในแอปจริง
    """
    cols = len(PATCH[0])
    rows_n = len(PATCH)
    span = size * 0.52
    gap_ratio = 2 / 7
    cell = span / (cols + gap_ratio * (cols - 1))
    gap = cell * gap_ratio
    radius = cell * 0.30

    grid_w = cols * cell + (cols - 1) * gap
    grid_h = rows_n * cell + (rows_n - 1) * gap
    ox = (size - grid_w) / 2
    oy = (size - grid_h) / 2

    boxes = []
    for r in range(rows_n):
        for c in range(cols):
            left = ox + c * (cell + gap)
            top = oy + r * (cell + gap)
            boxes.append((left, top, left + cell, top + cell,
                          RAMP[PATCH[r][c]]))

    rows = []
    for y in range(size):
        row = bytearray()
        cy = y + 0.5
        for x in range(size):
            cx = x + 0.5
            colour = PAPER
            for left, top, right, bottom, tone in boxes:
                if not (left <= cx <= right and top <= cy <= bottom):
                    continue
                dx = max(left + radius - cx, cx - (right - radius), 0)
                dy = max(top + radius - cy, cy - (bottom - radius), 0)
                if dx * dx + dy * dy <= radius * radius:
                    colour = tone
                break
            row += bytes(colour)
        rows.append(bytes(row))
    return rows


def write_png(path, rows, size):
    raw = b"".join(b"\x00" + r for r in rows)

    def chunk(kind, data):
        body = kind + data
        return (struct.pack(">I", len(data)) + body +
                struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF))

    header = struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0)
    png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) +
           chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))
    with open(path, "wb") as f:
        f.write(png)


def main():
    os.makedirs(OUT, exist_ok=True)
    cache = {}
    images = []
    for name, size in SIZES:
        if size not in cache:
            cache[size] = wall_patch(size)
        write_png(os.path.join(OUT, name), cache[size], size)

        base, scale = name.replace("Icon-App-", "").replace(".png", "").split("@")
        idiom = "ios-marketing" if size == 1024 else (
            "ipad" if base in ("76x76", "83.5x83.5") else "iphone")
        images.append({"size": base, "idiom": idiom,
                       "filename": name, "scale": scale})

    # iOS ต้องการทั้ง iphone และ ipad สำหรับขนาดที่ใช้ร่วมกัน
    extra = []
    for img in images:
        if img["idiom"] == "iphone" and img["size"] in ("20x20", "29x29", "40x40"):
            extra.append({**img, "idiom": "ipad"})
    images += extra

    with open(os.path.join(OUT, "Contents.json"), "w") as f:
        json.dump({"images": images,
                   "info": {"version": 1, "author": "xcode"}}, f, indent=2)

    print("เขียนไอคอน", len(SIZES), "ขนาด")


if __name__ == "__main__":
    main()
