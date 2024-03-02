local ASTNodeExprLiteral = require "ast.ASTNodeExprLiteral"

---@class ASTNodeExprLiteralString : ASTNodeExprLiteral
---@field Value string
local ASTNodeExprLiteralString = {}
ASTNodeExprLiteralString.__index = ASTNodeExprLiteralString

---@nodiscard
---@param value string
---@return ASTNodeExprLiteralString
function ASTNodeExprLiteralString.New(value)
    local node = ASTNodeExprLiteral.New('String') ---@cast node ASTNodeExprLiteralString
    
    node.Value = value
    node.String = ('"%s"'):format(value)
    
    return setmetatable(node, ASTNodeExprLiteralString)
end

return ASTNodeExprLiteralString