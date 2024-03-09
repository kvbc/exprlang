local Tests = require "test.Tests"
local Colors = require "util.Colors"

---@nodiscard
---@param tokens Token[]
---@return string
local function tokensToString(tokens)
    local str = "\n|"
    for _,token in ipairs(tokens) do
        str = str .. '\n| ' .. token:ToString()
    end
    return str .. '\n|'
end

---@class LexerTests : Tests
local LexerTests = setmetatable({}, Tests)
LexerTests.__index = LexerTests

---@nodiscard
---@return LexerTests
function LexerTests.New()
    local tests = Tests.New(function (test, testResult) -- onTestFailed
        ---@cast test LexerTest
        ---@cast testResult LexerTestResult
        
        io.write(Colors.Yellow)
        print("Source: " .. ('\n\n' .. test.SourceCode .. '\n'):gsub('\n', '\n| '))
        io.write(Colors.Clear)
        
        if not test.ExpectErrors then
            io.write(Colors.Yellow)
            print("Expected: " .. tokensToString(test.ExpectedTokens))
            print("Got: " .. tokensToString(testResult.Tokens))
            io.write(Colors.Clear)
        end
    end)
    ---@cast tests LexerTests
    setmetatable(tests, LexerTests)
    return tests
end

return LexerTests