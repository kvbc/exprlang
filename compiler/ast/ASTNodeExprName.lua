---@class ASTNodeExprName : ASTNodeExpr
---@field Name string
ASTNodeExprName = {}
ASTNodeExprName.__index = ASTNodeExprName

---@nodiscard
---@param name string
---@return ASTNodeExprName
function ASTNodeExprName.New(name)
    ---@type ASTNodeExprName
    local exprName = {
        Name = name;
    }
    return setmetatable(exprName, ASTNodeExprName)
end