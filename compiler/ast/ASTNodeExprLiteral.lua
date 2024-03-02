local ASTNodeExpr = require "ast.ASTNodeExpr"

---@alias ASTNodeExprLiteralKind
---| 'Number'
---| 'String'
---| 'Struct'

---@class ASTNodeExprLiteral : ASTNodeExpr
---@field LiteralKind ASTNodeExprLiteralKind
local ASTNodeExprLiteral = {}
ASTNodeExprLiteral.__index = ASTNodeExprLiteral

---@nodiscard
---@param kind ASTNodeExprLiteralKind
---@return ASTNodeExprLiteral
function ASTNodeExprLiteral.New(kind)
    local node = ASTNodeExpr.New('Literal') ---@cast node ASTNodeExprLiteral
    
    node.LiteralKind = kind
    
    return setmetatable(node, ASTNodeExprLiteral)
end

return ASTNodeExprLiteral