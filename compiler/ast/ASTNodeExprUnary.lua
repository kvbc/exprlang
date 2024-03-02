---@alias UnaryOpKind
---| 'not'
---| '-'

---@class ASTNodeExprUnary : ASTNodeExpr
---@field OpKind UnaryOpKind
---@field OpExpr ASTNodeExpr
local ASTNodeExprUnary = {}
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
    local node = ASTNodeExpr.New('Unary') ---@cast node ASTNodeExprUnary
    node.OpKind = opKind
    node.OpExpr = opExpr
    return setmetatable(node, ASTNodeExprUnary)
end

return ASTNodeExprUnary
