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

---@class ASTNodeExprBinary : ASTNodeExpr
---@field OpKind BinOpKind
---@field OpExpr1 ASTNodeExpr
---@field OpExpr2 ASTNodeExpr
ASTNodeExprBinary = {}
ASTNodeExprBinary.__index = ASTNodeExprBinary

---@type BinOpKind[]
ASTNodeExprBinary.Ops = {
    '+', '-', '*', '/', '%',
    '==', '~=', '>=', '<=', '>', '<',
    'and', 'or'
}

---@type { [BinOpKind]: integer }
ASTNodeExprBinary.OpPriority = {
    
    ['*'] = 5;
    ['/'] = 5;
    ['%'] = 5;
    
    ['+'] = 4;
    ['-'] = 4;

    ['=='] = 3;
    ['~='] = 3;
    ['>='] = 3;
    ['<='] = 3;
    ['<'] = 3;
    ['>'] = 3;
    
    ['and'] = 2;

    ['or'] = 1;
}

---@nodiscard
---@param opKind BinOpKind
---@param opExpr1 ASTNodeExpr
---@param opExpr2 ASTNodeExpr
---@return ASTNodeExprBinary
function ASTNodeExprBinary.New(opKind, opExpr1, opExpr2)
    ---@type ASTNodeExprBinary
    local node = ASTNodeExpr.New('Binary')
    node.OpKind = opKind
    node.OpExpr1 = opExpr1
    node.OpExpr2 = opExpr2
    node.String = ("%s %s %s"):format(opExpr1.String, opKind, opExpr2.String)
    return setmetatable(node, ASTNodeExprBinary)
end