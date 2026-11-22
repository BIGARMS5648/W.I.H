"""원작의 수치 표를 WIH/Data/Tables.lua 로 옮긴다.

입력은 조사 단계에서 내려받은 게임 데이터 추출 테이블(JSON)이 든 폴더다(taskbarhero.wiki 의 /data/t/*.json,
기준 버전 v1.00.17. 스테이지 레벨 배율표와 경험치 표는 v1.03.00 데이터와 완전히 같음을 조사 보고서에서 확인했다).
수치만 옮기고 이름·문장은 옮기지 않는다.

사용: python3 -I tools/import_tables.py <테이블 폴더>
"""
import json
import os
import sys

from fractions import Fraction

DIFF = {"NORMAL": 1, "NIGHTMARE": 2, "HELL": 3, "TORMENT": 4}


def round_half_even(x):
    """원작의 반올림(0.5는 짝수 쪽). x는 Fraction."""
    f = x.numerator // x.denominator
    diff = x - f
    if diff > Fraction(1, 2):
        return f + 1
    if diff < Fraction(1, 2):
        return f
    return f if f % 2 == 0 else f + 1


def final_values(mon, mult):
    """몬스터 한 종의 스테이지 레벨 적용값: round(기본값 × 배율 ÷ 1000). 돌려주는 값: hp, atk, gold, exp"""
    return (round_half_even(Fraction(mon["MaxLife"] * mult["MonsterHpMultiplier"], 1000)),
            round_half_even(Fraction(mon["AttackDamage"] * mult["MonsterAtkDmgMultiplier"], 1000)),
            round_half_even(Fraction(mon["RewardGold"] * mult["MonsterGoldMultiplier"], 1000)),
            round_half_even(Fraction(mon["RewardExp"] * mult["MonsterExpMultiplier"], 1000)))


def num(x):
    """Lua 숫자 표기. 정수면 정수로, 아니면 소수 넷째 자리까지."""
    x = Fraction(x)
    if x.denominator == 1:
        return str(x.numerator)
    return ("%.4f" % float(x)).rstrip("0").rstrip(".")


def load(folder, name):
    with open(os.path.join(folder, name), encoding="utf-8") as f:
        return json.load(f)


def main(folder):
    out = []
    w = out.append
    w("-- 원작의 수치 표 [원작]. tools/import_tables.py 가 만든 파일이므로 직접 고치지 않는다.")
    w("-- 출처: 게임 데이터 추출 테이블(v1.00.17). 경험치 표와 스테이지 레벨 배율표는 v1.03.00과 같다.")
    w("-- 배율의 단위는 퍼밀(1000 = 기본값 그대로)이다.")
    w("")
    w("local _, WIH = ...")
    w('local Tables = WIH.module("Tables")')
    w("")

    levels = sorted(load(folder, "levels.json"), key=lambda r: r["Level"])
    w("-- 레벨 n에서 다음 레벨까지 필요한 경험치. 100행이므로 최대 레벨은 101이다.")
    w("Tables.EXP = {")
    for i in range(0, len(levels), 5):
        w("    " + ", ".join(str(r["ExpForLevelUp"]) for r in levels[i:i + 5]) + ",")
    w("}")
    w("Tables.MAX_LEVEL = %d" % (len(levels) + 1))
    w("")

    sl = sorted(load(folder, "stage_levels.json"), key=lambda r: r["StageLevel"])
    w("-- 스테이지 레벨별 몬스터 배율: {공격력, 체력, 골드, 경험치}")
    w("Tables.STAGE_LEVEL = {")
    for r in sl:
        w("    { %d, %d, %d, %d }," % (r["MonsterAtkDmgMultiplier"], r["MonsterHpMultiplier"],
                                      r["MonsterGoldMultiplier"], r["MonsterExpMultiplier"]))
    w("}")
    w("")

    stages = sorted(load(folder, "stages.json"), key=lambda r: r["StageKey"])
    monsters = {m["MonsterKey"]: m for m in load(folder, "monsters.json")}
    mult_by_level = {r["StageLevel"]: r for r in sl}
    w("-- 스테이지 구조. 키 = 난이도(1~4) × 1000 + 액트 × 100 + 번호.")
    w("-- level, waves(웨이브 수), perWave(웨이브당 몬스터 수), chest/bossChest(상자 드롭률 퍼밀),")
    w("-- boss = {공격, 체력, 골드, 경험치 배율 퍼밀}, next(다음 스테이지 키), act(액트 보스 스테이지 여부)")
    w("-- mob = 그 스테이지에 나오는 일반 몬스터의 가중 평균(스테이지 레벨 적용, 원작 식으로 반올림한 뒤의 값):")
    w("--       { hp = 체력, dps = 공격력 × 공격속도, gold = 골드, exp = 경험치 }")
    w("-- bossFinal = 스테이지 보스의 최종값(보스 배율까지 적용): { hp, dps, gold, exp }")
    w("-- actBossFinal = 액트 보스의 최종값(보스 배율 없음): { hp, atk, as(공격속도 ×100), gold, exp }")
    w("-- 스테이지 표가 가리키지만 몬스터 표에 없는 종(20101, 액트 2의 8·9번 스테이지)은 평균에서 뺐다.")
    w("Tables.STAGES = {")
    missing = {}
    for r in stages:
        key = r["StageKey"]
        parts = ["level = %d" % r["StageLevel"]]
        mult = mult_by_level[r["StageLevel"]]
        if r["STAGETYPE"] == "ACTBOSS":
            parts.append("actBoss = true")
            b = monsters[r["BossMonsterKey"]]
            hp, atk, gold, exp = final_values(b, mult)
            parts.append("actBossFinal = { hp = %s, atk = %s, as = %d, gold = %s, exp = %s }"
                         % (num(hp), num(atk), b["AttackSpeed"], num(gold), num(exp)))
        else:
            total_w = 0
            acc = [Fraction(0)] * 4
            for part in r["Monsters"].split():
                mk, weight = part.split("_")
                weight = int(weight)
                m = monsters.get(int(mk))
                if m is None:
                    # 스테이지 표가 가리키지만 몬스터 표에 없는 종(v1.00.17 자료에서 20101). 평균에서 뺀다.
                    missing.setdefault(int(mk), []).append(key)
                    continue
                hp, atk, gold, exp = final_values(m, mult)
                vals = (Fraction(hp), Fraction(atk * m["AttackSpeed"], 100), Fraction(gold), Fraction(exp))
                acc = [a + v * weight for a, v in zip(acc, vals)]
                total_w += weight
            mob = [a / total_w for a in acc]
            b = monsters[r["BossMonsterKey"]]
            hp, atk, gold, exp = final_values(b, mult)
            boss = (Fraction(hp * r["BossHpMultiplier"], 1000),
                    Fraction(atk * r["BossDamageMultiplier"] * b["AttackSpeed"], 100000),
                    Fraction(gold * r["BossGoldMultiplier"], 1000),
                    Fraction(exp * r["BossExpMultiplier"], 1000))
            parts.append("waves = %d" % r["WaveAmount"])
            parts.append("perWave = %d" % r["WaveMonsterAmount"])
            parts.append("chest = %d" % r["MonsterDropItemRate"])
            parts.append("bossChest = %d" % r["BossDropItemRate"])
            parts.append("boss = { %d, %d, %d, %d }" % (r["BossDamageMultiplier"], r["BossHpMultiplier"],
                                                        r["BossGoldMultiplier"], r["BossExpMultiplier"]))
            parts.append("mob = { hp = %s, dps = %s, gold = %s, exp = %s }" % tuple(num(v) for v in mob))
            parts.append("bossFinal = { hp = %s, dps = %s, gold = %s, exp = %s }" % tuple(num(v) for v in boss))
        if r["NextStageKey"]:
            parts.append("next = %d" % r["NextStageKey"])
        assert DIFF[r["STAGEDIFFICULITY"]] == key // 1000
        w("    [%d] = { %s }," % (key, ", ".join(parts)))
    w("}")
    w("")

    off = sorted(load(folder, "offline_rewards.json"), key=lambda r: r["StageLevel"])
    w("-- 오프라인 보상표: 스테이지 레벨별 {기본 골드, 기본 경험치, 처치 수, 클리어 수}")
    w("Tables.OFFLINE = {")
    for r in off:
        w("    { %d, %d, %d, %d }," % (r["BaseGold"], r["BaseExp"], r["KillCount"], r["ClearCount"]))
    w("}")
    w("")

    out_path = os.path.join("WIH", "Data", "Tables.lua")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(out))
        f.write("\n-- 난이도별 영웅의 원소 저항 페널티 [원작]\n")
        f.write("Tables.RESIST_PENALTY = { 0, 20, 40, 60 }\n")
        f.write('Tables.DIFFICULTY_NAMES = { "일반", "악몽", "지옥", "고통" }\n\n')
        f.write("return Tables\n")
    print(out_path, "levels", len(levels), "stage levels", len(sl), "stages", len(stages), "offline", len(off))
    for mk, keys in sorted(missing.items()):
        print("몬스터 표에 없는 종", mk, "→ 평균에서 제외한 스테이지", keys)


if __name__ == "__main__":
    main(sys.argv[1])
