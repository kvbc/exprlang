local pprint = require "lib.pprint"

local ASTNode = require "ast.ASTNode"
local ASTNodeExpr = require "ast.ASTNodeExpr" ()
local ASTNodeExprBlock = require "ast.ASTNodeExprBlock"
local ASTNodeExprName = require "ast.ASTNodeExprName"
local ASTNodeExprDef = require "ast.ASTNodeExprDef"
local ASTNodeExprCall = require "ast.ASTNodeExprCall"
local ASTNodeExprUnary = require "ast.ASTNodeExprUnary"
local ASTNodeExprBinary = require "ast.ASTNodeExprBinary"
local ASTNodeExprCast = require "ast.ASTNodeExprCast"
local ASTNodeExprAssign = require "ast.ASTNodeExprAssign"
local ASTNodeTypeStruct = require "ast.ASTNodeTypeStruct"
local ASTNodeType = require "ast.ASTNodeType"
local ASTNodeTypeFunction = require "ast.ASTNodeTypeFunction"
local ASTNodeExprLiteral = require "ast.ASTNodeExprLiteral"
local ASTNodeExprLiteralNumber = require "ast.ASTNodeExprLiteralNumber"
local ASTNodeExprLiteralString = require "ast.ASTNodeExprLiteralString"
local ASTNodeExprLiteralStruct = require "ast.ASTNodeExprLiteralStruct"

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
function Parser:Parse()
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
---@param parseFunc fun(error: fun(message: string)): ...
function Parser:backtrack(parseFunc)
    local prevTokenIndex = self.tokenIndex
    local newErrors = {}

    ---@param message string
    local function errorFunc(message)
        table.insert(newErrors, message)
    end
    
    local rets = table.pack(parseFunc(errorFunc))
    if rets[1] == nil then
        -- backtrack
        self.tokenIndex = prevTokenIndex
    end
    for _,error in ipairs(newErrors) do
        table.insert(self.Errors, error)
    end
    
    return table.unpack(rets)
end

--[[
    name
    { ... }
--]]
---@private
---@nodiscard
---@param prevBinOpPriority integer?
---@param parseAssignAndDef boolean?
---@param isGrouped boolean?
---@return ASTNodeExpr?
function Parser:tryParseExpr(prevBinOpPriority, parseAssignAndDef, isGrouped)
    return self:backtrack(function(error)
        local function skipNewline()
            if isGrouped and self:isToken('\n') then
                self:advance()
            end
        end
        
        skipNewline()

        ---@type ASTNodeExpr?
        local expr = self:tryParseGroupedExpr()
                or self:tryParseExprBlock()
                or (parseAssignAndDef ~= false and self:tryParseExprDef())
                or self:tryParseExprUnary()
                or self:tryParseExprCast()
                or self:tryParseExprLiteral()
                or self:tryParseExprName()

        if expr then
            ---@type ASTNodeExpr?
            while true do
                local expandExpr = nil
                skipNewline()
                expandExpr = self:tryParseExprBinary(expandExpr or expr, prevBinOpPriority) or expandExpr
                skipNewline()
                expandExpr = self:tryParseExprCall(expandExpr or expr) or expandExpr
                skipNewline()
                expandExpr = (parseAssignAndDef ~= false and self:tryParseExprAssign(expandExpr or expr)) or expandExpr
                skipNewline()
                if expandExpr then
                    expr = expandExpr
                else
                    break
                end
            end
        end

        return expr
    end)
end

---@private
---@nodiscard
---@return string?, Token?
function Parser:tryParseName()
    local token = self:token()
    if token and token.Type == 'name' then
        self:advance()
        return token.Value, token
    end
end

--[[
    test
--]]
---@private
---@nodiscard
---@return ASTNodeExprName?
function Parser:tryParseExprName()
    local name, token = self:tryParseName()
    if not name then
        return
    end
    assert(token)
    return ASTNodeExprName.New(name, token.SourceRange)
end

--[[
    num a
--]]
---@private
---@nodiscard
---@return ASTNodeExprCast?
function Parser:tryParseExprCast()
    return self:backtrack(function (error)
        local type = self:tryParseType()
        if not type then
            return
        end

        local expr = self:tryParseExpr()
        if not expr then
            return --error(self:sourceRange():ToString(self.source, 'Expected cast expression'))
        end

        return ASTNodeExprCast.New(
            type, expr,
            SourceRange.FromRanges(type.SourceRange, expr.SourceRange)
        )
    end)
end

--[[
    (3 + 5)
--]]
---@private
---@nodiscard
---@return ASTNodeExpr?
function Parser:tryParseGroupedExpr()
    return self:backtrack(function (error)
        if self:isToken('(') then
            self:advance()

            local expr = self:tryParseExpr(nil, nil, true)
            if not expr then
                return error(self:sourceRange():ToString(self.source, 'Expected expression'))
            end

            if self:isToken(')') then
                self:advance()
                return expr
            else
                return error(self:sourceRange():ToString(self.source, 'Expected closing ")"'))
            end
        end
    end)
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
            local startToken = self:token()
            if startToken and startToken:Is(op) then
                self:advance()
                
                local expr = self:tryParseExpr()
                if not expr then
                    return error(self:sourceRange():ToString(self.source, "Expected expression"))
                end

                return ASTNodeExprUnary.New(
                    op, expr,
                    SourceRange.FromRanges(startToken.SourceRange, expr.SourceRange)
                )
            end
        end
    end)
end

--[[
    a + b
--]]
---@private
---@nodiscard
---@param expr ASTNodeExpr?
---@param prevPriority integer?
---@return ASTNodeExprBinary?
function Parser:tryParseExprBinary(expr, prevPriority)
    return self:backtrack(function (error)
        local opExpr1 = expr or self:tryParseExpr()
        if not opExpr1 then
            return
        end

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
        if prevPriority and priority.Left < prevPriority then
            return
        end

        ---@type (ASTNodeExpr | string)?, Token?
        local opExpr2, nameToken
        if opKind == '.' or opKind == ':' then
            opExpr2, nameToken = self:tryParseName()
        end
        opExpr2 = opExpr2 or self:tryParseExpr(priority.Right, false)
        if not opExpr2 then
            return error(self:sourceRange():ToString(self.source, "Expected second operand expression"))
        end

        ---@type SourceRange
        local endSourceRange
        if type(opExpr2) == 'string' then
            endSourceRange = assert(nameToken).SourceRange
        else
            endSourceRange = opExpr2.SourceRange
        end
        assert(endSourceRange)

        local newExpr = ASTNodeExprBinary.New(
            opKind, opExpr1, opExpr2,
            SourceRange.FromRanges(opExpr1.SourceRange, endSourceRange)
        )

        return self:tryParseExprBinary(newExpr) or newExpr
    end)
end

---@private
---@nodiscard
---@param omitBrackets boolean?
---@return ASTNodeExprBlock?
function Parser:tryParseExprBlock(omitBrackets)
    return self:backtrack(function(error)
        local startSourceRange = self:sourceRange()
        if omitBrackets or self:isToken('{') then
            local startToken = self:token()

            if not omitBrackets then
                self:advance()
            end

            ---@type ASTNodeExpr[]
            local expressions = {}
            while true do
                if not self:token() or self:isToken('}') then -- EOF or }
                    break
                end
                
                if self:isToken('\n') then
                    self:advance()
                elseif #expressions > 0 then
                    return error(self:sourceRange():ToString(self.source, 'Expected new-line'))
                end

                local expr = self:tryParseExpr()
                if expr then
                    table.insert(expressions, expr)
                else
                    break
                end
            end

            -- if omitBrackets and self:token() then -- not EOF
            --     error(self:sourceRange():ToString(self.source, 'Expected <EOF>'))
            -- end

            local endToken = self:token()
            if omitBrackets or (endToken and endToken:Is('}')) then
                local endSourceRange = self:sourceRange()
                if not omitBrackets then
                    endSourceRange = assert(endToken).SourceRange
                    self:advance()
                end
                return ASTNodeExprBlock.New(
                    expressions,
                    SourceRange.FromRanges(startSourceRange, endSourceRange)
                )
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
            type = ASTNodeType.New('auto', self:sourceRange())
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
                return ASTNodeExprDef.New(
                    name, type, expr,
                    SourceRange.FromRanges(token.SourceRange, expr.SourceRange)
                )
            else
                error(self:sourceRange():ToString(self.source, 'Expected expression'))
            end
        end
    end)
end

--[[
    a = 3
    a.b = 5
]]
---@private
---@nodiscard
---@param expr ASTNodeExpr
---@return ASTNodeExprAssign?
function Parser:tryParseExprAssign(expr)
    return self:backtrack(function (error)
        ---@type (ASTNodeExprName | ASTNodeExprBinary)?
        local lvalue
        if expr.Kind == 'Name' or expr.Kind == 'Binary' then
            ---@cast expr (ASTNodeExprName | ASTNodeExprBinary)
            lvalue = expr
        end
        if not lvalue then
            return
        end

        if not self:isToken('=') then
            return
        end
        self:advance()

        local exprValue = self:tryParseExpr()
        if not exprValue then
            return error(self:sourceRange():ToString(self.source, "Expected value expression"))
        end

        return ASTNodeExprAssign.New(
            lvalue, exprValue,
            SourceRange.FromRanges(expr.SourceRange, exprValue.SourceRange)
        )
    end)
end

--[[
    [1, 2, 3]
    [1, a: 3, 4]
--]]
---@private
---@nodiscard
---@return ASTNodeExprLiteralStruct?
function Parser:tryParseExprLiteralStruct()
    return self:backtrack(function(error)
        if self:isToken('[') then
            local startSourceRange = self:sourceRange()
            local startToken = self:token()
            assert(startToken)

            self:advance()

            ---@type ASTNodeExprLiteralStructField[]
            local fields = {}
            while true do
                if self:isToken(']') then
                    break
                end
                if #fields > 0 then
                    if not (self:isToken(',') or self:isToken(';')) then
                        local err = self:sourceRange():ToString(self.source, 'Expected separator <,> or <;>')
                        err = err .. '\n' .. startToken.SourceRange:ToString(self.source, 'For "["')
                        return error(err)
                    end
                    self:advance()
                end

                ---@type (string | ASTNodeExpr)?
                local name
                local nextTokenOfs = 0

                local token = self:token()
                if token and token.Type == 'name' then
                    nextTokenOfs = 1
                    name = token.Value
                end
                
                if not name then
                    name = self:tryParseExpr(nil, false)
                end

                ---@type ASTNodeExpr?
                local expr
                if name then
                    local nextToken = self:token(nextTokenOfs)
                    if nextToken and nextToken:Is('=') then
                        self:advance()
                        if token and token.Type == 'name' then
                            self:advance()
                        end
                    else
                        if type(name) ~= 'string' then
                            expr = name
                        end
                        name = nil
                    end
                end

                expr = expr or self:tryParseExpr(nil, false)
                if expr then
                    ---@type ASTNodeExprLiteralStructField
                    local field = {
                        Name = name;
                        Value = expr;
                    }
                    table.insert(fields, field)
                else
                    if name then
                        error(self:sourceRange():ToString(self.source, 'Expected expression'))
                    end
                end
            end

            if self:isToken(']') then
                local endSourceRange = self:sourceRange()
                self:advance()
                return ASTNodeExprLiteralStruct.New(
                    fields,
                    SourceRange.FromRanges(startSourceRange, endSourceRange)
                )
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
            local startSourceRange = self:sourceRange()
            if token.Type == 'number literal' then
                self:advance()
                return ASTNodeExprLiteralNumber.New(
                    token.Value,
                    SourceRange.FromRanges(startSourceRange, self:sourceRange())
                )
            elseif token.Type == 'string literal' then
                self:advance()
                return ASTNodeExprLiteralString.New(
                    token.Value,
                    SourceRange.FromRanges(startSourceRange, self:sourceRange())
                )
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
        if not expr:IsCallable() then
            return
        end

        local func = expr

        local args = self:tryParseExprLiteralStruct() or self:tryParseExpr()
        if not args then return end

        return ASTNodeExprCall.New(
            func, args,
            SourceRange.FromRanges(expr.SourceRange, args.SourceRange)
        )
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
            local sourceRange = self:sourceRange()
            self:advance()
            return ASTNodeType.New('number', sourceRange)
        end
        if self:isToken('auto') then
            local sourceRange = self:sourceRange()
            self:advance()
            return ASTNodeType.New('auto', sourceRange)
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
            local startSourceRange = self:sourceRange()

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
                local endSourceRange = self:sourceRange()
                self:advance()
                return ASTNodeTypeStruct.New(
                    fields,
                    SourceRange.FromRanges(startSourceRange, endSourceRange)
                )
            -- else
            --     local err = self:sourceRange():ToString(self.source, 'Expected closing bracket "]"')
            --     err = err .. '\n' .. startToken.SourceRange:ToString(self.source, 'For "["')
            --     error(err)
            end
        end
    end)
end

--[[
    [num] -> num
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
                return ASTNodeTypeFunction.New(
                    paramsType, returnType,
                    SourceRange.FromRanges(paramsType.SourceRange, returnType.SourceRange)
                )
            else
                error(self:sourceRange():ToString(self.source, 'Expected return type'))
            end
        elseif mustParse then
            error(self:sourceRange():ToString(self.source, 'Expected "->" for function type'))
        end
    end)
end

