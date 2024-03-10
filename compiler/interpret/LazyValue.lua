---@class LazyValue
---@field private value any
---@field private hasValue boolean
---@field private getValueFunc (fun(): ...)?
local LazyValue = {}
LazyValue.__index = LazyValue

---@nodiscard
---@param value any
---@return LazyValue
function LazyValue.New(value)
    ---@type LazyValue
    local var = {
        hasValue = true;
        value = value;
    }
    return setmetatable(var, LazyValue)
end

---@nodiscard
---@param getValueFunc fun(): ...
---@return LazyValue
function LazyValue.NewLazy(getValueFunc)
    ---@type LazyValue
    local var = {
        hasValue = false;
        getValueFunc = getValueFunc;
    }
    return setmetatable(var, LazyValue)
end

---@param value any
function LazyValue:SetValue(value)
    self.value = value
    self.hasValue = true
end

---@nodiscard
---@return any
function LazyValue:GetValue()
    if self.hasValue then
        return self.value
    end
    self.value = self.getValueFunc()
    self.hasValue = true
    return self.value
end

return LazyValue