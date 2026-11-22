-- 본 애드온의 모든 파일을 TOC 순서대로 WoW API 대역 위에서 불러온다.
-- 실행: lua5.1 Test/wih_load_test.lua

package.path = "./?.lua;" .. package.path
local Stub = require("Test.wow_stub")
Stub.install(_G)

local ns, meta, files = Stub.loadAddon("WIH", "WIH.toc", "WIH")
assert(meta.Interface == "16001", "Interface 번호가 16001이 아님")
assert(ns.Battle and ns.Skills and ns.AI, "엔진 모듈이 불러와지지 않음")
for i = 1, #files do
    local f = io.open("WIH/" .. files[i], "r")
    assert(f, "TOC에 적힌 파일이 없음: " .. files[i])
    f:close()
end
io.write(string.format("wih_load_test: 통과 (파일 %d개)\n", #files))
