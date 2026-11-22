"""애드온 폴더를 설치용 ZIP으로 묶는다. 사용: python3 tools/build_zip.py <애드온 폴더> <버전>"""
import os
import sys
import zipfile


def sync_camelot_toc(addon_dir):
    """포에버는 <애드온>_Camelot.toc 를 우선해서 읽는다(게임 내 확인). 기본 TOC와 내용이 어긋나지 않게 복사해 만든다."""
    addon = os.path.basename(os.path.normpath(addon_dir))
    base = os.path.join(addon_dir, addon + ".toc")
    if not os.path.exists(base):
        return
    with open(base, encoding="utf-8") as f:
        text = f.read()
    text = text.replace("## X-WIH-TOC: base", "## X-WIH-TOC: camelot")
    with open(os.path.join(addon_dir, addon + "_Camelot.toc"), "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def build(addon_dir, version, out_dir="dist"):
    addon = os.path.basename(os.path.normpath(addon_dir))
    if addon != "WIH_EnvCheck":
        sync_camelot_toc(addon_dir)
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
