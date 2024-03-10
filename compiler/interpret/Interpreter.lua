--
-- Simple AST Walker for testing purposes
--

local ASTNodeExpr, ASTNodeExprKind = require "ast.ASTNodeExpr" ()
local Scope = require "interpret.Scope"
local LazyValue = require "interpret.LazyValue"
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

---@class Interpreter
---@field private refKey table
---@field Errors string[]
---@field GlobalScope Scope
local Interpreter = {}
Interpreter.__index = Interpreter

---@nodiscard
---@param filename string?
---@return Interpreter
function Interpreter.New(filename)
    ---@type Interpreter
    local interpreter = {
        Errors = {};
        GlobalScope = Scope.New();
        refKey = {}
    }

    ---@param ... any
    local function gPrint(...)
        local lineNumber = interpreter.GlobalScope:GetVariable("__LINE"):GetValue()
        local prebarStr = ("%s%s"):format(
            filename and stringPad(filename, 15) .. ' ' or '',
            stringPad(lineNumber, 2)
        )
        io.write(("%s | "):format(prebarStr))
        for i,arg in ipairs({...}) do
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

    ---@param v any
    ---@return LazyValue
    local function gLen(v)
        if type(v) == 'number' then
            v = tostring(v)
        end
        return LazyValue.New(#v)
    end
    
    ---@param ... any
    local function gError(...)
        gPrint("[ERROR] ", ...)
    end
    
    ---@param filename string
    ---@return LazyValue?
    local function gImport(filename)
        if filename:sub(#filename - 2) ~= '.ry' then
            filename = filename .. '.ry'
        end
        local f = io.open(filename, "r")
        if not f then
            gError(('Could not import file "%s"'):format(filename))
            return
        end
        local src = f:read('a')
        f:close()
        local source = Source.New(src, filename)
        local lexer = Lexer.New(source)
        local tokens = lexer:Lex()
        local parser = Parser.New(source, tokens)
        local ast = parser:Parse()
        if not ast then
            gError(('Could not parse file "%s"'):format(filename))
            return
        end
        local interpreter = Interpreter.New(filename)
        return interpreter:Interpret(ast)
    end

    ---@nodiscard
    ---@param func fun(...): LazyValue
    ---@return function
    local function unlazifyFunction(func)
        ---@param ... LazyValue
        return function (...)
            local args = {...}
            for i,_ in ipairs(args) do
                args[i] = args[i]:GetValue()
            end
            return func(table.unpack(args))
        end
    end

    interpreter.GlobalScope:SetVariable("print",  LazyValue.New(unlazifyFunction(gPrint)))
    interpreter.GlobalScope:SetVariable("error",  LazyValue.New(unlazifyFunction(gError)))
    interpreter.GlobalScope:SetVariable("len",    LazyValue.New(unlazifyFunction(gLen)))
    interpreter.GlobalScope:SetVariable("import", LazyValue.New(unlazifyFunction(gImport)))

    return setmetatable(interpreter, Interpreter)
end

---@private
---@param message string
function Interpreter:error(message)
    table.insert(self.Errors, message)
end

---@param astExpr ASTNodeExpr
---@param scope Scope?
---@return LazyValue
function Interpreter:Interpret(astExpr, scope)
    for _,exprKind in pairs(ASTNodeExprKind) do
        if astExpr.Kind == exprKind then
            return Interpreter['interpretExpr' .. exprKind](self, astExpr, scope or self.GlobalScope)
        end
    end
    error()
end

---@private
---@param sourceRange SourceRange
function Interpreter:updateDebugGlobals(sourceRange)
    self.GlobalScope:SetVariable("__LINE", LazyValue.New(sourceRange.StartPos.LineNumber))
end

---@private
---@nodiscard
---@param exprCast ASTNodeExprCast
---@param scope Scope
---@return LazyValue
function Interpreter:interpretExprCast(exprCast, scope)
    assert(exprCast.Type.Kind == 'function', 'non-function casts not implemented')
    local funcType = exprCast.Type ---@cast funcType ASTNodeTypeFunction

    ---@param ... LazyValue
    ---@return LazyValue?
    local function func(...)
        local args = {...}

        scope = Scope.New(scope)
        for i,field in ipairs(funcType.ParamsType.Fields) do
            if field.Name and args[i] then
                scope:SetVariable(field.Name, args[i])
            end
        end

        return self:Interpret(exprCast.Expr, scope)
    end

    return LazyValue.New(func)
end

---@private
---@nodiscard
---@param exprUnary ASTNodeExprUnary
---@param scope Scope
---@return LazyValue
function Interpreter:interpretExprUnary(exprUnary, scope)
    return LazyValue.NewLazy(function ()
        local opKind = exprUnary.OpKind
        local opVal = self:Interpret(exprUnary.OpExpr, scope):GetValue()
        if opKind == 'not' then
            return unbool(not bool(opVal))
        elseif opKind == '-' then
            return -opVal
        end
    end)
end

---@private
---@nodiscard
---@param exprBin ASTNodeExprBinary
---@param scope Scope
---@return LazyValue
function Interpreter:interpretExprBinary(exprBin, scope)
    return LazyValue.NewLazy(
        --return value, index table, index key
        ---@return any, table?, any?
        function ()
            local opKind = exprBin.OpKind
            local op1Lazy = self:Interpret(exprBin.OpExpr1, scope)
            local op2Expr = exprBin.OpExpr2

            assert(op1Lazy)

            if opKind == 'and' then
                ---@cast op2Expr ASTNodeExpr
                local b = op1Lazy:GetValue()
                if bool(b) then --lazy eval
                    b = self:Interpret(op2Expr, scope):GetValue()
                end
                return unbool(b)
            elseif opKind == 'or' then
                ---@cast op2Expr ASTNodeExpr
                local b = op1Lazy:GetValue()
                if not bool(b) then --lazy eval
                    b = self:Interpret(op2Expr, scope):GetValue()
                end
                return unbool(b)
            elseif opKind == '.' or opKind == ':' then
                local v, table, key
                local orgOp1Lazy = op1Lazy

                if type(op2Expr == 'string') then
                    key = op2Expr
                else
                    ---@cast op2Expr ASTNodeExpr
                    key = self:Interpret(op2Expr, scope):GetValue()
                end

                while op1Lazy do
                    if opKind == ':' then
                        op1Lazy = debug.getmetatable(op1Lazy) and debug.getmetatable(op1Lazy).ref
                    end
                    if not op1Lazy then
                        break
                    end

                    local op1Val = op1Lazy:GetValue()
                    v, table = op1Val[key], op1Val

                    if opKind == '.' then
                        break
                    end
                end
                if opKind == ':' and type(v) == 'function' then
                    local oldfunc = v
                    v = function(...)
                        return oldfunc(orgOp1Lazy, ...)
                    end
                end
                return v, table, key
            else
                assert(type(op2Expr) ~= 'string')
                local op2Lazy = self:Interpret(op2Expr, scope)
                assert(op2Lazy)
                if opKind == 'ref' then
                    return debug.setmetatable(op1Lazy, { ref = op2Lazy })
                else
                    local op1 = op1Lazy:GetValue()
                    local op2 = op2Lazy:GetValue()
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
        end
    )
end

---@private
---@nodiscard
---@param exprBlock ASTNodeExprBlock
---@param scope Scope
---@return LazyValue
function Interpreter:interpretExprBlock(exprBlock, scope)
    return LazyValue.NewLazy(function ()
        scope = Scope.New(scope)
        for i,expr in ipairs(exprBlock.Expressions) do
            local lazy = self:Interpret(expr, scope)
            local value = lazy:GetValue()
            if i == #exprBlock.Expressions then -- last expression
                return value
            end
        end
        return nil
    end)
end

---@nodiscard
---@private
---@param exprCall ASTNodeExprCall
---@param scope Scope
---@return LazyValue
function Interpreter:interpretExprCall(exprCall, scope)
    return LazyValue.NewLazy(function ()
        local func = self:Interpret(exprCall.Func, scope)
        assert(type(func) == 'function')
        
        local argsExpr = exprCall.Args
        
        ---@type LazyValue[]
        local args = {}
    
        local pack = false
        if exprCall.Args.Kind ~= 'Literal' then 
            pack = true
        else
            ---@cast argsExpr ASTNodeExprLiteral
            if argsExpr.LiteralKind == 'Struct' then
                ---@cast argsExpr ASTNodeExprLiteralStruct
                for _,field in ipairs(argsExpr.Fields) do
                    local lazy = self:Interpret(field.Value, scope)
                    table.insert(args, lazy)
                end
            else
                pack = true
            end
        end
        if pack then
            local argsLazy = self:Interpret(argsExpr, scope)
            args = { argsLazy }
        end
        
        -- before calling debug functions
        self:updateDebugGlobals(exprCall.SourceRange)
    
        return func(table.unpack(args)):GetValue()
    end)
end

---@nodiscard
---@private
---@param exprDef ASTNodeExprDef
---@param scope Scope
---@return LazyValue
function Interpreter:interpretExprDef(exprDef, scope)
    return LazyValue.NewLazy(function ()
        local name = exprDef.Name
        local lazyValue = self:Interpret(exprDef.Expr, scope)
        scope:SetVariable(name, lazyValue)
        return nil
    end)
end

---@nodiscard
---@private
---@param exprAssign ASTNodeExprAssign
---@param scope Scope
---@return LazyValue
function Interpreter:interpretExprAssign(exprAssign, scope)
    return LazyValue.NewLazy(function ()
        if exprAssign.LValue.Kind == 'Name' then
            scope:SetVariable(
                exprAssign.LValue.Name,
                self:Interpret(exprAssign.Value, scope)
            )
        elseif exprAssign.LValue.Kind == 'Binary' then
            local _, obj, key = self:Interpret(exprAssign.LValue, scope):GetValue()
            assert(key)
            obj[key] = self:Interpret(exprAssign.Value, scope)
        end
        return nil
    end)
end

---@private
---@nodiscard
---@param exprLit ASTNodeExprLiteral
---@param scope Scope
---@return LazyValue
function Interpreter:interpretExprLiteral(exprLit, scope)
    return LazyValue.NewLazy(function ()
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
                local value = self:Interpret(field.Value, scope)
                local key = field.Name
                if key then
                    if type(key) == 'string' then
                        values[key] = value
                    else
                        local keyValue = self:Interpret(key, scope)
                        assert(keyValue ~= nil)
                        values[keyValue] = value
                    end
                else
                    table.insert(values, value)
                end
            end
            return values
        end
    end)
end

---@private
---@nodiscard
---@param exprName ASTNodeExprName
---@param scope Scope
---@return LazyValue
function Interpreter:interpretExprName(exprName, scope)
    return LazyValue.NewLazy(function ()
        -- before getting debug vars
        self:updateDebugGlobals(exprName.SourceRange)
        
        return scope:GetVariable(exprName.Name):GetValue()
    end)
end

return Interpreter