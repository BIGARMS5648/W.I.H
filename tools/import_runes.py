"""원작 룬 트리(v1.00.17, 197노드)의 구조와 수치를 WIH/Data/Runes.lua 로 옮긴다.

노드의 스탯, 최대 레벨, 레벨별 비용과 수치, 연결 관계만 옮긴다. 이름·아이콘·좌표는 옮기지 않는다.
사용: python3 -I tools/import_runes.py <t_runes.json 이 있는 폴더>
"""
import json
import os
import sys


def main(folder):
    runes = json.load(open(os.path.join(folder, "t_runes.json"), encoding="utf-8"))
    levels = json.load(open(os.path.join(folder, "t_rune_levels.json"), encoding="utf-8"))
    by_key = {}
    for row in levels:
        by_key.setdefault(row["LevelKey"], []).append(row)
    parent = {}
    for r in runes:
        nxt = r.get("NextRuneKey")
        if nxt:
            for child in str(nxt).split():
                parent[int(child)] = r["RuneKey"]

    out = []
    w = out.append
    w("-- 룬 트리 [원작 v1.00.17: 197노드의 스탯·최대 레벨·레벨별 비용과 수치·연결]. tools/import_runes.py 가 만든 파일.")
    w("-- 각 줄: [키] = { stat, max, parent, req(부모에게 요구하는 레벨), cost = {레벨별 골드}, value = {레벨별 증가량} }")
    w("-- 퍼센트형 스탯의 수치는 퍼밀(100 = 10%)이다. 1.2.0 이후에 추가된 노드는 들어 있지 않다(docs/STATUS.md).")
    w("")
    w("local _, WIH = ...")
    w('local RuneData = WIH.module("RuneData")')
    w("")
    w("RuneData.nodes = {")
    count = 0
    for r in sorted(runes, key=lambda x: x["RuneKey"]):
        key = r["RuneKey"]
        rows = sorted(by_key.get(r["LevelDataKey"], []), key=lambda x: x["Level"])
        rows = rows[: r["MaxLevel"]]          # 409번처럼 최대 레벨보다 행이 많은 노드가 있다
        assert rows, key
        assert len({row["STATTYPE"] for row in rows}) == 1, key
        assert all(row["CostItemKey"] == 100001 for row in rows), key
        stat = rows[0]["STATTYPE"]
        p = parent.get(key)
        req = r.get("PrevNodeRequiredLevel") or 1
        parts = ['stat = "%s"' % stat, "max = %d" % len(rows)]
        if p is not None:
            parts.append("parent = %d" % p)
            parts.append("req = %d" % req)
        parts.append("cost = { %s }" % ", ".join(str(row["CostValue"]) for row in rows))
        parts.append("value = { %s }" % ", ".join(str(row["Value"]) for row in rows))
        w("    [%d] = { %s }," % (key, ", ".join(parts)))
        count += 1
    w("}")
    w("")
    roots = [r["RuneKey"] for r in runes if r["RuneKey"] not in parent]
    w("-- 부모가 없는 노드: %s" % ", ".join(str(k) for k in sorted(roots)))
    w("RuneData.ROOT = %d" % min(roots))
    w("")
    w("return RuneData")
    with open(os.path.join("WIH", "Data", "Runes.lua"), "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    print("nodes", count, "roots", sorted(roots))


if __name__ == "__main__":
    main(sys.argv[1])
