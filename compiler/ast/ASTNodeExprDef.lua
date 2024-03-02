local ASTNodeExpr = require "ast.ASTNodeExpr"

---@class ASTNodeExprDef : ASTNodeExpr
---@field Name string
---@field Type ASTNodeType
---@field Expr ASTNodeExpr
local ASTNodeExprDef = {}
ASTNodeExprDef.__index = ASTNodeExprDef

---@nodiscard
---@param name string
---@param type ASTNodeType
---@param expr ASTNodeExpr
---@return ASTNodeExprDef
function ASTNodeExprDef.New(name, type, expr)
    local node = ASTNodeExpr.New('Def') ---@cast node ASTNodeExprDef
    
    node.Name = name;
    node.Type = type;
    node.Expr = expr;
    node.String = ("%s %s = %s"):format(name, type.String, expr.String)
    
    return setmetatable(node, ASTNodeExprDef)
end

return ASTNodeExprDef