local ASTNodeExprLiteral = require "ast.ASTNodeExprLiteral"

---@alias ASTNodeExprLiteralStructField {Name: (string | ASTNodeExpr)?, Value: ASTNodeExpr}

---@class ASTNodeExprLiteralStruct : ASTNodeExprLiteral
---@field Fields ASTNodeExprLiteralStructField[]
local ASTNodeExprLiteralStruct = setmetatable({}, ASTNodeExprLiteral)
ASTNodeExprLiteralStruct.__index = ASTNodeExprLiteralStruct

---@nodiscard
---@param fields ASTNodeExprLiteralStructField[]
---@param sourceRange SourceRange
---@return ASTNodeExprLiteralStruct
function ASTNodeExprLiteralStruct.New(fields, sourceRange)
    local node = ASTNodeExprLiteral.New('Struct', sourceRange) ---@cast node ASTNodeExprLiteralStruct
    
    node.Fields = fields
    node.String = "["
    
    for i,field in ipairs(fields) do
        local name = field.Name
        if field.Name and type(field.Name) ~= 'string' then
            name = field.Name.String
        end
        node.String = node.String
            .. (i ~= 1 and ", " or "")
            .. (name and name .. ': ' or '')
            .. field.Value.String
    end
    node.String = node.String .. "]"
    
    return setmetatable(node, ASTNodeExprLiteralStruct)
end

return ASTNodeExprLiteralStruct