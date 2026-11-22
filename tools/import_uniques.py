"""원작 장비의 고유 능력치(UniqueMod)를 WIH/Data/UniqueTable.lua 로 옮긴다.

입력: 조사 단계에서 내려받은 v1.3.0 자료(tbh-data.json). 저장소에는 없다.
옮기는 것: 고유 능력치가 붙은 장비 116개의 (곡선, 레벨, 등급, 변형)과 고유 능력치의 종류·인자. 설명문과 이름은 옮기지 않는다.
변형 번호는 tools/import_items.py 와 같은 방식((레벨, 등급, 원작 번호) 순서)으로 매긴다.
해석(원작의 특정 스킬 → 착용한 영웅의 같은 순번 스킬 등)은 Inventory/Uniques.lua 가 한다.

사용: python3 -I tools/import_uniques.py <tbh-data.json>
"""
import json
import sys
from collections import Counter, defaultdict

GRADES = ["COMMON", "UNCOMMON", "RARE", "LEGENDARY", "IMMORTAL", "ARCANA", "BEYOND", "CELESTIAL", "DIVINE", "COSMIC"]


def lua_param(p):
    t, v = p["type"], p["val"]
    if t == "Divided":
        return v
    if t == "Raw_Divide1000":
        return str(int(v) / 1000)
    if t == "Raw_Divide100":
        return str(int(v) / 100)
    if t == "GearStat":
        stat, kind, value = v.split(":")
        return '{ "%s", %d, %s }' % (stat, {"FLAT": 1, "ADDITIVE": 2, "MULTIPLICATIVE": 3}[kind], value)
    if t == "DamageAttribute":
        return '"%s"' % v
    raise ValueError(t)


def main(path):
    d = json.load(open(path, encoding="utf-8"))
    mods = d["uniqueMods"]
    gear = [e for e in d["entries"] if e["cat"] == "gear"]
    rows = defaultdict(list)
    for e in gear:
        r = {x["label"]: x["value"] for x in e["data"]}
        rows[r["Gear Type"]].append((int(r["Level"]), GRADES.index(r["Grade"]) + 1, int(e["gid"]), e.get("um")))
    out = []
    kinds = Counter()
    for curve in sorted(rows):
        seen = Counter()
        for level, grade, gid, um in sorted(rows[curve]):
            seen[(level, grade)] += 1
            if um is None:
                continue
            m = mods[str(um)]
            kinds[m["key"]] += 1
            params = ", ".join(lua_param(p) for p in m["params"])
            out.append('    { "%s", %d, %d, %d, "%s", { %s } },' % (curve, level, grade, seen[(level, grade)], m["key"], params))
    lines = [
        "-- 고유 능력치가 붙은 장비 [원작 v1.3.0]. tools/import_uniques.py 가 만든 파일이므로 직접 고치지 않는다.",
        "-- 한 줄: { 곡선, 레벨, 등급, 변형, 원작 고유 능력치 종류, { 인자... } }",
        "--   인자: 스킬 번호(원작의 직업 × 10000 + 순번 × 100 + 1), 비율(1 = 100%), 능력치 { 능력치, 연산, 값 }, 원소 이름",
        "-- 해석은 Inventory/Uniques.lua 에 있다.",
        "",
        "local _, WIH = ...",
        'local UniqueTable = WIH.module("UniqueTable")',
        "",
        "UniqueTable.items = {",
    ] + out + ["}", "", "return UniqueTable", ""]
    with open("WIH/Data/UniqueTable.lua", "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("items", len(out), "kinds", len(kinds))


if __name__ == "__main__":
    main(sys.argv[1])
