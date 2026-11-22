"""창고(Stash) 칸 해금 비용을 WIH/Data/StashTable.lua 로 옮긴다.

입력: 조사 단계에서 내려받은 v1.00.17 표 t_stash.json(칸 번호별 해금 비용). 저장소에는 없다.
사용: python3 -I tools/import_stash.py <t_stash.json>
"""
import json
import sys


def main(path):
    rows = sorted(json.load(open(path, encoding="utf-8")), key=lambda r: r["Index"])
    assert [r["Index"] for r in rows] == list(range(len(rows)))
    free = sum(1 for r in rows if r["CostForUnlock"] == 0)
    costs = [r["CostForUnlock"] for r in rows[free:]]
    out = [
        "-- 창고 칸 해금 비용 [원작 v1.00.17 t_stash]. tools/import_stash.py 가 만든 파일이므로 직접 고치지 않는다.",
        "",
        "local _, WIH = ...",
        'local StashTable = WIH.module("StashTable")',
        "",
        "StashTable.FREE = %d          -- 처음부터 열린 칸 수" % free,
        "StashTable.MAX = %d           -- 한 페이지의 최대 칸 수" % len(rows),
        "StashTable.COST = { %s }      -- %d번째 칸부터 차례로" % (", ".join(str(c) for c in costs), free + 1),
        "",
        "return StashTable",
        "",
    ]
    open("WIH/Data/StashTable.lua", "w", encoding="utf-8").write("\n".join(out))
    print("free", free, "max", len(rows), "total", sum(costs))


if __name__ == "__main__":
    main(sys.argv[1])
