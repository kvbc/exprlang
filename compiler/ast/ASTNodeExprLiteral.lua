---@alias ASTNodeExprLiteralKind
---| 'Number'
---| 'String'
---| 'Struct'

---@class ASTNodeExprLiteral : ASTNodeExpr
---@field LiteralKind ASTNodeExprLiteralKind
ASTNodeExprLiteral = {}
ASTNodeExprLiteral.__index = ASTNodeExprLiteral

---@nodiscard
---@param kind ASTNodeExprLiteralKind
---@return ASTNodeExprLiteral
function ASTNodeExprLiteral.New(kind)
    ---@type ASTNodeExprLiteral
    local node = ASTNodeExpr.New('Literal')
    node.LiteralKind = kind
    return setmetatable(node, ASTNodeExprLiteral)
end