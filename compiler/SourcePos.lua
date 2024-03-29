local dedent = require "lib.dedent"
local stringPad = require "util.stringPad"

---@class SourcePos
---@field LineNumber integer
---@field Column integer
SourcePos = {}
SourcePos.__index = SourcePos

---@nodiscard
---@param source Source
---@param index integer
function SourcePos.FromIndex(source, index)
    assert(index >= 1)

    local finalLineNumber = 0
    local finalColumn = 0

    for lineNumber, lineIndices in pairs(source.LineIndices) do
        -- if index >= lineIndices.StartIndex and index <= source.LineIndices[lineNumber + 1].EndIndex then
        --     finalLineNumber = lineNumber
        --     finalColumn = index - lineIndices.StartIndex + 1
        --     break
        -- end
        if index >= lineIndices.StartIndex then
            finalLineNumber = lineNumber
            finalColumn = index - lineIndices.StartIndex + 1
        end
    end

    -- if not, then index must be pointing to a newline
    -- TODO: figure out what to do when this happens
    assert(finalLineNumber >= 1)
    assert(finalColumn >= 1)

    ---@type SourcePos
    return setmetatable({
        LineNumber = finalLineNumber;
        Column = finalColumn;
    }, SourcePos)
end

---@nodiscard
---@param lineNumber integer
---@param column integer
function SourcePos.New(lineNumber, column)
    assert(lineNumber >= 1)
    assert(column >= 1)
    ---@type SourcePos
    return setmetatable({
        LineNumber = lineNumber;
        Column = column;
    }, SourcePos)
end

--[[
    1 | int x + 3;
      |       ^
      |       error
      |       multiple
      |       lines
]]
---@nodiscard
---@param source Source
---@param msg string?
---@param endColumnIndex integer?
---@param pointerChar string?
---@return string
function SourcePos:ToString(source, msg, endColumnIndex, pointerChar)
    msg = debug.traceback(msg)

    endColumnIndex = endColumnIndex or self.Column
    pointerChar = pointerChar or '^'

    endColumnIndex = math.min(endColumnIndex, source:GetColumnCount(self.LineNumber))

    local sourceLine = source:GetLine(self.LineNumber)
    local filename = source.Filename
    local prefixSpaces = (" "):rep(#tostring(filename or self.LineNumber))

    local str = ""

    if filename then
        str = str .. ("%s |\n"):format(filename)
    end

    str = str .. string.format(
        "%s | %s",
        stringPad(self.LineNumber, #prefixSpaces), sourceLine
    )

    if msg then
        local columnSpaces = (" "):rep(self.Column - 1)
        msg = msg:gsub(
            '\n',
            string.format(dedent
                [[

                    %s | %s
                ]],
                prefixSpaces, columnSpaces 
            )
        )
        str = str .. string.format(dedent
            [[

                %s | %s%s%s
                %s | %s%s
            ]],
            prefixSpaces, columnSpaces, pointerChar, ("~"):rep(endColumnIndex - self.Column),
            prefixSpaces, columnSpaces, msg
        )
    end

    str = str .. string.format("\n%s | ", prefixSpaces)

    return str
end