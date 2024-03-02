local deepcopy = require "lib.deepcopy"

---@class Scope
---@field Variables Variable[]
---@field UpperScope Scope?
Scope = {}
Scope.__index = Scope

---@nodiscard
---@param upperScope Scope?
---@return Scope
function Scope.New(upperScope)
    ---@type Scope
    local scope = {
        Variables = {};
        UpperScope = upperScope;
    }
    return setmetatable(scope, Scope)
end

---@param name string
---@param value any
function Scope:SetVariable(name, value)
    ---@param scope Scope
    ---@return boolean
    local function setExisting(scope)
        for _,var in ipairs(scope.Variables) do
            if var.Name == name then
                var.Value = value
                return true
            end
        end
        return false
    end

    if setExisting(self) then return end
    -- if self.UpperScope and setExisting(self.UpperScope) then return end

    local var = Variable.New(name, value)
    table.insert(self.Variables, var)
end

---@nodiscard
---@param name string
---@return any
function Scope:GetVariable(name)
    for _,var in ipairs(self.Variables) do
        if var.Name == name then
            return var.Value
        end
    end
    return self.UpperScope and self.UpperScope:GetVariable(name)
end