require "ast.ASTNode"
require "ast.ASTNodeExpr"
require "ast.ASTNodeExprBlock"
require "ast.ASTNodeExprName"
require "ast.ASTNodeExprDef"
require "ast.ASTNodeType"
require "ast.ASTNodeTypeStruct"
require "ast.ASTNodeTypeFunction"
require "ast.ASTNodeExprLiteral"
require "ast.ASTNodeExprLiteralNumber"
require "ast.ASTNodeExprLiteralString"

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

--[[
    name
    { ... }
--]]
---@private
---@nodiscard
---@return ASTNodeExpr?
function Parser:tryParseExpr()
    local token = self:token()
    if token and token.Type == 'name' then
        self:advance()
        local name = token.Value
        local expr = self:tryParseExprDef(name)
        if expr then return expr end
        return ASTNodeExprName.New(name)
    end
    return self:tryParseExprBlock()
        or self:tryParseExprLiteral()
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
                self:error(self:token().SourceRange:ToString(self.source, 'Expected "="'))
            end
        end
    end
    
    if type then
        local expr = self:tryParseExpr()
        if expr then
            return ASTNodeExprDef.New(name, type, expr)
        else
            self:error(self:token().SourceRange:ToString(self.source, 'Expected expression'))
        end
    end
end

--[[
    123
    "text"
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