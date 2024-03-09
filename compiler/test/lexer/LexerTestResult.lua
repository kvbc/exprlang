local TestResult = require "test.TestResult"

---@class LexerTestResult : TestResult
---@field Lexer Lexer
---@field Tokens Token[]
local LexerTestResult = setmetatable({}, TestResult)
LexerTestResult.__index = LexerTestResult

---@param ok boolean
---@param lexer Lexer
---@param tokens Token[]
---@nodiscard
---@return LexerTestResult
function LexerTestResult.New(ok, lexer, tokens)
    local self = TestResult.New(ok, lexer.Errors) ---@cast self LexerTestResult
    self.Lexer = lexer
    self.Tokens = tokens
    return setmetatable(self, LexerTestResult)
end

return LexerTestResult
