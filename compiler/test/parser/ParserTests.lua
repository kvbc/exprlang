local Tests = require "test.Tests"
local Colors = require "util.Colors"
local pprint = require "lib.pprint"
local tablechanges = require "lib.tablechanges"

---@nodiscard
---@param ast table?
---@return string
local function astToString(ast)
    local str = pprint.pformat(ast)
    str = ('\n' .. str):gsub('\n', '\n| ')
    return str
end

---@class ParserTests : Tests
local ParserTests = setmetatable({}, Tests)
ParserTests.__index = ParserTests

---@nodiscard
---@return ParserTests
function ParserTests.New()
    local tests = Tests.New(function (test, testResult) -- onTestFailed
        ---@cast test ParserTest
        ---@cast testResult ParserTestResult
        
        io.write(Colors.Yellow)
        print("Source: " .. ('\n\n' .. test.SourceCode .. '\n'):gsub('\n', '\n| '))
        io.write(Colors.Clear)
        
        if not test.ExpectErrors then
            io.write(Colors.Yellow)
            local astDiff = tablechanges(testResult.AST, test.ExpectedAST)
            print("AST Diff: " .. astToString(astDiff))
            print("Expected: " .. astToString(test.ExpectedAST))
            print("Got: " .. astToString(testResult.AST))
            io.write(Colors.Clear)
        end
    end)
    ---@cast tests ParserTests
    setmetatable(tests, ParserTests)
    return tests
end

return ParserTests