---@class ASTNodeTypeFunction : ASTNodeType
---@field ParamsType ASTNodeTypeStruct
---@field ReturnType ASTNodeType
ASTNodeTypeFunction = {}
ASTNodeTypeFunction.__index = ASTNodeTypeFunction

---@nodiscard
---@param paramsType ASTNodeTypeStruct
---@param returnType ASTNodeType
---@return ASTNodeTypeFunction
function ASTNodeTypeFunction.New(paramsType, returnType)
    ---@type ASTNodeTypeFunction
    local node = ASTNodeType.New('function')
    node.ParamsType = paramsType
    node.ReturnType = returnType
    node.String = ("%s -> %s"):format(paramsType.String, returnType.String)
    return setmetatable(node, ASTNodeTypeFunction)
end