---@class SourceRange
---@field StartPos SourcePos
---@field EndPos SourcePos
SourceRange = {}

---@nodiscard
---@param startPos SourcePos
---@param endPos SourcePos
function SourceRange.New(startPos, endPos)
    ---@type SourceRange
    return {
        StartPos = startPos;
        EndPos = endPos;
    }
end