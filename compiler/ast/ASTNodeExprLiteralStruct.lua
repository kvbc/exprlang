local ASTNodeExprLiteral = require "ast.ASTNodeExprLiteral"

---@class ASTNodeExprLiteralStruct : ASTNodeExprLiteral
---@field Values ASTNodeExpr[]
local ASTNodeExprLiteralStruct = {}
ASTNodeExprLiteralStruct.__index = ASTNodeExprLiteralStruct

---@nodiscard
---@param values ASTNodeExpr[]
---@param sourceRange SourceRange
---@return ASTNodeExprLiteralStruct
function ASTNodeExprLiteralStruct.New(values, sourceRange)
    local node = ASTNodeExprLiteral.New('Struct', sourceRange) ---@cast node ASTNodeExprLiteralStruct
    
    node.Values = values
    node.String = "["
    
    for i,expr in ipairs(values) do
        node.String = node.String .. (i ~= 1 and ", " or "") .. expr.String
    end
    node.String = node.String .. "]"
    
    return setmetatable(node, ASTNodeExprLiteralStruct)
end

return ASTNodeExprLiteralStruct