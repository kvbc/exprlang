require "Source"
require "SourcePos"
require "SourceRange"
require "Lexer"
require "Token"
local deepcompare = require "lib.deepcompare"
local dedent = require "lib.dedent"

local red = '\27[31m'
local green = '\27[32m'
local yellow = '\27[33m'
local clear = '\27[0m'

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

---@nodiscard
---@param type TokenType
---@param value any
---@return Token
local function newToken(type, value)
    --dummy source range
    return Token.New(type, value, SourceRange.New(SourcePos.New(1, 1)))
end

local testNum = 0
local testsFailedNum = 0
local testsSuccessNum = 0
---@param name string
---@param sourceCode string
---@param expectedTokens (Token[])? if no tokens expected, an error is expected
local function test(name, sourceCode, expectedTokens)
    testNum = testNum + 1

    local source = Source.New(sourceCode)
    local lexer = Lexer.New(source)
    local tokens = lexer:Lex()

    local hasErrors = #lexer.Errors > 0
    local ok = (not expectedTokens and hasErrors) or (expectedTokens and #tokens == #expectedTokens and not hasErrors)
    if ok and expectedTokens then
        for i = 1, #tokens do
            local tk1 = tokens[i]
            local tk2 = expectedTokens[i]
            if tk1.Type ~= tk2.Type or not deepcompare(tk1.Value, tk2.Value) then
                ok = false
                break
            end
        end
    end

    if not ok then
        -- test failed
        testsFailedNum = testsFailedNum + 1
        print(red .. ('[%02d] Test failed: "%s"'):format(testNum, name))
        print(yellow .. "Source: " .. ('\n\n' .. sourceCode .. '\n'):gsub('\n', '\n| '))
        if not expectedTokens then
            print(yellow .. "Expected errors, got none")
        end
        if expectedTokens then
            print("Expected: " .. tokensToString(expectedTokens))
            print("Got: " .. tokensToString(tokens))
        end
        if hasErrors then
            print("Errors: ")
            for _, error in ipairs(lexer.Errors) do
                print(error)
            end
        end
    else
        -- test succeeded
        testsSuccessNum = testsSuccessNum + 1
        print(green .. ('[%02d] Test succeeded: "%s" %s'):format(testNum, name, not expectedTokens and "(errored)" or ""))
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
    {}
)
test(
    "multiple new-lines become one", dedent
    [[
        name_1


        
        name_2
    ]],
    {
        newToken('name', 'name_1'),
        newToken('character', '\n'),
        newToken('name', 'name_2')
    }
)

--
-- Comments
--

test(
    "just comment",
    "# this is just a comment",
    {}
)
test(
    "comment right after name", dedent
    [[
        name_1 # cool comment
        name_2
    ]],
    {
        newToken('name', 'name_1'),
        newToken('character', '\n'),
        newToken('name', 'name_2'),
    }
)
test(
    "comment in comment", dedent
    [[
        name_1
        # com # ment
        name_2
    ]],
    {
        newToken('name', 'name_1'),
        newToken('character', '\n'),
        newToken('name', 'name_2')
    }
)
test(
    "comment right after comment", dedent
    [[
        name_1
        # this
        # is a comment
        # (s)
        name_2
    ]],
    {
        newToken('name', 'name_1'),
        newToken('character', '\n'),
        newToken('name', 'name_2')
    }
)

--
-- keywords
--

test(
    "keywords", dedent
    [[
        num not or and auto ref
    ]],
    {
        newToken('keyword', 'num'),
        newToken('keyword', 'not'),
        newToken('keyword', 'or'),
        newToken('keyword', 'and'),
        newToken('keyword', 'auto'),
        newToken('keyword', 'ref'),
    }
)

--
-- operators
--

test(
    "operators", dedent
    [[
        == ~= >= <= -> :=
    ]],
    {
        newToken('operator', '=='),
        newToken('operator', '~='),
        newToken('operator', '>='),
        newToken('operator', '<='),
        newToken('operator', '->'),
        newToken('operator', ':='),
    }
)

--
-- name
--

test(
    "name", dedent
    [[
        _0123456789abcdefghijklmnopqrstuvwxyz9876543210_
    ]],
    {
        newToken('name', '_0123456789abcdefghijklmnopqrstuvwxyz9876543210_')
    }
)

--
-- number literal
--

test(
    "integers", dedent
    [[
        0 1 135 9999 0.1 1.3 123.657
    ]],
    {
        newToken('number literal', 0),
        newToken('number literal', 1),
        newToken('number literal', 135),
        newToken('number literal', 9999),
        newToken('number literal', 0.1),
        newToken('number literal', 1.3),
        newToken('number literal', 123.657) 
    }
)
test(
    "integer unexpected dot", dedent
    [[
        123.456.789
    ]]
)

--
-- string literal
--

test(
    'string literal', dedent
    [[
        "this is a test"
    ]],
    {
        newToken('string literal', 'this is a test')
    }
)
test(
    'unterminated string literal', dedent
    [[
        "i am unclo-
    ]]
)

--
-- all
--

test(
    'mixed', dedent
    [[
        x := 13 + 15.67
        y := "string" # comment :)
        c := [] ref C
    ]],
    {
        newToken('name', 'x'),
        newToken('operator', ':='),
        newToken('number literal', 13),
        newToken('character', '+'),
        newToken('number literal', 15.67),
        newToken('character', '\n'),
        newToken('name', 'y'),
        newToken('operator', ':='),
        newToken('string literal', 'string'),
        newToken('character', '\n'),
        newToken('name', 'c'),
        newToken('operator', ':='),
        newToken('character', '['),
        newToken('character', ']'),
        newToken('keyword', 'ref'),
        newToken('name', 'C'),
    }
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