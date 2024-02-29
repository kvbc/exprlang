---@class ASTNodeExprLiteralString : ASTNodeExprLiteral
---@field Value string
ASTNodeExprLiteralString = {}
ASTNodeExprLiteralString.__index = ASTNodeExprLiteralString

---@nodiscard
---@param value string
---@return ASTNodeExprLiteralString
function ASTNodeExprLiteralString.New(value)
    ---@type ASTNodeExprLiteralString
    local node = ASTNodeExprLiteral.New('String')
    node.Value = value
    return setmetatable(node, ASTNodeExprLiteralString)
end