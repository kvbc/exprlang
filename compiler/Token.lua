---@alias TokenType
---| 'number literal'
---| 'string literal'
---| 'character'
---| 'name'
---| 'keyword'
---| 'operator'

---@class Token
---@field Type TokenType
---@field SourceRange SourceRange 
---@field Value any
Token = {}
Token.__index = Token

---@nodiscard
---@param type TokenType
---@param value any
---@param sourceRange SourceRange
function Token.New(type, value, sourceRange)
    ---@type Token
    return setmetatable({
        Type = type;
        SourceRange = sourceRange;
        Value = value;
    }, Token)
end

---@nodiscard
---@param value any
---@return boolean
function Token:Is(value)
    local compareValue = self.Value
    if self.Type == 'string literal' then
        compareValue = '"' .. compareValue .. '"'
    end
    return value == compareValue
end

---@nodiscard
---@return string
function Token:ToString()
    local value = self.Value
    if value == '\n' then
        value = '\\n'
    end
    return ("%s(%s) @ (%d:%d):(%d:%d)"):format(
        self.Type, value,
        self.SourceRange.StartPos.LineNumber, self.SourceRange.StartPos.Column,
        self.SourceRange.EndPos.LineNumber, self.SourceRange.EndPos.Column
    )
end