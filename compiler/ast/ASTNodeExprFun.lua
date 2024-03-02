local ASTNodeExpr = require "ast.ASTNodeExpr"

---@class ASTNodeExprFun : ASTNodeExpr
---@field FunctionType ASTNodeTypeFunction?
---@field FunctionBody ASTNodeExprBlock
local ASTNodeExprFun = {}
ASTNodeExprFun.__index = ASTNodeExprFun

---@nodiscard
---@param functionType ASTNodeTypeFunction?
---@param functionBody ASTNodeExprBlock
---@param sourceRange SourceRange
---@return ASTNodeExprFun
function ASTNodeExprFun.New(functionType, functionBody, sourceRange)
    local node = ASTNodeExpr.New('Fun', sourceRange) ---@cast node ASTNodeExprFun
    
    node.FunctionType = functionType;
    node.FunctionBody = functionBody;
    node.String = ("fun %s %s"):format(
        functionType and functionType.String or "",
        functionBody.String
    )
    
    return setmetatable(node, ASTNodeExprFun)
end

return ASTNodeExprFun