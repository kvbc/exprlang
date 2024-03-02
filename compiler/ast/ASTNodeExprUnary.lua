---@alias UnaryOpKind
---| 'not'
---| '-'

---@class ASTNodeExprUnary : ASTNodeExpr
---@field OpKind UnaryOpKind
---@field OpExpr ASTNodeExpr
ASTNodeExprUnary = {}
ASTNodeExprUnary.__index = ASTNodeExprUnary

---@type UnaryOpKind[]
ASTNodeExprUnary.Ops = {
    'not',
    '-',
}

---@nodiscard
---@param opKind UnaryOpKind
---@param opExpr ASTNodeExpr
---@return ASTNodeExprUnary
function ASTNodeExprUnary.New(opKind, opExpr)
    ---@type ASTNodeExprUnary
    local node = ASTNodeExpr.New('Unary')
    node.OpKind = opKind
    node.OpExpr = opExpr
    return setmetatable(node, ASTNodeExprUnary)
end