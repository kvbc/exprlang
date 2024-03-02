local ASTNode = require "ast.ASTNode"
local pprint = require "lib.pprint"

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
local ASTNodeExpr = setmetatable({}, ASTNode)
ASTNodeExpr.__index = ASTNodeExpr

---@param kind ASTNodeExprKind
---@param sourceRange SourceRange
function ASTNodeExpr.New(kind, sourceRange)
    local node = ASTNode.New(sourceRange) ---@cast node ASTNodeExpr
    node.Kind = kind
    return setmetatable(node, ASTNodeExpr)
end

---@nodiscard
---@return boolean
function ASTNodeExpr:IsCallable()
    return self.Kind == 'Block'
        or self.Kind == 'Call'
        or self.Kind == 'Name'
        or self.Kind == 'Fun'
        or self.Kind == 'Binary'
end

return ASTNodeExpr