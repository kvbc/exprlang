---@class ASTNodeExprFun : ASTNodeExpr
---@field FunctionType ASTNodeTypeFunction?
---@field FunctionBody ASTNodeExprBlock
ASTNodeExprFun = {}
ASTNodeExprFun.__index = ASTNodeExprFun

---@nodiscard
---@param functionType ASTNodeTypeFunction?
---@param functionBody ASTNodeExprBlock
---@return ASTNodeExprFun
function ASTNodeExprFun.New(functionType, functionBody)
    ---@type ASTNodeExprFun
    local node = ASTNodeExpr.New('Fun')
    node.FunctionType = functionType;
    node.FunctionBody = functionBody;
    node.String = ("fun %s %s"):format(
        functionType and functionType.String or "",
        functionBody.String
    )
    return setmetatable(node, ASTNodeExprFun)
end