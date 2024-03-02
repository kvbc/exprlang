local ASTNode = require "ast.ASTNode"

---@alias ASTNodeTypeKind
---| "number"
---| "struct"
---| "function"
---| "auto"

---@class ASTNodeType : ASTNode
---@field Kind ASTNodeTypeKind
local ASTNodeType = {}
ASTNodeType.__index = ASTNodeType

---@nodiscard
---@param kind ASTNodeTypeKind
---@param sourceRange SourceRange
---@return ASTNodeType
function ASTNodeType.New(kind, sourceRange)
    local node = ASTNode.New(sourceRange) ---@cast node ASTNodeType
    node.Kind = kind;
    node.String = kind;
    return setmetatable(node, ASTNodeType)
end

return ASTNodeType