-- 화면 검사: WoW API 대역 위에서 애드온 전체(화면 포함)를 불러와 사냥 띠와 메뉴 창을 열고, 화면을 오가며 버튼을 누른다.
-- 이 검사가 확인하는 것: Lua 실행 오류가 없는지, 버튼이 규칙 함수를 불러 상태가 실제로 바뀌는지.
-- 확인하지 못하는 것: 실제 클라이언트에서의 모양, 배치, 글자 잘림, 3D 모델이 보이는지, 대역에 없는 API의 동작.
-- 실행: lua5.1 Test/test_ui.lua

package.path = "./?.lua;" .. package.path
local Stub = require("Test.wow_stub")
local T = require("Test.t")
Stub.install(_G)

local WIH = Stub.loadAddon("WIH", "WIH.toc", "WIH")
local App, Main, Strip, UI, Game, Runes, Scene = WIH.App, WIH.Main, WIH.Strip, WIH.UI, WIH.Game, WIH.Runes, WIH.Scene
local Items, Inventory, Chests, Models = WIH.Items, WIH.Inventory, WIH.Chests, WIH.Models

local function noErrors(where)
    if #App.lastErrors > 0 then
        error(where .. ": 화면 오류 발생 → " .. App.lastErrors[1], 2)
    end
end

-- 프레임 아래의 보이는 버튼을 모두 모은다.
local function visibleButtons(root, out)
    out = out or {}
    for _, child in ipairs(root.__children) do
        if child.__kind == "Button" and child:IsVisible() and child.__scripts.OnClick then out[#out + 1] = child end
        if child.__children and child.__shown then visibleButtons(child, out) end
    end
    return out
end

local function open(id)
    Main.open(id)
    T.eq(Main.current(), id, "화면 전환: " .. id)
    noErrors("화면 " .. id)
    return Main.built[id]
end

-- 영웅 화면의 목록에서 그 영웅의 줄을 찾는다.
local function heroRow(f, heroId)
    for _, row in ipairs(f.rows) do
        if row:IsShown() and row.heroId == heroId then return row end
    end
    error("목록에 없는 영웅: " .. heroId, 2)
end

T.case("처음 실행: 저장이 없으면 띠는 뜨지 않고, /wih로 시작 화면이 열린다", function()
    WIH_DB, WIH_DB_BACKUP, WIH_UI = nil, nil, nil
    Stub.fire("ADDON_LOADED", "WIH")
    T.ok(App.loaded, "불러오기 완료 표시")
    T.eq(App.state, nil)
    T.ok(Strip.frame() == nil or not Strip.frame():IsShown(), "게임을 시작하기 전에는 사냥 띠가 없음")
    SlashCmdList["WIH"]("")
    T.ok(Main.isShown(), "/wih로 메뉴 창이 열림")
    T.eq(Main.current(), "setup")
    noErrors("시작 화면")
end)

T.case("진영과 첫 영웅을 고르면 게임이 시작되고 사냥 띠가 뜬다", function()
    local f = Main.built.setup
    f.factionCards[2]:Click("LeftButton")
    T.eq(f.faction, "Horde")
    f.start:Click("LeftButton")
    T.eq(App.state, nil, "영웅을 고르기 전에는 시작되지 않음")
    f.heroButtons["war_prot"]:Click("LeftButton")
    f.start:Click("LeftButton")
    T.ok(App.state ~= nil, "게임 상태가 만들어짐")
    T.eq(App.state.party[1], "war_prot")
    T.eq(WIH_DB, App.state, "저장 변수에 연결됨")
    T.eq(Main.current(), "heroes", "메뉴 창은 영웅 화면으로")
    T.ok(Strip.frame() and Strip.frame():IsShown(), "사냥 띠가 뜸")
    T.ok(WIH_StripFrame ~= WIH_MainFrame, "띠와 메뉴 창은 서로 다른 창")
    noErrors("게임 시작")
end)

T.case("사냥 띠: 메뉴 창을 닫아도 전투가 보이고 진행된다", function()
    Main.toggle()
    T.ok(not Main.isShown(), "메뉴 창을 닫음")
    T.ok(Strip.frame():IsShown(), "띠는 그대로")
    local before = App.state.stats.playSeconds
    Stub.advance(40, 0.05)
    T.ok(App.state.stats.playSeconds - before > 30, "진행 시간이 흐름")
    T.ok(App.state.stats.kills > 0, "처치가 기록됨")
    T.ok(App.session.relayBattle, "띠가 전투를 중계받음")
    local scene = Strip.scene
    local views = 0
    for _ in pairs(scene.views) do views = views + 1 end
    T.ok(views >= 1, "장면에 유닛이 그려짐")
    -- 대역에서는 모델이 불러와지지 않는다. 장비 룩 → 고정 모델 → 다른 후보를 차례로 기다린 뒤(각 8초) 아이콘 표시로 바뀐다.
    for _, t in pairs(scene.views) do
        if t.unit and t.unit.kind == "hero" then
            T.ok(not t.useModel and t.token:IsShown(), "모델이 모두 실패하면 아이콘으로 표시")
        end
    end
    T.eq(Models.dress, false, "장비 룩이 안 되는 것을 기억함")
    T.eq(Models.known[Models.HEROES.war_prot[2]], false, "실패한 모델 번호를 기억함")
    T.ok(not App.paused, "진행이 멈추지 않음")
    noErrors("사냥 띠")
end)

T.case("전투 장면: 영웅이 앞으로 달려 나가 적과 맞붙는다", function()
    App.restartStage()
    local scene = Strip.scene
    local minX, maxX, minGap = math.huge, -math.huge, math.huge
    for _ = 1, 400 do
        Stub.advance(0.05, 0.05)
        local runner = App.session.runner
        local hero = runner.heroes[1]
        local p = scene.pos[hero.id]
        if p then
            if p.x < minX then minX = p.x end
            if p.x > maxX then maxX = p.x end
            for _, u in ipairs(runner.battle.units) do
                local q = scene.pos[u.id]
                if u.team == 2 and u.alive and q then
                    if q.x - p.x < minGap then minGap = q.x - p.x end
                end
            end
        end
    end
    T.ok(maxX - minX > 40, string.format("영웅의 화면 자리가 움직임(%.0f ~ %.0f)", minX, maxX))
    T.ok(minGap < 110, string.format("적과 가까이 붙음(가장 가까웠을 때 %.0f픽셀)", minGap))
    T.ok(scene.cam ~= nil, "시점이 전장을 따라감")
    noErrors("전투 장면")
end)

T.case("사냥 띠: 접기, 숨기기, 진행 설정 누르기", function()
    local frame = Strip.frame()
    local buttons = visibleButtons(frame)
    T.ok(#buttons >= 5, "띠의 버튼 수: " .. #buttons)
    -- 접으면 전투 중계를 끈다(그리지 않으므로)
    Strip.saved().collapsed = false
    local collapse
    for _, b in ipairs(buttons) do if b.label and b.label:GetText() == "접기" then collapse = b end end
    T.ok(collapse, "접기 버튼")
    collapse:Click("LeftButton")
    T.ok(Strip.saved().collapsed)
    T.ok(not App.session.relayBattle, "접으면 중계를 끔")
    T.eq(collapse.label:GetText(), "펼치기")
    local kills = App.state.stats.kills
    Stub.advance(20, 0.05)
    T.ok(App.state.stats.kills > kills, "접어도 사냥은 계속됨")
    collapse:Click("LeftButton")
    T.ok(App.session.relayBattle, "펼치면 다시 중계")
    -- 숨기기(/wih 띠)
    SlashCmdList["WIH"]("띠")
    T.ok(not frame:IsShown() and not App.session.relayBattle, "숨기면 띠가 사라지고 중계도 끔")
    SlashCmdList["WIH"]("띠")
    T.ok(frame:IsShown() and App.session.relayBattle)
    -- 아래 줄의 진행 설정
    local was = App.state.settings.repeatMode
    for _, b in ipairs(visibleButtons(frame)) do
        if b.key == "repeatMode" then b:Click("LeftButton") end
    end
    T.eq(App.state.settings.repeatMode, not was, "띠에서 반복을 켜고 끔")
    App.state.settings.repeatMode = was
    -- 메뉴 버튼
    for _, b in ipairs(visibleButtons(frame)) do
        if b.label and b.label:GetText() == "메뉴" then b:Click("LeftButton") end
    end
    T.ok(Main.isShown(), "띠의 메뉴 버튼으로 메뉴 창이 열림")
    noErrors("띠 조작")
end)

local function heroView()
    for _, t in pairs(Strip.scene.views) do
        if t.unit and t.unit.kind == "hero" then return t end
    end
end

T.case("장비 룩: 낀 장비대로 옷과 무기를 입힌 캐릭터로 표시한다", function()
    local s = App.state
    Stub.modelsWork = true
    Models.resetKnown()
    Strip.scene.battle = nil          -- 장면을 다시 꾸민다
    Stub.advance(2, 0.05)
    local hero = heroView()
    T.ok(hero and hero.useModel and not hero.token:IsShown(), "영웅이 모델로 표시됨")
    T.ok(hero.view.look ~= nil, "장비 룩 방식으로 표시")
    T.eq(Models.dress, true)
    local look = WIH.Looks.forHero(s, "war_prot")
    T.eq(hero.view.look.race, 6, "호드의 방어 전사는 타우렌")
    local worn = table.concat(hero.view.model.__worn, " ")
    T.ok(worn:find("item:38") and worn:find("item:39"), "장비가 없으면 기본 옷을 입음: " .. worn)
    -- 장비를 끼면 겉모습이 바뀐다
    s.inventory.items = {}
    Inventory.add(s, Items.find("SWORD", 30, 3).id); Inventory.equip(s, "war_prot", 1)
    Inventory.add(s, Items.find("ARMOR", 50, 3).id); Inventory.equip(s, "war_prot", 1)
    Inventory.add(s, Items.find("SHIELD", 90, 5).id); Inventory.equip(s, "war_prot", 1)
    local after = WIH.Looks.forHero(s, "war_prot")
    T.ok(after.key ~= look.key, "장비에 따라 겉모습이 달라짐")
    App.restartStage()
    Stub.advance(2, 0.05)
    hero = heroView()
    worn = table.concat(hero.view.model.__worn, " ")
    T.ok(worn:find("item:" .. WIH.Looks.WEAPONS.SWORD[3]), "검의 겉모습을 입힘: " .. worn)
    T.ok(worn:find("item:" .. WIH.Looks.WEAPONS.SHIELD[6]), "방패의 겉모습을 입힘")
    T.ok(worn:find("item:16865"), "갑옷의 겉모습(가슴)을 입힘")
    T.ok(not worn:find("item:38 "), "갑옷을 끼면 기본 옷은 벗음")
    for _, h in pairs(s.heroes) do h.gear = {} end
    s.inventory.items = {}
    noErrors("장비 룩")
end)

T.case("동작: 이동하는 동안 달리기 동작이 끊기지 않고, 공격할 때 공격 동작으로 바뀐다", function()
    -- 화면은 초당 60번, 전투 계산은 초당 20번이다. 좌표가 안 바뀐 프레임에 서 있기로 돌아가면 안 된다.
    Stub.modelsWork = true
    Models.resetKnown()
    App.restartStage()
    Stub.advance(0.5, 1 / 60)
    local hero = heroView()
    T.ok(hero and hero.useModel, "영웅이 모델로 표시됨")
    local model = hero.view.model
    local runFrames, standFrames, flips, last, sawAttack = 0, 0, 0, nil, false
    local unit = hero.unit
    for _ = 1, 600 do
        local x0 = unit.x
        Stub.advance(1 / 60, 1 / 60)
        hero = heroView()
        if hero and hero.unit == unit and hero.useModel then
            local anim = model.__anim
            if anim == 17 or anim == 16 or anim == 18 then sawAttack = true end
            if hero.moveLeft and not hero.animUntil then
                if anim == 5 then runFrames = runFrames + 1 elseif anim == 0 then standFrames = standFrames + 1 end
                if last and last ~= anim and (anim == 5 or anim == 0) and (last == 5 or last == 0) then flips = flips + 1 end
                last = anim
            else
                last = nil
            end
        end
    end
    T.ok(runFrames > 30, "달리는 프레임 수: " .. runFrames)
    T.eq(standFrames, 0, "이동 중에 서 있기 동작으로 돌아가는 프레임이 없어야 함")
    T.eq(flips, 0, "달리기와 서 있기가 번갈아 걸리지 않아야 함")
    T.ok(sawAttack, "공격할 때 공격 동작이 걸림")
    -- 그 모델에 없는 동작이면 다음 후보를 쓴다
    Stub.animations = { [0] = true, [4] = true, [16] = true }
    T.eq(hero.view:pickAnim(UI.ANIM_CHOICES.run), 4, "달리기가 없으면 걷기")
    T.eq(hero.view:pickAnim(UI.ANIM_CHOICES.melee1h), 16, "한손 공격이 없으면 맨손 공격")
    Stub.animations = nil
    noErrors("동작")
end)

T.case("3D 모델: 옷을 입힐 수 없는 클라이언트에서는 고정 모델로, 실패한 번호는 다음 후보로 넘어간다", function()
    Stub.noDress = true
    Models.resetKnown()
    Strip.scene.battle = nil
    Stub.advance(3, 0.05)
    local hero = heroView()
    T.ok(hero and hero.useModel and not hero.token:IsShown(), "영웅이 모델로 표시됨")
    T.eq(hero.view.look, nil)
    T.eq(hero.view.creature, Models.HEROES.war_prot[2], "호드 진영의 모델 번호")
    T.eq(Models.known[hero.view.creature], true)
    T.ok(WIH_UI.displayIds[hero.view.creature], "불러온 생물의 표시 번호를 저장해 둠")
    -- 첫 후보가 실패하면 다음 후보(상대 진영의 번호)로. 실패 판정까지 8초를 기다린다.
    WIH_UI.displayIds = {}
    Stub.badModels = { [Models.HEROES.war_prot[2]] = true }
    Models.resetKnown()
    Strip.scene.battle = nil
    Stub.advance(10, 0.05)
    hero = heroView()
    T.eq(hero.view.creature, Models.HEROES.war_prot[1], "다음 후보로 넘어감")
    T.eq(Models.known[Models.HEROES.war_prot[2]], false, "실패한 번호를 기억함")
    Stub.badModels = nil
    Stub.noDress = nil
    Models.resetKnown()
    -- 설정에서 모델을 끄면 아이콘으로
    Scene.options().models = false
    Stub.advance(1, 0.05)
    for _, t in pairs(Strip.scene.views) do T.ok(not t.useModel, "모델을 끄면 아이콘 표시") end
    Scene.options().models = true
    Stub.advance(1, 0.05)
    noErrors("모델")
end)

T.case("영웅 화면: 목록과 필터, 해금, 스킬 투자·환급·장착, 패시브, 능력치, 전투력", function()
    local s = App.state
    s.gold = 5000
    s.heroes.war_prot.level, s.heroes.war_prot.exp = 12, 0
    local f = open("heroes")
    T.ok(f.power:GetText() ~= "" and f.power:IsShown(), "전투력이 보임: " .. f.power:GetText())
    T.ok(f.model.look ~= nil or f.model.creature ~= nil, "가운데에 캐릭터 모델")
    -- 필터: 힐러만
    for _, b in ipairs(f.chips) do if b.id == "healer" then b:Click("LeftButton") end end
    for _, row in ipairs(f.rows) do
        if row:IsShown() then T.eq(WIH.Heroes.byId[row.heroId].role, "healer", "힐러 필터") end
    end
    -- 잠긴 영웅을 골라 해금
    heroRow(f, "pri_holy"):Click("LeftButton")
    T.eq(f.heroId, "pri_holy")
    T.ok(f.unlock:IsShown() and not f.power:IsShown(), "잠긴 영웅에게는 해금 버튼이 보임")
    f.unlock:Click("LeftButton")
    T.ok(s.heroes.pri_holy ~= nil, "해금됨")
    T.eq(s.gold, 5000 - Game.HERO_UNLOCK_COST)
    for _, b in ipairs(f.chips) do if b.id == "all" then b:Click("LeftButton") end end
    -- 스킬 투자와 환급
    heroRow(f, "war_prot"):Click("LeftButton")
    local first = WIH.Heroes.byId.war_prot.skills[1]
    f.tiles[1]:Click("LeftButton")
    T.eq(s.heroes.war_prot.active[first], 1, "왼쪽 클릭으로 투자")
    f.tiles[1]:Click("LeftButton")
    f.tiles[1]:Click("RightButton")
    T.eq(s.heroes.war_prot.active[first], 1, "오른쪽 클릭으로 환급")
    -- 장착과 해제
    T.ok(f.tiles[1].equip:IsShown(), "배운 스킬에는 장착 버튼이 보임")
    s.heroes.war_prot.bar = {}
    f.tiles[1].equip:Click("LeftButton")
    T.eq(s.heroes.war_prot.bar[1], first, "장착")
    f.bar[1]:Click("LeftButton")
    T.eq(#s.heroes.war_prot.bar, 0, "장착 칸을 누르면 해제")
    f.tiles[1].equip:Click("LeftButton")
    -- 조건이 안 되는 티어는 거절
    local before = Game.spentPoints(s, "war_prot")
    f.tiles[6]:Click("LeftButton")
    T.eq(Game.spentPoints(s, "war_prot"), before, "조건이 안 되는 투자는 거절됨")
    -- 패시브 쪽
    f.seg.buttons[2]:Click("LeftButton")
    T.eq(f.page, "passive")
    f.passives[1]:Click("LeftButton")
    T.eq(s.heroes.war_prot.passive[1], 1, "패시브 투자")
    f.passives[1]:Click("RightButton")
    T.eq(s.heroes.war_prot.passive[1] or 0, 0, "패시브 환급")
    f.passives[1]:Click("LeftButton")
    -- 능력치 쪽
    f.seg.buttons[3]:Click("LeftButton")
    T.ok(f.statValues:GetText():find("%d"), "능력치가 채워짐")
    f.seg.buttons[1]:Click("LeftButton")
    f.apply:Click("LeftButton")
    T.ok(Game.treeValid(WIH.Heroes.byId.war_prot, s.heroes.war_prot), "트리 상태가 규칙에 맞음")
    -- 전투력은 엔진이 계산한 값
    local p = WIH.Power.get(s, "war_prot")
    T.eq(f.power:GetText(), UI.number(p.power), "표시한 전투력 = 엔진의 값")
    noErrors("영웅 화면")
end)

T.case("장비: 영웅 화면의 칸에서 가방으로 넘어가 장착하고, 칸에서 해제한다", function()
    local s = App.state
    s.inventory.items, s.mail = {}, {}
    for _, h in pairs(s.heroes) do h.gear = {} end
    local sword, staff, helmet = Items.find("SWORD", 1, 1), Items.find("STAFF", 1, 1), Items.find("HELMET", 1, 2)
    Inventory.add(s, sword.id); Inventory.add(s, staff.id); Inventory.add(s, helmet.id)
    local f = open("heroes")
    heroRow(f, "war_prot"):Click("LeftButton")
    -- 빈 주무기 칸을 누르면 가방 화면이 그 영웅과 주무기 필터로 열린다
    f.slots.MAIN:Click("LeftButton")
    T.eq(Main.current(), "bag")
    local bag = Main.built.bag
    T.eq(bag.heroId, "war_prot")
    T.eq(bag.filter, "MAIN")
    T.eq(#bag.view, 2, "주무기 두 개만 보임")
    -- 고르고 장착
    bag.cells[1]:Click("LeftButton")
    T.eq(bag.selected, bag.view[1])
    T.ok(bag.dName:GetText():find("한손검"), "상세에 이름이 보임")
    bag.dEquip:Click("LeftButton")
    T.eq(s.heroes.war_prot.gear.MAIN.id, sword.id)
    -- 쓸 수 없는 무기는 장착 버튼이 꺼지고 오른쪽 클릭으로도 끼워지지 않는다
    bag.cells[1]:Click("LeftButton")
    T.ok(not bag.dEquip.enabled, "전사는 지팡이를 못 낌")
    bag.cells[1]:Click("RightButton")
    T.eq(s.heroes.war_prot.gear.MAIN.id, sword.id)
    -- 전체 필터에서 오른쪽 클릭으로 투구 장착
    for _, b in ipairs(bag.filters) do if b.id == "all" then b:Click("LeftButton") end end
    T.ok(bag.cells[20]:IsShown() and not bag.cells[21], "전체 보기에서는 용량만큼 칸이 보임")
    bag.cells[2]:Click("RightButton")
    T.eq(s.heroes.war_prot.gear.HELMET.id, helmet.id)
    T.ok(bag.apply:IsShown(), "장비를 바꾸면 '지금 적용'이 보임")
    bag.apply:Click("LeftButton")
    T.ok(App.session.runner.heroes[1]:get("AttackDamage") >= 3, "장비가 전투에 반영됨")
    -- 영웅 화면의 칸에 표시되고, 오른쪽 클릭으로 해제된다
    f = open("heroes")
    T.eq(f.slots.MAIN.corner:GetText(), "1", "칸에 아이템 레벨이 보임")
    T.ok(f.slots.MAIN.tooltip().title:find("한손검"))
    f.slots.HELMET:Click("RightButton")
    T.eq(s.heroes.war_prot.gear.HELMET, nil, "오른쪽 클릭으로 해제")
    T.eq(#s.inventory.items, 2)
    noErrors("장비")
end)

T.case("가방 화면: 장착 대상, 잠금, 팔기, 칸 구매, 상자", function()
    local s = App.state
    local f = open("bag")
    -- 장착 대상 칩: 편성한 영웅
    T.ok(f.targets[1]:IsShown() and f.targets[1].heroId == s.party[1])
    -- 잠금과 팔기
    for _, b in ipairs(f.filters) do if b.id == "all" then b:Click("LeftButton") end end
    f.cells[1]:Click("LeftButton")
    f.dLock:Click("LeftButton")
    T.eq(s.inventory.items[f.selected].lock, true)
    T.ok(not f.dSell.enabled, "잠근 것은 팔기 버튼이 꺼짐")
    local count, gold = #s.inventory.items, s.gold
    f.bulk:Click("LeftButton")
    T.eq(#s.inventory.items, 1, "잠근 것만 남음")
    T.ok(s.gold > gold, "판 만큼 골드가 늘어남")
    -- 칸 구매
    local cost = Inventory.nextSlotCost(s)
    s.gold = cost
    UI.screens.bag.refresh(f)
    f.buy:Click("LeftButton")
    T.eq(Inventory.capacity(s), 21 + Runes.total(s, "MaxInventorySlot"))
    T.eq(s.gold, 0)
    -- 상자
    s.chests.normal.list = { 1, 1, 1 }
    UI.screens.bag.refresh(f)
    T.ok(f.chestRows.normal.open.enabled)
    T.ok(not f.chestRows.normal.all.enabled, "모두 열기는 룬이 있어야 함")
    f.chestRows.normal.open:Click("LeftButton")
    T.eq(Chests.count(s, "normal"), 2)
    T.ok(App.lastLoot and #App.lastLoot > 0, "최근 획득이 기록됨")
    T.ok(f.chestRows.raid.text:GetText():find("레이드 상자"))
    T.ok(UI.itemTip(Items.find("SWORD", 1, 1), nil, Items.find("STAFF", 1, 1)).title ~= nil)
    noErrors("가방 화면")
end)

T.case("창고: 가방에서 맡기고 꺼내기, 칸 구매, 룬으로 페이지 열기", function()
    local s = App.state
    s.gold = 1e7
    s.inventory.items = {}
    Inventory.add(s, Items.find("HELMET", 1, 1).id)
    Inventory.add(s, Items.find("BOOTS", 1, 1).id)
    local f = open("bag")
    local function seg(id) for _, b in ipairs(f.srcSeg.buttons) do if b.id == id then b:Click("LeftButton") end end end
    f.cells[1]:Click("LeftButton")
    T.ok(f.dStash:IsShown(), "가방의 장비에는 창고로 버튼")
    f.dStash:Click("LeftButton")
    T.eq(#s.inventory.items, 1)
    T.eq(#s.stash.pages[1], 1, "창고 1쪽에 들어감")
    seg(1)
    T.eq(f.src, 1)
    T.ok(f.bagTitle:GetText():find("창고 1쪽  1 / 41"), f.bagTitle:GetText())
    T.ok(not f.bulk:IsShown() and not f.sort:IsShown(), "창고에서는 일괄 팔기·정렬이 없음")
    local before = Inventory.stashCapacity(s)
    f.buy:Click("LeftButton")
    T.eq(Inventory.stashCapacity(s), before + 1, "창고 칸 구매")
    T.eq(s.gold, 1e7 - 100, "42번째 칸 100골드 [원작]")
    f.cells[1]:Click("LeftButton")
    T.eq(f.dEquip.label:GetText(), "가방으로")
    f.cells[1]:Click("RightButton")
    T.eq(#s.stash.pages[1], 0, "오른쪽 클릭으로 꺼냄")
    T.eq(#s.inventory.items, 2)
    seg(2)
    T.eq(f.src, 1, "닫힌 페이지는 열리지 않음")
    for key, node in pairs(WIH.RuneData.nodes) do if node.stat == "UnlockStashPageCount" then s.runes[key] = node.max end end
    seg(2)
    T.eq(f.src, 2, "룬을 사면 페이지가 열림")
    seg("bag")
    noErrors("창고")
end)

T.case("성장 화면(룬): 구매가 골드와 룬 레벨에 반영된다", function()
    local s = App.state
    s.gold = 100000
    local f = open("runes")
    T.ok(#f.items > 0, "살 수 있는 룬이 있음")
    T.eq(f.items[1], 1, "처음에는 뿌리 룬만 열려 있음")
    local gold = s.gold
    f.rows[1].buy:Click("LeftButton")
    T.eq(Runes.level(s, 1), 1)
    T.ok(s.gold < gold, "골드가 줄어듦")
    local seen = {}
    for _, key in ipairs(f.items) do seen[key] = true end
    T.ok(seen[10] and seen[20], "새로 열린 룬이 목록에 나타남")
    for _, b in ipairs(f.filters) do if b.id == "all" then b:Click("LeftButton") end end
    T.eq(#f.items, f.total, "전체 보기는 모든 룬을 보여 줌")
    T.ok(Runes.buy(s, 20) and Runes.buy(s, 21), "편성 칸 룬 구매")
    T.eq(Game.partySlots(s), 2)
    s.gold = 0
    f = open("runes")
    for n = 1, #f.items do
        local row = f.rows[n]
        if row.buy:IsShown() then T.ok(not row.buy.enabled, "골드가 없으면 구매 버튼이 꺼짐") end
    end
    for n = 1, #f.items do T.ok(f.rows[n].tooltip(f.rows[n]).title ~= nil) end
    noErrors("성장 화면")
end)

T.case("펫: 성장 화면에서 동행을 고르면 사냥 띠에 영웅 뒤를 따라 나타나고, 풀면 사라진다", function()
    local s = App.state
    local Pets = WIH.Pets
    s.pets.owned.bat = true
    local f = open("runes")
    for _, b in ipairs(f.seg.buttons) do if b.id == "pet" then b:Click("LeftButton") end end
    local row
    for _, r in ipairs(f.petView.rows) do if r.pet.id == "bat" then row = r end end
    T.ok(row.follow:IsShown(), "가진 펫에는 동행 버튼")
    row.follow:Click("LeftButton")
    T.eq(s.pets.follow, "bat")
    Strip.saved().hidden, Strip.saved().collapsed = false, false
    Strip.refresh()
    Stub.advance(2, 0.05)
    local scene = Strip.scene
    T.ok(scene.petView and scene.petView:IsShown(), "띠에 동행 펫이 보임")
    T.eq(scene.petView.petId, "bat")
    row.follow:Click("LeftButton")
    T.eq(s.pets.follow, nil)
    Stub.advance(1, 0.05)
    T.ok(not scene.petView:IsShown(), "동행을 풀면 사라짐")
    for _, b in ipairs(f.seg.buttons) do if b.id == "rune" then b:Click("LeftButton") end end
    noErrors("동행 펫")
end)

T.case("성장 화면(유물): 기원으로 얻고, 장착하고, 칸에 끼워 공명시키고, 조율·적용한다", function()
    local s = App.state
    local Relics, Cube, Rng = WIH.Relics, WIH.Cube, WIH.Rng
    s.gold = 1e8
    local f = open("runes")
    local function seg(segment, id)
        for _, b in ipairs(segment.buttons) do if b.id == id then b:Click("LeftButton") end end
    end
    seg(f.seg, "relic")
    local v = f.relicView
    T.ok(v:IsShown(), "유물 화면이 보임")
    T.ok(v.summary:GetText():find("원정"), "잠겨 있으면 여는 방법을 안내")
    T.ok(not v.qName:IsShown() and v.qEmpty:IsShown(), "유물함이 없으면 안내 문구")
    noErrors("유물 화면(빈 상태)")
    -- 원정 클리어 → 1칸. 큐브 기원으로 유물함을 얻는다.
    s.stage.cleared[WIH.Expeditions.keys[2][1]] = 1
    s.cube.level = 40
    if not Cube.unlocked(s, Cube.find("OFFERING")) then T.ok(Cube.unlock(s, Cube.find("OFFERING"))) end
    s.materials[161005] = 1
    local cube = open("cube")
    cube.recipes[7]:Click("LeftButton")
    local found
    for _, row in ipairs(cube.leftList.rows) do if row:IsShown() and row.data == 161005 then found = row end end
    T.ok(found, "기원 목록에 오염된 유물함이 보임")
    found:Click("LeftButton")
    T.ok(cube.odds:GetText():find("유물함 등급"), "유물함 등급 확률이 보임")
    cube.go:Click("LeftButton")
    T.eq(s.materials[161005], nil, "재료를 씀")
    T.ok(cube.result:GetText():find("유물함"), "결과: " .. cube.result:GetText())
    local q = Relics.list(s, "RELIQUARY")[1]
    T.ok(q and q.grade >= 5)
    cube.recipes[1]:Click("LeftButton")       -- 큐브 화면을 처음 페이지로 돌려 둔다
    -- 시험을 위해 힘의 유물함(빨강 3)으로 바꾸고 빨간 유물 3개를 준다
    local might = Relics.makeReliquary(s, 790008, 6, Rng.new(2))
    for i = 1, #might.slots do might.slots[i] = "RED" end
    for _ = 1, 3 do Relics.makeRelic(s, 710001, 6, Rng.new(4)) end
    f = open("runes")
    seg(f.seg, "relic")
    v = f.relicView
    T.ok(v.summary:GetText():find("유물함 칸 1 / 2"))
    -- 목록에서 힘의 유물함을 고른다
    local row
    for _, r in ipairs(v.rows) do if r:IsShown() and r.item == might then row = r end end
    T.ok(row, "목록에 유물함이 보임")
    row:Click("LeftButton")
    T.eq(v.quiver, might.uid)
    T.ok(v.qName:GetText():find("힘"), v.qName:GetText())
    T.ok(not v.eq2.enabled, "2번째 칸은 잠김")
    v.eq1:Click("LeftButton")
    T.eq(s.relics.equipped[1], might.uid, "칸 1에 장착")
    T.ok(v.apply.enabled, "바꾸면 지금 적용이 켜짐")
    -- 유물 목록에서 하나 골라 칸에 끼운다
    seg(v.kindSeg, "RELIC")
    local relicRow
    for _, r in ipairs(v.rows) do if r:IsShown() and r.item and r.item.kind == "RELIC" then relicRow = r; break end end
    relicRow:Click("LeftButton")
    T.ok(v.pick ~= nil and v.pInfo:IsShown(), "고른 유물의 정보")
    v.sockets[1]:Click("LeftButton")
    T.eq(might.sockets[1] ~= nil, true, "칸에 끼움")
    -- 나머지는 자동 끼우기
    v.fill:Click("LeftButton")
    T.ok(Relics.resonating(s, might), "빨강 3개로 공명")
    T.ok(v.totals:GetText():find("힘의 축복"), "발동 중인 공명이 합계에 보임: " .. v.totals:GetText())
    -- 오른쪽 클릭으로 빼기
    v.sockets[2]:Click("RightButton")
    T.eq(might.sockets[2], nil)
    T.ok(not Relics.resonating(s, might))
    -- 조율
    local gold = s.gold
    v.qAttune:Click("LeftButton")
    T.ok(s.gold < gold, "조율 비용을 냄")
    T.eq(might.attune, 1)
    -- 적용: 전투 영웅에게 들어간다
    v.fill:Click("LeftButton")
    v.apply:Click("LeftButton")
    T.ok(not v.apply.enabled)
    noErrors("유물 화면")
    -- 펫·룬으로 돌아가도 오류가 없다
    seg(f.seg, "pet"); seg(f.seg, "rune")
    T.ok(not v:IsShown())
    noErrors("성장 화면 전환")
end)

T.case("편성 화면: 넣기, 순서 바꾸기, 빼기", function()
    local s = App.state
    local f = open("party")
    T.eq(#s.party, 1)
    T.ok(f.benchRows[1] and f.benchRows[1]:IsShown(), "대기 중인 영웅이 보임")
    f.benchRows[1]:Click("LeftButton")
    T.eq(#s.party, 2, "편성에 들어감")
    f.cards[2].front:Click("LeftButton")
    T.eq(s.party[1], "pri_holy", "앞으로 이동")
    f.cards[1].back:Click("LeftButton")
    T.eq(s.party[1], "war_prot", "뒤로 이동")
    f.cards[2].remove:Click("LeftButton")
    T.eq(#s.party, 1, "빼기")
    f.cards[1].remove:Click("LeftButton")
    T.eq(#s.party, 1, "마지막 한 명은 뺄 수 없음")
    f.benchRows[1]:Click("LeftButton")
    f.apply:Click("LeftButton")
    T.eq(#App.session.runner.heroes, 2, "지금 적용을 누르면 새 편성으로 스테이지가 다시 시작됨")
    Stub.advance(2, 0.05)
    noErrors("편성 화면")
end)

T.case("스테이지 화면: 잠긴 곳은 못 가고, 열린 곳으로는 이동한다", function()
    local s = App.state
    Game.selectStage(s, 1, 101)
    local f = open("stage")
    f.rows[105]:Click("LeftButton")
    T.ok(not f.go.enabled, "잠긴 스테이지는 이동 버튼이 꺼짐")
    f.go:Click("LeftButton")
    T.eq(s.stage.section, 101, "잠긴 스테이지로는 이동하지 않음")
    s.stage.cleared[1101] = 1
    f.rows[102]:Click("LeftButton")
    T.ok(f.go.enabled, "앞 스테이지를 클리어하면 열림")
    f.go:Click("LeftButton")
    T.eq(s.stage.section, 102)
    T.eq(App.session.stageKey, 1102, "이동하면 그 스테이지가 바로 시작됨")
    T.ok(not f.tabs[2].enabled, "다음 난이도는 잠겨 있음")
    T.ok(#f.body:GetText() > 100, "보스 정보가 채워짐")
    noErrors("스테이지 화면")
end)

T.case("레이드: 스테이지 화면에서 시작하고, 띠가 보스 순번을 보여 준다", function()
    local s = App.state
    local Raids = WIH.Raids
    for n = 1, 9 do s.stage.cleared[1100 + n] = 1 end
    s.stage.cleared[1110] = nil
    Game.selectStage(s, 1, 109)
    s.materials[Raids.TOKEN[1]] = 0
    local f = open("stage")
    f.difficulty = 1
    f.raidRows[1]:Click("LeftButton")
    T.ok(f.name:GetText():find("오닉시아"), "레이드 이름이 보임")
    T.ok(not f.go.enabled, "증표가 없으면 시작할 수 없음")
    T.ok(f.state:GetText():find("증표"), "못 가는 사유가 보임")
    s.materials[Raids.TOKEN[1]] = 1
    UI.screens.stage.refresh(f)
    f.go:Click("LeftButton")
    T.eq(s.stage.raidKey, 1110)
    T.ok(App.session.runner.raid ~= nil, "레이드가 바로 시작됨")
    Stub.advance(3, 0.05)
    local head = visibleButtons(Strip.frame())
    T.ok(#head > 0)
    -- 띠의 위쪽 줄에 레이드 이름이 보인다
    local found = false
    for _, child in ipairs(Strip.frame().head.__children) do
        if child.__kind == "FontString" and child:GetText():find("오닉시아") then found = true end
    end
    T.ok(found, "띠에 레이드 이름이 보임")
    f.rows[103]:Click("LeftButton")
    f.go:Click("LeftButton")
    T.eq(s.stage.raidKey, nil, "던전을 고르면 레이드를 그만둠")
    T.eq(Game.raidTokens(s, 1), 1, "그만두면 증표는 그대로")
    noErrors("레이드 화면")
end)

T.case("원정·낙스라마스: 스테이지 화면에서 열림 조건, 강도, 보급품, 나가기, 증표", function()
    local s = App.state
    local Expeditions, Raids = WIH.Expeditions, WIH.Raids
    for _, h in pairs(s.heroes) do h.level = 70 end
    s.stage.cleared[Raids.key(2, 1)] = nil
    for n = 1, 20 do s.stage.cleared[Expeditions.keys[2][n]] = nil end     -- 앞 검사(유물)가 연 기록을 지운다
    local f = open("stage")
    f.tabs[1]:Click("LeftButton")
    T.ok(not f.expRow:IsShown() and f.specialHint:IsShown(), "일반 난이도에는 원정이 없다는 안내")
    s.stage.cleared[1310] = 1           -- 일반의 마지막 레이드 → 악몽 탭이 열린다
    for n = 1, 9 do s.stage.cleared[2100 + n] = 1 end
    UI.screens.stage.refresh(f)
    f.tabs[2]:Click("LeftButton")
    T.eq(f.difficulty, 2)
    T.ok(f.expRow:IsShown(), "악몽에는 원정 줄이 보임")
    f.expRow:Click("LeftButton")
    T.ok(f.name:GetText():find("줄구룹"), f.name:GetText())
    T.ok(not f.go.enabled and f.state:GetText():find("레이드"), "첫 레이드 전에는 잠김")
    T.ok(f.intensityRow:IsShown(), "강도 줄이 보임")
    -- 첫 레이드를 클리어하면 열린다
    s.stage.cleared[Raids.key(2, 1)] = 1
    s.supply = 10
    UI.screens.stage.refresh(f)
    T.ok(not f.go.enabled and f.state:GetText():find("보급품"), "보급품이 모자라면 못 들어감")
    s.supply = 60
    UI.screens.stage.refresh(f)
    T.ok(f.go.enabled, "들어갈 수 있음")
    T.ok(not f.intensityBtns[2].enabled, "강도 2는 아직 잠김")
    T.ok(f.body:GetText():find("강도 1"), "강도의 강화가 보임")
    f.go:Click("LeftButton")
    T.eq(s.stage.expedition, Expeditions.keys[2][1])
    T.ok(App.session.inExpedition, "원정이 바로 시작됨")
    T.ok(f.leave:IsShown(), "나가기 버튼")
    Stub.advance(3, 0.05)
    local found = false
    for _, child in ipairs(Strip.frame().head.__children) do
        if child.__kind == "FontString" and (child:GetText() or ""):find("원정") then found = true end
    end
    T.ok(found, "띠에 원정이 표시됨")
    T.ok(s.supply < 60, "원정 중에는 보급품이 줆")
    -- 강도 1을 클리어한 것으로 두면 강도 2로 옮길 수 있고, 안에서는 보급품 30 조건을 다시 묻지 않는다
    s.stage.cleared[Expeditions.keys[2][1]] = 1
    s.supply = 5
    UI.screens.stage.refresh(f)
    f.intensityBtns[2]:Click("LeftButton")
    T.ok(f.go.enabled, "원정 안에서는 강도를 바꿀 수 있음")
    f.go:Click("LeftButton")
    T.eq(s.stage.expedition, Expeditions.keys[2][2])
    f.leave:Click("LeftButton")
    T.eq(s.stage.expedition, nil, "나가면 던전으로")
    T.ok(not App.session.inExpedition)
    -- 낙스라마스: 액트 1 레이드를 클리어해 열렸고, 증표가 있어야 시작
    f.naxxRows[1]:Click("LeftButton")
    T.ok(f.name:GetText():find("낙스라마스"))
    s.materials[Expeditions.NAXX_TOKEN[2]] = nil
    UI.screens.stage.refresh(f)
    T.ok(not f.go.enabled and f.state:GetText():find("증표"))
    s.materials[Expeditions.NAXX_TOKEN[2]] = 1
    UI.screens.stage.refresh(f)
    f.go:Click("LeftButton")
    T.eq(s.stage.raidKey, Expeditions.naxxKeys[2][1])
    T.ok(App.session.runner.raid ~= nil)
    T.ok(not f.naxxRows[2].label:GetText():find("잠김"), "줄 이름")
    -- 던전으로 돌아간다
    f.tabs[1]:Click("LeftButton")
    f.rows[101]:Click("LeftButton")
    f.go:Click("LeftButton")
    T.eq(s.stage.raidKey, nil)
    noErrors("원정 화면")
end)

T.case("큐브 부식: 장비와 역병 열매로 원정 보급품을 채우고, 가득 차면 멈춘다", function()
    local s = App.state
    local Cube = WIH.Cube
    s.stage.cleared[WIH.Raids.key(2, 1)] = 1
    s.supply = 10
    s.inventory.items = {}
    Inventory.add(s, Items.find("AMULET", 1, 3).id)
    Inventory.add(s, Items.find("HELMET", 1, 3).id)
    s.materials[150103] = 3
    local f = open("cube")
    f.recipes[9]:Click("LeftButton")
    T.eq(f.page, "CORROSION")
    T.ok(f.rightList.rows[1]:IsShown() and f.rightList.rows[2]:IsShown(), "장비 목록")
    f.rightList.rows[1]:Click("LeftButton")
    f.rightList.rows[2]:Click("LeftButton")
    T.ok(f.odds:GetText():find("보급품"), f.odds:GetText())
    f.go:Click("LeftButton")
    T.eq(#s.inventory.items, 0, "장비 두 개를 씀")
    T.eq(s.supply, 10 + 12 + 2, "희귀 아뮬렛 12 + 희귀 투구 2(0.8배)")
    local fruitRow
    for _, row in ipairs(f.leftList.rows) do if row:IsShown() and row.data == 150103 then fruitRow = row end end
    T.ok(fruitRow, "역병 열매가 재료 목록에 보임")
    fruitRow:Click("LeftButton")
    f.go:Click("LeftButton")
    T.eq(s.supply, 24 + 3 * 20, "열매 3개 × 20")
    T.eq(s.materials[150103], nil)
    s.materials[150103] = 5
    s.supply = 95
    UI.screens.cube.refresh(f)
    for _, row in ipairs(f.leftList.rows) do if row:IsShown() and row.data == 150103 then row:Click("LeftButton") end end
    f.go:Click("LeftButton")
    T.eq(s.supply, 100, "최대치에서 멈춤")
    T.eq(s.materials[150103], 4, "필요한 1개만 씀")
    UI.screens.cube.refresh(f)
    T.ok(not f.go.enabled, "가득 차면 버튼이 꺼짐")
    f.recipes[1]:Click("LeftButton")
    noErrors("부식")
end)

T.case("큐브 화면: 해금, 자동 채우기와 합성, 제작, 장식, 기원", function()
    local s = App.state
    local Cube = WIH.Cube
    s.gold = 1e7
    s.inventory.items = {}
    for _ = 1, 9 do Inventory.add(s, Items.find("HELMET", 1, 1).id) end
    local f = open("cube")
    T.eq(f.page, "SYNTHESIS")
    f.auto:Click("LeftButton")
    T.eq(#f.picked, 9, "자동 채우기로 9칸이 참")
    T.ok(f.go.enabled, "합성 버튼이 켜짐")
    T.ok(f.odds:GetText():find("결과 등급"), "확률이 보임")
    f.go:Click("LeftButton")
    T.eq(#s.inventory.items, 1, "9개를 넣고 1개를 받음")
    T.ok(f.result:GetText() ~= "", "결과가 보임")
    -- 제작: 잠긴 단계는 해금 버튼
    f.recipes[2]:Click("LeftButton")
    T.eq(f.page, "CRAFTING")
    s.cube.level = 5
    UI.screens.cube.refresh(f)
    T.ok(f.unlock:IsShown() and f.unlock.enabled, "해금 버튼이 보이고 켜짐")
    f.unlock:Click("LeftButton")
    T.ok(Cube.unlocked(s, Cube.find("CRAFTING", 1)))
    for _, m in ipairs(Cube.craftCost("MAIN", 1)) do s.materials[m[1]] = 5 end
    UI.screens.cube.refresh(f)
    T.ok(f.go.enabled)
    f.go:Click("LeftButton")
    T.eq(#s.inventory.items, 2, "제작한 장비가 가방에 들어옴")
    -- 장식
    s.cube.level = 30
    Cube.unlock(s, Cube.find("DECORATION"))
    Inventory.add(s, Items.find("SWORD", 30, 4).id)
    s.materials[110001] = 2
    f.recipes[3]:Click("LeftButton")
    T.eq(f.page, "DECORATION")
    T.ok(f.leftList.rows[1] and f.leftList.rows[1]:IsShown(), "칸이 있는 장비가 보임")
    f.leftList.rows[1]:Click("LeftButton")
    f.rightList.rows[1]:Click("LeftButton")
    T.ok(f.go.enabled)
    f.go:Click("LeftButton")
    local entry = s.inventory.items[#s.inventory.items]
    T.ok(entry.added and #entry.added == 1, "능력치가 붙음")
    -- 기원
    Cube.unlock(s, Cube.find("OFFERING"))
    s.materials[160001] = 1
    f.recipes[7]:Click("LeftButton")
    f.leftList.rows[1]:Click("LeftButton")
    f.go:Click("LeftButton")
    T.eq(s.materials[160001], nil, "주화를 씀")
    noErrors("큐브 화면")
end)

T.case("기록 화면: 편성 상태, 최근 기록, 통계", function()
    local s = App.state
    App.addLog("시험용 기록 줄")
    local f = open("records")
    Stub.advance(2, 0.05)
    T.ok(f.cards[1]:IsShown(), "편성 카드가 보임")
    T.ok(f.log:GetText():find("시험용 기록 줄"), "기록이 보임")
    T.ok(f.statValues:GetText():find("%d"), "통계가 보임")
    T.ok(f.where:GetText() ~= "", "현재 위치가 보임")
    noErrors("기록 화면")
end)

T.case("모든 화면과 띠의 보이는 버튼을 눌러도 오류가 없다", function()
    local s = App.state
    s.gold = 5e8
    for _, h in pairs(s.heroes) do h.level = 60 end
    for _ = 1, 12 do Inventory.add(s, Items.find("HELMET", 1, 1).id) end
    s.chests.normal.list, s.chests.stage.list = { 1, 1, 1 }, { 2, 2 }
    local order = { "heroes", "bag", "party", "stage", "cube", "runes", "records", "modelcheck" }
    s.cube.level = 40
    for _, id in ipairs({ 110001, 120001, 130001, 160003, 140001, 140003 }) do s.materials[id] = 12 end
    local clicks = 0
    for round = 1, 3 do
        for _, id in ipairs(order) do
            local f = open(id)
            local buttons = visibleButtons(f)
            if id ~= "records" then T.ok(#buttons > 0, id .. " 화면에 버튼이 있음") end      -- 기록 화면은 보기만 하는 화면이다
            for i, b in ipairs(buttons) do
                if b:IsVisible() and Main.current() == id then
                    b:Click((i + round) % 4 == 0 and "RightButton" or "LeftButton")
                    clicks = clicks + 1
                    noErrors(id .. " 화면의 버튼 " .. i)
                    T.ok(App.state ~= nil, "게임 상태가 유지됨")
                end
            end
            Stub.advance(2, 0.05)
            noErrors(id .. " 화면 진행")
        end
        -- 띠의 버튼(메뉴 창을 닫을 수 있으므로 다시 연다)
        if Strip.frame():IsShown() then
            for _, b in ipairs(visibleButtons(Strip.frame())) do
                if b:IsVisible() then b:Click("LeftButton"); clicks = clicks + 1; noErrors("띠의 버튼") end
            end
        end
        Strip.saved().hidden, Strip.saved().collapsed = false, false
        Strip.refresh()
    end
    T.ok(clicks > 300, "누른 버튼 수: " .. clicks)
    local notes = WIH.Save.validate(WIH.Save.deepCopy(s))
    T.ok(notes and #notes == 0, "마구 누른 뒤에도 저장 데이터가 규칙에 맞음: " .. table.concat(notes or { "검증 실패" }, " / "))
end)

T.case("설정 화면: 진영, 진행 방식, 화면 옵션, 초기화와 백업 되돌리기", function()
    local s = App.state
    local f = open("settings")
    f.factions.Alliance:Click("LeftButton")
    T.eq(s.faction, "Alliance")
    local was = s.settings.repeatMode
    for _, b in ipairs(f.toggles) do if b.key == "repeatMode" then b:Click("LeftButton") end end
    T.eq(s.settings.repeatMode, not was)
    -- 화면 옵션
    local o = Scene.options()
    local models = o.models
    f.optModels:Click("LeftButton")
    T.eq(o.models, not models, "3D 모델 켜고 끄기")
    f.optModels:Click("LeftButton")
    f.optFlip:Click("LeftButton")
    T.eq(o.modelFlip, true)
    f.optFlip:Click("LeftButton")
    local limit = o.modelLimit
    f.optLimit:Click("LeftButton")
    T.ok(o.modelLimit ~= limit, "모델 수 바꾸기")
    f.optStrip:Click("LeftButton")
    T.ok(not Strip.frame():IsShown(), "띠 숨기기")
    f.optStrip:Click("LeftButton")
    T.ok(Strip.frame():IsShown(), "띠 보이기")
    f.optLock:Click("LeftButton")
    T.eq(Strip.saved().locked, true)
    f.optLock:Click("LeftButton")
    -- 모델 점검 화면
    for _, b in ipairs(f.display) do if b.label:GetText() == "모델 점검" then b:Click("LeftButton") end end
    T.eq(Main.current(), "modelcheck")
    Stub.advance(1, 0.05)
    local mc = Main.built.modelcheck
    T.ok(mc.cells[1]:IsShown() and mc.cells[1].state:GetText():find("%d"), "모델 번호와 상태가 보임")
    noErrors("모델 점검")
    f = open("settings")
    -- 초기화는 두 번 눌러야 한다
    f.reset:Click("LeftButton")
    T.ok(App.state ~= nil, "한 번 눌러서는 초기화되지 않음")
    Stub.advance(6, 0.5)
    f.reset:Click("LeftButton")
    T.ok(App.state ~= nil, "시간이 지나면 다시 처음부터 확인함")
    f.reset:Click("LeftButton")
    T.eq(App.state, nil, "이어서 두 번 누르면 초기화")
    T.eq(WIH_DB, nil)
    T.eq(Main.current(), "setup")
    T.ok(not Strip.frame():IsShown(), "초기화하면 띠가 사라짐")
    T.ok(type(WIH_DB_BACKUP) == "table" and #WIH_DB_BACKUP == 1, "초기화 직전 상태가 백업에 남음")
    local setup = Main.built.setup
    T.ok(setup.restore:IsShown(), "백업이 있으면 되돌리기 버튼이 보임")
    setup.restore:Click("LeftButton")
    T.ok(App.state ~= nil, "백업에서 되돌아옴")
    T.eq(App.state.faction, "Alliance")
    T.ok(Strip.frame():IsShown(), "되돌리면 띠가 다시 뜸")
    Stub.advance(5, 0.05)
    noErrors("설정 화면")
end)

T.case("접속 종료 때 저장되고, 다시 불러오면 같은 상태가 된다", function()
    local s = App.state
    Stub.fire("PLAYER_LOGOUT")
    T.eq(WIH_DB, s)
    T.ok(s.savedAt > 0)
    local state, info = WIH.Save.load(WIH.Save.deepCopy(WIH_DB))
    T.ok(state ~= nil, "불러오기 성공")
    T.eq(info.status, "ok", "고칠 것이 없음: " .. table.concat(info.notes, " / "))
    T.eq(state.gold, s.gold)
    T.ok(type(WIH_UI) == "table" and type(WIH_UI.strip) == "table", "창과 띠의 배치가 저장 변수에 있음")
end)

T.case("진행 중 오류가 나면 멈추고 알린다", function()
    local session = App.session
    local old = session.advance
    session.advance = function() error("시험용 오류") end
    Stub.advance(0.2, 0.05)
    T.ok(App.paused, "오류가 나면 진행을 멈춤")
    T.eq(#App.lastErrors, 1, "같은 오류를 프레임마다 반복해 기록하지 않음")
    session.advance = old
    Main.open("settings")
    local settings = Main.built.settings
    T.ok(settings.resume:IsShown(), "설정 화면에 다시 시작 버튼이 보임")
    settings.resume:Click("LeftButton")
    T.ok(not App.paused, "다시 시작됨")
    for i = #App.lastErrors, 1, -1 do App.lastErrors[i] = nil end
end)

-- 대역에 정의하지 않은 위젯 메서드 가운데, 실제 클라이언트에 있다고 확인했거나 문서로 아는 것의 목록.
-- 여기에 없는 이름이 불리면 오타일 수 있으므로 실패로 처리한다.
local KNOWN = {
    SetAllPoints = true, SetColorTexture = true, SetTextColor = true, SetJustifyH = true, SetJustifyV = true,
    SetWordWrap = true, SetNonSpaceWrap = true, SetFont = true, SetTexCoord = true, SetAlpha = true, SetFrameStrata = true,
    SetToplevel = true, SetClampedToScreen = true, SetMovable = true, SetResizable = true, SetResizeBounds = true,
    EnableMouse = true, EnableMouseWheel = true, RegisterForDrag = true, RegisterForClicks = true, StartMoving = true,
    StartSizing = true, StopMovingOrSizing = true, SetFrameLevel = true, SetClipsChildren = true, SetDrawLayer = true,
    SetDesaturated = true, SetAtlas = true, SetVertexColor = true, UpdateScrollChildRect = true, SetSpacing = true,
    SetOwner = true, ClearLines = true, AddLine = true,
    -- PlayerModel(환경 점검에서 있는 것을 확인)
    SetFacing = true, SetCamDistanceScale = true, SetKeepModelOnHide = true, GetBottom = true,
}
T.case("화면이 부른 위젯 메서드는 모두 아는 이름이다", function()
    local unknown = {}
    for name in pairs(Stub.unknownCalls) do
        if not KNOWN[name] then unknown[#unknown + 1] = name end
    end
    table.sort(unknown)
    T.eq(#unknown, 0, "확인되지 않은 메서드: " .. table.concat(unknown, ", "))
end)

local uiOk = T.report("test_ui")
if arg and arg[1] == "-v" then
    local names = {}
    for name, n in pairs(Stub.unknownCalls) do names[#names + 1] = name .. "×" .. n end
    table.sort(names)
    io.write("대역에 없는 메서드 호출: ", table.concat(names, ", "), "\n")
end
if arg and arg[1] == "-v" then
    for i, e in ipairs(App.lastErrors) do io.write("기록된 오류 ", i, ": ", e, "\n") end
end
if not uiOk then os.exit(1) end
