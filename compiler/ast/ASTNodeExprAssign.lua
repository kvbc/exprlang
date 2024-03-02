local ASTNodeExpr = require "ast.ASTNodeExpr"

---@class ASTNodeExprAssign : ASTNodeExpr
---@field LValue ASTNodeExprName | ASTNodeExprBinary
---@field Value ASTNodeExpr
local ASTNodeExprAssign = {}
ASTNodeExprAssign.__index = ASTNodeExprAssign

---@nodiscard
---@param lvalue ASTNodeExprName | ASTNodeExprBinary
---@param value ASTNodeExpr
---@return ASTNodeExprAssign
function ASTNodeExprAssign.New(lvalue, value)
    local node = ASTNodeExpr.New('Assign') ---@cast node ASTNodeExprAssign
    node.LValue = lvalue
    node.Value = value
    node.String = ("%s = %s"):format(lvalue.String, value.String)
    return setmetatable(node, ASTNodeExprAssign)
end

return ASTNodeExprAssign
