---@class ASTNode
---@field String string
---@field SourceRange SourceRange
local ASTNode = {}
ASTNode.__index = ASTNode

---@nodiscard
---@param sourceRange SourceRange
---@param string string?
---@return ASTNode
function ASTNode.New(sourceRange, string)
    ---@type ASTNode
    local node = {
        SourceRange = sourceRange;
        String = string or "???"
    }
    return setmetatable(node, ASTNode)
end

return ASTNode