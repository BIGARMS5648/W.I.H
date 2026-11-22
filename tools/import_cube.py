"""큐브의 수치 표를 WIH/Data/CubeTable.lua 로 옮긴다.

입력(조사 단계에서 내려받은 자료, 저장소에는 없다):
  · <t 폴더>: 게임 데이터 추출 테이블 v1.00.17 (cube_sub_recipes, synthesis_recipes, synthesis_drops, crafting_recipes,
    drops, item_groups, grades, item_level_scales)
  · <items.json>: v1.00.17 아이템 목록(삭제된 레벨의 장비 포함. 드롭 표가 가리키는 장비의 부위·레벨·등급을 알아내는 데 쓴다)
  · <tbh-data.json>: v1.3.0 자료(재료의 장식·세공·각인 능력치 범위)
  · <03-cube-crafting.md>: 조사 보고서(큐브 레벨별 필요 경험치 표)
옮기는 것은 수치뿐이다. 이름·설명은 옮기지 않는다.

사용: python3 -I tools/import_cube.py <t 폴더> <items.json> <tbh-data.json> <03-cube-crafting.md>
"""
import json
import re
import sys
from collections import defaultdict

GRADES = ["COMMON", "UNCOMMON", "RARE", "LEGENDARY", "IMMORTAL", "ARCANA", "BEYOND", "CELESTIAL", "DIVINE", "COSMIC"]
PART = {"SWORD": "MAIN", "AXE": "MAIN", "BOW": "MAIN", "CROSSBOW": "MAIN", "SCEPTER": "MAIN", "STAFF": "MAIN",
        "SHIELD": "SUB", "ARROW": "SUB", "ORB": "SUB", "TOME": "SUB", "BOLT": "SUB", "HATCHET": "SUB",
        "HELMET": "HELMET", "ARMOR": "ARMOR", "GLOVES": "GLOVES", "BOOTS": "BOOTS",
        "AMULET": "AMULET", "EARING": "EARRING", "RING": "RING", "BRACER": "BRACER"}
PART_ORDER = ["MAIN", "SUB", "HELMET", "ARMOR", "GLOVES", "BOOTS", "AMULET", "EARRING", "RING", "BRACER"]
LEVELS = [1, 5, 10, 15, 20, 30, 40, 50, 65, 80, 90]
# 1.00.07에서 삭제된 레벨은 바로 아래의 현행 레벨로 옮긴다
REMAP = {25: 20, 35: 30, 45: 40, 55: 50, 60: 50, 70: 65, 75: 65, 85: 80, 100: 90}
KIND = {"FLAT": 1, "ADDITIVE": 2, "MULTIPLICATIVE": 3}
SCALE = 1000000


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def main(tdir, items_path, data_path, doc_path):
    T = lambda n: load(f"{tdir}/{n}.json")
    items = {i["id"]: i for i in load(items_path)}
    groups = defaultdict(list)
    for r in T("item_groups"):
        groups[r["ItemGroupKey"]].append(r["ItemKey"])
    drops = defaultdict(list)
    for r in T("drops"):
        drops[r["DropKey"]].append(r)

    # 재료 번호(v1.3.0)
    data = load(data_path)
    mats = {}
    for e in data["entries"]:
        if e["cat"] == "item":
            r = {x["label"]: x["value"] for x in e["data"]}
            mats[int(e["gid"])] = r

    tables, index = [], {}

    def item_key(item_id):
        it = items.get(item_id)
        if not it:
            return None
        if it["type"] == "GEAR":
            lv = REMAP.get(it["level"], it["level"])
            return ("G", PART[it["gear"]], lv, GRADES.index(it["grade"]) + 1)
        if item_id in mats:
            return ("M", item_id)
        return None

    def resolve(drop_key):
        acc = defaultdict(float)
        for r in drops.get(drop_key, []):
            if r.get("HeroKeyCondition"):
                continue                   # 추가 영웅이 있을 때만 더해지는 항목은 뺀다(상자 표와 같은 규칙)
            if r["REWARDTYPE"] == "ITEMGROUP":
                members = [item_key(i) for i in groups[r["RewardKey"]]]
            elif r["REWARDTYPE"] == "ITEM":
                members = [item_key(r["RewardKey"])]
            else:
                raise SystemExit("모르는 보상 종류: %s" % r["REWARDTYPE"])
            members = [m for m in members if m]
            if not members:
                continue
            for m in members:
                acc[m] += r["Weight"] / len(members)
        total = sum(acc.values())
        if total <= 0:
            return None
        entries = sorted(((k, int(round(v / total * SCALE))) for k, v in acc.items()),
                         key=lambda e: (0, PART_ORDER.index(e[0][1]), e[0][2], e[0][3]) if e[0][0] == "G" else (1, e[0][1]))
        entries = [e for e in entries if e[1] > 0]
        sig = tuple(entries)
        if sig not in index:
            tables.append(entries)
            index[sig] = len(tables)
        return index[sig]

    out = []
    w = out.append
    w("-- 큐브 수치 표 [원작]. tools/import_cube.py 가 만든 파일이므로 직접 고치지 않는다.")
    w("-- 레시피·확률·제작 재료는 v1.00.17, 재료의 능력치 범위는 v1.3.0 자료다. 드롭 표의 형식은 ChestTable과 같다.")
    w("")
    w("local _, WIH = ...")
    w('local CubeTable = WIH.module("CubeTable")')
    w("")

    # 큐브 레벨
    doc = open(doc_path, encoding="utf-8").read()
    sec = doc[doc.index("### 2.3"):doc.index("### 2.4")]
    need = {}
    for m in re.finditer(r"\|\s*(\d+)\s*\|\s*([\d,]+)\s*", sec):
        need[int(m.group(1))] = int(m.group(2).replace(",", ""))
    exp = [need[i] for i in range(1, 100)]
    w("-- 큐브 레벨 n에서 다음 레벨까지 필요한 경험치(최대 레벨 100)")
    w("CubeTable.LEVEL_EXP = { %s }" % ", ".join(map(str, exp)))
    grades = {g["GRADE"]: g for g in T("grades")}
    w("CubeTable.GRADE_EXP = { %s }" % ", ".join(str(grades[g]["BaseCubeExp"]) for g in GRADES))
    w("-- 합성 등급 가중치: { 같은 등급, 한 등급 위, 두 등급 위 } [원작 v1.00.17, 1.3.0의 불멸·아르카나 변경을 반영]")
    weights = []
    for g in GRADES:
        r = grades[g]
        same, h1, h2 = r["SameGradeWeight"], r["Higher1GradeWeight"], r["Higher2GradeWeight"]
        if g == "IMMORTAL":
            same = round(h1 / 0.8 - h1 - h2)       # 1.3.0: 불멸 → 아르카나 80% [원작 공지. 대성공 가중치는 그대로 둠: 추정]
        if g == "ARCANA":
            same = round(h1 / 0.5 - h1 - h2)       # 1.3.0: 아르카나 → 초월 50%
        weights.append("{ %d, %d, %d }" % (same, h1, h2))
    w("CubeTable.SYNTH_GRADE = { %s }" % ", ".join(weights))
    w("CubeTable.EXP_LEVEL = { %s }" % ", ".join("[%d] = %d" % (r["Level"], r["CubeExpScale"]) for r in T("item_level_scales") if r["Level"] in LEVELS))
    w("")

    # 레시피 해금
    w("-- 레시피: { 종류, 단계, 해금 큐브 레벨, 해금 비용, 재료, 수수료, 결과 표 }")
    w("CubeTable.SUB = {")
    for r in T("cube_sub_recipes"):
        table = resolve(r["DropKey"]) if r["DropKey"] else None
        mat = r["Material"]
        w('    { "%s", %s, %d, %d, %s, %s, %s },' % (r["RECIPETYPE"], r["RecipeTier"] or "nil", r["UnlockCubeLevel"], r["UnlockCost"] or 0,
                                                  int(mat.split("_")[0]) if mat else "nil", r["TriggerGoldCost"] or "nil", table or "nil"))
    w("}")
    w("")

    # 합성
    w("-- 합성: SYNTH[분류][단계][등급] = { { 재료 평균 레벨 ≥, 결과 레벨 최소, 최대, 가중치1~4 }, ... } (평균 레벨 오름차순)")
    synth = defaultdict(lambda: defaultdict(lambda: defaultdict(list)))
    for r in T("synthesis_recipes"):
        synth[r["ItemSynthesisType"]][r["RecipeTier"]][GRADES.index(r["GRADE"]) + 1].append(
            (r["MinMaterialAverageLevel"], r["MinResultLevel"], r["MaxResultLevel"], r["LevelWeight1"], r["LevelWeight2"], r["LevelWeight3"], r["LevelWeight4"]))
    w("CubeTable.SYNTH = {")
    for kind in ("Gear", "Accessory", "Material"):
        w("    %s = {" % kind)
        for tier in sorted(synth[kind]):
            parts = []
            for g in sorted(synth[kind][tier]):
                rows = sorted(synth[kind][tier][g])
                parts.append("[%d] = { %s }" % (g, ", ".join("{ %s }" % ", ".join(map(str, row)) for row in rows)))
            w("        [%d] = { %s }," % (tier, ", ".join(parts)))
        w("    },")
    w("}")
    w("-- 합성 결과 표: SYNTH_DROP[분류][단계][결과 등급][결과 레벨] = 표 번호(재료는 레벨 0)")
    sd = defaultdict(lambda: defaultdict(lambda: defaultdict(dict)))
    for r in T("synthesis_drops"):
        lv = REMAP.get(r["ItemLevel"], r["ItemLevel"]) if r["ItemSynthesisType"] != "Material" else 0
        t = resolve(r["DropKey"])
        if t:
            sd[r["ItemSynthesisType"]][r["RecipeTier"]][GRADES.index(r["GRADE"]) + 1].setdefault(lv, t)
    w("CubeTable.SYNTH_DROP = {")
    for kind in ("Gear", "Accessory", "Material"):
        w("    %s = {" % kind)
        for tier in sorted(sd[kind]):
            parts = []
            for g in sorted(sd[kind][tier]):
                parts.append("[%d] = { %s }" % (g, ", ".join("[%d] = %d" % kv for kv in sorted(sd[kind][tier][g].items()))))
            w("        [%d] = { %s }," % (tier, ", ".join(parts)))
        w("    },")
    w("}")
    w("")

    # 제작
    CRAFT_PART = {"MainWeapon": "MAIN", "SubWeapon": "SUB", "Helmet": "HELMET", "Armor": "ARMOR", "Gloves": "GLOVES", "Boots": "BOOTS", "Accessory": "ACC"}
    w("-- 제작: CRAFT[부위][단계] = { 재료 = { {번호, 수}, ... }, 결과 표 }")
    w("CubeTable.CRAFT = {")
    craft = defaultdict(dict)
    for r in T("crafting_recipes"):
        m = [tuple(map(int, x.split("_"))) for x in r["Material"].split()]
        craft[CRAFT_PART[r["ItemCraftingType"]]][r["RecipeTier"]] = (m, resolve(r["DropKey"]))
    for part in ("MAIN", "SUB", "HELMET", "ARMOR", "GLOVES", "BOOTS", "ACC"):
        rows = []
        for tier in sorted(craft[part]):
            m, t = craft[part][tier]
            rows.append("[%d] = { mats = { %s }, table = %d }" % (tier, ", ".join("{ %d, %d }" % x for x in m), t))
        w("    %s = { %s }," % (part, ", ".join(rows)))
    w("}")
    w("")

    # 재료의 능력치(장식·세공·각인)
    def parse(spec):
        res = []
        for part in spec.split("|"):
            stat, kind, lo, hi = part.split(":")
            res.append('{ "%s", %d, %s, %s }' % (stat, KIND[kind], lo, hi))
        return "{ %s }" % ", ".join(res)
    w("-- 재료가 붙이는 능력치: MODS[재료] = { WEAPON = {후보...}, ARMOR = {...}, ACCESSORY = {...} } 또는 { ALL = {...} }(각인)")
    w("-- 후보 = { 능력치, 연산(1 Flat / 2 Increased), 최소, 최대 }. 장식은 후보 1개, 세공은 2개 중 1개, 각인은 풀 전체에서 1개")
    w("CubeTable.MODS = {")
    stats = set()
    for gid in sorted(mats):
        r = mats[gid]
        kind = r.get("MaterialType")
        if kind == "DECORATION" or kind == "ENGRAVING":
            prefix = "Decoration"          # v1.3.0 자료는 세공 재료도 같은 이름의 열을 쓴다(세공은 후보가 2개)
            groups_ = []
            for g, label in (("WEAPON", "Weapon"), ("ARMOR", "Armor"), ("ACCESSORY", "Accessory")):
                spec = r.get(prefix + label)
                if spec:
                    groups_.append("%s = %s" % (g, parse(spec)))
                    stats.update(p.split(":")[0] for p in spec.split("|"))
            w("    [%d] = { %s }," % (gid, ", ".join(groups_)))
        elif kind == "INSCRIPTION":
            spec = r["InscriptionStats"]
            stats.update(p.split(":")[0] for p in spec.split("|"))
            w("    [%d] = { ALL = %s }," % (gid, parse(spec)))
    w("}")
    w("")
    w("-- 제거 비용: EXTRACT[종류][단계 1~10]. 단계는 붙인 재료의 등급으로 본다 [추정]")
    ex = defaultdict(dict)
    for r in T("extraction_costs"):
        if r["GearGroup"] == "WEAPON":
            ex[r["MATERIALTYPE"]][r["Tier"]] = r["Cost"]
    w("CubeTable.EXTRACT = {")
    for k in ("DECORATION", "ENGRAVING", "INSCRIPTION"):
        w("    %s = { %s }," % (k, ", ".join(str(ex[k][t]) for t in range(1, 11))))
    w("}")
    w("")
    w("CubeTable.tables = {")
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
    w("return CubeTable")
    with open("WIH/Data/CubeTable.lua", "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    print("drop tables", len(tables), "| 재료 능력치에 쓰인 능력치:", ", ".join(sorted(stats)))


if __name__ == "__main__":
    main(*sys.argv[1:5])
