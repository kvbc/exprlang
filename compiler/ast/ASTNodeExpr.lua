---@alias ASTNodeExprKind
---| 'Block'
---| 'Call'
---| 'Def'
---| 'Literal'
---| 'Name'
---| 'Fun'
---| 'Assign'
---| 'Unary'
---| 'Binary'

---@class ASTNodeExpr : ASTNode
---@field Kind ASTNodeExprKind
ASTNodeExpr = {}
ASTNodeExpr.__index = ASTNodeExpr

---@param kind ASTNodeExprKind
function ASTNodeExpr.New(kind)
    ---@type ASTNodeExpr
    local expr = {
        Kind = kind;
    }
    return setmetatable(expr, ASTNodeExpr)
end