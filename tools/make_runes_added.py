"""원작 1.2.0~1.3.0에 추가된 룬 노드 56개를 WIH/Data/RunesAdded.lua 로 만든다.

근거(docs/research/05 1.6절)
- 노드 수, 레벨당 수치의 합, 추가 레벨 수: 데이터 v1.03.00(스탯별 집계) [원작]
- 묶음별 비용 합: tbhindex 검색 요약 [추정]
- 나머지 묶음의 비용: 원작 트리 전체 합(50,046,840,050)에서 원래 197노드와 위 묶음을 뺀 나머지를 노드 수로 똑같이 나눈다 [독자]
- 노드 안의 레벨별 비용은 1:2:3:4:5, 묶음 안의 노드별 비용은 1:2:3... 비율 [독자]. 연결(부모)도 [독자].
사용: python3 -I tools/make_runes_added.py
"""

ORIGINAL_TOTAL = 50046840050
BASE_TOTAL = 10040515050

# (이름, 스탯, 노드별 레벨당 수치 목록, 최대 레벨, 묶음 비용 합 또는 None, 첫 노드의 부모)
GROUPS = [
    ("growth_act", "AdditionalExpActBoss", [3000, 4000], 5, None, 3152),
    ("shield", "AllHeroArmor", [5, 5], 5, None, 410),
    ("shield_pct", "AllHeroArmorPercent", [20], 5, None, 412),
    ("war", "AllHeroAttackDamage", [1, 1, 2], 5, 1215000000, 4081),
    ("war_pct", "AllHeroAttackDamagePercent", [20], 5, 70000000, 413),
    ("frenzy", "AllHeroAttackSpeed", [20], 5, None, 4061),
    ("gale", "AllHeroMoveSpeed", [10], 5, None, 4101),
    ("alchemy", "CubeAlchemyGoldPercent", [20], 5, None, 3122),
    ("forging", "CubeExpPercent", [20], 5, None, 3121),
    ("explore", "DropChanceNormalChestPercent", [50, 50], 5, None, 127),
    ("conquest", "DropChanceStageBossChestPercent", [100, 100], 5, None, 128),
    ("training", "OfflineRewardExpPercent", [50, 50, 50], 5, None, 180701),
    ("brevity", "WaveCountReduction", [1, 1], 1, 650000000, 1171),
    # 역병의 룬 [원작 1.2.0]
    ("p_explore", "DropChancePlagueNormalChestPercent", [125, 125, 125, 125], 5, 4715000000, 21),
    ("p_conquest", "DropChancePlagueStageBossChestPercent", [300, 400, 400], 5, None, "p_explore"),
    ("p_contain", "MaxAmountPlagueNormalChest", [1, 1, 1, 1, 1], 1, 771000000, "p_explore"),
    ("p_vault", "MaxAmountPlagueStageBossChest", [1, 1, 1, 1, 1], 1, 1565000000, "p_conquest"),
    ("p_infinity", "MaxAmountPlagueActBossChest", [1, 1, 1, 1, 1], 1, 2540000000, "p_conquest"),
    ("p_spring_n", "UnlockAutoOpenPlagueNormalChest", [600], 1, 30000000, "p_contain"),
    ("p_spring_s", "UnlockAutoOpenPlagueStageBossChest", [1200], 1, 75000000, "p_vault"),
    ("p_spring_a", "UnlockAutoOpenPlagueActBossChest", [120], 1, 150000000, "p_infinity"),
    ("p_lube_n", "ReduceAutoOpenPlagueNormalChestTime", [4, 4, 4], 5, 2350000000, "p_spring_n"),
    ("p_lube_s", "ReduceAutoOpenPlagueStageBossChestTime", [8, 8, 8], 5, 2350000000, "p_spring_s"),
    ("p_lube_a", "ReduceAutoOpenPlagueActBossChestTime", [1, 1, 1], 5, 2350000000, "p_spring_a"),
]


def main():
    known = sum(g[4] for g in GROUPS if g[4])
    unknown_nodes = sum(len(g[2]) for g in GROUPS if not g[4])
    per_unknown = (ORIGINAL_TOTAL - BASE_TOTAL - known) // unknown_nodes
    key = 95000
    first, last, out = {}, {}, []
    total_nodes, total_cost = 0, 0
    for name, stat, values, max_level, group_total, parent in GROUPS:
        n = len(values)
        weights = list(range(1, n + 1))
        node_totals = [group_total * w // sum(weights) for w in weights] if group_total else [per_unknown] * n
        prev = parent
        for i, v in enumerate(values):
            key += 1
            if isinstance(prev, str):
                prev = first[prev]
            lw = list(range(1, max_level + 1))
            costs = [max(1, node_totals[i] * w // sum(lw)) for w in lw]
            out.append((key, stat, max_level, prev, costs, [v] * max_level, name))
            if i == 0:
                first[name] = key
            last[name] = key
            prev = key
            total_nodes += 1
            total_cost += sum(costs)
    lines = [
        "-- 원작 1.2.0~1.3.0에 추가된 룬 노드 56개. tools/make_runes_added.py 가 만든 파일이므로 직접 고치지 않는다.",
        "-- [원작] 스탯, 노드 수, 레벨당 수치, 최대 레벨(데이터 v1.03.00의 스탯별 집계와 공식 패치노트)",
        "-- [추정] 묶음별 비용 합(tbhindex 요약) / [독자] 나머지 묶음의 비용, 레벨별 비용 비율, 연결",
        "-- 노드 3152(레이드 보스 추가 경험치)는 1.3.0에서 레벨당 2,000 → 10,000으로 바뀌었다 [원작].",
        "",
        "local _, WIH = ...",
        'local RuneData = WIH.module("RuneData")',
        "local nodes = RuneData.nodes",
        "",
        "if nodes[3152] then for i = 1, nodes[3152].max do nodes[3152].value[i] = 10000 end end",
        "",
    ]
    for key, stat, max_level, parent, costs, values, name in out:
        lines.append('nodes[%d] = { stat = "%s", max = %d, parent = %d, req = 1, cost = { %s }, value = { %s }, added = "%s" }'
                     % (key, stat, max_level, parent, ", ".join(str(c) for c in costs), ", ".join(str(v) for v in values), name))
    lines += ["", "return RuneData", ""]
    with open("WIH/Data/RunesAdded.lua", "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("nodes", total_nodes, "cost", total_cost, "per unknown node", per_unknown, "tree total", BASE_TOTAL + total_cost)


if __name__ == "__main__":
    main()
