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
---@param sourceRange SourceRange
---@param value any
function Token.New(type, sourceRange, value)
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