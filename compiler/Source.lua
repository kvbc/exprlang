
---@alias LineIndices {[integer]: {StartIndex: integer, EndIndex: integer}} both indices are exclusive

---@class Source
---@field String string
---@field Filename string?
---@field LineIndices LineIndices
Source = {}
Source.__index = Source

---@nodiscard
---@param string string
---@param filename string?
function Source.New(string, filename)
    ---@type LineIndices
    local lineIndices = {}
    local lineNumber = 1
    lineIndices[lineNumber] = {
        StartIndex = 1;
    }
    for i=1, #string do
        local char = string:sub(i, i)
        if char == '\n' or char == '\r' then
            lineIndices[lineNumber].EndIndex = i - 1
            local nextChar = string:sub(i+1, i+1)
            if char == '\r' and nextChar == '\n' then
                i = i + 1
            end
            lineNumber = lineNumber + 1
            lineIndices[lineNumber] = {
                StartIndex = i + 1
            }
        end
    end
    lineIndices[lineNumber].EndIndex = #string

    ---@type Source
    return setmetatable({
        String = string;
        LineIndices = lineIndices;
        Filename = filename;
    }, Source)
end

---@nodiscard
---@param lineNumber integer
function Source:GetLine(lineNumber)
    assert(lineNumber >= 1)
    local lineIndices = self.LineIndices[lineNumber]
    return self.String:sub(lineIndices.StartIndex, lineIndices.EndIndex)
end

---@nodiscard
---@param lineNumber integer
---@return integer
function Source:GetColumnCount(lineNumber)
    assert(lineNumber >= 1)
    local lineIndices = self.LineIndices[lineNumber]
    local colCount = lineIndices.EndIndex - lineIndices.StartIndex + 1
    return math.max(1, colCount)
end