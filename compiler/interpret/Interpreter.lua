-- Simple AST Walker for testing purposes

local pprint = require "lib.pprint"
local stringPad = require "util.stringPad"

---@nodiscard
---@param v any
---@return boolean
local function bool(v)
    if type(v) == 'number' then
        return v ~= 0
    end
    return v
end

---@nodiscard
---@param v any
---@return any
local function unbool(v)
    if type(v) == 'boolean' then
        if v then return 1 end
        return 0
    end
    return v
end

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

    interpreter.GlobalScope:SetVariable("print", function(...)
        local ln = interpreter.GlobalScope:GetVariable("__LINE") or "?"
        local args = table.pack(...)
        io.write(("%s | "):format(stringPad(ln, 2)))
        for i,arg in ipairs(args) do
            io.write(
                i ~= 1 and ', ' or '',
                (pprint.pformat(arg):gsub('\n', "\n   | "))
            )
        end
        io.write('\n')
    end)

    interpreter.GlobalScope:SetVariable("len", function(v)
        if type(v) == 'number' then
            v = tostring(v)
        end
        return #v
    end)

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
---@param sourceRange SourceRange
function Interpreter:updateDebugGlobals(sourceRange)
    self.GlobalScope:SetVariable("__LINE", sourceRange.StartPos.LineNumber)
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
    elseif expr.Kind == 'Assign' then
        ---@cast expr ASTNodeExprAssign
        return self:interpretExprAssign(expr, scope)
    elseif expr.Kind == 'Unary' then
        ---@cast expr ASTNodeExprUnary
        return self:interpretExprUnary(expr, scope)
    elseif expr.Kind == 'Binary' then
        ---@cast expr ASTNodeExprBinary
        return self:interpretExprBinary(expr, scope)
    end
end

---@private
---@nodiscard
---@param exprUnary ASTNodeExprUnary
---@param scope Scope
---@return any
function Interpreter:interpretExprUnary(exprUnary, scope)
    local opKind = exprUnary.OpKind
    local opExpr = self:interpretExpr(exprUnary.OpExpr, scope)
    if opKind == 'not' then
        return unbool(not bool(opExpr))
    elseif opKind == '-' then
        return - opExpr
    end
end

---@private
---@nodiscard
---@param exprBin ASTNodeExprBinary
---@param scope Scope
---@return any, any, any
function Interpreter:interpretExprBinary(exprBin, scope)
    local opKind = exprBin.OpKind
    local op1 = self:interpretExpr(exprBin.OpExpr1, scope)
    if opKind == 'and' then
        local b = op1
        if bool(b) then --lazy eval
            local op2 = self:interpretExpr(exprBin.OpExpr2, scope)
            b = op2
        end
        return unbool(b)
    elseif opKind == 'or' then
        local b = op1
        if not bool(b) then --lazy eval
            local op2 = self:interpretExpr(exprBin.OpExpr2, scope)
            b = op2
        end
        return unbool(b)
    elseif opKind == '.' then
        assert(op1 ~= nil)
        if exprBin.OpExpr2.Kind == 'Name' then
            local exprName = exprBin.OpExpr2 ---@cast exprName ASTNodeExprName
            return op1[exprName.Name], op1, exprName.Name
        else
            local op2 = self:interpretExpr(exprBin.OpExpr2, scope)
            return op1[op2], op1, op2
        end
    else
        local op2 = self:interpretExpr(exprBin.OpExpr2, scope)
        if     opKind == '+'   then return op1 + op2
        elseif opKind == '-'   then return op1 - op2
        elseif opKind == '*'   then return op1 * op2
        elseif opKind == '/'   then return op1 / op2
        elseif opKind == '%'   then return op1 % op2
        elseif opKind == '=='  then return unbool(op1 == op2)
        elseif opKind == '~='  then return unbool(op1 ~= op2)
        elseif opKind == '>='  then return unbool(op1 >= op2)
        elseif opKind == '<='  then return unbool(op1 <= op2)
        elseif opKind == '<'   then return unbool(op1 > op2)
        elseif opKind == '>'   then return unbool(op1 < op2)
        end
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

    -- before calling debug functions
    self:updateDebugGlobals(exprCall.SourceRange)

    return func(table.unpack(args))
end

---@private
---@param exprDef ASTNodeExprDef
---@param scope Scope
function Interpreter:interpretExprDef(exprDef, scope)
    local name = exprDef.Name
    local value = self:interpretExpr(exprDef.Expr, scope)
    scope:SetVariable(name, value)
end

---@private
---@param exprAssign ASTNodeExprAssign
---@param scope Scope
function Interpreter:interpretExprAssign(exprAssign, scope)
    if exprAssign.LValue.Kind == 'Name' then
        scope:SetVariable(
            exprAssign.LValue.Name,
            self:interpretExpr(exprAssign.Value, scope)
        )
    elseif exprAssign.LValue.Kind == 'Binary' then
        local _, obj, key = self:interpretExpr(exprAssign.LValue, scope)
        assert(key)
        obj[key] = self:interpretExpr(exprAssign.Value, scope)
    end
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
    -- before getting debug vars
    self:updateDebugGlobals(exprName.SourceRange)
    return scope:GetVariable(exprName.Name)
end

---@private
---@param exprFun ASTNodeExprFun
---@param scope Scope
---@nodiscard
---@return function
function Interpreter:interpretExprFun(exprFun, scope)
    return function(...)
        if exprFun.FunctionType then
            local args = table.pack(...)
            scope = Scope.New(scope)
            for i,field in ipairs(exprFun.FunctionType.ParamsType.Fields) do
                if field.Name then
                    scope:SetVariable(field.Name, args[i])
                end
            end
        end
        return self:interpretExpr(exprFun.FunctionBody, scope)
    end
end