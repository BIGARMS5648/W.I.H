"""유물·유물함의 수치를 WIH/Data/RelicTable.lua 로 옮긴다.

입력: 조사 단계에서 내려받은 v1.3.0 자료(tbh-data.json). 저장소에는 없다.
옮기는 것: 유물 36종의 색·능력치·등급별 범위, 유물함 62종의 등급별 칸 수·고정 속성 수·미완성 여부와 공명 조건,
유물함 고정 속성 풀(등급별), 조율 비용, 오염된 유물·유물함을 기원에 바쳤을 때의 결과 가중치. 이름은 옮기지 않는다.

사용: python3 -I tools/import_relics.py <tbh-data.json>
"""
import json
import sys

GRADES = ["COMMON", "UNCOMMON", "RARE", "LEGENDARY", "IMMORTAL", "ARCANA", "BEYOND", "CELESTIAL", "DIVINE", "COSMIC"]
KIND = {"FLAT": 1, "ADDITIVE": 2, "MULTIPLICATIVE": 3}
COLOR = {"Red": "RED", "Blue": "BLUE", "Yellow": "YELLOW", "Purple": "PURPLE", "White": "WHITE"}


def main(path):
    d = json.load(open(path, encoding="utf-8"))
    out = []
    w = out.append
    w("-- 유물·유물함 수치 표 [원작 v1.3.0]. tools/import_relics.py 가 만든 파일이므로 직접 고치지 않는다.")
    w("-- 능력치 값은 원작의 내부값이다(% 계열은 퍼밀).")
    w("")
    w("local _, WIH = ...")
    w('local RelicTable = WIH.module("RelicTable")')
    w("")
    w("-- 유물함 고정 속성 풀: POOL[등급] = { { 능력치, 연산, 최소, 최대 }, ... }")
    w("RelicTable.POOL = {")
    for g in GRADES:
        rows = []
        for spec in d["relicPools"][g]:
            stat, kind, lo, hi = spec.split(":")
            rows.append('{ "%s", %d, %s, %s }' % (stat, KIND[kind], lo, hi))
        w("    { %s }," % ", ".join(rows))
    w("}")
    w("")
    relics, quivers = [], []
    for e in d["entries"]:
        if e["cat"] != "relic":
            continue
        r = {x["label"]: x["value"] for x in e["data"]}
        gid = int(e["gid"])
        if r["Kind"] == "RELIC":
            stat, kind = r["Stat"].split(":")
            ranges = ", ".join("{ %s }" % r["Range_" + g].replace(":", ", ") for g in GRADES)
            relics.append('    [%d] = { color = "%s", stat = "%s", kind = %d, double = %s, range = { %s } },'
                          % (gid, COLOR[r["Color"]], stat, KIND[kind], "true" if r.get("Special") == "ResonanceDoubleCount" else "false", ranges))
        else:
            grades = []
            for i, g in enumerate(GRADES, 1):
                if ("Grade_" + g) in r:
                    slots, inherent, unfinished = r["Grade_" + g].split(":")
                    grades.append("[%d] = { %s, %s, %s }" % (i, slots, inherent, "true" if unfinished == "1" else "false"))
            cond = []
            for part in r["Resonance"].split():
                color, n = part.split("_")
                cond.append("%s = %s" % (COLOR[color], n))
            quivers.append("    [%d] = { grades = { %s }, cond = { %s } }," % (gid, ", ".join(grades), ", ".join(cond)))
    w("-- 유물: RELICS[번호] = { color, stat, kind, double(공명 판정에서 2개로 셈), range = { 등급별 { 최소, 최대 } } }")
    w("RelicTable.RELICS = {")
    out.extend(sorted(relics))
    w("}")
    w("")
    w("-- 유물함: RELIQUARIES[번호] = { grades = { [등급] = { 칸 수, 고정 속성 수, 미완성(공명 없음) } }, cond = { 색 = 개수 } }")
    w("RelicTable.RELIQUARIES = {")
    out.extend(sorted(quivers))
    w("}")
    w("")
    w("-- 조율 비용: 기본 + 증가분 × min(횟수, 상한)")
    a = d["relicAttunement"]
    w("RelicTable.ATTUNE = {")
    for kind in ("RELIQUARY", "RELIC"):
        w("    %s = { %s }," % (kind, ", ".join("{ %d, %d, %d }" % (a[kind][g]["base"], a[kind][g]["inc"], a[kind][g]["max"]) for g in GRADES)))
    w("}")
    w("")
    w("-- 오염된 유물함(161xxx)·유물(162xxx)을 기원에 바쳤을 때: OFFER[재료] = { { 등급, 가중치, { 번호, ... } }, ... }")
    w("-- 원작에서 특정 추가 영웅이 있어야 나오는 줄은 뺐다.")
    w("RelicTable.OFFER = {")
    for key in sorted(d["offerings"], key=int):
        if not key.startswith("161") and not key.startswith("162"):
            continue
        rows = []
        for row in d["offerings"][key]["r"]:
            grade, weight, cond = row[0], row[1], row[2]
            if cond:
                continue
            ids = [int(x.split(":")[1]) for x in row[3:] if x.startswith("relic:")]
            rows.append("{ %d, %s, { %s } }" % (GRADES.index(grade) + 1, ("%.4f" % weight).rstrip("0").rstrip("."), ", ".join(map(str, ids))))
        w("    [%s] = { %s }," % (key, ", ".join(rows)))
    w("}")
    w("")
    w("return RelicTable")
    with open("WIH/Data/RelicTable.lua", "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    print("relics", len(relics), "reliquaries", len(quivers))


if __name__ == "__main__":
    main(sys.argv[1])
