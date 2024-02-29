---@alias ASTNodeTypeKind
---| "number"
---| "struct"
---| "function"
---| "auto"

---@class ASTNodeType : ASTNode
---@field Kind ASTNodeTypeKind
ASTNodeType = {}
ASTNodeType.__index = ASTNodeType

---@nodiscard
---@param kind ASTNodeTypeKind
---@return ASTNodeType
function ASTNodeType.New(kind)
    ---@type ASTNodeType
    local type = {
        Kind = kind;
    }
    return setmetatable(type, ASTNodeType)
end