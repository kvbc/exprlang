local ASTNode = require "ast.ASTNode"
local pprint = require "lib.pprint"

---@enum ASTNodeExprKind
local ASTNodeExprKind = {
    Block   = 'Block';
    Call    = 'Call';
    Def     = 'Def';
    Literal = 'Literal';
    Name    = 'Name';
    Assign  = 'Assign';
    Unary   = 'Unary';
    Binary  = 'Binary';
    Cast    = 'Cast';
}

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
        or self.Kind == 'Binary'
        or self.Kind == 'Cast'
end

return function()
    return ASTNodeExpr, ASTNodeExprKind
end