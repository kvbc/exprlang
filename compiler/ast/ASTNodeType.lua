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
---@return ASTNodeType
function ASTNodeType.New(kind)
    ---@type ASTNodeType
    local node = {
        Kind = kind;
        String = kind;
    }
    return setmetatable(node, ASTNodeType)
end

return ASTNodeType