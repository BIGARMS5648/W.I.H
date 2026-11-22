"""원정(원작의 역병지대)과 낙스라마스(원작의 오염된 액트 보스)의 수치를 WIH/Data/ExpeditionTable.lua 로 옮긴다.

입력: 조사 단계에서 내려받은 v1.3.0 자료 두 개(tbh-data.json, tbh-drops.json). 저장소에는 없다.
옮기는 것은 수치뿐이다: 강도별 몬스터 강화, 스테이지 레벨·웨이브·드롭률·대기 시간, 일반 몬스터 평균과 보스 최종값,
상자 내용물 표(ChestTable과 같은 형식). 이름은 옮기지 않는다.

사용: python3 -I tools/import_expeditions.py <tbh-data.json> <tbh-drops.json>
"""
import json
import sys
from collections import defaultdict
from fractions import Fraction

GRADES = ["COMMON", "UNCOMMON", "RARE", "LEGENDARY", "IMMORTAL", "ARCANA", "BEYOND", "CELESTIAL", "DIVINE", "COSMIC"]
PART = {"MAIN_WEAPON": "MAIN", "SUB_WEAPON": "SUB", "HELMET": "HELMET", "ARMOR": "ARMOR", "GLOVES": "GLOVES",
        "BOOTS": "BOOTS", "AMULET": "AMULET", "EARING": "EARRING", "RING": "RING", "BRACER": "BRACER"}
PART_ORDER = ["MAIN", "SUB", "HELMET", "ARMOR", "GLOVES", "BOOTS", "AMULET", "EARRING", "RING", "BRACER"]
DIFF = {"NIGHTMARE": 2, "HELL": 3, "TORMENT": 4}
SCALE = 1000000


def rhe(x):
    f = x.numerator // x.denominator
    d = x - f
    if d > Fraction(1, 2):
        return f + 1
    if d < Fraction(1, 2):
        return f
    return f if f % 2 == 0 else f + 1


def num(x):
    x = Fraction(x)
    if x.denominator == 1:
        return str(x.numerator)
    return ("%.4f" % float(x)).rstrip("0").rstrip(".")


def main(data_path, drops_path):
    data = json.load(open(data_path, encoding="utf-8"))
    drops = json.load(open(drops_path, encoding="utf-8"))
    rec = lambda e: {x["label"]: x["value"] for x in e["data"]}
    gear, mats, mons, stages = {}, set(), {}, {}
    for e in data["entries"]:
        if e["cat"] == "gear":
            r = rec(e)
            gear[e["gid"]] = (PART[r["Parts"]], int(r["Level"]), GRADES.index(r["Grade"]) + 1)
        elif e["cat"] == "item":
            mats.add(int(e["gid"]))
        elif e["cat"] == "monster":
            mons[e["gid"]] = rec(e)
        elif e["cat"] == "stage":
            stages[e["gid"]] = rec(e)
    levels = {r[0]: r for r in data["mechanics"]["stageLevel"]}     # [레벨, 공격, 체력, 골드, 경험치]

    def final(m, level):
        mult = levels[level]
        return (rhe(Fraction(int(m["HP"]) * mult[2], 1000)), rhe(Fraction(int(m["ATK"]) * mult[1], 1000)),
                rhe(Fraction(int(m["Gold"]) * mult[3], 1000)), rhe(Fraction(int(m["EXP"]) * mult[4], 1000)), int(m["ATK Speed"]))

    tables, index = [], {}

    def table_for(rows):
        acc = defaultdict(float)
        for r in rows:
            if r.get("ev") or r.get("hero"):
                continue
            if r["cat"] == "gear":
                acc[("G",) + gear[r["item"]]] += r["pct"]
            elif int(r["item"]) in mats:
                acc[("M", int(r["item"]))] += r["pct"]
        total = sum(acc.values())
        if total <= 0:
            return None
        entries = [(k, int(round(v / total * SCALE))) for k, v in acc.items()]
        entries = [e for e in entries if e[1] > 0]
        entries.sort(key=lambda e: (0, PART_ORDER.index(e[0][1]), e[0][2], e[0][3]) if e[0][0] == "G" else (1, e[0][1]))
        sig = tuple(entries)
        if sig not in index:
            tables.append(entries)
            index[sig] = len(tables)
        return index[sig]

    out = []
    w = out.append
    w("-- 원정·낙스라마스 수치 표 [원작 v1.3.0: 역병지대, 오염된 액트 보스]. tools/import_expeditions.py 가 만든 파일이므로 직접 고치지 않는다.")
    w("")
    w("local _, WIH = ...")
    w('local ExpeditionTable = WIH.module("ExpeditionTable")')
    w("")
    w("-- 강도별 몬스터 강화(퍼밀, 더하는 양): { 체력, 공격력, 이동속도 }")
    w("ExpeditionTable.INTENSITY = { %s }" % ", ".join("{ %d, %d, %d }" % (r[1], r[2], r[3]) for r in data["mechanics"]["plague"]))
    w("-- 원정 스테이지: PLAGUE[난이도 2~4][강도 1~20]")
    w("--   chestPpm/bossChestPpm = 상자 드롭 확률(백만분율), cool/bossCool = 획득 허용량 충전 시간(분)")
    w("--   mob = 일반 몬스터 평균(스테이지 레벨 적용, 강도 적용 전) { hp, dps, gold, exp }, bossFinal = 보스 최종값(보스 배율 적용, 강도 적용 전)")
    w("ExpeditionTable.PLAGUE = {")
    plague = defaultdict(dict)
    for gid, r in stages.items():
        if r["StageType"] != "PLAGUE":
            continue
        d, n, level = DIFF[r["Difficulty"]], int(r["Stage"]), int(r["Level"])
        vals = [final(mons[k], level) for k in r["Monsters"].split() if k in mons]
        cnt = len(vals)
        mob = (Fraction(sum(v[0] for v in vals), cnt), Fraction(sum(Fraction(v[1] * v[4], 100) for v in vals), cnt),
               Fraction(sum(v[2] for v in vals), cnt), Fraction(sum(v[3] for v in vals), cnt))
        b = final(mons[r["Boss"]], level)
        boss = (Fraction(b[0] * 6000, 1000), Fraction(b[1] * 3000 * b[4], 100000), Fraction(b[2] * 3000, 1000), Fraction(b[3] * 6000, 1000))
        rows = drops["stages"].get(gid, [])
        normal = table_for([x for x in rows if x["src"] == "monster"])
        bt = table_for([x for x in rows if x["src"] == "boss"])
        plague[d][n] = ("{ key = %s, level = %d, waves = %s, perWave = %s, chestPpm = %d, bossChestPpm = %d, cool = %s, bossCool = %s, "
                        "mob = { hp = %s, dps = %s, gold = %s, exp = %s }, bossFinal = { hp = %s, dps = %s, gold = %s, exp = %s }, normal = %s, boss = %s }"
                        % (gid, level, r["Waves"], r["Monsters/Wave"], int(r["MonsterDropRate"]), int(r["BossDropRate"]),
                           r["MonsterDropCooldown"], r["BossDropCooldown"], *[num(x) for x in mob], *[num(x) for x in boss], normal, bt))
    for d in sorted(plague):
        w("    [%d] = {" % d)
        for n in sorted(plague[d]):
            w("        [%d] = %s," % (n, plague[d][n]))
        w("    },")
    w("}")
    w("")
    w("-- 낙스라마스(오염된 액트 보스 자리): NAXX[난이도 2~4][스테이지 1~3] = { level, final = { hp, atk, as, gold, exp }, raid = 상자 표 }")
    w("ExpeditionTable.NAXX = {")
    naxx = defaultdict(dict)
    for gid, r in stages.items():
        if r["StageType"] != "CONTAMINACTBOSS":
            continue
        d, act, level = DIFF[r["Difficulty"]], int(r["Act"]), int(r["Level"])
        b = final(mons[r["Boss"]], level)
        t = table_for(drops["stages"].get(gid, []))
        naxx[d][act] = "{ key = %s, level = %d, final = { hp = %d, atk = %d, as = %d, gold = %d, exp = %d }, raid = %s }" % (gid, level, b[0], b[1], b[4], b[2], b[3], t)
    for d in sorted(naxx):
        w("    [%d] = { %s }," % (d, ", ".join("[%d] = %s" % (a, naxx[d][a]) for a in sorted(naxx[d]))))
    w("}")
    w("")
    w("ExpeditionTable.tables = {")
    for i, entries in enumerate(tables, 1):
        parts = []
        for key, wgt in entries:
            parts.append('{ %d, "%s", %d, %d }' % (wgt, key[1], key[2], key[3]) if key[0] == "G" else '{ %d, "MAT", %d }' % (wgt, key[1]))
        w("    [%d] = { %s }," % (i, ", ".join(parts)))
    w("}")
    w("")
    w("return ExpeditionTable")
    with open("WIH/Data/ExpeditionTable.lua", "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    print("plague stages", sum(len(v) for v in plague.values()), "naxx", sum(len(v) for v in naxx.values()), "tables", len(tables))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
