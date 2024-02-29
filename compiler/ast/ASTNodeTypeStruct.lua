---@class ASTNodeTypeStruct : ASTNodeType
---@field Fields ASTNodeType[]
ASTNodeTypeStruct = {}
ASTNodeTypeStruct.__index = ASTNodeTypeStruct

---@nodiscard
---@param fields ASTNodeType[]
---@return ASTNodeTypeStruct
function ASTNodeTypeStruct.New(fields)
    ---@type ASTNodeTypeStruct
    local typeStruct = ASTNodeType.New('struct')
    typeStruct.Fields = fields
    return setmetatable(typeStruct, ASTNodeTypeStruct)
end