-- 게임 밖에서 엔진 파일을 불러온다. TOC의 순서를 그대로 따르고 UI 폴더의 파일은 건너뛴다.
-- 사용: local WIH = require("Test.engine").load()

local M = {}

function M.files(tocPath)
    local out = {}
    local f = assert(io.open(tocPath, "r"))
    for line in f:lines() do
        line = line:gsub("\r", "")
        if line ~= "" and not line:match("^#") then
            out[#out + 1] = (line:gsub("\\", "/"))
        end
    end
    f:close()
    return out
end

function M.load(opts)
    opts = opts or {}
    local dir = opts.dir or "WIH"
    local ns = {}
    local files = M.files(dir .. "/WIH.toc")
    for i = 1, #files do
        local path = files[i]
        if opts.withUI or not path:match("^UI/") then
            local chunk, err = loadfile(dir .. "/" .. path)
            if not chunk then error("불러오기 실패: " .. tostring(err)) end
            chunk("WIH", ns)
        end
    end
    return ns
end

return M
