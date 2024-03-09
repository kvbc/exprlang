---@class Test
---@field Name string
---@field ExpectErrors boolean
local Test = {}
Test.__index = Test

---@nodiscard
---@param name string
---@param expectErrors boolean
---@return Test
function Test.New(name, expectErrors)
    ---@type Test
    local test = {
        Name = name;
        ExpectErrors = expectErrors;
    }
    return setmetatable(test, Test)
end

---@nodiscard
---@return TestResult
function Test:Test()
    error "override"
end

return Test