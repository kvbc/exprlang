---@alias ASTNodeExprLiteralKind
---| 'Number'
---| 'String'
---| 'Struct'

---@class ASTNodeExprLiteral : ASTNodeExpr
---@field Kind ASTNodeExprLiteralKind
ASTNodeExprLiteral = {}
ASTNodeExprLiteral.__index = ASTNodeExprLiteral

---@nodiscard
---@param kind ASTNodeExprLiteralKind
---@return ASTNodeExprLiteral
function ASTNodeExprLiteral.New(kind)
    ---@type ASTNodeExprLiteral
    local node = {
        Kind = kind
    }
    return setmetatable(node, ASTNodeExprLiteral)
end