local ASTNodeExprLiteral = require "ast.ASTNodeExprLiteral"

---@class ASTNodeExprLiteralString : ASTNodeExprLiteral
---@field Value string
local ASTNodeExprLiteralString = {}
ASTNodeExprLiteralString.__index = ASTNodeExprLiteralString

---@nodiscard
---@param value string
---@param sourceRange SourceRange
---@return ASTNodeExprLiteralString
function ASTNodeExprLiteralString.New(value, sourceRange)
    local node = ASTNodeExprLiteral.New('String', sourceRange) ---@cast node ASTNodeExprLiteralString
    
    node.Value = value
    node.String = ('"%s"'):format(value)
    
    return setmetatable(node, ASTNodeExprLiteralString)
end

return ASTNodeExprLiteralString