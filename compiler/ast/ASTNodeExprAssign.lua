---@class ASTNodeExprAssign : ASTNodeExpr
---@field Name string
---@field Value ASTNodeExpr
local ASTNodeExprAssign = {}
ASTNodeExprAssign.__index = ASTNodeExprAssign

---@nodiscard
---@param name string
---@param value ASTNodeExpr
---@return ASTNodeExprAssign
function ASTNodeExprAssign.New(name, value)
    local node = ASTNodeExpr.New('Assign') ---@cast node ASTNodeExprAssign
    node.Name = name
    node.Value = value
    node.String = ("%s = %s"):format(name, value.String)
    return setmetatable(node, ASTNodeExprAssign)
end

return ASTNodeExprAssign
