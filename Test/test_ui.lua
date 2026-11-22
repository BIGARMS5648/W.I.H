-- 화면 검사: WoW API 대역 위에서 애드온 전체(화면 포함)를 불러와 창을 열고, 화면을 오가며 버튼을 누른다.
-- 이 검사가 확인하는 것: Lua 실행 오류가 없는지, 버튼이 규칙 함수를 불러 상태가 실제로 바뀌는지.
-- 확인하지 못하는 것: 실제 클라이언트에서의 모양, 배치, 글자 잘림, 대역에 없는 API의 동작.
-- 실행: lua5.1 Test/test_ui.lua

package.path = "./?.lua;" .. package.path
local Stub = require("Test.wow_stub")
local T = require("Test.t")
Stub.install(_G)

local WIH, meta, files = Stub.loadAddon("WIH", "WIH.toc", "WIH")
local App, Main, UI, Game, Runes = WIH.App, WIH.Main, WIH.UI, WIH.Game, WIH.Runes

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
    Main.show(id)
    T.eq(Main.current(), id, "화면 전환: " .. id)
    noErrors("화면 " .. id)
    return Main.built[id]
end

T.case("처음 실행: 저장이 없으면 시작 화면이 열린다", function()
    WIH_DB, WIH_DB_BACKUP, WIH_UI = nil, nil, nil
    Stub.fire("ADDON_LOADED", "WIH")
    T.ok(App.loaded, "불러오기 완료 표시")
    T.eq(App.state, nil)
    SlashCmdList["WIH"]()
    T.ok(Main.isShown(), "/wih로 창이 열림")
    T.eq(Main.current(), "setup")
    noErrors("시작 화면")
end)

T.case("진영과 첫 영웅을 고르면 게임이 시작된다", function()
    local f = Main.built.setup
    f.factionCards[2]:Click("LeftButton")
    T.eq(f.faction, "Horde")
    T.eq(f.step, 2)
    f.start:Click("LeftButton")
    T.eq(App.state, nil, "영웅을 고르기 전에는 시작되지 않음")
    f.heroButtons["war_prot"]:Click("LeftButton")
    f.start:Click("LeftButton")
    T.ok(App.state ~= nil, "게임 상태가 만들어짐")
    T.eq(App.state.faction, "Horde")
    T.eq(App.state.party[1], "war_prot")
    T.eq(WIH_DB, App.state, "저장 변수에 연결됨")
    T.eq(Main.current(), "battle")
    noErrors("게임 시작")
end)

T.case("전투 화면이 보이는 동안 진행이 돌아가고 오류가 없다", function()
    local before = App.state.stats.playSeconds
    Stub.advance(40, 0.05)
    T.ok(App.state.stats.playSeconds - before > 30, "진행 시간이 흐름: " .. (App.state.stats.playSeconds - before))
    T.ok(App.state.stats.kills > 0, "처치가 기록됨")
    T.ok(App.state.gold > Game.START_GOLD, "골드가 늘어남")
    T.ok(not App.paused, "진행이 멈추지 않음")
    noErrors("전투 진행")
end)

T.case("창을 닫아도 진행은 계속된다", function()
    Main.toggle()
    T.ok(not Main.isShown())
    local kills = App.state.stats.kills
    Stub.advance(30, 0.05)
    T.ok(App.state.stats.kills > kills, "창이 닫힌 동안에도 처치가 늘어남")
    T.ok(not App.session.relayBattle, "창이 닫히면 전투 장면 중계를 끔")
    Main.toggle()
    T.ok(Main.isShown())
    T.ok(App.session.relayBattle, "다시 열면 중계를 켬")
    noErrors("창 여닫기")
end)

T.case("영웅 화면: 해금, 스킬 투자·환급, 장착", function()
    local s = App.state
    s.gold = 5000
    s.heroes.war_prot.level, s.heroes.war_prot.exp = 12, 0
    local f = open("heroes")
    -- 다른 영웅을 골라 해금
    f.rows["pri_holy"]:Click("LeftButton")
    T.eq(f.heroId, "pri_holy")
    T.ok(f.unlock:IsShown(), "잠긴 영웅에게는 해금 버튼이 보임")
    f.unlock:Click("LeftButton")
    T.ok(s.heroes.pri_holy ~= nil, "해금됨")
    T.eq(s.gold, 5000 - Game.HERO_UNLOCK_COST)
    -- 스킬 투자와 환급
    f.rows["war_prot"]:Click("LeftButton")
    local first = WIH.Heroes.byId.war_prot.skills[1]
    f.actives[1]:Click("LeftButton")
    T.eq(s.heroes.war_prot.active[first], 1, "왼쪽 클릭으로 투자")
    f.actives[1]:Click("LeftButton")
    T.eq(s.heroes.war_prot.active[first], 2)
    f.actives[1]:Click("RightButton")
    T.eq(s.heroes.war_prot.active[first], 1, "오른쪽 클릭으로 환급")
    f.passives[1]:Click("LeftButton")
    T.eq(s.heroes.war_prot.passive[1], 1, "패시브 투자")
    -- 장착과 해제
    T.ok(f.equips[1]:IsShown(), "배운 스킬에는 장착 버튼이 보임")
    local had = false
    for _, id in ipairs(s.heroes.war_prot.bar) do if id == first then had = true end end
    f.equips[1]:Click("LeftButton")
    local has = false
    for _, id in ipairs(s.heroes.war_prot.bar) do if id == first then has = true end end
    T.ok(has ~= had, "장착 상태가 바뀜")
    -- 투자할 수 없는 티어를 누르면 상태는 그대로이고 사유가 뜬다
    local before = Game.spentPoints(s, "war_prot")
    f.passives[16]:Click("LeftButton")
    T.eq(Game.spentPoints(s, "war_prot"), before, "조건이 안 되는 투자는 거절됨")
    f.apply:Click("LeftButton")
    T.ok(Game.treeValid(WIH.Heroes.byId.war_prot, s.heroes.war_prot), "트리 상태가 규칙에 맞음")
    noErrors("영웅 화면")
end)

T.case("룬 화면: 구매가 골드와 룬 레벨에 반영된다", function()
    local s = App.state
    s.gold = 100000
    local f = open("runes")
    T.ok(#f.items > 0, "살 수 있는 룬이 있음")
    T.eq(f.items[1], 1, "처음에는 뿌리 룬만 열려 있음")
    local gold = s.gold
    f.rows[1].buy:Click("LeftButton")
    T.eq(Runes.level(s, 1), 1)
    T.ok(s.gold < gold, "골드가 줄어듦")
    -- 새로 열린 룬이 목록 뒤에 붙는다
    local seen = {}
    for _, key in ipairs(f.items) do seen[key] = true end
    T.ok(seen[10] and seen[20], "새로 열린 룬이 목록에 나타남")
    -- 편성 칸 룬까지: 20 → 21
    for _, b in ipairs(f.filters) do if b.id == "all" then b:Click("LeftButton") end end
    T.eq(#f.items, f.total, "전체 보기는 모든 룬을 보여 줌")
    T.ok(Runes.buy(s, 20) and Runes.buy(s, 21), "편성 칸 룬 구매")
    T.eq(Game.partySlots(s), 2)
    -- 골드가 모자라면 버튼이 꺼진다
    s.gold = 0
    f = open("runes")
    for n = 1, #f.items do
        local row = f.rows[n]
        if row.buy:IsShown() then T.ok(not row.buy.enabled, "골드가 없으면 구매 버튼이 꺼짐") end
    end
    -- 툴팁 내용이 만들어지는지
    for n = 1, #f.items do T.ok(f.rows[n].tooltip(f.rows[n]).title ~= nil) end
    noErrors("룬 화면")
end)

T.case("편성 화면: 넣기, 순서 바꾸기, 빼기", function()
    local s = App.state
    local f = open("party")
    T.eq(#s.party, 1)
    T.ok(f.benchRows[1] and f.benchRows[1]:IsShown(), "대기 중인 영웅이 보임")
    f.benchRows[1]:Click("LeftButton")
    T.eq(#s.party, 2, "편성에 들어감")
    T.eq(s.party[2], "pri_holy")
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
    noErrors("편성 화면")
end)

T.case("스테이지 화면: 잠긴 곳은 못 가고, 열린 곳으로는 이동한다", function()
    local s = App.state
    Game.selectStage(s, 1, 101)
    local f = open("stage")
    f.rows[105]:Click("LeftButton")
    T.eq(f.section, 105)
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

T.case("가방 화면: 첫 클리어 보상, 장착·해제, 잠금, 팔기, 칸 구매, 상자 열기", function()
    local s = App.state
    local Items, Inventory, Chests = WIH.Items, WIH.Inventory, WIH.Chests
    -- 시험 준비: 가방을 비우고 정해진 아이템을 넣는다.
    s.inventory.items, s.mail = {}, {}
    for id, h in pairs(s.heroes) do h.gear = {} end
    local sword, staff, helmet = Items.find("SWORD", 1, 1), Items.find("STAFF", 1, 1), Items.find("HELMET", 1, 2)
    Inventory.add(s, sword.id); Inventory.add(s, staff.id); Inventory.add(s, helmet.id)
    local f = open("bag")
    f.heroRows[1]:Click("LeftButton")
    T.eq(f.heroId, s.party[1])
    f.heroId = "war_prot"
    UI.screens.bag.refresh(f)
    T.ok(f.cells[1]:IsShown() and f.cells[20]:IsShown() and not f.cells[21], "칸 수 = 가방 용량")
    -- 고르면 상세가 보이고, 장착 버튼으로 낀다
    f.cells[1]:Click("LeftButton")
    T.eq(f.selected, 1)
    T.ok(f.dEquip:IsShown() and f.dEquip.enabled)
    T.ok(f.dName:GetText():find("한손검"), "상세에 이름이 보임: " .. f.dName:GetText())
    f.dEquip:Click("LeftButton")
    T.eq(s.heroes.war_prot.gear.MAIN.id, sword.id)
    T.eq(#s.inventory.items, 2)
    -- 쓸 수 없는 무기는 장착 버튼이 꺼지고, 오른쪽 클릭으로도 끼워지지 않는다
    f.cells[1]:Click("LeftButton")
    T.ok(not f.dEquip.enabled, "전사는 지팡이를 못 낌")
    f.cells[1]:Click("RightButton")
    T.eq(s.heroes.war_prot.gear.MAIN.id, sword.id)
    -- 오른쪽 클릭으로 바로 장착
    f.cells[2]:Click("RightButton")
    T.eq(s.heroes.war_prot.gear.HELMET.id, helmet.id)
    -- 해제
    f.slots.HELMET.off:Click("LeftButton")
    T.eq(s.heroes.war_prot.gear.HELMET, nil)
    T.eq(#s.inventory.items, 2)
    -- 잠금과 팔기
    f.selected = 2
    UI.screens.bag.refresh(f)
    f.dLock:Click("LeftButton")
    T.eq(s.inventory.items[2].lock, true)
    T.ok(not f.dSell.enabled, "잠근 것은 팔기 버튼이 꺼짐")
    local gold = s.gold
    f.bulk:Click("LeftButton")
    T.eq(#s.inventory.items, 1, "잠근 것만 남음")
    T.eq(s.gold, gold + Inventory.alchemyValue(s, staff))
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
    T.ok(not f.chestRows.stage.open.enabled or Chests.count(s, "stage") > 0)
    -- 툴팁 내용이 만들어지는지
    T.ok(UI.itemTip(sword, nil, staff).title ~= nil)
    T.ok(f.slots.MAIN.tooltip(f.slots.MAIN).title:find("한손검"))
    f.apply:Click("LeftButton")
    T.near(App.session.runner.heroes[1]:get("AttackDamage") >= 3 and 1 or 0, 1, 0, "장비가 전투에 반영됨")
    noErrors("가방 화면")
end)

T.case("모든 화면의 보이는 버튼을 눌러도 오류가 없다", function()
    local s = App.state
    s.gold = 5e8
    for id, h in pairs(s.heroes) do h.level = 60 end
    local order = { "battle", "heroes", "bag", "party", "stage", "runes" }
    for _ = 1, 12 do WIH.Inventory.add(s, WIH.Items.find("HELMET", 1, 1).id) end
    s.chests.normal.list, s.chests.stage.list = { 1, 1, 1 }, { 2, 2 }
    local clicks = 0
    for round = 1, 3 do
        for _, id in ipairs(order) do
            local f = open(id)
            local buttons = visibleButtons(f)
            T.ok(#buttons > 0, id .. " 화면에 버튼이 있음")
            for i, b in ipairs(buttons) do
                if b:IsVisible() then
                    b:Click((i + round) % 4 == 0 and "RightButton" or "LeftButton")
                    clicks = clicks + 1
                    noErrors(id .. " 화면의 버튼 " .. i)
                    T.ok(App.state ~= nil, "게임 상태가 유지됨")
                end
            end
            Stub.advance(3, 0.05)
            noErrors(id .. " 화면 진행")
        end
    end
    T.ok(clicks > 300, "누른 버튼 수: " .. clicks)
    local notes = WIH.Save.validate(WIH.Save.deepCopy(s))
    T.ok(notes and #notes == 0, "마구 누른 뒤에도 저장 데이터가 규칙에 맞음: " .. table.concat(notes or { "검증 실패" }, " / "))
end)

T.case("설정 화면: 진영, 진행 방식, 초기화와 백업 되돌리기", function()
    local s = App.state
    local f = open("settings")
    f.factions.Alliance:Click("LeftButton")
    T.eq(s.faction, "Alliance")
    local was = s.settings.repeatMode
    for _, b in ipairs(f.toggles) do if b.key == "repeatMode" then b:Click("LeftButton") end end
    T.eq(s.settings.repeatMode, not was)
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
    T.ok(type(WIH_DB_BACKUP) == "table" and #WIH_DB_BACKUP == 1, "초기화 직전 상태가 백업에 남음")
    -- 시작 화면에서 되돌리기
    local setup = Main.built.setup
    T.ok(setup.restore:IsShown(), "백업이 있으면 되돌리기 버튼이 보임")
    setup.restore:Click("LeftButton")
    T.ok(App.state ~= nil, "백업에서 되돌아옴")
    T.eq(App.state.faction, "Alliance")
    T.eq(#App.state.party, #s.party)
    T.eq(Main.current(), "battle")
    Stub.advance(5, 0.05)
    noErrors("설정 화면")
end)

T.case("접속 종료 때 저장되고, 다시 불러오면 같은 상태가 된다", function()
    local s = App.state
    Stub.fire("PLAYER_LOGOUT")
    T.eq(WIH_DB, s)
    T.ok(s.savedAt > 0)
    local copy = WIH.Save.deepCopy(WIH_DB)
    local state, info = WIH.Save.load(copy)
    T.ok(state ~= nil, "불러오기 성공")
    T.eq(info.status, "ok", "고칠 것이 없음: " .. table.concat(info.notes, " / "))
    T.eq(state.gold, s.gold)
    T.ok(type(WIH_UI) == "table", "창 배치 저장 변수가 표로 준비됨")
end)

T.case("진행 중 오류가 나면 멈추고 알린다", function()
    local session = App.session
    local old = session.advance
    session.advance = function() error("시험용 오류") end
    Stub.advance(0.2, 0.05)
    T.ok(App.paused, "오류가 나면 진행을 멈춤")
    T.eq(#App.lastErrors, 1, "같은 오류를 프레임마다 반복해 기록하지 않음")
    session.advance = old
    Main.show("settings")
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
    SetOwner = true, ClearLines = true, AddLine = true, SetBlendMode = true, SetRotation = true,
}
T.case("화면이 부른 위젯 메서드는 모두 아는 이름이다", function()
    local unknown = {}
    for name in pairs(Stub.unknownCalls) do
        if not KNOWN[name] then unknown[#unknown + 1] = name end
    end
    table.sort(unknown)
    T.eq(#unknown, 0, "확인되지 않은 메서드: " .. table.concat(unknown, ", "))
end)

if not T.report("test_ui") then os.exit(1) end
if arg and arg[1] == "-v" then
    local names = {}
    for name, n in pairs(Stub.unknownCalls) do names[#names + 1] = name .. "×" .. n end
    table.sort(names)
    io.write("대역에 없는 메서드 호출: ", table.concat(names, ", "), "\n")
end
