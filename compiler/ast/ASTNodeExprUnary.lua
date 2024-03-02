local ASTNodeExpr = require "ast.ASTNodeExpr" ()

---@alias UnaryOpKind
---| 'not'
---| '-'

---@class ASTNodeExprUnary : ASTNodeExpr
---@field OpKind UnaryOpKind
---@field OpExpr ASTNodeExpr
local ASTNodeExprUnary = setmetatable({}, ASTNodeExpr)
ASTNodeExprUnary.__index = ASTNodeExprUnary

---@type UnaryOpKind[]
ASTNodeExprUnary.Ops = {
    'not',
    '-',
}

---@nodiscard
---@param opKind UnaryOpKind
---@param opExpr ASTNodeExpr
---@param sourceRange SourceRange
---@return ASTNodeExprUnary
function ASTNodeExprUnary.New(opKind, opExpr, sourceRange)
    local node = ASTNodeExpr.New('Unary', sourceRange) ---@cast node ASTNodeExprUnary
    
    node.OpKind = opKind
    node.OpExpr = opExpr
    
    return setmetatable(node, ASTNodeExprUnary)
end

return ASTNodeExprUnary
