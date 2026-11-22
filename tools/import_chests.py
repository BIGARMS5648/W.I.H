"""원작의 상자 내용물 표를 WIH/Data/ChestTable.lua 와 WIH/Data/Materials.lua 로 옮긴다.

입력: 조사 단계에서 내려받은 v1.3.0 기준 데이터 묶음 두 개(tbh-data.json, tbh-drops.json).
원작 자료는 스테이지마다 "아이템별 처치당 확률"로 펼쳐져 있다. 이것을 상자 하나를 열었을 때의
(부위, 아이템 레벨, 등급) 묶음과 재료별 가중치로 다시 묶는다. 같은 내용의 표는 하나로 합친다.
주무기·보조무기 묶음 안에서 어떤 종류가 나오는지는 게임이 정한다(보유한 영웅이 쓰는 종류 중에서 고르게).
원작은 영웅을 더 가지면 그 영웅의 무기 묶음이 표에 더해져 무기 비중이 커진다. 이 프로젝트는 영웅이 30명이므로
그 방식을 쓰지 않고, 원작의 기본 영웅 4명 기준 비율(주무기 약 41%, 보조무기 약 6%)로 묶음의 총량을 고정한다.

사용: python3 -I tools/import_chests.py <tbh-data.json> <tbh-drops.json>
"""
import json
import sys
from collections import defaultdict

GRADES = ["COMMON", "UNCOMMON", "RARE", "LEGENDARY", "IMMORTAL", "ARCANA", "BEYOND", "CELESTIAL", "DIVINE", "COSMIC"]
PART = {"MAIN_WEAPON": "MAIN", "SUB_WEAPON": "SUB", "HELMET": "HELMET", "ARMOR": "ARMOR", "GLOVES": "GLOVES",
        "BOOTS": "BOOTS", "AMULET": "AMULET", "EARING": "EARRING", "RING": "RING", "BRACER": "BRACER"}
PART_ORDER = ["MAIN", "SUB", "HELMET", "ARMOR", "GLOVES", "BOOTS", "AMULET", "EARRING", "RING", "BRACER"]
SCALE = 1000000


def main(data_path, drops_path):
    data = json.load(open(data_path, encoding="utf-8"))
    drops = json.load(open(drops_path, encoding="utf-8"))
    gear, mats, stages = {}, {}, {}
    for e in data["entries"]:
        r = {x["label"]: x["value"] for x in e["data"]} if e["cat"] in ("gear", "item", "stage") else None
        if e["cat"] == "gear":
            gear[e["gid"]] = (PART[r["Parts"]], int(r["Level"]), GRADES.index(r["Grade"]) + 1)
        elif e["cat"] == "item":
            mats[e["gid"]] = (r.get("MaterialType") or r.get("Type"), GRADES.index(r["Grade"]) + 1)
        elif e["cat"] == "stage":
            stages[e["gid"]] = r

    tables, table_index = [], {}
    event_share = [0.0]

    def table_for(rows):
        acc = defaultdict(float)
        everything = sum(r["pct"] for r in rows)
        for r in rows:
            if r.get("ev"):
                continue        # 기간 한정 이벤트 항목은 옮기지 않는다(뺀 만큼은 나머지에 비례 배분된다)
            if r.get("hero"):
                continue        # 추가 영웅을 가졌을 때만 더해지는 무기 묶음은 뺀다: 기본 영웅 4명 기준의 비율로 고정한다
            if r["cat"] == "gear":
                acc[("G",) + gear[r["item"]]] += r["pct"]
            else:
                acc[("M", int(r["item"]))] += r["pct"]
        total = sum(acc.values())
        if total <= 0:
            return None, 0
        with_dlc = sum(r["pct"] for r in rows if not r.get("ev"))
        event_share[0] = max(event_share[0], 1 - with_dlc / everything)
        entries = []
        for key, v in acc.items():
            wgt = int(round(v / total * SCALE))
            if wgt > 0:
                entries.append((key, wgt))

        def order(e):
            k = e[0]
            return (0, PART_ORDER.index(k[1]), k[2], k[3]) if k[0] == "G" else (1, k[1], 0, 0)
        entries.sort(key=order)
        sig = tuple(entries)
        if sig not in table_index:
            tables.append(entries)
            table_index[sig] = len(tables)
        return table_index[sig], everything

    stage_rows = {}
    for key, r in sorted(stages.items()):
        if r["StageType"] not in ("NORMAL", "ACTBOSS"):
            continue            # 역병지대·오염된 액트 보스·이벤트는 해당 콘텐츠를 만들 때 옮긴다
        rows = drops["stages"].get(key, [])
        mon, mon_total = table_for([x for x in rows if x["src"] == "monster"])
        boss, boss_total = table_for([x for x in rows if x["src"] == "boss"])
        if r["StageType"] == "NORMAL":
            # 검산: 표의 확률 합 = 스테이지의 상자 드롭 확률
            assert abs(mon_total - int(r["MonsterDropRate"]) / 10000) < 0.01, (key, mon_total, r["MonsterDropRate"])
            assert abs(boss_total - int(r["BossDropRate"]) / 10000) < 0.01, (key, boss_total, r["BossDropRate"])
            stage_rows[int(key)] = "normal = %d, boss = %d, cool = %s, bossCool = %s" % (
                mon, boss, r["MonsterDropCooldown"], r["BossDropCooldown"])
        else:
            stage_rows[int(key)] = "raid = %d" % boss

    out = []
    w = out.append
    w("-- 상자 내용물 표 [원작 v1.3.0]. tools/import_chests.py 가 만든 파일이므로 직접 고치지 않는다.")
    w("-- tables[번호] = 상자 하나를 열었을 때의 가중치 표. 가중치의 합은 약 1,000,000.")
    w('--   장비 묶음: { 가중치, "부위", 아이템 레벨, 등급 }   재료: { 가중치, "MAT", 재료 번호 }')
    w("-- STAGE[스테이지 키] = { normal = 일반 상자의 표, boss = 스테이지 상자의 표, cool/bossCool = 획득 허용량 충전 시간(분) }")
    w("--                    레이드 자리(액트 보스)는 { raid = 레이드 상자의 표 }")
    w("")
    w("local _, WIH = ...")
    w('local ChestTable = WIH.module("ChestTable")')
    w("")
    w("ChestTable.tables = {")
    for i, entries in enumerate(tables, 1):
        parts = []
        for key, wgt in entries:
            if key[0] == "G":
                parts.append('{ %d, "%s", %d, %d }' % (wgt, key[1], key[2], key[3]))
            else:
                parts.append('{ %d, "MAT", %d }' % (wgt, key[1]))
        w("    [%d] = { %s }," % (i, ", ".join(parts)))
    w("}")
    w("")
    w("ChestTable.STAGE = {")
    for key in sorted(stage_rows):
        w("    [%d] = { %s }," % (key, stage_rows[key]))
    w("}")
    w("")
    w("return ChestTable")
    with open("WIH/Data/ChestTable.lua", "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")

    out = []
    w = out.append
    w("-- 재료의 분류와 등급 [원작 v1.3.0]. tools/import_chests.py 가 만든 파일이므로 직접 고치지 않는다.")
    w("-- 번호는 원작 데이터의 것을 그대로 쓴다. 이름과 쓰임새는 큐브를 만들 때 정한다.")
    w("")
    w("local _, WIH = ...")
    w('local Materials = WIH.module("Materials")')
    w("")
    w("Materials.defs = {")
    for gid in sorted(mats, key=int):
        kind, grade = mats[gid]
        w('    [%d] = { kind = "%s", grade = %d },' % (int(gid), kind, grade))
    w("}")
    w("")
    w("return Materials")
    with open("WIH/Data/Materials.lua", "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    used = {k[1] for t in tables for k, _ in t if k[0] == "M"}
    print("tables", len(tables), "stages", len(stage_rows), "materials", len(mats), "상자에서 나오는 재료", len(used))
    print("가장 큰 표의 항목 수", max(len(t) for t in tables), "| 뺀 이벤트 항목의 최대 비중 %.2f%%" % (event_share[0] * 100))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
