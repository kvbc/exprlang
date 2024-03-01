---@class ASTNodeExprDef : ASTNodeExpr
---@field Name string
---@field Type ASTNodeType
---@field Expr ASTNodeExpr
ASTNodeExprDef = {}
ASTNodeExprDef.__index = ASTNodeExprDef

---@nodiscard
---@param name string
---@param type ASTNodeType
---@param expr ASTNodeExpr
---@return ASTNodeExprDef
function ASTNodeExprDef.New(name, type, expr)
    ---@type ASTNodeExprDef
    local node = ASTNodeExpr.New('Def')
    node.Name = name;
    node.Type = type;
    node.Expr = expr;
    return setmetatable(node, ASTNodeExprDef)
end