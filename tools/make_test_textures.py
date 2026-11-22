"""환경 점검 애드온에 넣을 시험용 텍스처를 만든다. 외부 라이브러리 없이 TGA와 PNG를 직접 쓴다."""
import struct
import sys
import zlib


def pattern(w, h):
    """회색 바탕에 대각선 띠와 테두리. (r, g, b, a) 행 목록, 위에서 아래 순서."""
    rows = []
    for y in range(h):
        row = []
        for x in range(w):
            edge = x < 4 or y < 4 or x >= w - 4 or y >= h - 4
            band = ((x + y) // 16) % 2 == 0
            if edge:
                px = (230, 230, 230, 255)
            elif band:
                px = (90, 110, 140, 255)
            else:
                px = (40, 44, 52, 200)
            row.append(px)
        rows.append(row)
    return rows


def write_tga(path, w, h):
    rows = pattern(w, h)
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 0x08)
    body = bytearray()
    for row in reversed(rows):  # TGA 기본 원점은 왼쪽 아래
        for r, g, b, a in row:
            body += bytes((b, g, r, a))
    with open(path, "wb") as f:
        f.write(header)
        f.write(body)


def write_png(path, w, h):
    rows = pattern(w, h)
    raw = bytearray()
    for row in rows:
        raw.append(0)
        for px in row:
            raw += bytes(px)

    def chunk(kind, data):
        c = struct.pack(">I", len(data)) + kind + data
        return c + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        f.write(chunk(b"IEND", b""))


if __name__ == "__main__":
    out = sys.argv[1]
    write_tga(out + "/test256.tga", 256, 256)
    write_tga(out + "/test300x200.tga", 300, 200)
    write_png(out + "/test256.png", 256, 256)
