require "Source"
require "SourcePos"
require "SourceRange"
require "Lexer"
require "Token"
require "Parser"
local AST = require "AST"
local deepcompare = require "lib.deepcompare"
local dedent = require "lib.dedent"

local red = '\27[31m'
local green = '\27[32m'
local yellow = '\27[33m'
local clear = '\27[0m'
local defSrcRange = SourceRange.New(SourcePos.New(1, 1))
local emptyAST = AST.Node.New(defSrcRange)

---@nodiscard
---@param ast ASTNode
---@return string
local function astToString(ast)
    local str = ast.String:gsub('\n', '\n| ')
    return str
end

local testNum = 0
local testsFailedNum = 0
local testsSuccessNum = 0
---@param name string
---@param sourceCode string
---@param expectedASTNode ASTNode? if no node expected, an error is expected
local function test(name, sourceCode, expectedASTNode)
    testNum = testNum + 1

    local source = Source.New(sourceCode)
    local lexer = Lexer.New(source)
    local tokens = lexer:Lex()
    local parser = Parser.New(source, tokens)
    local ast = parser:Parse()

    local hasErrors = #parser.Errors > 0
    local ok = (not expectedASTNode and hasErrors) or (expectedASTNode and not hasErrors)
    if ok and expectedASTNode then
        ok = deepcompare(ast, expectedASTNode)
    end

    if not ok then
        -- test failed
        testsFailedNum = testsFailedNum + 1
        print(red .. ('[%02d] Test failed: "%s"'):format(testNum, name))
        print(yellow .. "Source: " .. ('\n\n' .. sourceCode .. '\n'):gsub('\n', '\n| '))
        if not expectedASTNode then
            print(yellow .. "Expected errors, got none")
        end
        if expectedASTNode then
            print("Expected: " .. astToString(expectedASTNode))
            print("Got: " .. (ast and astToString(ast) or "<none>"))
        end
        if hasErrors then
            print("Errors: ")
            for _, error in ipairs(parser.Errors) do
                print(error)
            end
        end
    else
        -- test succeeded
        testsSuccessNum = testsSuccessNum + 1
        print(green .. ('[%02d] Test succeeded: "%s" %s'):format(testNum, name, not expectedASTNode and "(errored)" or ""))
    end
    io.write(clear)
end

--[[
--
-- Test Start
--
--]]

test(
    "empty source",
    "",
    AST.NodeExprBlock.New({}, defSrcRange)
)

--[[
--
-- Test End
--
--]]

if testsFailedNum == 0 then
    print(green .. ("[%02d/%02d] All tests succeeded! (100%% success rate)"):format(testNum, testNum) .. clear)
else
    print(red .. ("[%02d/%02d] %d test(s) failed! (%.0f%% success rate)"):format(testsSuccessNum, testNum, testsFailedNum, testsSuccessNum / testNum * 100) .. clear)
end