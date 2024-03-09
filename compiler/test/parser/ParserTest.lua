local Test = require "test.Test"
local ParserTestResult = require "test.parser.ParserTestResult"
local deepcompare = require "lib.deepcompare"

---@class ParserTest : Test
---@field SourceCode string
---@field ExpectedAST ASTNodeExprBlock
local ParserTest = setmetatable({}, Test)
ParserTest.__index = ParserTest

---@nodiscard
---@param name string
---@param sourceCode string
---@param expectedAST ASTNodeExprBlock
---@param expectErrors boolean
---@return ParserTest
function ParserTest.New(name, sourceCode, expectedAST, expectErrors)
    local self = Test.New(name, expectErrors) ---@cast self ParserTest
    self.SourceCode = sourceCode
    self.ExpectedAST = expectedAST
    return setmetatable(self, ParserTest)
end

---@nodiscard
---@return ParserTestResult
function ParserTest:Test()
    local source = Source.New(self.SourceCode)
    local lexer = Lexer.New(source)
    local tokens = lexer:Lex()
    local parser = Parser.New(source, tokens)
    local ast = parser:Parse()
    local ok = deepcompare(ast, self.ExpectedAST)
    return ParserTestResult.New(ok, ast, parser)
end

return ParserTest