---@class Test
---@field TestsCount integer
---@field TestsSuccededCount integer
---@field TestsFailedCount integer
local Test = {}
Test.__index = Test

function Test.New()
    ---@type Test
    local test = {
        TestsCount = 0;
        TestsSuccededCount = 0;
        TestsFailedCount = 0;
    }
    return setmetatable(test, Test)
end

---@param testName string
---@param ok boolean
---@param errors string[]
---@param expectErrors boolean
---@param printOnFailAlways string[]
---@param printOnFailNoError string[]
---@protected
function Test:test(testName, ok, errors, expectErrors, printOnFailAlways, printOnFailNoError)
    local red = '\27[31m'
    local green = '\27[32m'
    local yellow = '\27[33m'
    local clear = '\27[0m'

    if expectErrors and #errors == 0 then
        ok = false
    end

    self.testCount = self.testCount + 1

    if not ok then
        -- test failed
        self.TestsFailedCount = self.TestsFailedCount + 1
        print(red .. ('[%02d] Test failed: "%s"'):format(self.TestsCount, testName) .. clear)
        
        for _,str in ipairs(printOnFailAlways) do
            print(yellow .. str .. clear)
        end
        
        if expectErrors then
            print(yellow .. "Expected errors, got none" .. clear)
        else
            for _,str in ipairs(printOnFailNoError) do
                print(yellow .. str .. clear)
            end
        end
        
        if #errors > 0 then
            print(red .. "Errors: " .. clear)
            for _, error in ipairs(errors) do
                print(red .. error .. clear)
            end
        end
    else
        -- test succeeded
        self.TestsSuccededCount = self.TestsSuccededCount + 1
        print(green .. ('[%02d] Test succeeded: "%s" %s'):format(self.TestsCount, testName, expectErrors and "(errored)" or "") .. clear)
    end
end

return Test