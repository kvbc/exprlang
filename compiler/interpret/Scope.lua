local deepcopy = require "lib.deepcopy"

---@class Scope
---@field private variables table<string, LazyValue>
---@field private upperScope Scope?
local Scope = {}
Scope.__index = Scope

---@nodiscard
---@param upperScope Scope?
---@return Scope
function Scope.New(upperScope)
    ---@type Scope
    local scope = {
        variables = {};
        upperScope = upperScope;
    }
    return setmetatable(scope, Scope)
end

---@param name string
---@param val LazyValue
function Scope:SetVariable(name, val)
    self.variables[name] = val
end

---@nodiscard
---@param name string
---@return LazyValue?
function Scope:GetVariable(name)
    return self.variables[name] or (self.upperScope and self.upperScope:GetVariable(name))
end

return Scope