local ASTNodeExpr = require "ast.ASTNodeExpr" ()

---@alias BinOpKind
---| '+'
---| '-'
---| '*'
---| '/'
---| '%'
---| 'and'
---| 'or'
---| '~='
---| '=='
---| '>='
---| '<='
---| '>'
---| '<'
---| '.'

---@alias BinOpPriority integer | {Left: integer; Right: integer}
---@nodiscard
---@param left integer
---@param right integer?
---@return BinOpPriority
local function priority(left, right)
    return {
        Left = left;
        Right = right or left;
    }
end

---@class ASTNodeExprBinary : ASTNodeExpr
---@field OpKind BinOpKind
---@field OpExpr1 ASTNodeExpr
---@field OpExpr2 ASTNodeExpr
local ASTNodeExprBinary = setmetatable({}, ASTNodeExpr)
ASTNodeExprBinary.__index = ASTNodeExprBinary

---@type BinOpKind[]
ASTNodeExprBinary.Ops = {
    '+', '-', '*', '/', '%',
    '==', '~=', '>=', '<=', '>', '<',
    '.',
    'and', 'or'
}

---@type { [BinOpKind]: BinOpPriority }
ASTNodeExprBinary.OpPriority = {
    ["."] = priority(6, 7), -- left-assoc

    ['*'] = priority(5);
    ['/'] = priority(5);
    ['%'] = priority(5);
    
    ['+'] = priority(4);
    ['-'] = priority(4);

    ['=='] = priority(3);
    ['~='] = priority(3);
    ['>='] = priority(3);
    ['<='] = priority(3);
    ['<'] = priority(3);
    ['>'] = priority(3);
    
    ['and'] = priority(2);

    ['or'] = priority(1);
}

---@nodiscard
---@param opKind BinOpKind
---@param opExpr1 ASTNodeExpr
---@param opExpr2 ASTNodeExpr
---@param sourceRange SourceRange
---@return ASTNodeExprBinary
function ASTNodeExprBinary.New(opKind, opExpr1, opExpr2, sourceRange)
    local node = ASTNodeExpr.New('Binary', sourceRange) ---@cast node ASTNodeExprBinary
    node.OpKind = opKind
    node.OpExpr1 = opExpr1
    node.OpExpr2 = opExpr2
    node.String = ("%s %s %s"):format(opExpr1.String, opKind, opExpr2.String)
    return setmetatable(node, ASTNodeExprBinary)
end

return ASTNodeExprBinary
