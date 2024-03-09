---@class TestResult
---@field Ok boolean
---@field Errors string[]
local TestResult = {}
TestResult.__index = TestResult

---@nodiscard
---@param ok boolean
---@param errors string[]
---@return TestResult
function TestResult.New(ok, errors)
    ---@type TestResult
    local self = {
        Ok = ok;
        Errors = errors;
    }
    return setmetatable(self, TestResult)
end

return TestResult