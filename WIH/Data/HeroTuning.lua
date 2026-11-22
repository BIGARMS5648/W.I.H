-- 영웅별 화력 보정 계수 [독자]. Test/tune_heroes.lua 가 만든 파일이므로 직접 고치지 않는다.
-- 영웅의 모든 피해(기본 공격, 스킬, 지속 피해, 소환물)에 곱한다. 역할 묶음(딜러·탱커·힐러)의 중앙값에 맞춘 값이다.

local _, WIH = ...
local HeroTuning = WIH.module("HeroTuning")

HeroTuning.damage = {
    ["dru_balance"] = 1.35,
    ["dru_feral:bear"] = 0.65,
    ["dru_feral:cat"] = 1.21,
    ["dru_resto"] = 1.18,
    ["hun_bm"] = 0.48,
    ["hun_mm"] = 1.08,
    ["hun_sv"] = 1.38,
    ["mag_arcane"] = 0.99,
    ["mag_fire"] = 0.65,
    ["mag_frost"] = 1.43,
    ["pal_holy"] = 0.68,
    ["pal_prot"] = 0.98,
    ["pal_ret"] = 0.58,
    ["pri_disc"] = 0.90,
    ["pri_holy"] = 0.57,
    ["pri_shadow"] = 1.75,
    ["rog_assa"] = 1.00,
    ["rog_combat"] = 0.85,
    ["rog_sub"] = 0.60,
    ["sha_ele"] = 0.98,
    ["sha_enh"] = 1.58,
    ["sha_resto"] = 1.13,
    ["tin_armor"] = 1.20,
    ["tin_destroy"] = 0.40,
    ["tin_medic"] = 1.13,
    ["war_arms"] = 0.51,
    ["war_fury"] = 0.99,
    ["war_prot"] = 0.94,
    ["wlk_aff"] = 1.44,
    ["wlk_demo"] = 0.41,
    ["wlk_destro"] = 1.04,
}

return HeroTuning
