local deepcopy = require "lib.deepcopy"

---@class Scope
---@field Variables Variable[]
Scope = {}
Scope.__index = Scope

---@nodiscard
---@param scope Scope?
---@return Scope
function Scope.New(scope)
    ---@type Scope
    local newScope = {
        Variables = {}
    }
    scope = scope and deepcopy(scope) or newScope
    return setmetatable(scope, Scope)
end