-- 전투 장면과 영웅 화면에 쓰는 3D 모델의 대응표. 값은 클라이언트의 생물(NPC) 번호다.
-- 게임 내 확인(2026-11-22): PlayerModel:SetCreature(번호)로 모델이 불러와진다(11502, 10184, 3098로 확인).
-- 아래 번호는 오리지널의 번호를 기억에 의존해 적은 것이다. 틀린 번호는 다른 모델이 나오거나 아무것도 나오지 않는다.
-- 나오지 않으면 다음 후보를 쓰고, 후보가 모두 실패하면 아이콘 표시로 바뀐다. 설정 화면의 "모델 점검"으로 확인할 수 있다.

local _, WIH = ...
local Models = WIH.module("Models")

-- 영웅: 직업 상급자 NPC. { 얼라이언스, 호드 }. 한쪽 진영에 그 직업이 없으면 같은 번호를 쓴다.
Models.HEROES = {
    war_arms = { 911, 3153 }, war_fury = { 913, 3169 }, war_prot = { 914, 3353 },
    pal_holy = { 925, 925 }, pal_prot = { 928, 928 }, pal_ret = { 927, 927 },
    hun_bm = { 895, 3154 }, hun_mm = { 5515, 3352 }, hun_sv = { 3596, 3171 },
    rog_assa = { 915, 3155 }, rog_combat = { 917, 3170 }, rog_sub = { 918, 3401 },
    pri_disc = { 375, 3707 }, pri_holy = { 376, 3706 }, pri_shadow = { 377, 6018 },
    sha_ele = { 3157, 3157 }, sha_enh = { 3173, 3173 }, sha_resto = { 3344, 3344 },
    mag_arcane = { 198, 5884 }, mag_fire = { 328, 5882 }, mag_frost = { 331, 5885 },
    wlk_aff = { 459, 3156 }, wlk_demo = { 461, 3172 }, wlk_destro = { 906, 3324 },
    dru_balance = { 3597, 3060 }, dru_feral = { 3602, 3064 }, dru_resto = { 4217, 3033 },
    tin_armor = { 7944, 11017 }, tin_destroy = { 5174, 3494 }, tin_medic = { 5518, 8126 },
}
-- 야성 드루이드의 형태
Models.FORMS = { bear = 822, cat = 2032 }

-- 몬스터와 보스: [몬스터 ID] = 생물 번호
Models.MONSTERS = {
    -- 성난불길 협곡
    rfc_trogg = 11318, rfc_shaman = 11319, rfc_cultist = 11322, rfc_warlock = 11324, rfc_elemental = 11321,
    rfc_oggleflint = 11517, rfc_taragaman = 11520, rfc_jergosh = 11518, rfc_bazzalan = 11519,
    -- 통곡의 동굴
    wc_raptor = 3636, wc_druid = 3840, wc_ooze = 3638, wc_viper = 5755,
    wc_anacondra = 3671, wc_cobrahn = 3669, wc_pythas = 3670, wc_skum = 3674, wc_serpentis = 3673, wc_verdan = 5775, wc_mutanus = 3654,
    -- 죽음의 폐광
    dm_miner = 598, dm_overseer = 634, dm_evoker = 1729, dm_pirate = 657, dm_gunner = 636,
    dm_rhahkzor = 644, dm_sneed = 642, dm_gilnid = 1763, dm_smite = 646, dm_greenskin = 647, dm_vancleef = 639,
    -- 그림자송곳니 성채
    sfk_worg = 3861, sfk_worgen = 3851, sfk_ghost = 3873, sfk_mage = 3853, sfk_bat = 3866,
    sfk_razorclaw = 3886, sfk_silverlaine = 3887, sfk_springvale = 4278, sfk_odo = 4279, sfk_fenrus = 4274, sfk_nandos = 3927, sfk_arugal = 4275,
    -- 검은심연 나락
    bfd_naga = 4807, bfd_siren = 4805, bfd_acolyte = 4809, bfd_turtle = 4825, bfd_murloc = 4818,
    bfd_ghamoora = 4887, bfd_sarevess = 4831, bfd_gelihast = 6243, bfd_serrakis = 4830, bfd_kelris = 4832, bfd_akumai = 4829,
    -- 스톰윈드 지하감옥
    stk_prisoner = 1706, stk_convict = 1711, stk_insurgent = 1715, stk_inmate = 1708,
    stk_targorr = 1696, stk_kam = 1666, stk_hamhock = 1717, stk_bazil = 1716, stk_dextren = 1663,
    -- 놈리건
    gno_invader = 6213, gno_sentry = 6233, gno_tank = 6225, gno_bomb = 7915,
    gno_grubbis = 7361, gno_fallout = 7079, gno_electrocutioner = 6235, gno_pummeler = 6229, gno_thermaplugg = 7800,
    -- 가시덩굴 우리
    rfk_defender = 4442, rfk_geomancer = 4520, rfk_boar = 4511, rfk_priest = 4517, rfk_bat = 4538,
    rfk_jargba = 4428, rfk_ramtusk = 4420, rfk_agathelos = 4422, rfk_halmgar = 4842, rfk_charlga = 4421,
    -- 붉은십자군 수도원
    smg_torturer = 4306, smg_spirit = 4308, smg_vishas = 3983, smg_thalnos = 4543,
    sml_hound = 4304, sml_beastmaster = 4288, sml_adept = 4296, sml_monk = 4540, sml_diviner = 4291, sml_loksey = 3974, sml_doan = 6487,
    sma_soldier = 4286, sma_defender = 4298, sma_myrmidon = 4295, sma_evoker = 4289, sma_herod = 3975,
    smc_champion = 4302, smc_abbot = 4303, smc_wizard = 4300, smc_centurion = 4301, smc_chaplain = 4299,
    smc_fairbanks = 4542, smc_mograine = 3976, smc_whitemane = 3977,
    -- 가시덩굴 구릉
    rfd_necro = 7337, rfd_warrior = 7873,
    rfd_tutenkash = 7355, rfd_mordresh = 7357, rfd_glutton = 8567, rfd_ragglesnout = 7354, rfd_amnennar = 7358,
    -- 울다만
    uld_revelosh = 6910, uld_ironaya = 7228, uld_obsidian = 7023, uld_keeper = 7206, uld_galgann = 7291, uld_grimlok = 4854, uld_archaedas = 2748,
    -- 줄파락
    zf_antusul = 8127, zf_theka = 7272, zf_zumrah = 7271, zf_nekrum = 7796, zf_sezzziz = 7275, zf_ukorz = 7267, zf_gahzrilla = 7273,
    -- 마라우돈
    mar_noxxion = 13282, mar_razorlash = 12258, mar_vyletongue = 12236, mar_celebras = 12225,
    mar_landslide = 12203, mar_gizlock = 13601, mar_rotgrip = 13596, mar_theradras = 12201,
    -- 아탈학카르 신전
    st_alarion = 8580, st_dreamscythe = 5721, st_weaver = 5720, st_avatar = 8443, st_jammalan = 5710, st_eranikus = 5709,
    -- 검은바위 나락
    brd_gerstahn = 9018, brd_roccor = 9025, brd_grebmar = 9319, brd_loregrain = 9024, brd_incendius = 9017, brd_angerforge = 9033,
    brd_argelmach = 8983, brd_flamelash = 9156, brd_magmus = 9938, brd_thaurissan = 9019,
    -- 검은바위 첨탑 하층
    lbrs_omokk = 9196, lbrs_voshgajin = 9236, lbrs_voone = 9237, lbrs_smolderweb = 10596, lbrs_urok = 10584, lbrs_zigris = 9736,
    lbrs_halycon = 10220, lbrs_gizrul = 10268, lbrs_wyrmthalak = 9568,
    -- 혈투의 전장
    dme_zevrim = 11490, dme_hydrospawn = 13280, dme_lethtendris = 14327, dme_alzzin = 11492,
    dmw_tendris = 11489, dmw_illyanna = 11488, dmw_kalendris = 11487, dmw_immolthar = 11496, dmw_tortheldrin = 11486,
    dmn_moldar = 14326, dmn_stomper = 14322, dmn_fengus = 14321, dmn_slipkik = 14323, dmn_kromcrush = 14325, dmn_chorush = 14324, dmn_gordok = 11501,
    -- 스칼로맨스
    sch_kirtonos = 10506, sch_jandice = 10503, sch_rattlegore = 11622, sch_rasfrost = 10508, sch_malicia = 10505, sch_krastinov = 11261,
    sch_polkelt = 10901, sch_ravenian = 10507, sch_alexei = 10504, sch_gandling = 1853,
    -- 스트라솔름
    stl_malown = 11143, stl_unforgiven = 10516, stl_timmy = 10808, stl_willey = 10997, stl_galford = 10811, stl_balnazzar = 10813,
    stu_anastari = 10436, stu_nerubenkan = 10437, stu_maleki = 10438, stu_magistrate = 10435, stu_ramstein = 10439, stu_rivendare = 10440,
    -- 검은바위 첨탑 상층
    ubrs_emberseer = 9816, ubrs_solakar = 10264, ubrs_gyth = 10339, ubrs_rend = 10429, ubrs_beast = 10430, ubrs_drakkisath = 10363,
    -- 레이드
    ony_onyxia = 10184,
    mc_lucifron = 12118, mc_magmadar = 11982, mc_gehennas = 12259, mc_garr = 12057, mc_geddon = 12056, mc_shazzrah = 12264,
    mc_sulfuron = 12098, mc_golemagg = 11988, mc_majordomo = 12018, mc_ragnaros = 11502,
    bwl_razorgore = 12435, bwl_vaelastrasz = 13020, bwl_lashlayer = 12017, bwl_firemaw = 11983, bwl_ebonroc = 14601, bwl_flamegor = 11981,
    bwl_chromaggus = 14020, bwl_nefarian = 11583,
    -- 원정: 줄구룹
    zg_venoxis = 14507, zg_jeklik = 14517, zg_marli = 14510, zg_thekal = 14509, zg_arlokk = 14515, zg_mandokir = 11382,
    zg_jindo = 11380, zg_hakkar = 14834,
    zg_berserker = 11351, zg_shadowhunter = 11339, zg_bat = 14965, zg_witchdoctor = 11831, zg_razzashi = 11371, zg_axe = 11350,
    -- 원정: 안퀴라즈 폐허
    aq20_kurinnaxx = 15348, aq20_rajaxx = 15341, aq20_moam = 15340, aq20_buru = 15370, aq20_ayamiss = 15369, aq20_ossirian = 15339,
    aq20_warrior = 15343, aq20_swarmguard = 15319, aq20_stinger = 15327, aq20_obsidian = 15338, aq20_soldier = 15387, aq20_mage = 15335,
    -- 원정: 안퀴라즈 사원
    aq40_skeram = 15263, aq40_bug = 15544, aq40_sartura = 15516, aq40_fankriss = 15510, aq40_viscidus = 15299, aq40_huhuran = 15509,
    aq40_twins = 15276, aq40_cthun = 15727,
    aq40_anubisath = 15240, aq40_reaver = 15229, aq40_templar = 15262, aq40_drone = 15233, aq40_obsidian = 15312, aq40_prophet = 15247,
    -- 낙스라마스
    nx_anubrekhan = 15956, nx_faerlina = 15953, nx_maexxna = 15952, nx_noth = 15954, nx_heigan = 15936, nx_loatheb = 16011,
    nx_razuvious = 16061, nx_gothik = 16060, nx_horsemen = 16064, nx_patchwerk = 16028, nx_grobbulus = 15931, nx_gluth = 15932,
    nx_thaddius = 15928, nx_sapphiron = 15989, nx_kelthuzad = 15990,
}

-- 번호를 따로 적지 않은 몬스터가 쓰는 유형별 대체 모델
Models.ARCHETYPES = {
    grunt = 38, soldier = 440, brute = 1178, tank = 36, fast = 299, swarm = 1512, stalker = 3123, berserk = 1535,
    caster = 474, archer = 1535, boss = 1178,
}

-- 소환물: 주인의 직업에 따른 대체 모델
Models.SUMMONS = {
    HUNTER = 299, WARLOCK = 416, SHAMAN = 3527, MAGE = 510, DRUID = 1964, TINKER = 2673, PRIEST = 1860, PALADIN = 2673, WARRIOR = 2673, ROGUE = 2673,
}
Models.SUMMON_OF_MONSTER = 1512

-- 유닛에 쓸 모델 후보를 차례로 돌려준다(없으면 빈 표). faction = "Alliance" | "Horde"
function Models.candidates(u, faction)
    local out = {}
    if u.kind == "hero" and u.heroId then
        if u.form and Models.FORMS[u.form] then out[#out + 1] = Models.FORMS[u.form] end
        local pair = Models.HEROES[u.heroId]
        if pair then
            out[#out + 1] = pair[faction == "Horde" and 2 or 1]
            if pair[1] ~= pair[2] then out[#out + 1] = pair[faction == "Horde" and 1 or 2] end
        end
    elseif u.kind == "summon" then
        local owner = u.owner
        local class = owner and owner.def and owner.def.class
        out[#out + 1] = class and Models.SUMMONS[class] or Models.SUMMON_OF_MONSTER
    else
        local def = u.def
        if def then
            if Models.MONSTERS[def.id] then out[#out + 1] = Models.MONSTERS[def.id] end
            if def.archetype and Models.ARCHETYPES[def.archetype] then out[#out + 1] = Models.ARCHETYPES[def.archetype] end
        end
    end
    return out
end

-- 영웅 화면처럼 유닛 없이 영웅 ID만 있을 때
function Models.heroCandidates(heroId, faction, form)
    return Models.candidates({ kind = "hero", heroId = heroId, form = form }, faction)
end

return Models
