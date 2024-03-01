---@class ASTNodeExprName : ASTNodeExpr
---@field Name string
ASTNodeExprName = {}
ASTNodeExprName.__index = ASTNodeExprName

---@nodiscard
---@param name string
---@return ASTNodeExprName
function ASTNodeExprName.New(name)
    ---@type ASTNodeExprName
    local node = ASTNodeExpr.New('Name')
    node.Name = name;
    return setmetatable(node, ASTNodeExprName)
end