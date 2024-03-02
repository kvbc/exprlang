local ASTNodeExpr = require "ast.ASTNodeExpr"

---@class ASTNodeExprName : ASTNodeExpr
---@field Name string
local ASTNodeExprName = setmetatable({}, ASTNodeExpr)
ASTNodeExprName.__index = ASTNodeExprName

---@nodiscard
---@param name string
---@param sourceRange SourceRange
---@return ASTNodeExprName
function ASTNodeExprName.New(name, sourceRange)
    local node = ASTNodeExpr.New('Name', sourceRange) ---@cast node ASTNodeExprName
    
    node.Name = name;
    node.String = name
    
    return setmetatable(node, ASTNodeExprName)
end

return ASTNodeExprName