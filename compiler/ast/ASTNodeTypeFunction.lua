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
    local typeStruct = ASTNodeType.New('function')
    typeStruct.ParamsType = paramsType
    typeStruct.ReturnType = returnType
    return setmetatable(typeStruct, ASTNodeTypeFunction)
end