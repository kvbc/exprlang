local TestResult = require "test.TestResult"

---@class ParserTestResult : TestResult
---@field Parser Parser
---@field AST ASTNodeExprBlock?
local ParserTestResult = setmetatable({}, TestResult)
ParserTestResult.__index = ParserTestResult

---@param ok boolean
---@param ast ASTNodeExprBlock?
---@param parser Parser
---@nodiscard
---@return ParserTestResult
function ParserTestResult.New(ok, ast, parser)
    local self = TestResult.New(ok, parser.Errors) ---@cast self ParserTestResult
    self.AST = ast
    self.Parser = parser
    return setmetatable(self, ParserTestResult)
end

return ParserTestResult
