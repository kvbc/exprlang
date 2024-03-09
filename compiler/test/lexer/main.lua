require "Source"
require "SourcePos"
require "SourceRange"
require "Lexer"
require "Token"
local LexerTests = require "test.lexer.LexerTests"
local LexerTest = require "test.lexer.LexerTest"
local deepcompare = require "lib.deepcompare"
local dedent = require "lib.dedent"

---@nodiscard
---@param type TokenType
---@param value any
---@return Token
local function newToken(type, value)
    --dummy source range
    return Token.New(type, value, SourceRange.New(SourcePos.New(1, 1)))
end

local lexerTests = LexerTests.New()

---@param name string
---@param sourceCode string
---@param expectedTokens Token[]?
local function addTest(name, sourceCode, expectedTokens)
    local expectErrors = false
    if expectedTokens == nil then
        expectedTokens = {}
        expectErrors = true
    end
    lexerTests:Add(LexerTest.New(name, sourceCode, expectedTokens, expectErrors))
end

--[[
--
-- Test Start
--
--]]

addTest(
    "empty source",
    "",
    {}
)
addTest(
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

addTest(
    "just comment",
    "# this is just a comment",
    {}
)
addTest(
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
addTest(
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
addTest(
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

addTest(
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

addTest(
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

addTest(
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

addTest(
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
addTest(
    "integer unexpected dot", dedent
    [[
        123.456.789
    ]]
)

--
-- string literal
--

addTest(
    'string literal', dedent
    [[
        "this is a addTest"
    ]],
    {
        newToken('string literal', 'this is a addTest')
    }
)
addTest(
    'unterminated string literal', dedent
    [[
        "i am unclo-
    ]]
)

--
-- all
--

addTest(
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

lexerTests:Test()