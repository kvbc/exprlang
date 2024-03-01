---@class ASTNodeExprBlock : ASTNodeExpr
---@field Expressions ASTNodeExpr[]
ASTNodeExprBlock = {}
ASTNodeExprBlock.__index = ASTNodeExprBlock

---@nodiscard
---@param expressions ASTNodeExpr[]
---@return ASTNodeExprBlock
function ASTNodeExprBlock.New(expressions)
    ---@type ASTNodeExprBlock
    local node = ASTNodeExpr.New('Block')
    node.Expressions = expressions
    return setmetatable(node, ASTNodeExprBlock)
end