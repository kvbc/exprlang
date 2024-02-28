---@alias TokenType
---| 'number literal'
---| 'string literal'

---@class Token
---@field Type TokenType
---@field SourceRange SourceRange 
Token = {}

---@nodiscard
---@param type TokenType
---@param sourceRange SourceRange
function Token.New(type, sourceRange)
    ---@type Token
    return {
        Type = type;
        SourceRange = sourceRange;
    }
end