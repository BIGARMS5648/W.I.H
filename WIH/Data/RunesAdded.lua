-- 원작 1.2.0~1.3.0에 추가된 룬 노드 56개. tools/make_runes_added.py 가 만든 파일이므로 직접 고치지 않는다.
-- [원작] 스탯, 노드 수, 레벨당 수치, 최대 레벨(데이터 v1.03.00의 스탯별 집계와 공식 패치노트)
-- [추정] 묶음별 비용 합(tbhindex 요약) / [독자] 나머지 묶음의 비용, 레벨별 비용 비율, 연결
-- 노드 3152(레이드 보스 추가 경험치)는 1.3.0에서 레벨당 2,000 → 10,000으로 바뀌었다 [원작].

local _, WIH = ...
local RuneData = WIH.module("RuneData")
local nodes = RuneData.nodes

if nodes[3152] then for i = 1, nodes[3152].max do nodes[3152].value[i] = 10000 end end

nodes[95001] = { stat = "AdditionalExpActBoss", max = 5, parent = 3152, req = 1, cost = { 74299385, 148598771, 222898157, 297197543, 371496929 }, value = { 3000, 3000, 3000, 3000, 3000 }, added = "growth_act" }
nodes[95002] = { stat = "AdditionalExpActBoss", max = 5, parent = 95001, req = 1, cost = { 74299385, 148598771, 222898157, 297197543, 371496929 }, value = { 4000, 4000, 4000, 4000, 4000 }, added = "growth_act" }
nodes[95003] = { stat = "AllHeroArmor", max = 5, parent = 410, req = 1, cost = { 74299385, 148598771, 222898157, 297197543, 371496929 }, value = { 5, 5, 5, 5, 5 }, added = "shield" }
nodes[95004] = { stat = "AllHeroArmor", max = 5, parent = 95003, req = 1, cost = { 74299385, 148598771, 222898157, 297197543, 371496929 }, value = { 5, 5, 5, 5, 5 }, added = "shield" }
nodes[95005] = { stat = "AllHeroArmorPercent", max = 5, parent = 412, req = 1, cost = { 74299385, 148598771, 222898157, 297197543, 371496929 }, value = { 20, 20, 20, 20, 20 }, added = "shield_pct" }
nodes[95006] = { stat = "AllHeroAttackDamage", max = 5, parent = 4081, req = 1, cost = { 13500000, 27000000, 40500000, 54000000, 67500000 }, value = { 1, 1, 1, 1, 1 }, added = "war" }
nodes[95007] = { stat = "AllHeroAttackDamage", max = 5, parent = 95006, req = 1, cost = { 27000000, 54000000, 81000000, 108000000, 135000000 }, value = { 1, 1, 1, 1, 1 }, added = "war" }
nodes[95008] = { stat = "AllHeroAttackDamage", max = 5, parent = 95007, req = 1, cost = { 40500000, 81000000, 121500000, 162000000, 202500000 }, value = { 2, 2, 2, 2, 2 }, added = "war" }
nodes[95009] = { stat = "AllHeroAttackDamagePercent", max = 5, parent = 413, req = 1, cost = { 4666666, 9333333, 14000000, 18666666, 23333333 }, value = { 20, 20, 20, 20, 20 }, added = "war_pct" }
nodes[95010] = { stat = "AllHeroAttackSpeed", max = 5, parent = 4061, req = 1, cost = { 74299385, 148598771, 222898157, 297197543, 371496929 }, value = { 20, 20, 20, 20, 20 }, added = "frenzy" }
nodes[95011] = { stat = "AllHeroMoveSpeed", max = 5, parent = 4101, req = 1, cost = { 74299385, 148598771, 222898157, 297197543, 371496929 }, value = { 10, 10, 10, 10, 10 }, added = "gale" }
nodes[95012] = { stat = "CubeAlchemyGoldPercent", max = 5, parent = 3122, req = 1, cost = { 74299385, 148598771, 222898157, 297197543, 371496929 }, value = { 20, 20, 20, 20, 20 }, added = "alchemy" }
nodes[95013] = { stat = "CubeExpPercent", max = 5, parent = 3121, req = 1, cost = { 74299385, 148598771, 222898157, 297197543, 371496929 }, value = { 20, 20, 20, 20, 20 }, added = "forging" }
nodes[95014] = { stat = "DropChanceNormalChestPercent", max = 5, parent = 127, req = 1, cost = { 74299385, 148598771, 222898157, 297197543, 371496929 }, value = { 50, 50, 50, 50, 50 }, added = "explore" }
nodes[95015] = { stat = "DropChanceNormalChestPercent", max = 5, parent = 95014, req = 1, cost = { 74299385, 148598771, 222898157, 297197543, 371496929 }, value = { 50, 50, 50, 50, 50 }, added = "explore" }
nodes[95016] = { stat = "DropChanceStageBossChestPercent", max = 5, parent = 128, req = 1, cost = { 74299385, 148598771, 222898157, 297197543, 371496929 }, value = { 100, 100, 100, 100, 100 }, added = "conquest" }
nodes[95017] = { stat = "DropChanceStageBossChestPercent", max = 5, parent = 95016, req = 1, cost = { 74299385, 148598771, 222898157, 297197543, 371496929 }, value = { 100, 100, 100, 100, 100 }, added = "conquest" }
nodes[95018] = { stat = "OfflineRewardExpPercent", max = 5, parent = 180701, req = 1, cost = { 74299385, 148598771, 222898157, 297197543, 371496929 }, value = { 50, 50, 50, 50, 50 }, added = "training" }
nodes[95019] = { stat = "OfflineRewardExpPercent", max = 5, parent = 95018, req = 1, cost = { 74299385, 148598771, 222898157, 297197543, 371496929 }, value = { 50, 50, 50, 50, 50 }, added = "training" }
nodes[95020] = { stat = "OfflineRewardExpPercent", max = 5, parent = 95019, req = 1, cost = { 74299385, 148598771, 222898157, 297197543, 371496929 }, value = { 50, 50, 50, 50, 50 }, added = "training" }
nodes[95021] = { stat = "WaveCountReduction", max = 1, parent = 1171, req = 1, cost = { 216666666 }, value = { 1 }, added = "brevity" }
nodes[95022] = { stat = "WaveCountReduction", max = 1, parent = 95021, req = 1, cost = { 433333333 }, value = { 1 }, added = "brevity" }
nodes[95023] = { stat = "DropChancePlagueNormalChestPercent", max = 5, parent = 21, req = 1, cost = { 31433333, 62866666, 94300000, 125733333, 157166666 }, value = { 125, 125, 125, 125, 125 }, added = "p_explore" }
nodes[95024] = { stat = "DropChancePlagueNormalChestPercent", max = 5, parent = 95023, req = 1, cost = { 62866666, 125733333, 188600000, 251466666, 314333333 }, value = { 125, 125, 125, 125, 125 }, added = "p_explore" }
nodes[95025] = { stat = "DropChancePlagueNormalChestPercent", max = 5, parent = 95024, req = 1, cost = { 94300000, 188600000, 282900000, 377200000, 471500000 }, value = { 125, 125, 125, 125, 125 }, added = "p_explore" }
nodes[95026] = { stat = "DropChancePlagueNormalChestPercent", max = 5, parent = 95025, req = 1, cost = { 125733333, 251466666, 377200000, 502933333, 628666666 }, value = { 125, 125, 125, 125, 125 }, added = "p_explore" }
nodes[95027] = { stat = "DropChancePlagueStageBossChestPercent", max = 5, parent = 95023, req = 1, cost = { 74299385, 148598771, 222898157, 297197543, 371496929 }, value = { 300, 300, 300, 300, 300 }, added = "p_conquest" }
nodes[95028] = { stat = "DropChancePlagueStageBossChestPercent", max = 5, parent = 95027, req = 1, cost = { 74299385, 148598771, 222898157, 297197543, 371496929 }, value = { 400, 400, 400, 400, 400 }, added = "p_conquest" }
nodes[95029] = { stat = "DropChancePlagueStageBossChestPercent", max = 5, parent = 95028, req = 1, cost = { 74299385, 148598771, 222898157, 297197543, 371496929 }, value = { 400, 400, 400, 400, 400 }, added = "p_conquest" }
nodes[95030] = { stat = "MaxAmountPlagueNormalChest", max = 1, parent = 95023, req = 1, cost = { 51400000 }, value = { 1 }, added = "p_contain" }
nodes[95031] = { stat = "MaxAmountPlagueNormalChest", max = 1, parent = 95030, req = 1, cost = { 102800000 }, value = { 1 }, added = "p_contain" }
nodes[95032] = { stat = "MaxAmountPlagueNormalChest", max = 1, parent = 95031, req = 1, cost = { 154200000 }, value = { 1 }, added = "p_contain" }
nodes[95033] = { stat = "MaxAmountPlagueNormalChest", max = 1, parent = 95032, req = 1, cost = { 205600000 }, value = { 1 }, added = "p_contain" }
nodes[95034] = { stat = "MaxAmountPlagueNormalChest", max = 1, parent = 95033, req = 1, cost = { 257000000 }, value = { 1 }, added = "p_contain" }
nodes[95035] = { stat = "MaxAmountPlagueStageBossChest", max = 1, parent = 95027, req = 1, cost = { 104333333 }, value = { 1 }, added = "p_vault" }
nodes[95036] = { stat = "MaxAmountPlagueStageBossChest", max = 1, parent = 95035, req = 1, cost = { 208666666 }, value = { 1 }, added = "p_vault" }
nodes[95037] = { stat = "MaxAmountPlagueStageBossChest", max = 1, parent = 95036, req = 1, cost = { 313000000 }, value = { 1 }, added = "p_vault" }
nodes[95038] = { stat = "MaxAmountPlagueStageBossChest", max = 1, parent = 95037, req = 1, cost = { 417333333 }, value = { 1 }, added = "p_vault" }
nodes[95039] = { stat = "MaxAmountPlagueStageBossChest", max = 1, parent = 95038, req = 1, cost = { 521666666 }, value = { 1 }, added = "p_vault" }
nodes[95040] = { stat = "MaxAmountPlagueActBossChest", max = 1, parent = 95027, req = 1, cost = { 169333333 }, value = { 1 }, added = "p_infinity" }
nodes[95041] = { stat = "MaxAmountPlagueActBossChest", max = 1, parent = 95040, req = 1, cost = { 338666666 }, value = { 1 }, added = "p_infinity" }
nodes[95042] = { stat = "MaxAmountPlagueActBossChest", max = 1, parent = 95041, req = 1, cost = { 508000000 }, value = { 1 }, added = "p_infinity" }
nodes[95043] = { stat = "MaxAmountPlagueActBossChest", max = 1, parent = 95042, req = 1, cost = { 677333333 }, value = { 1 }, added = "p_infinity" }
nodes[95044] = { stat = "MaxAmountPlagueActBossChest", max = 1, parent = 95043, req = 1, cost = { 846666666 }, value = { 1 }, added = "p_infinity" }
nodes[95045] = { stat = "UnlockAutoOpenPlagueNormalChest", max = 1, parent = 95030, req = 1, cost = { 30000000 }, value = { 600 }, added = "p_spring_n" }
nodes[95046] = { stat = "UnlockAutoOpenPlagueStageBossChest", max = 1, parent = 95035, req = 1, cost = { 75000000 }, value = { 1200 }, added = "p_spring_s" }
nodes[95047] = { stat = "UnlockAutoOpenPlagueActBossChest", max = 1, parent = 95040, req = 1, cost = { 150000000 }, value = { 120 }, added = "p_spring_a" }
nodes[95048] = { stat = "ReduceAutoOpenPlagueNormalChestTime", max = 5, parent = 95045, req = 1, cost = { 26111111, 52222222, 78333333, 104444444, 130555555 }, value = { 4, 4, 4, 4, 4 }, added = "p_lube_n" }
nodes[95049] = { stat = "ReduceAutoOpenPlagueNormalChestTime", max = 5, parent = 95048, req = 1, cost = { 52222222, 104444444, 156666666, 208888888, 261111111 }, value = { 4, 4, 4, 4, 4 }, added = "p_lube_n" }
nodes[95050] = { stat = "ReduceAutoOpenPlagueNormalChestTime", max = 5, parent = 95049, req = 1, cost = { 78333333, 156666666, 235000000, 313333333, 391666666 }, value = { 4, 4, 4, 4, 4 }, added = "p_lube_n" }
nodes[95051] = { stat = "ReduceAutoOpenPlagueStageBossChestTime", max = 5, parent = 95046, req = 1, cost = { 26111111, 52222222, 78333333, 104444444, 130555555 }, value = { 8, 8, 8, 8, 8 }, added = "p_lube_s" }
nodes[95052] = { stat = "ReduceAutoOpenPlagueStageBossChestTime", max = 5, parent = 95051, req = 1, cost = { 52222222, 104444444, 156666666, 208888888, 261111111 }, value = { 8, 8, 8, 8, 8 }, added = "p_lube_s" }
nodes[95053] = { stat = "ReduceAutoOpenPlagueStageBossChestTime", max = 5, parent = 95052, req = 1, cost = { 78333333, 156666666, 235000000, 313333333, 391666666 }, value = { 8, 8, 8, 8, 8 }, added = "p_lube_s" }
nodes[95054] = { stat = "ReduceAutoOpenPlagueActBossChestTime", max = 5, parent = 95047, req = 1, cost = { 26111111, 52222222, 78333333, 104444444, 130555555 }, value = { 1, 1, 1, 1, 1 }, added = "p_lube_a" }
nodes[95055] = { stat = "ReduceAutoOpenPlagueActBossChestTime", max = 5, parent = 95054, req = 1, cost = { 52222222, 104444444, 156666666, 208888888, 261111111 }, value = { 1, 1, 1, 1, 1 }, added = "p_lube_a" }
nodes[95056] = { stat = "ReduceAutoOpenPlagueActBossChestTime", max = 5, parent = 95055, req = 1, cost = { 78333333, 156666666, 235000000, 313333333, 391666666 }, value = { 1, 1, 1, 1, 1 }, added = "p_lube_a" }

return RuneData
