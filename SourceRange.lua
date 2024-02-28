local dedent = require "lib.dedent"

---@class SourceRange
---@field StartPos SourcePos
---@field EndPos SourcePos
SourceRange = {}
SourceRange.__index = SourceRange

---@nodiscard
---@param startPos SourcePos
---@param endPos SourcePos
function SourceRange.New(startPos, endPos)
    ---@type SourceRange
    return setmetatable({
        StartPos = startPos;
        EndPos = endPos;
    }, SourceRange)
end

--[[
    1 | int x + 3;
      |     ^~~~~
      |     this
      |     is
      |     very wrong

    1 | int x + 3;
      |     ^~~~~~
      |     you really \n
    2 | int y - 5;
      | ~~~~~~~~~~
      | are stupid, \n
    3 | int z - 8;
      | ~~~~~
      | aren't you? \n
      | lol \n
      | lol
]]
--TODO: split message
---@nodiscard
---@param msg string?
---@return string
function SourceRange:ToString(msg)
    local str = ""

    -- start
    local startEndColumn = math.huge
    if self.EndPos.LineNumber == self.StartPos.LineNumber then
        startEndColumn = self.EndPos.Column
    end
    str = str .. self.StartPos:ToString(msg, startEndColumn)

    -- middle
    for lineNumber = self.StartPos.LineNumber + 1, self.EndPos.LineNumber - 1 do
        local sourcePos = SourcePos.New(
            self.StartPos.Source,
            lineNumber,
            1
        )
        str = str .. '\n' .. sourcePos:ToString(msg, math.huge, '~')
    end

    -- end
    if self.EndPos.LineNumber ~= self.StartPos.LineNumber then
        local endPos = SourcePos.New(
            self.EndPos.Source,
            self.EndPos.LineNumber,
            1
        )
        str = str .. '\n' .. endPos:ToString(msg, self.EndPos.Column, '~')
    end

    return str
end