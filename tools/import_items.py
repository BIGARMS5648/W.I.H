"""원작 장비의 수치 표를 WIH/Data/ItemTable.lua 로 옮긴다.

입력: 조사 단계에서 내려받은 v1.3.0 기준 데이터 묶음(tbh-data.json, 장비 1,590개).
옮기는 것은 수치뿐이다: (곡선, 아이템 레벨, 등급, 변형)마다 기본 능력치 값과 고정 능력치(능력치·연산·값).
이름·설명·그림은 옮기지 않는다. 고유 능력치(원작의 특정 스킬에 붙는 효과)는 옮기지 않는다.

사용: python3 -I tools/import_items.py <tbh-data.json 경로>
"""
import json
import sys
from collections import Counter, defaultdict

GRADES = ["COMMON", "UNCOMMON", "RARE", "LEGENDARY", "IMMORTAL", "ARCANA", "BEYOND", "CELESTIAL", "DIVINE", "COSMIC"]
KIND = {"FLAT": 1, "ADDITIVE": 2, "MULTIPLICATIVE": 3}
ORDER = ["SWORD", "AXE", "BOW", "CROSSBOW", "STAFF", "SCEPTER", "SHIELD", "HATCHET", "BOLT", "ARROW", "ORB", "TOME",
         "HELMET", "ARMOR", "GLOVES", "BOOTS", "AMULET", "EARING", "RING", "BRACER"]


def main(path):
    data = json.load(open(path, encoding="utf-8"))
    gear = [e for e in data["entries"] if e["cat"] == "gear"]
    rows = defaultdict(list)
    base_def = {}
    stats = Counter()
    for e in gear:
        r = {x["label"]: x["value"] for x in e["data"]}
        curve = r["Gear Type"]
        level, grade = int(r["Level"]), GRADES.index(r["Grade"]) + 1
        b = []
        for label in ("BaseStat1", "BaseStat2"):
            if label in r:
                stat, mod, value = r[label].split(":")
                b.append((stat, KIND[mod], int(value)))
        key = tuple((s, k) for s, k, _ in b)
        assert base_def.setdefault(curve, key) == key, (curve, key, base_def[curve])
        fixed = []
        for label in ("InherentStat1", "InherentStat2", "InherentStat3"):
            if label in r:
                stat, mod, value = r[label].split(":")
                fixed.append((stat, KIND[mod], int(value)))
                stats[stat] += 1
        assert len({(s, k) for s, k, _ in fixed}) == len(fixed), "같은 (능력치, 연산)이 두 번: " + e["gid"]
        rows[curve].append((level, grade, int(e["gid"]), [v for _, _, v in b], fixed))
    assert sorted(rows) == sorted(ORDER), sorted(rows)

    out = []
    w = out.append
    w("-- 장비 수치 표 [원작 v1.3.0]. tools/import_items.py 가 만든 파일이므로 직접 고치지 않는다.")
    w("-- 곡선(원작의 장비 종류 20가지)마다 (아이템 레벨, 등급, 변형)별 기본 능력치 값과 고정 능력치가 들어 있다.")
    w("-- 한 줄: { 레벨, 등급(1 일반 ~ 10 우주), 변형, 기본값1, 기본값2, 능력치, 연산(1 Flat / 2 Increased / 3 More), 값, ... }")
    w("-- 기본값이 없는 자리는 0이다(장신구에는 기본 능력치가 없다). % 계열 값은 퍼밀이다.")
    w("-- 이 프로젝트의 장비 종류가 어느 곡선을 쓰는지는 Data/ItemTypes.lua 에 있다.")
    w("")
    w("local _, WIH = ...")
    w('local ItemTable = WIH.module("ItemTable")')
    w("")
    levels = sorted({lv for rs in rows.values() for lv, *_ in rs})
    w("ItemTable.LEVELS = { %s }" % ", ".join(map(str, levels)))
    w("")
    w("-- 곡선의 기본 능력치: { {능력치, 연산}, ... }")
    w("ItemTable.BASE = {")
    for curve in ORDER:
        w("    %s = { %s }," % (curve, ", ".join('{ "%s", %d }' % sk for sk in base_def[curve])))
    w("}")
    w("")
    w("ItemTable.curves = {")
    total = 0
    for curve in ORDER:
        w("    %s = {" % curve)
        seen = Counter()
        for level, grade, gid, b, fixed in sorted(rows[curve], key=lambda r: (r[0], r[1], r[2])):
            seen[(level, grade)] += 1
            parts = [str(level), str(grade), str(seen[(level, grade)])]
            parts += [str(v) for v in (b + [0, 0])[:2]]
            for stat, kind, value in fixed:
                parts += ['"%s"' % stat, str(kind), str(value)]
            w("        { %s }," % ", ".join(parts))
            total += 1
        w("    },")
    w("}")
    w("")
    w("return ItemTable")
    with open("WIH/Data/ItemTable.lua", "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    print("WIH/Data/ItemTable.lua", "rows", total, "levels", levels)
    print("고정 능력치에 쓰인 능력치:", ", ".join("%s=%d" % kv for kv in stats.most_common()))


if __name__ == "__main__":
    main(sys.argv[1])
