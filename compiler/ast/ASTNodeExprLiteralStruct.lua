---@class ASTNodeExprLiteralStruct : ASTNodeExprLiteral
---@field Values ASTNodeExpr[]
ASTNodeExprLiteralStruct = {}
ASTNodeExprLiteralStruct.__index = ASTNodeExprLiteralStruct

---@nodiscard
---@param values ASTNodeExpr[]
---@return ASTNodeExprLiteralStruct
function ASTNodeExprLiteralStruct.New(values)
    ---@type ASTNodeExprLiteralStruct
    local node = ASTNodeExprLiteral.New('Struct')
    node.Values = values
    return setmetatable(node, ASTNodeExprLiteralStruct)
end