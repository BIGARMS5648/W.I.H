-- 3D 모델 표시 부품. 두 가지 방식으로 보여 준다.
--   · 생물 모델: 클라이언트에 들어 있는 생물(NPC)의 모델. SetCreature(생물 번호) 또는 SetDisplayInfo(표시 번호).
--   · 캐릭터 모델: 종족·성별의 기본 캐릭터에 장비를 입힌 것. SetCustomRace + Undress + TryOn. 낀 장비에 따라 모습이 바뀐다.
-- 게임 내 확인(2026-11-22): DressUpModel·PlayerModel 생성, SetCreature, SetDisplayInfo, SetAnimation, SetFacing,
--   SetCamDistanceScale, GetModelFileID, GetDisplayInfo 사용 가능. 생물 모델이 실제로 화면에 보인다(사용자 캡처).
-- 확인되지 않은 것: SetCustomRace, TryOn, Undress, SetSheathed가 있는지와 동작하는지. 없거나 실패하면 생물 모델로 돌아간다.
-- 생물 모델은 처음 보는 생물이면 정보를 받아오는 데 시간이 걸린다. 그래서 일정 간격으로 다시 요청하고,
-- 한 번 불러온 생물의 표시 번호는 저장해 두었다가 다음부터 표시 번호로 바로 띄운다.

local _, WIH = ...
local UI = WIH.module("UI")
local Models = WIH.module("Models")

-- 동작 번호(클라이언트의 애니메이션 번호)
UI.ANIM = { stand = 0, death = 1, walk = 4, run = 5, dead = 6, wound = 8, attack = 17, attackUnarmed = 16, cast = 51, castOmni = 52 }

Models.known = {}        -- [생물 번호] = true(불러와짐) | false(실패). 접속해 있는 동안 기억한다
Models.dress = nil       -- 캐릭터에 장비를 입히는 방식이 되는지: nil(아직 모름) | true | false
Models.dressInfo = {}    -- 점검 화면에 보여 줄 진단(어떤 함수가 있고 어떤 호출이 성공했는지)
local RETRY = 0.7        -- 불러와지지 않았으면 이 간격으로 다시 요청한다
local GIVE_UP = 8.0      -- 이 시간이 지나도 안 되면 실패로 본다

-- 한 번 불러온 생물의 표시 번호를 저장해 둔다(창 배치와 같은 저장 변수).
local function displayCache()
    WIH_UI = type(WIH_UI) == "table" and WIH_UI or {}
    if type(WIH_UI.displayIds) ~= "table" then WIH_UI.displayIds = {} end
    return WIH_UI.displayIds
end

function Models.resetKnown()
    for k in pairs(Models.known) do Models.known[k] = nil end
    Models.dress = nil
end

function UI.modelView(parent)
    local v = CreateFrame("Frame", nil, parent)
    -- 옷을 입힐 수 있는 종류를 먼저 시도하고, 안 되면 보통 모델 프레임을 쓴다.
    local ok, m = pcall(CreateFrame, "DressUpModel", nil, v)
    if not (ok and m and m.SetCreature) then
        ok, m = pcall(CreateFrame, "PlayerModel", nil, v)
    end
    if ok and m and m.SetCreature then
        v.model = m
        m:SetAllPoints()
        m:Hide()
        if m.SetKeepModelOnHide then pcall(m.SetKeepModelOnHide, m, true) end
    end
    v.anim = nil

    local function apply(self)
        local model = self.model
        if model.SetFacing then pcall(model.SetFacing, model, self.facing or 0) end
        if model.SetCamDistanceScale then pcall(model.SetCamDistanceScale, model, self.camScale or 1) end
        if self.anim and model.SetAnimation then pcall(model.SetAnimation, model, self.anim) end
    end

    -- 생물 모델을 요청한다(저장해 둔 표시 번호가 있으면 그것으로).
    local function request(self)
        local id = self.creature
        local display = displayCache()[id]
        if display and self.model.SetDisplayInfo then
            pcall(self.model.SetDisplayInfo, self.model, display)
        else
            pcall(self.model.SetCreature, self.model, id)
        end
        apply(self)
    end

    -- 캐릭터에 장비를 입힌다.
    local function dress(self)
        local model, look = self.model, self.look
        local info = Models.dressInfo
        info.race = pcall(model.SetCustomRace, model, look.race, look.sex)
        if model.Undress then info.undress = pcall(model.Undress, model) end
        local worn = 0
        for _, itemId in ipairs(look.items) do
            if pcall(model.TryOn, model, "item:" .. itemId) then worn = worn + 1 end
        end
        if look.offhand and pcall(model.TryOn, model, "item:" .. look.offhand, "SECONDARYHANDSLOT") then worn = worn + 1 end
        info.tryOn = worn .. " / " .. (#look.items + (look.offhand and 1 or 0))
        if model.SetSheathed then info.sheath = pcall(model.SetSheathed, model, false) end
        apply(self)
    end

    local function try(self)
        local id = self.candidates and self.candidates[self.index]
        while id and Models.known[id] == false do
            self.index = self.index + 1
            id = self.candidates[self.index]
        end
        if not id or not self.model then
            self.creature, self.pending = nil, nil
            if self.model then self.model:Hide() end
            if self.onFail then self.onFail(self) end
            return false
        end
        self.creature = id
        self.model:Show()
        request(self)
        self.pending = Models.known[id] ~= true and 0 or nil
        self.sinceRequest = 0
        return true
    end

    -- candidates = 생물 번호 목록(앞에서부터 시도). 돌려주는 값: 모델을 띄우기 시작했으면 true
    function v:setCreature(candidates, facing, camScale)
        self.look = nil
        self.candidates, self.index = candidates, 1
        self.facing, self.camScale = facing, camScale
        self.anim = UI.ANIM.stand
        return try(self)
    end

    -- look = { race = 종족 번호, sex = 0(남) | 1(여), items = { 아이템 번호, ... } }
    -- 돌려주는 값: 입히기를 시작했으면 true. 이 클라이언트에서 안 되는 방식이면 false(부른 쪽이 생물 모델을 쓴다).
    function v:setCharacter(look, facing, camScale)
        local model = self.model
        Models.dressInfo.frame = model and (model.TryOn and "DressUpModel" or "PlayerModel") or "없음"
        Models.dressInfo.hasRace = model ~= nil and model.SetCustomRace ~= nil
        Models.dressInfo.hasTryOn = model ~= nil and model.TryOn ~= nil
        if not model or not model.SetCustomRace or not model.TryOn or Models.dress == false then return false end
        self.candidates, self.creature = nil, nil
        self.look = look
        self.facing, self.camScale = facing, camScale
        self.anim = UI.ANIM.stand
        model:Show()
        dress(self)
        self.pending, self.sinceRequest = 0, 0
        return true
    end

    function v:clear()
        self.candidates, self.creature, self.pending, self.look = nil, nil, nil, nil
        if self.model then
            if self.model.ClearModel then pcall(self.model.ClearModel, self.model) end
            self.model:Hide()
        end
    end

    function v:setAnim(id)
        if self.anim == id then return end
        self.anim = id
        if self.model and (self.creature or self.look) and self.model.SetAnimation then pcall(self.model.SetAnimation, self.model, id) end
    end

    function v:setFacing(facing)
        if self.facing == facing then return end
        self.facing = facing
        if self.model and (self.creature or self.look) and self.model.SetFacing then pcall(self.model.SetFacing, self.model, facing) end
    end

    function v:isPending() return self.pending ~= nil end

    -- 불러오기 확인. 화면이 프레임마다 부른다.
    function v:update(elapsed)
        if not self.pending then return end
        -- 모델 파일 번호를 물을 수 없는 클라이언트라면 확인할 방법이 없으므로 불러와진 것으로 본다.
        local fileId = 1
        if self.model.GetModelFileID then fileId = self.model:GetModelFileID() end
        if fileId and fileId ~= 0 then
            self.pending = nil
            if self.look then
                Models.dress = true
                dress(self)             -- 캐릭터가 올라온 뒤에 장비를 다시 입힌다(먼저 입힌 것이 빠질 수 있다)
            else
                Models.known[self.creature] = true
                if self.model.GetDisplayInfo then
                    local okInfo, display = pcall(self.model.GetDisplayInfo, self.model)
                    if okInfo and type(display) == "number" and display > 0 then displayCache()[self.creature] = display end
                end
                apply(self)             -- 모델이 올라온 뒤에 방향과 동작을 다시 건다
            end
            if self.onReady then self.onReady(self) end
            return
        end
        self.pending = self.pending + elapsed
        self.sinceRequest = self.sinceRequest + elapsed
        if self.pending >= GIVE_UP then
            if self.look then
                Models.dress = false     -- 이 클라이언트에서는 입히는 방식이 안 된다. 생물 모델로 돌아간다
                self.look, self.pending = nil, nil
                self.model:Hide()
                if self.onFail then self.onFail(self) end
            else
                Models.known[self.creature] = false
                self.index = self.index + 1
                try(self)
            end
        elseif self.sinceRequest >= RETRY then
            self.sinceRequest = 0
            if self.look then dress(self) else request(self) end
        end
    end

    if v.model then
        -- 이 스크립트 종류가 없는 클라이언트에서는 SetScript가 오류를 내므로 보호해서 건다.
        pcall(v.model.SetScript, v.model, "OnModelLoaded", function() if v.creature or v.look then apply(v) end end)
    end
    return v
end

return UI
