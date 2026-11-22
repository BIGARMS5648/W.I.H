-- 아주 작은 테스트 틀.

local T = { passed = 0, failed = 0, failures = {}, current = "" }

function T.case(name, fn)
    T.current = name
    local ok, err = xpcall(fn, function(e) return debug.traceback(tostring(e), 2) end)
    if ok then
        T.passed = T.passed + 1
    else
        T.failed = T.failed + 1
        T.failures[#T.failures + 1] = name .. "\n    " .. tostring(err):gsub("\n", "\n    ")
    end
end

function T.eq(actual, expected, msg)
    if actual ~= expected then
        error((msg or "값이 다름") .. ": 기대 " .. tostring(expected) .. ", 실제 " .. tostring(actual), 2)
    end
end

function T.near(actual, expected, tol, msg)
    tol = tol or 1e-6
    if type(actual) ~= "number" or math.abs(actual - expected) > tol then
        error((msg or "값이 다름") .. ": 기대 " .. tostring(expected) .. " ±" .. tol .. ", 실제 " .. tostring(actual), 2)
    end
end

function T.ok(cond, msg)
    if not cond then error(msg or "조건이 거짓", 2) end
end

function T.report(title)
    io.write(string.format("%s: 통과 %d, 실패 %d\n", title, T.passed, T.failed))
    for i = 1, #T.failures do io.write("  실패: ", T.failures[i], "\n") end
    return T.failed == 0
end

return T
