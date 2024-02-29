---@class ASTNodeExprBlock : ASTNodeExpr
---@field Expressions ASTNodeExpr[]
ASTNodeExprBlock = {}
ASTNodeExprBlock.__index = ASTNodeExprBlock

---@nodiscard
---@param expressions ASTNodeExpr[]
---@return ASTNodeExprBlock
function ASTNodeExprBlock.New(expressions)
    ---@type ASTNodeExprBlock
    local exprBlock = {
        Expressions = expressions;
    }
    return setmetatable(exprBlock, ASTNodeExprBlock)
end