local ASTNodeExpr = require "ast.ASTNodeExpr" ()

---@class ASTNodeExprCast : ASTNodeExpr
---@field Type ASTNodeType
---@field Expr ASTNodeExpr
local ASTNodeExprCast = setmetatable({}, ASTNodeExpr)
ASTNodeExprCast.__index = ASTNodeExprCast

---@nodiscard
---@param type ASTNodeType
---@param expr ASTNodeExpr
---@param sourceRange SourceRange
---@return ASTNodeExprCast
function ASTNodeExprCast.New(type, expr, sourceRange)
    local node = ASTNodeExpr.New('Cast', sourceRange) ---@cast node ASTNodeExprCast
    node.Type = type
    node.Expr = expr
    node.String = type.String .. ' ' .. expr.String
    return setmetatable(node, ASTNodeExprCast)
end

return ASTNodeExprCast