---@class ASTNodeExprLiteralNumber : ASTNodeExprLiteral
---@field Value number
ASTNodeExprLiteralNumber = {}
ASTNodeExprLiteralNumber.__index = ASTNodeExprLiteralNumber

---@nodiscard
---@param value number
---@return ASTNodeExprLiteralNumber
function ASTNodeExprLiteralNumber.New(value)
    ---@type ASTNodeExprLiteralNumber
    local node = ASTNodeExprLiteral.New('Number')
    node.Value = value
    node.String = tostring(value)
    return setmetatable(node, ASTNodeExprLiteralNumber)
end