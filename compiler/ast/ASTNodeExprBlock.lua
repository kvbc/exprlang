local ASTNodeExpr = require "ast.ASTNodeExpr"

---@class ASTNodeExprBlock : ASTNodeExpr
---@field Expressions ASTNodeExpr[]
local ASTNodeExprBlock = {}
ASTNodeExprBlock.__index = ASTNodeExprBlock

---@nodiscard
---@param expressions ASTNodeExpr[]
---@param sourceRange SourceRange
---@return ASTNodeExprBlock
function ASTNodeExprBlock.New(expressions, sourceRange)
    local node = ASTNodeExpr.New('Block', sourceRange) ---@cast node ASTNodeExprBlock
    
    node.Expressions = expressions

    node.String = "{"
    for _,expr in ipairs(expressions) do
        node.String = node.String .. '\n\t' .. expr.String
    end
    node.String = node.String .. '\n}'

    return setmetatable(node, ASTNodeExprBlock)
end

return ASTNodeExprBlock