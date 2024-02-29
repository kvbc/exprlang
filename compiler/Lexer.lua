--[[

Lexer
    Splits input source code into tokens

--]]

require "token"
local pprint = require "lib.pprint"
local dedent = require "lib.dedent"

---@param ch string
local function isWhitespaceChar(ch)
    assert(#ch == 1)
    return ch == '\n'
        or ch == '\r'
        or ch == '\v'
        or ch == '\f'
        or ch == '\t'
        or ch == ' '
end

---@param str string
local function isKeyword(str)
    return str == 'num'
        or str == 'fun'
        or str == 'not'
        or str == 'or'
        or str == 'and'
        or str == 'auto'
end

---@class Lexer
---@field Source Source
---@field SourceIndex integer
---@field Errors string[]
Lexer = {}
Lexer.__index = Lexer

---@param source Source
function Lexer.New(source)
    ---@type Lexer
    local lexer = {
        Errors = {};
        Source = source;
        SourceIndex = 1;
    }
    return setmetatable(lexer, Lexer)
end

---@return Token[]
function Lexer:Lex()
    ---@type Token[]
    local tokens = {}

    while self.SourceIndex <= #self.Source.String do
        local tokenAdded = false

        ---@param token Token?
        local function tryAddToken(token)
            if token then
                table.insert(tokens, token)
                tokenAdded = true
            end
        end

        tryAddToken(self:tryLexNumberLiteral())
        tryAddToken(self:tryLexStringLiteral())
        tryAddToken(self:tryLexNameOrKeyword())
        tryAddToken(self:tryLexOperator())

        if not tokenAdded then
            local char = self:char()
            if char and not isWhitespaceChar(char) then
                tryAddToken(Token.New(
                    'character',
                    SourceRange.New(self:sourcePos()),
                    self:char()
                ))
            end
            self:advance()
        end
    end

    return tokens
end

---@param tokens Token[]
function Lexer:PrintTokens(tokens)
    for _,token in ipairs(tokens) do
        pprint(token)
    end
end

---@param tokens Token[]
function Lexer:PrintTokensCompact(tokens)
    for _,token in ipairs(tokens) do
        print(string.format(
            "%s(%s)",
            token.Type, pprint.pformat(token.Value)
        ))
    end
end

---@private
---@param offset integer?
---@return string?
function Lexer:char(offset)
    local sourceIndex = self.SourceIndex + (offset or 0)
    if sourceIndex <= #self.Source.String then
        return self.Source.String:sub(sourceIndex, sourceIndex)
    end
end

---@private
---@return SourcePos
function Lexer:sourcePos()
    return SourcePos.FromIndex(self.Source, math.min(self.SourceIndex, #self.Source.String))
end

---@param by integer?
---@private
function Lexer:advance(by)
    self.SourceIndex = self.SourceIndex + (by or 1)
end

---@private
---@param message string
function Lexer:error(message)
    table.insert(self.Errors, message)
end

--[[
    Examples:
        123
        123.345.678
--]]
---@private
---@return Token?
function Lexer:tryLexNumberLiteral(allowDot)
    ---@param allowDot boolean?
    ---@return number?, integer?, integer?
    --- return number, startSourceIndex, endSourceIndex
    local function tryLex(allowDot)
        if allowDot == nil then
            allowDot = true
        end
        local startSourceIndex = self.SourceIndex
        while tonumber(self:char()) do -- char is digit
            self:advance()
        end
        local endSourceIndex = self.SourceIndex - 1
        if startSourceIndex <= endSourceIndex then
            if self:char() == '.' then
                if allowDot then
                    self:advance()
                    local _, _, newEndSourceIndex = tryLex(false)
                    if newEndSourceIndex then
                        endSourceIndex = newEndSourceIndex
                    end
                else
                    self:error(self:sourcePos():ToString(self.Source, 'Unexpected "."'))
                    self:advance()
                end
            end
            local number = tonumber(self.Source.String:sub(startSourceIndex, endSourceIndex))
            return number, startSourceIndex, endSourceIndex
        end
    end
    local number, startSourceIndex, endSourceIndex = tryLex()
    if number ~= nil then
        assert(startSourceIndex ~= nil)
        assert(endSourceIndex ~= nil)
        local startSourcePos = SourcePos.FromIndex(self.Source, startSourceIndex)
        local endSourcePos = SourcePos.FromIndex(self.Source, endSourceIndex)
        local sourceRange = SourceRange.New(startSourcePos, endSourcePos)
        return Token.New('number literal', sourceRange, number)
    end
end

---@private
---@return Token?
function Lexer:tryLexStringLiteral()
    if self:char() == '"' then
        local startSourceIndex = self.SourceIndex
        self:advance()
        while self:char() and self:char() ~= '"' do
            self:advance()
        end
        if self:char() == '"' then
            local endSourceIndex = self.SourceIndex
            self:advance()
            local string = self.Source.String:sub(startSourceIndex + 1, endSourceIndex - 1)
            local startSourcePos = SourcePos.FromIndex(self.Source, startSourceIndex)
            local endSourcePos = SourcePos.FromIndex(self.Source, endSourceIndex)
            local sourceRange = SourceRange.New(startSourcePos, endSourcePos)
            return Token.New('string literal', sourceRange, string)
        else
            local startSourcePos = SourcePos.FromIndex(self.Source, startSourceIndex)
            local msg = startSourcePos:ToString(self.Source, "Unterminated string literal")
            msg = msg .. '\n' .. self:sourcePos():ToString(self.Source, "Expected <\">, got <EOF>")
            self:error(msg)
        end
    end
end

---@private
---@return Token?
function Lexer:tryLexNameOrKeyword()
    ---@param ch string?
    local function isNameChar(ch)
        if not ch then return false end
        assert(#ch == 1)
        return (ch >= 'a' and ch <= 'z')
            or (ch >= 'A' and ch <= 'Z')
            or  ch == '_'
    end

    if isNameChar(self:char()) then
        local startSourceIndex = self.SourceIndex
        self:advance()
        while isNameChar(self:char()) do
            self:advance()
        end
        local endSourceIndex = self.SourceIndex - 1
        local nameOrKeyword = self.Source.String:sub(startSourceIndex, endSourceIndex)

        ---@type TokenType
        local tokenType = 'name'
        if isKeyword(nameOrKeyword) then
            tokenType = 'keyword'
        end

        local startSourcePos = SourcePos.FromIndex(self.Source, startSourceIndex)
        local endSourcePos = SourcePos.FromIndex(self.Source, endSourceIndex)
        local sourceRange = SourceRange.New(startSourcePos, endSourcePos)
        return Token.New(tokenType, sourceRange, nameOrKeyword)
    end
end

---@private
---@return Token?
function Lexer:tryLexOperator()
    local c1 = self:char(0)
    local c2 = self:char(1)
    if not c1 or not c2 then -- eof
        return
    end
    local op = c1 .. c2
    if op=='==' or op=='~=' or op=='>=' or op=='<=' or op=='->' or op==':=' then
        local startSourcePos = self:sourcePos()
        self:advance()
        local endSourcePos = self:sourcePos()
        self:advance()
        return Token.New(
            'operator',
            SourceRange.New(startSourcePos, endSourcePos),
            op
        )
    end
end