local ASTNodeExpr = require "ast.ASTNodeExpr"

---@class ASTNodeExprFun : ASTNodeExpr
---@field FunctionType ASTNodeTypeFunction?
---@field FunctionBody ASTNodeExprBlock
local ASTNodeExprFun = {}
ASTNodeExprFun.__index = ASTNodeExprFun

---@nodiscard
---@param functionType ASTNodeTypeFunction?
---@param functionBody ASTNodeExprBlock
---@return ASTNodeExprFun
function ASTNodeExprFun.New(functionType, functionBody)
    local node = ASTNodeExpr.New('Fun') ---@cast node ASTNodeExprFun
    
    node.FunctionType = functionType;
    node.FunctionBody = functionBody;
    node.String = ("fun %s %s"):format(
        functionType and functionType.String or "",
        functionBody.String
    )
    
    return setmetatable(node, ASTNodeExprFun)
end

return ASTNodeExprFun