---@class ASTNodeExprAssign : ASTNodeExpr
---@field Name string
---@field Value ASTNodeExpr
ASTNodeExprAssign = {}
ASTNodeExprAssign.__index = ASTNodeExprAssign

---@nodiscard
---@param name string
---@param value ASTNodeExpr
---@return ASTNodeExprAssign
function ASTNodeExprAssign.New(name, value)
    ---@type ASTNodeExprAssign
    local node = ASTNodeExpr.New('Assign')
    node.Name = name
    node.Value = value
    return setmetatable(node, ASTNodeExprAssign)
end