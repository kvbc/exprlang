---@class SourcePos
---@field Source Source
---@field LineNumber integer
---@field Column integer
SourcePos = {}

---@nodiscard
---@param source Source
---@param index integer
function SourcePos.FromIndex(source, index)
    assert(index >= 1)

    local finalLineNumber = 0
    local finalColumn = 0

    for lineNumber, lineIndices in pairs(source.LineIndices) do
        if index >= lineIndices.StartIndex and index <= lineIndices.EndIndex then
            finalLineNumber = lineNumber
            finalColumn = index - lineIndices.StartIndex + 1
            break
        end
    end

    -- if not, then index must be pointing to a newline
    -- TODO: figure out what to do when this happens
    assert(finalLineNumber >= 1)
    assert(finalColumn >= 1)

    ---@type SourcePos
    return {
        Source = source;
        LineNumber = finalLineNumber;
        Column = finalColumn;
    }
end

---@nodiscard
---@param src Source
---@param lineNumber integer
---@param column integer
function SourcePos.New(src, lineNumber, column)
    assert(lineNumber >= 1)
    assert(column >= 1)
    ---@type SourcePos
    return {
        Source = src;
        LineNumber = lineNumber;
        Column = column;
    }
end