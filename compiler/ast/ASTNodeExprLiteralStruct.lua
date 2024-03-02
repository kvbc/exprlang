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
    node.String = "["
    for i,expr in ipairs(values) do
        node.String = node.String .. (i ~= 1 and ", " or "") .. expr.String
    end
    node.String = node.String .. "]"
    return setmetatable(node, ASTNodeExprLiteralStruct)
end