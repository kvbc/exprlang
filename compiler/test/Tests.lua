local Colors = require "util.Colors"
local pprint = require "lib.pprint"

---@class Tests
---@field Tests Test[]
---@field OnTestFailed fun(test: Test, testResult: TestResult)?
local Tests = {}
Tests.__index = Tests

---@nodiscard
---@param onTestFailed fun(test: Test, testResult: TestResult)?
---@return Tests
function Tests.New(onTestFailed)
    ---@type Tests
    local tests = {
        Tests = {};
        OnTestFailed = onTestFailed;
    }
    return setmetatable(tests, Tests)
end

---@param test Test
function Tests:Add(test)
    table.insert(self.Tests, test)
end

function Tests:Test()
    local failedTests = 0
    local succededTests = 0

    for i,test in ipairs(self.Tests) do
        local testRes = test:Test()

        if test.ExpectErrors then
            testRes.Ok = (#testRes.Errors > 0)
        end
    
        if not testRes.Ok then
            -- test failed
            failedTests = failedTests + 1

            print(Colors.Red .. ('[%02d/%02d] Test failed: "%s"'):format(i, #self.Tests, test.Name) .. Colors.Clear)
            
            if self.OnTestFailed then
                self.OnTestFailed(test, testRes)
            end
            
            if test.ExpectErrors then
                print(Colors.Yellow .. "Expected errors, got none" .. Colors.Clear)
            end
            
            if #testRes.Errors > 0 then
                print(Colors.Red .. "Errors: " .. Colors.Clear)
                for _, error in ipairs(testRes.Errors) do
                    print(Colors.Red .. error .. Colors.Clear)
                end
            end
        else
            -- test succeeded
            succededTests = succededTests + 1
            print(Colors.Green .. ('[%02d/%02d] Test succeeded: "%s" %s'):format(i, #self.Tests, test.Name, test.ExpectErrors and "(errored)" or "") .. Colors.Clear)
        end
    end

    if failedTests == 0 then
        print(Colors.Green .. ("[%02d/%02d] All tests succeeded! (100%% success rate)"):format(#self.Tests, #self.Tests) .. Colors.Clear)
    else
        print(Colors.Red .. ("[%02d/%02d] %d test(s) failed! (%.0f%% success rate)"):format(succededTests, #self.Tests, failedTests, succededTests / #self.Tests * 100) .. Colors.Clear)
    end
end

return Tests