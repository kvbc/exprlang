local ASTNodeExpr = require "ast.ASTNodeExpr"

---@class ASTNodeExprCall : ASTNodeExpr
---@field Func ASTNodeExpr
---@field Args ASTNodeExprLiteralStruct
local ASTNodeExprCall = {}
ASTNodeExprCall.__index = ASTNodeExprCall

---@nodiscard
---@param func ASTNodeExpr
---@param args ASTNodeExprLiteralStruct
---@return ASTNodeExprCall
function ASTNodeExprCall.New(func, args)
    local node = ASTNodeExpr.New('Call') ---@cast node ASTNodeExprCall

    node.Func = func;
    node.Args = args;
    node.String = func.String .. args.String

    return setmetatable(node, ASTNodeExprCall)
end

return ASTNodeExprCall