---@class ASTNodeExprCall : ASTNodeExpr
---@field Func ASTNodeExpr
---@field Args ASTNodeExprLiteralStruct
ASTNodeExprCall = {}
ASTNodeExprCall.__index = ASTNodeExprCall

---@nodiscard
---@param func ASTNodeExpr
---@param args ASTNodeExprLiteralStruct
---@return ASTNodeExprCall
function ASTNodeExprCall.New(func, args)
    ---@type ASTNodeExprCall
    local node = ASTNodeExpr.New('Call')
    node.Func = func;
    node.Args = args;
    node.String = func.String .. args.String
    return setmetatable(node, ASTNodeExprCall)
end