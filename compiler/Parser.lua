local pprint = require "lib.pprint"

require "ast.ASTNode"
require "ast.ASTNodeExpr"
require "ast.ASTNodeExprBlock"
require "ast.ASTNodeExprName"
require "ast.ASTNodeExprDef"
require "ast.ASTNodeExprCall"
local ASTNodeExprUnary = require "ast.ASTNodeExprUnary"
local ASTNodeExprBinary = require "ast.ASTNodeExprBinary"
local ASTNodeExprAssign = require "ast.ASTNodeExprAssign"
require "ast.ASTNodeType"
local ASTNodeTypeStruct = require "ast.ASTNodeTypeStruct"
require "ast.ASTNodeTypeFunction"
require "ast.ASTNodeExprLiteral"
require "ast.ASTNodeExprLiteralNumber"
require "ast.ASTNodeExprLiteralString"
require "ast.ASTNodeExprLiteralStruct"
require "ast.ASTNodeExprFun"

---@class Parser
---@field private source Source
---@field private tokens Token[]
---@field private tokenIndex integer
---@field Errors string[]
Parser = {}
Parser.__index = Parser

---@nodiscard
---@param source Source
---@param tokens Token[]
---@return Parser
function Parser.New(source, tokens)
    ---@type Parser
    local parser = {
        source = source;
        tokens = tokens;
        tokenIndex = 1;
        Errors = {};
    }
    return setmetatable(parser, Parser)
end

---@nodiscard
---@return ASTNodeExprBlock?
function Parser:parse()
    return self:tryParseExprBlock(true)
end

---@private
---@nodiscard
---@param offset integer?
---@return Token?
function Parser:token(offset)
    local index = self.tokenIndex + (offset or 0)
    if index <= #self.tokens then
        return self.tokens[index]
    end
end

---@private
---@nodiscard
---@return SourceRange
function Parser:sourceRange()
    local token = self:token()
    if token then
        return token.SourceRange
    end
    local lastLn = #self.source.LineIndices
    local lastCol = self.source:GetColumnCount(lastLn)
    local lastSourcePos = SourcePos.New(lastLn, lastCol)
    return SourceRange.New(lastSourcePos)
end

---@private
---@nodiscard
---@param value any
---@return boolean
function Parser:isToken(value)
    return self:token() ~= nil and self:token():Is(value)
end

---@param by integer?
---@private
function Parser:advance(by)
    self.tokenIndex = self.tokenIndex + (by or 1)
end

---@private
---@param parseFunc fun(error: fun(message: string)): any
function Parser:backtrack(parseFunc)
    local prevTokenIndex = self.tokenIndex
    local newErrors = {}

    ---@param message string
    local function errorFunc(message)
        table.insert(newErrors, message)
    end
    
    local ret = parseFunc(errorFunc)
    if ret == nil then
        -- backtrack
        self.tokenIndex = prevTokenIndex
    end
    for _,error in ipairs(newErrors) do
        table.insert(self.Errors, error)
    end
    
    return ret
end

--[[
    name
    { ... }
--]]
---@private
---@nodiscard
---@param prevBinOpPriority integer?
---@return ASTNodeExpr?
function Parser:tryParseExpr(prevBinOpPriority)
    return self:backtrack(function(error)
        ---@type ASTNodeExpr?
        local expr = self:tryParseExprBlock()
                or self:tryParseExprFun()
                or self:tryParseExprDef()
                or self:tryParseExprAssign()
                or self:tryParseExprUnary()
                or self:tryParseExprLiteral()
        if not expr then
            local name = self:tryParseName()
            if name then
                expr = ASTNodeExprName.New(name)
            end
        end
        expr = expr and self:tryParseExprCall(expr) or expr
        expr = expr and self:tryParseExprBinary(expr, prevBinOpPriority) or expr
        return expr
    end)
end

---@private
---@nodiscard
---@return string?
function Parser:tryParseName()
    local token = self:token()
    if token and token.Type == 'name' then
        self:advance()
        return token.Value
    end
end

--[[
    -a
--]]
---@private
---@nodiscard
---@return ASTNodeExprUnary?
function Parser:tryParseExprUnary()
    return self:backtrack(function (error)
        for _,op in ipairs(ASTNodeExprUnary.Ops) do
            if self:isToken(op) then
                self:advance()
                
                local expr = self:tryParseExpr()
                if not expr then
                    return error(self:sourceRange():ToString(self.source, "Expected expression"))
                end

                return ASTNodeExprUnary.New(op, expr)
            end
        end
    end)
end

--[[
    a + b
--]]
---@private
---@nodiscard
---@param expr ASTNodeExpr
---@param prevPriority integer?
---@return ASTNodeExprBinary?
function Parser:tryParseExprBinary(expr, prevPriority)
    return self:backtrack(function (error)
        local opExpr1 = expr

        ---@type BinOpKind?
        local opKind
        for _,op in ipairs(ASTNodeExprBinary.Ops) do
            if self:isToken(op) then
                self:advance()
                opKind = op
                break
            end
        end
        if not opKind then
            return
        end

        local priority = ASTNodeExprBinary.OpPriority[opKind]
        print(opKind, priority, "<", prevPriority)
        if prevPriority and priority < prevPriority then
            return
        end

        local opExpr2 = self:tryParseExpr(priority)
        if not opExpr2 then
            return error(self:sourceRange():ToString(self.source, "Expected second operand expression"))
        end
        
        local newExpr = ASTNodeExprBinary.New(opKind, opExpr1, opExpr2)
        return self:tryParseExprBinary(newExpr) or newExpr
    end)
end

---@private
---@nodiscard
---@param omitBrackets boolean?
---@return ASTNodeExprBlock?
function Parser:tryParseExprBlock(omitBrackets)
    return self:backtrack(function(error)
        if omitBrackets or self:isToken('{') then
            local startToken = self:token()

            if not omitBrackets then
                self:advance()
            end

            ---@type ASTNodeExpr[]
            local expressions = {}
            while true do
                local expr = self:tryParseExpr()
                if expr then
                    table.insert(expressions, expr)
                else
                    break
                end
            end

            if omitBrackets and self:token() then -- not EOF
                error(self:sourceRange():ToString(self.source, 'Expected <EOF>'))
            end

            if omitBrackets or self:isToken('}') then
                if not omitBrackets then
                    self:advance()
                end
                return ASTNodeExprBlock.New(expressions)
            else
                assert(startToken)
                local err = self:sourceRange():ToString(self.source, 'Expected closing bracket "}"')
                err = err .. '\n' .. startToken.SourceRange:ToString(self.source, 'For "{"')
                error(err)
            end
        end
    end)
end

--[[
    x := 3
    x num = 3
--]]
---@private
---@nodiscard
---@return ASTNodeExprDef?
function Parser:tryParseExprDef()
    return self:backtrack(function(error)
        local token = self:token()
        local name
        if token and token.Type == 'name' then
            name = token.Value
            self:advance()
        else
            return
        end

        ---@type ASTNodeType?
        local type = nil
    
        if self:isToken(':=') then
            self:advance()
            type = ASTNodeType.New('auto')
        else
            type = self:tryParseType()
            if type then
                if self:isToken('=') then
                    self:advance()                
                else
                    -- error(self:sourceRange():ToString(self.source, 'Expected "="'))
                    return
                end
            end
        end
        
        if type then
            local expr = self:tryParseExpr()
            if expr then
                return ASTNodeExprDef.New(name, type, expr)
            else
                error(self:sourceRange():ToString(self.source, 'Expected expression'))
            end
        end
    end)
end

--[[
    a = 3
]]
---@private
---@nodiscard
---@return ASTNodeExprAssign?
function Parser:tryParseExprAssign()
    return self:backtrack(function (error)
        local token = self:token()
        if not(token and token.Type == 'name') then
            return
        end
        local name = token.Value
        self:advance()
    
        if not self:isToken('=') then
            return
        end
        self:advance()

        local exprValue = self:tryParseExpr()
        if not exprValue then
            return error(self:sourceRange():ToString(self.source, "Expected value expression"))
        end

        return ASTNodeExprAssign.New(name, exprValue)
    end)
end

--[[
    [1, 2, 3]
--]]
---@private
---@nodiscard
---@return ASTNodeExprLiteralStruct?
function Parser:tryParseExprLiteralStruct()
    return self:backtrack(function(error)
        if self:isToken('[') then
            local startToken = self:token()
            assert(startToken)

            self:advance()

            ---@type ASTNodeExpr[]
            local exprs = {}
            while true do
                if self:isToken(']') then
                    break
                end
                if #exprs > 0 then
                    if not (self:isToken(',') or self:isToken(';')) then
                        local err = self:sourceRange():ToString(self.source, 'Expected separator <,> or <;>')
                        err = err .. '\n' .. startToken.SourceRange:ToString(self.source, 'For "["')
                        error(err)
                    end
                    self:advance()
                end
                local expr = self:tryParseExpr()
                if expr then
                    table.insert(exprs, expr)
                else
                    break
                end
            end

            if self:isToken(']') then
                self:advance()
                return ASTNodeExprLiteralStruct.New(exprs)
            else
                local err = self:sourceRange():ToString(self.source, 'Expected closing bracket "]"')
                err = err .. '\n' .. startToken.SourceRange:ToString(self.source, 'For "["')
                error(err)
            end
        end
    end)
end

--[[
    123
    "text"
    [1, 2, 3]
--]]
---@private
---@nodiscard
---@return ASTNodeExprLiteral?
function Parser:tryParseExprLiteral()
    return self:backtrack(function(error)
        local token = self:token()
        if token then
            if token.Type == 'number literal' then
                self:advance()
                return ASTNodeExprLiteralNumber.New(token.Value)
            elseif token.Type == 'string literal' then
                self:advance()
                return ASTNodeExprLiteralString.New(token.Value)
            end
            return self:tryParseExprLiteralStruct()
        end
    end)
end

--[[
    abc[1, 2; 3]
--]]
---@private
---@nodiscard
---@param expr ASTNodeExpr
---@return ASTNodeExprCall?
function Parser:tryParseExprCall(expr)
    return self:backtrack(function(error)
        local func = expr

        local args = self:tryParseExprLiteralStruct()
        if not args then return end

        return ASTNodeExprCall.New(func, args)
    end)
end

--[[
    fun [num] -> num { 3 + 5 }
--]]
---@private
---@nodiscard
---@return ASTNodeExprFun?
function Parser:tryParseExprFun()
    return self:backtrack(function(error)
        if not self:isToken('fun') then
            return
        end

        self:advance()

        local funcType = self:tryParseTypeFunction()
        local funcBody = self:tryParseExprBlock()
        if not funcBody then
            error(self:sourceRange():ToString(self.source, 'Expected function body'))
            return
        end

        return ASTNodeExprFun.New(funcType, funcBody)
    end)
end

--[[
    num
    [num]
--]]
---@private
---@nodiscard
---@return ASTNodeType?
function Parser:tryParseType()
    return self:backtrack(function(error)
        if self:isToken('num') then
            self:advance()
            return ASTNodeType.New('number')
        end
        if self:isToken('auto') then
            self:advance()
            return ASTNodeType.New('auto')
        end
        local structType = self:tryParseTypeStruct()
        if structType then
            return self:tryParseTypeFunction(structType, false) or structType
        end
    end)
end

--[[
    [num]
    [num, num]
    [num; num]
    [a num; b num]
--]]
---@private
---@nodiscard
---@return ASTNodeTypeStruct?
function Parser:tryParseTypeStruct()
    return self:backtrack(function(error)
        if self:isToken('[') then
            local startToken = self:token()
            assert(startToken)

            self:advance()

            ---@type ASTNodeTypeStructField[]
            local fields = {}
            while true do
                if self:isToken(']') then
                    break
                end
                if #fields > 0 then
                    if not (self:isToken(',') or self:isToken(';')) then
                        local err = self:sourceRange():ToString(self.source, 'Expected separator <,> or <;>')
                        err = err .. '\n' .. startToken.SourceRange:ToString(self.source, 'For "["')
                        error(err)
                    end
                    self:advance()
                end
                local name = self:tryParseName()
                local type = self:tryParseType()
                if type then
                    ---@type ASTNodeTypeStructField
                    local field = {
                        Type = type;
                        Name = name;
                    }
                    table.insert(fields, field)
                else
                    break
                end
            end

            if self:isToken(']') then
                self:advance()
                return ASTNodeTypeStruct.New(fields)
            -- else
            --     local err = self:sourceRange():ToString(self.source, 'Expected closing bracket "]"')
            --     err = err .. '\n' .. startToken.SourceRange:ToString(self.source, 'For "["')
            --     error(err)
            end
        end
    end)
end

--[[
    [num] => num
    [num, num] -> [num]
--]]
---@private
---@nodiscard
---@param paramsType ASTNodeTypeStruct?
---@param mustParse boolean?
---@return ASTNodeTypeFunction?
function Parser:tryParseTypeFunction(paramsType, mustParse)
    return self:backtrack(function(error)
        if mustParse == nil then
            mustParse = true
        end
        paramsType = paramsType or self:tryParseTypeStruct()
        if not paramsType then
            return
        end
        if self:isToken('->') then
            self:advance()
            local returnType = self:tryParseType()
            if returnType then
                return ASTNodeTypeFunction.New(paramsType, returnType)
            else
                error(self:sourceRange():ToString(self.source, 'Expected return type'))
            end
        elseif mustParse then
            error(self:sourceRange():ToString(self.source, 'Expected "->" for function type'))
        end
    end)
end
