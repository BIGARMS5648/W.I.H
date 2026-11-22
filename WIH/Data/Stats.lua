-- 능력치 정의.
-- 이름과 정수 단위는 원작 데이터의 식별자와 같다(research/01 3.2절).
--   scale : 데이터의 정수를 실제 값으로 바꿀 때 나누는 수
--   base  : 수정치가 없을 때의 기본 정수값
-- 합산식 [원작]: 최종 = (기본 + ΣFlat) × (1 + ΣIncreased/1000) × Π(1 + More/1000)

local _, WIH = ...
local Stats = WIH.module("Stats")

Stats.FLAT = 1   -- 원작 표기 "+10"
Stats.INC = 2    -- 원작 표기 "10% Increased" (전부 더해 한 번 곱함). 값은 퍼밀
Stats.MORE = 3   -- 원작 표기 "10% More" (각각 따로 곱함). 값은 퍼밀

Stats.ELEMENTS = { "Physical", "Fire", "Cold", "Lightning", "Chaos" }
Stats.ELEMENT_NAMES = { Physical = "물리", Fire = "화염", Cold = "냉기", Lightning = "번개", Chaos = "암흑" }

local defs = {}
Stats.defs = defs

local function def(name, scale, base, label)
    defs[name] = { name = name, scale = scale or 1, base = base or 0, label = label or name }
end

-- 공격
def("AttackDamage", 1, 0, "공격력")
def("AttackSpeed", 100, 0, "공격속도")            -- 초당 기본 공격 횟수
def("CastSpeed", 100, 100, "시전속도")            -- 배율. 기본 1.00
def("CriticalChance", 1000, 0, "치명타 확률")
def("CriticalDamage", 1000, 1000, "치명타 피해")  -- 배율. 영웅 기본값이 덮어쓴다
for _, e in ipairs(Stats.ELEMENTS) do
    def(e .. "DamagePercent", 1000, 0, Stats.ELEMENT_NAMES[e] .. " 피해")
    def(e .. "DamageAddition", 1, 0, Stats.ELEMENT_NAMES[e] .. " 추가 피해")
    def(e .. "DamageReduction", 1000, 0, Stats.ELEMENT_NAMES[e] .. " 피해 감소")
    def("Taken" .. e, 1000, 0, Stats.ELEMENT_NAMES[e] .. " 피해 더 받음")   -- 디버프 전용 [독자 표현]
end
def("DamageAddition", 1, 0, "추가 피해")
def("IncreaseMeleeDamage", 1000, 1000, "근접 피해")
def("IncreaseProjectileDamage", 1000, 1000, "투사체 피해")
def("IncreaseAreaOfEffectDamage", 1000, 1000, "광역 피해")
def("IncreaseSummonDamage", 1000, 1000, "소환 피해")
def("IncreaseProjectileSpeed", 1000, 1000, "투사체 속도")
def("Multistrike", 1, 0, "연속 타격")
def("ProjectileCount", 1, 0, "투사체 수")
def("AreaOfEffect", 1000, 1000, "범위")
def("SkillRangeExpansion", 1000, 1000, "사거리")
def("DamageDealt", 1000, 1000, "주는 피해")       -- 버프 전용 [독자 표현]
def("TakenAll", 1000, 0, "모든 피해 더 받음")      -- 디버프 전용 [독자 표현]

-- 스킬
def("CooldownReduction", 1000, 0, "재사용 감소")
def("BaseAttackCountReduction", 1, 0, "기본공격 횟수 요구 감소")
def("SkillDurationIncrease", 1000, 1000, "지속시간")
def("SkillHealIncrease", 1000, 1000, "회복량")
def("AddAllSkillLevel", 1, 0, "모든 스킬 레벨")

-- 방어
def("MaxHp", 1, 0, "최대 체력")
def("Armor", 1, 0, "방어도")
def("FireResistance", 1, 0, "화염 저항")
def("ColdResistance", 1, 0, "냉기 저항")
def("LightningResistance", 1, 0, "번개 저항")
def("ChaosResistance", 1, 0, "암흑 저항")
def("AllElementalResistance", 1, 0, "모든 원소 저항")
def("MaxFireResistance", 1, 75, "최대 화염 저항")
def("MaxColdResistance", 1, 75, "최대 냉기 저항")
def("MaxLightningResistance", 1, 75, "최대 번개 저항")
def("MaxChaosResistance", 1, 75, "최대 암흑 저항")
def("DodgeChance", 1000, 0, "회피")
def("ElementalDodgeChance", 1000, 0, "원소 회피")
def("MaxDodgeChance", 1000, 750, "최대 회피")
def("MaxElementalDodgeChance", 1000, 750, "최대 원소 회피")
def("BlockChance", 1000, 0, "막기")
def("ElementalBlockChance", 1000, 0, "원소 막기")
def("MaxBlockChance", 1000, 750, "최대 막기")
def("MaxElementalBlockChance", 1000, 750, "최대 원소 막기")
def("DamageReduction", 1000, 0, "피해 감소")
def("DamageAbsorption", 10, 0, "피해 흡수")

-- 회복
def("HpRegenPerSec", 100, 0, "초당 재생")
def("HpLeech", 1000, 0, "생명력 흡수")
def("AddHpPerHit", 1, 0, "타격당 회복")
def("AddHpPerKill", 1, 0, "처치당 회복")
def("HealingTaken", 1000, 1000, "받는 회복")          -- 디버프 전용 [독자 표현]

-- 이동, 획득
def("MovementSpeed", 1, 0, "이동속도")
def("IncreaseExpAmount", 1000, 1000, "경험치 획득")
def("AdditionalExp", 1, 0, "처치당 추가 경험치")

-- 상한 [원작 / 추정]. 값은 실제 단위.
Stats.CAP_CRIT = 1.0
Stats.CAP_COOLDOWN_REDUCTION = 0.75
Stats.CAP_DAMAGE_REDUCTION = 0.75
Stats.CAP_ARMOR_MELEE = 0.85
Stats.CAP_ARMOR_RANGED = 0.75
Stats.CAP_MOVE_MULT = 3.0   -- [독자] 원작은 상한의 존재만 확인됨

function Stats.exists(name)
    return defs[name] ~= nil
end

return Stats
