"""애드온 폴더를 설치용 ZIP으로 묶는다. 사용: python3 tools/build_zip.py <애드온 폴더> <버전>"""
import os
import sys
import zipfile


def build(addon_dir, version, out_dir="dist"):
    addon = os.path.basename(os.path.normpath(addon_dir))
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, f"{addon}-{version}.zip")
    count = 0
    with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as z:
        for root, dirs, files in os.walk(addon_dir):
            dirs.sort()
            for name in sorted(files):
                full = os.path.join(root, name)
                rel = os.path.relpath(full, os.path.dirname(os.path.normpath(addon_dir)))
                z.write(full, rel.replace(os.sep, "/"))
                count += 1
    return out_path, count


if __name__ == "__main__":
    path, n = build(sys.argv[1], sys.argv[2])
    print(f"{path} ({n} files, {os.path.getsize(path)} bytes)")
