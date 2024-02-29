local pprint = require "lib.pprint"

require "ast.ASTNode"
require "ast.ASTNodeExpr"
require "ast.ASTNodeExprBlock"
require "ast.ASTNodeExprName"
require "ast.ASTNodeExprDef"
require "ast.ASTNodeExprCall"
require "ast.ASTNodeType"
require "ast.ASTNodeTypeStruct"
require "ast.ASTNodeTypeFunction"
require "ast.ASTNodeExprLiteral"
require "ast.ASTNodeExprLiteralNumber"
require "ast.ASTNodeExprLiteralString"
require "ast.ASTNodeExprLiteralStruct"

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
    return self:tryParseExprBlock()
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

---@param by integer?
---@private
function Parser:advance(by)
    self.tokenIndex = self.tokenIndex + (by or 1)
end

---@private
---@param message string
function Parser:error(message)
    table.insert(self.Errors, message)
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
    else
        for _,error in ipairs(newErrors) do
            table.insert(self.Errors, error)
        end
    end
    
    return ret
end

--[[
    name
    { ... }
--]]
---@private
---@nodiscard
---@return ASTNodeExpr?
function Parser:tryParseExpr()
    ---@type ASTNodeExpr?
    local expr = nil
    local token = self:token()
    if token and token.Type == 'name' then
        self:advance()
        local name = token.Value
        expr = self:tryParseExprDef(name) or ASTNodeExprName.New(name)
    else
        expr = self:tryParseExprBlock() or self:tryParseExprLiteral()
    end
    if expr then
        return self:tryParseExprCall(expr) or expr
    end
end

---@private
---@nodiscard
---@return ASTNodeExprBlock?
function Parser:tryParseExprBlock()
    if self:token():Is('{') then
        local startToken = self:token()
        assert(startToken)

        self:advance()

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

        if self:token():Is('}') then
            self:advance()

            return ASTNodeExprBlock.New(expressions)
        else
            local err = self:token().SourceRange:ToString(self.source, 'Expected closing bracket "}"')
            err = err .. '\n' .. startToken.SourceRange:ToString(self.source, 'For "{"')
            self:error(err)
        end
    end
end

--[[
    x := 3
    x num = 3
--]]
---@private
---@param name string
---@nodiscard
---@return ASTNodeExprDef?
function Parser:tryParseExprDef(name)
    return self:backtrack(function(error)
        ---@type ASTNodeType?
        local type = nil
    
        if self:token():Is(':=') then
            self:advance()
            type = ASTNodeType.New('auto')
        else
            type = self:tryParseType()
            if type then
                if self:token():Is('=') then
                    self:advance()                
                else
                    error(self:token().SourceRange:ToString(self.source, 'Expected "="'))
                end
            end
        end
        
        if type then
            local expr = self:tryParseExpr()
            if expr then
                return ASTNodeExprDef.New(name, type, expr)
            else
                error(self:token().SourceRange:ToString(self.source, 'Expected expression'))
            end
        end
    end)
end

--[[
    [1, 2, 3]
--]]
---@private
---@nodiscard
---@return ASTNodeExprLiteralStruct?
function Parser:tryParseExprLiteralStruct()
    if self:token():Is('[') then
        local startToken = self:token()
        assert(startToken)

        self:advance()

        ---@type ASTNodeExpr[]
        local exprs = {}
        while true do
            if self:token():Is(']') then
                break
            end
            if #exprs > 0 then
                if not (self:token():Is(',') or self:token():Is(';')) then
                    local err = self:token().SourceRange:ToString(self.source, 'Expected separator <,> or <;>')
                    err = err .. '\n' .. startToken.SourceRange:ToString(self.source, 'For "["')
                    self:error(err)
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

        if self:token():Is(']') then
            self:advance()
            return ASTNodeExprLiteralStruct.New(exprs)
        else
            local err = self:token().SourceRange:ToString(self.source, 'Expected closing bracket "]"')
            err = err .. '\n' .. startToken.SourceRange:ToString(self.source, 'For "["')
            self:error(err)
        end
    end
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
end

--[[
    abc[1, 2; 3]
--]]
---@private
---@nodiscard
---@param func ASTNodeExpr
---@return ASTNodeExprCall?
function Parser:tryParseExprCall(func)
    -- self:error(self:token().SourceRange:ToString(self.source, 'hier'))
    local args = self:tryParseExprLiteralStruct()
    if args then
        return ASTNodeExprCall.New(func, args)
    end
end

--[[
    num
    [num]
--]]
---@private
---@nodiscard
---@return ASTNodeType?
function Parser:tryParseType()
    if self:token():Is('num') then
        self:advance()
        return ASTNodeType.New('number')
    end
    if self:token():Is('auto') then
        self:advance()
        return ASTNodeType.New('auto')
    end
    local structType = self:tryParseTypeStruct()
    if structType then
        return self:tryParseTypeFunction(structType, false) or structType
    end
end

--[[
    [num]
    [num, num]
    [num; num]
--]]
---@private
---@nodiscard
---@return ASTNodeTypeStruct?
function Parser:tryParseTypeStruct()
    if self:token():Is('[') then
        local startToken = self:token()
        assert(startToken)

        self:advance()

        ---@type ASTNodeType[]
        local fields = {}
        while true do
            if self:token():Is(']') then
                break
            end
            if #fields > 0 then
                if not (self:token():Is(',') or self:token():Is(';')) then
                    local err = self:token().SourceRange:ToString(self.source, 'Expected separator <,> or <;>')
                    err = err .. '\n' .. startToken.SourceRange:ToString(self.source, 'For "["')
                    self:error(err)
                end
                self:advance()
            end
            local type = self:tryParseType()
            if type then
                table.insert(fields, type)
            else
                break
            end
        end

        if self:token():Is(']') then
            self:advance()
            return ASTNodeTypeStruct.New(fields)
        else
            local err = self:token().SourceRange:ToString(self.source, 'Expected closing bracket "]"')
            err = err .. '\n' .. startToken.SourceRange:ToString(self.source, 'For "["')
            self:error(err)
        end
    end
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
    if mustParse == nil then
        mustParse = true
    end
    paramsType = paramsType or self:tryParseTypeStruct()
    if not paramsType then
        return
    end
    if self:token():Is('->') then
        self:advance()
        local returnType = self:tryParseType()
        if returnType then
            return ASTNodeTypeFunction.New(paramsType, returnType)
        else
            self:error(self:token().SourceRange:ToString(self.source, 'Expected return type'))
        end
    elseif mustParse then
        self:error(self:token().SourceRange:ToString(self.source, 'Expected "->" for function type'))
    end
end