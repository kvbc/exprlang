local ASTNodeType = require "ast.ASTNodeType"

---@class ASTNodeTypeFunction : ASTNodeType
---@field ParamsType ASTNodeTypeStruct
---@field ReturnType ASTNodeType
local ASTNodeTypeFunction = {}
ASTNodeTypeFunction.__index = ASTNodeTypeFunction

---@nodiscard
---@param paramsType ASTNodeTypeStruct
---@param returnType ASTNodeType
---@param sourceRange SourceRange
---@return ASTNodeTypeFunction
function ASTNodeTypeFunction.New(paramsType, returnType, sourceRange)
    local node = ASTNodeType.New('function', sourceRange) ---@cast node ASTNodeTypeFunction
    
    node.ParamsType = paramsType
    node.ReturnType = returnType
    node.String = ("%s -> %s"):format(paramsType.String, returnType.String)
    
    return setmetatable(node, ASTNodeTypeFunction)
end

return ASTNodeTypeFunction