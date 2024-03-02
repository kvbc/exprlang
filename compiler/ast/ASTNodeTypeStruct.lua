local ASTNodeType = require "ast.ASTNodeType"

---@alias ASTNodeTypeStructField {Name: string?; Type: ASTNodeType}

---@class ASTNodeTypeStruct : ASTNodeType
---@field Fields ASTNodeTypeStructField[]
local ASTNodeTypeStruct = {}
ASTNodeTypeStruct.__index = ASTNodeTypeStruct

---@nodiscard
---@param fields ASTNodeTypeStructField[]
---@return ASTNodeTypeStruct
function ASTNodeTypeStruct.New(fields)
    local node = ASTNodeType.New('struct') ---@cast node ASTNodeTypeStruct

    node.Fields = fields
    node.String = "["
    for i,field in ipairs(fields) do
        node.String = node.String
            .. (i ~= 1 and ", " or "")
            .. (field.Name .. " " or "")
            .. field.Type.String
    end
    node.String = node.String .. "]"

    return setmetatable(node, ASTNodeTypeStruct)
end

return ASTNodeTypeStruct