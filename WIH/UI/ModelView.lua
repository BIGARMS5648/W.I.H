-- 3D 모델 표시 부품. 클라이언트에 들어 있는 생물 모델을 PlayerModel 프레임으로 보여 준다.
-- 게임 내 확인(2026-11-22): PlayerModel 생성, SetCreature, SetAnimation, SetFacing, SetCamDistanceScale 사용 가능.
-- 확인되지 않은 것: 모델이 실제로 눈에 보이는지, 동작이 바뀌는지, 여러 개를 띄웠을 때의 부하.
-- 그래서 모델이 불러와지지 않으면 다음 후보를 쓰고, 모두 실패하면 onFail을 불러 아이콘 표시로 바꿀 수 있게 한다.

local _, WIH = ...
local UI = WIH.module("UI")
local Models = WIH.module("Models")

-- 동작 번호(클라이언트의 애니메이션 번호)
UI.ANIM = { stand = 0, death = 1, walk = 4, run = 5, wound = 8, attack = 17, attackUnarmed = 16, cast = 51, castOmni = 52 }

Models.known = {}        -- [생물 번호] = true(불러와짐) | false(실패). 한 번 알아내면 다시 시험하지 않는다
local CHECK_TIME = 2.0   -- 이 시간 안에 모델 파일이 잡히지 않으면 실패로 본다(처음 불러올 때는 시간이 걸릴 수 있다)

function UI.modelView(parent)
    local v = CreateFrame("Frame", nil, parent)
    local ok, m = pcall(CreateFrame, "PlayerModel", nil, v)
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
        pcall(self.model.SetCreature, self.model, id)
        apply(self)
        self.pending = Models.known[id] ~= true and 0 or nil
        return true
    end

    -- candidates = 생물 번호 목록(앞에서부터 시도). 돌려주는 값: 모델을 띄우기 시작했으면 true
    function v:setCreature(candidates, facing, camScale)
        self.candidates, self.index = candidates, 1
        self.facing, self.camScale = facing, camScale
        self.anim = UI.ANIM.stand
        self.failed = nil
        return try(self)
    end

    function v:clear()
        self.candidates, self.creature, self.pending = nil, nil, nil
        if self.model then
            if self.model.ClearModel then pcall(self.model.ClearModel, self.model) end
            self.model:Hide()
        end
    end

    function v:setAnim(id)
        if self.anim == id then return end
        self.anim = id
        if self.model and self.creature and self.model.SetAnimation then pcall(self.model.SetAnimation, self.model, id) end
    end

    function v:setFacing(facing)
        if self.facing == facing then return end
        self.facing = facing
        if self.model and self.creature and self.model.SetFacing then pcall(self.model.SetFacing, self.model, facing) end
    end

    -- 불러오기 확인. 장면이 프레임마다 부른다.
    function v:update(elapsed)
        if not self.pending then return end
        -- 모델 파일 번호를 물을 수 없는 클라이언트라면 확인할 방법이 없으므로 불러와진 것으로 본다.
        local fileId = 1
        if self.model.GetModelFileID then fileId = self.model:GetModelFileID() end
        if fileId and fileId ~= 0 then
            Models.known[self.creature] = true
            self.pending = nil
            apply(self)      -- 모델이 올라온 뒤에 방향과 동작을 다시 건다
            return
        end
        self.pending = self.pending + elapsed
        if self.pending >= CHECK_TIME then
            Models.known[self.creature] = false
            self.index = self.index + 1
            try(self)
        end
    end

    if v.model then
        -- 이 스크립트 종류가 없는 클라이언트에서는 SetScript가 오류를 내므로 보호해서 건다.
        pcall(v.model.SetScript, v.model, "OnModelLoaded", function() if v.creature then apply(v) end end)
    end
    return v
end

return UI
