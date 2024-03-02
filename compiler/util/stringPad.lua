---@param str any
---@param places integer
---@return string
return function(str, places)
    assert(places >= 1)
    str = tostring(str)
    return (" "):rep(places - #str) .. str
end