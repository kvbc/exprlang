---@class Variable
---@field Name string
---@field Value any
Variable = {}
Variable.__index = Variable

---@nodiscard
---@param name string
---@param value any
---@return Variable
function Variable.New(name, value)
    ---@type Variable
    local var = {
        Name = name;
        Value = value;
    }
    return setmetatable(var, Variable)
end