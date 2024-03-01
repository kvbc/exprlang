-- Simple AST Walker for testing purposes

require "interpret.Scope"
require "interpret.Variable"

---@class Interpreter
---@field private astExprBlock ASTNodeExprBlock
---@field Errors string[]
---@field GlobalScope Scope
Interpreter = {}
Interpreter.__index = Interpreter

---@nodiscard
---@param astExprBlock ASTNodeExprBlock
---@return Interpreter
function Interpreter.New(astExprBlock)
    ---@type Interpreter
    local interpreter = {
        astExprBlock = astExprBlock;
        Errors = {};
        GlobalScope = Scope.New()
    }
    return setmetatable(interpreter, Interpreter)
end

---@private
---@param message string
function Interpreter:error(message)
    table.insert(self.Errors, message)
end

---@return any
function Interpreter:Interpret()
    return self:interpretExprBlock(self.astExprBlock, self.GlobalScope)
end

---@private
---@param expr ASTNodeExpr
---@param scope Scope
function Interpreter:interpretExpr(expr, scope)
    if expr.Kind == 'Block' then
        ---@cast expr ASTNodeExprBlock
        return self:interpretExprBlock(expr, scope)
    elseif expr.Kind == 'Call' then
        ---@cast expr ASTNodeExprCall
        return self:interpretExprCall(expr, scope)
    elseif expr.Kind == 'Def' then
        ---@cast expr ASTNodeExprDef
        return self:interpretExprDef(expr, scope)
    elseif expr.Kind == 'Literal' then
        ---@cast expr ASTNodeExprLiteral
        return self:interpretExprLiteral(expr, scope)
    elseif expr.Kind == 'Name' then
        ---@cast expr ASTNodeExprName
        return self:interpretExprName(expr, scope)
    elseif expr.Kind == 'Fun' then
        ---@cast expr ASTNodeExprFun
        return self:interpretExprFun(expr, scope)
    end
end

---@private
---@nodiscard
---@param exprBlock ASTNodeExprBlock
---@param scope Scope
---@return any
function Interpreter:interpretExprBlock(exprBlock, scope)
    scope = Scope.New(scope)
    for i,expr in ipairs(exprBlock.Expressions) do
        local value = self:interpretExpr(expr, scope)
        if i == #exprBlock.Expressions then -- last expression
            return value
        end
    end
end

---@private
---@param exprCall ASTNodeExprCall
---@param scope Scope
function Interpreter:interpretExprCall(exprCall, scope)
    local func = self:interpretExpr(exprCall.Func, scope)
    assert(type(func) == 'function')
    local args = self:interpretExpr(exprCall.Args, scope)
    assert(type(args) == 'table')
    func(table.unpack(args))
end

---@private
---@param exprDef ASTNodeExprDef
---@param scope Scope
function Interpreter:interpretExprDef(exprDef, scope)
    local name = exprDef.Name
    local value = self:interpretExpr(exprDef.Expr, scope)
    local var = Variable.New(name, value)
    table.insert(scope.Variables, var)
end

---@private
---@nodiscard
---@param exprLit ASTNodeExprLiteral
---@param scope Scope
---@return any
function Interpreter:interpretExprLiteral(exprLit, scope)
    if exprLit.LiteralKind == 'Number' then
        ---@cast exprLit ASTNodeExprLiteralNumber
        return exprLit.Value
    elseif exprLit.LiteralKind == 'String' then
        ---@cast exprLit ASTNodeExprLiteralString
        return exprLit.Value
    elseif exprLit.LiteralKind == 'Struct' then
        ---@cast exprLit ASTNodeExprLiteralStruct
        local values = {}
        for _,expr in ipairs(exprLit.Values) do
            local value = self:interpretExpr(expr, scope)
            table.insert(values, value)
        end
        return values
    end
end

---@private
---@nodiscard
---@param exprName ASTNodeExprName
---@param scope Scope
---@return any
function Interpreter:interpretExprName(exprName, scope)
    for _,var in ipairs(scope.Variables) do
        if var.Name == exprName.Name then
            return var.Value
        end
    end
end

---@private
---@param exprFun ASTNodeExprFun
---@param scope Scope
---@nodiscard
---@return function
function Interpreter:interpretExprFun(exprFun, scope)
    return function(...)
        -- scope = Scope.New(scope)
        return self:interpretExpr(exprFun.FunctionBody, scope)
    end
end