local ASTNodeExprLiteral = require "ast.ASTNodeExprLiteral"

---@class ASTNodeExprLiteralNumber : ASTNodeExprLiteral
---@field Value number
local ASTNodeExprLiteralNumber = {}
ASTNodeExprLiteralNumber.__index = ASTNodeExprLiteralNumber

---@nodiscard
---@param value number
---@return ASTNodeExprLiteralNumber
function ASTNodeExprLiteralNumber.New(value)
    local node = ASTNodeExprLiteral.New('Number') ---@cast node ASTNodeExprLiteralNumber
    
    node.Value = value
    node.String = tostring(value)
    
    return setmetatable(node, ASTNodeExprLiteralNumber)
end

return ASTNodeExprLiteralNumber