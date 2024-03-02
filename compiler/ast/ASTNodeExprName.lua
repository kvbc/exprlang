local ASTNodeExpr = require "ast.ASTNodeExpr"

---@class ASTNodeExprName : ASTNodeExpr
---@field Name string
local ASTNodeExprName = {}
ASTNodeExprName.__index = ASTNodeExprName

---@nodiscard
---@param name string
---@return ASTNodeExprName
function ASTNodeExprName.New(name)
    local node = ASTNodeExpr.New('Name') ---@cast node ASTNodeExprName
    
    node.Name = name;
    node.String = name
    
    return setmetatable(node, ASTNodeExprName)
end

return ASTNodeExprName