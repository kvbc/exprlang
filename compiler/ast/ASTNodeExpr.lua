local ASTNode = require "ast.ASTNode"

---@alias ASTNodeExprKind
---| 'Block'
---| 'Call'
---| 'Def'
---| 'Literal'
---| 'Name'
---| 'Fun'
---| 'Assign'
---| 'Unary'
---| 'Binary'

---@class ASTNodeExpr : ASTNode
---@field Kind ASTNodeExprKind
local ASTNodeExpr = {}
ASTNodeExpr.__index = ASTNodeExpr

---@param kind ASTNodeExprKind
---@param sourceRange SourceRange
function ASTNodeExpr.New(kind, sourceRange)
    local node = ASTNode.New(sourceRange) ---@cast node ASTNodeExpr
    node.Kind = kind
    return setmetatable(node, ASTNodeExpr)
end

return ASTNodeExpr