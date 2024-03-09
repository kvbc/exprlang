local Test = require "test.Test"
local LexerTestResult = require "test.lexer.LexerTestResult"
local deepcompare = require "lib.deepcompare"

---@class LexerTest : Test
---@field SourceCode string
---@field ExpectedTokens Token[]
local LexerTest = setmetatable({}, Test)
LexerTest.__index = LexerTest

---@nodiscard
---@param name string
---@param sourceCode string
---@param expectedTokens Token[]
---@param expectErrors boolean
---@return LexerTest
function LexerTest.New(name, sourceCode, expectedTokens, expectErrors)
    local self = Test.New(name, expectErrors) ---@cast self LexerTest
    self.SourceCode = sourceCode
    self.ExpectedTokens = expectedTokens
    setmetatable(self, LexerTest)
    return self
end

---@nodiscard
---@return LexerTestResult
function LexerTest:Test()
    local source = Source.New(self.SourceCode)
    local lexer = Lexer.New(source)
    local tokens = lexer:Lex()

    local ok = (#tokens == #self.ExpectedTokens)
    if ok then
        for i = 1, #tokens do
            local tk1 = tokens[i]
            local tk2 = self.ExpectedTokens[i]
            if tk1.Type ~= tk2.Type or not deepcompare(tk1.Value, tk2.Value) then
                ok = false
                break
            end
        end
    end

    return LexerTestResult.New(ok, lexer, tokens)
end

return LexerTest