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

---@param name string
---@param value any
function Scope:SetVariable(name, value)
    for _,var in ipairs(self.Variables) do
        if var.Name == name then
            var.Value = value
            return
        end
    end
    local var = Variable.New(name, value)
    table.insert(self.Variables, var)
end