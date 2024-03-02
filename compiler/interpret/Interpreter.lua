-- Simple AST Walker for testing purposes

local ASTNodeExpr, ASTNodeExprKind = require "ast.ASTNodeExpr" ()

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
---@param filename string?
---@return Interpreter
function Interpreter.New(astExprBlock, filename)
    ---@type Interpreter
    local interpreter = {
        astExprBlock = astExprBlock;
        Errors = {};
        GlobalScope = Scope.New()
    }

    local function gPrint(...)
        local ln = interpreter.GlobalScope:GetVariable("__LINE") or "?"
        local args = table.pack(...)
        local prebarStr = ("%s%s"):format(
            filename and stringPad(filename, 15) .. ' ' or '',
            stringPad(ln, 2)
        )
        io.write(("%s | "):format(prebarStr))
        for i,arg in ipairs(args) do
            io.write(
                i ~= 1 and ', ' or '',
                (pprint.pformat(arg)
                    :gsub('\n', ("\n%s | "):format(
                        (" "):rep(#prebarStr)
                    ))
                )
            )
        end
        io.write('\n')
    end

    local function gLen(v)
        if type(v) == 'number' then
            v = tostring(v)
        end
        return #v
    end

    local function gError(...)
        gPrint("[ERROR] ", ...)
    end

    local function gImport(filename)
        local f = io.open(filename, "r")
        if not f then
            return gError(('Could not import file "%s"'):format(filename))
        end
        local src = f:read('a')
        f:close()
        local source = Source.New(src, filename)
        local lexer = Lexer.New(source)
        local tokens = lexer:Lex()
        local parser = Parser.New(source, tokens)
        local ast = parser:Parse()
        if not ast then
            return gError(('Could not parse file "%s"'):format(filename))
        end
        local interpreter = Interpreter.New(ast, filename)
        return interpreter:Interpret()
    end

    interpreter.GlobalScope:SetVariable("print", gPrint)
    interpreter.GlobalScope:SetVariable("error", gError)
    interpreter.GlobalScope:SetVariable("len", gLen)
    interpreter.GlobalScope:SetVariable("import", gImport)

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
    for _,exprKind in pairs(ASTNodeExprKind) do
        if expr.Kind == exprKind then
            return Interpreter['interpretExpr' .. exprKind](self, expr, scope)
        end
    end
end

---@private
---@nodiscard
---@param exprCast ASTNodeExprCast
---@param scope Scope
---@return any
function Interpreter:interpretExprCast(exprCast, scope)
    assert(exprCast.Type.Kind == 'function', 'non-function casts not implemented')
    local funcType = exprCast.Type ---@cast funcType ASTNodeTypeFunction
    return function(...)
        local args = table.pack(...)
        scope = Scope.New(scope)
        for i,field in ipairs(funcType.ParamsType.Fields) do
            if field.Name then
                scope:SetVariable(field.Name, args[i])
            end
        end
        return self:interpretExpr(exprCast.Expr, scope)
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
        for _,field in ipairs(exprLit.Fields) do
            local value = self:interpretExpr(field.Value, scope)
            local key = field.Name
            if key then
                if type(key) == 'string' then
                    values[key] = value
                else
                    local keyValue = self:interpretExpr(key, scope)
                    assert(keyValue ~= nil)
                    values[keyValue] = value
                end
            else
                table.insert(values, value)
            end
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