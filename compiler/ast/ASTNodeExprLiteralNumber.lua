local ASTNodeExprLiteral = require "ast.ASTNodeExprLiteral"

---@class ASTNodeExprLiteralNumber : ASTNodeExprLiteral
---@field Value number
local ASTNodeExprLiteralNumber = {}
ASTNodeExprLiteralNumber.__index = ASTNodeExprLiteralNumber

---@nodiscard
---@param value number
---@param sourceRange SourceRange
---@return ASTNodeExprLiteralNumber
function ASTNodeExprLiteralNumber.New(value, sourceRange)
    local node = ASTNodeExprLiteral.New('Number', sourceRange) ---@cast node ASTNodeExprLiteralNumber
    
    node.Value = value
    node.String = tostring(value)
    
    return setmetatable(node, ASTNodeExprLiteralNumber)
end

return ASTNodeExprLiteralNumber