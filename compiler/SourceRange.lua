local dedent = require "lib.dedent"
local pprint = require "lib.pprint"

---@class SourceRange
---@field StartPos SourcePos
---@field EndPos SourcePos
SourceRange = {}
SourceRange.__index = SourceRange

---@nodiscard
---@param startPos SourcePos
---@param endPos SourcePos?
---@return SourceRange
function SourceRange.New(startPos, endPos)
    ---@type SourceRange
    local sourceRange = {
        StartPos = startPos;
        EndPos = endPos or startPos;
    }
    return setmetatable(sourceRange, SourceRange)
end

---@nodiscard
---@param startLn integer
---@param startCol integer
---@param endLn integer
---@param endCol integer
---@return SourceRange
function SourceRange.From(startLn, startCol, endLn, endCol)
    local startPos = SourcePos.New(startLn, startCol)
    local endPos = SourcePos.New(endLn, endCol)
    return SourceRange.New(startPos, endPos)
end

---@nodiscard
---@param startRange SourceRange
---@param endRange SourceRange
---@return SourceRange
function SourceRange.FromRanges(startRange, endRange)
    return SourceRange.New(
        startRange.StartPos,
        endRange.EndPos
    )
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
---@nodiscard
---@param source Source
---@param msg string?
---@return string
function SourceRange:ToString(source, msg)
    msg = debug.traceback(msg)

    local str = ""

    local startLineNumber = self.StartPos.LineNumber
    local endLineNumber = self.EndPos.LineNumber

    local msgs = {}
    if msg then
        for line in msg:gmatch("[^\n]*") do
            table.insert(msgs, line)
        end
    end
    local nextMsgIndex = 1
    local function getNextMsg()
        nextMsgIndex = nextMsgIndex + 1
        return msgs[nextMsgIndex - 1]
    end

    -- start
    local startEndColumn = math.huge
    if endLineNumber == startLineNumber then
        startEndColumn = self.EndPos.Column
    end
    str = str .. self.StartPos:ToString(source, getNextMsg(), startEndColumn)

    -- middle
    for lineNumber = startLineNumber + 1, endLineNumber - 1 do
        local sourcePos = SourcePos.New(lineNumber, 1)
        str = str .. '\n' .. sourcePos:ToString(source, getNextMsg(), math.huge, '~')
    end

    -- end
    if endLineNumber ~= startLineNumber then
        local endPos = SourcePos.New(endLineNumber, 1)
        local endMsg = getNextMsg()
        while true do
            local nextMsg = getNextMsg()
            if not nextMsg then break end
            endMsg = endMsg .. '\n' .. nextMsg
        end
        str = str .. '\n' .. endPos:ToString(source, endMsg, self.EndPos.Column, '~')
    end

    return str
end