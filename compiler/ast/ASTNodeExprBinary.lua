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
---| ':'
---| 'ref'

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
---@field OpExpr2 ASTNodeExpr | string
local ASTNodeExprBinary = setmetatable({}, ASTNodeExpr)
ASTNodeExprBinary.__index = ASTNodeExprBinary

---@type BinOpKind[]
ASTNodeExprBinary.Ops = {
    '+', '-', '*', '/', '%',
    '==', '~=', '>=', '<=', '>', '<',
    '.', 'ref', ':',
    'and', 'or'
}

---@type { [BinOpKind]: BinOpPriority }
ASTNodeExprBinary.OpPriority = {
    ["."] = priority(8, 9), -- left-assoc
    [":"] = priority(8, 9), -- left-assoc

    ['*'] = priority(7);
    ['/'] = priority(7);
    ['%'] = priority(7);
    
    ['+'] = priority(6);
    ['-'] = priority(6);

    ['ref'] = priority(4, 5); -- left-assoc

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
---@param opExpr2 ASTNodeExpr | string
---@param sourceRange SourceRange
---@return ASTNodeExprBinary
function ASTNodeExprBinary.New(opExpr1, opKind, opExpr2, sourceRange)
    local node = ASTNodeExpr.New('Binary', sourceRange) ---@cast node ASTNodeExprBinary
    node.OpKind = opKind
    node.OpExpr1 = opExpr1
    node.OpExpr2 = opExpr2
    node.String = ("%s %s %s"):format(opExpr1.String, opKind, opExpr2.String)
    return setmetatable(node, ASTNodeExprBinary)
end

return ASTNodeExprBinary
