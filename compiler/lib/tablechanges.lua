local function table_changes(original, modified)
    if original == modified then return nil end -- no changes
    if not (type(original) == "table" and type(modified) == "table") then return {Expected = original, Got = modified} end -- primitive types
    local result = {}
    for k, v in pairs(original) do
        result[k] = table_changes(v, modified[k])
    end
    for k, v in pairs(modified) do
        if original[k] == nil then
            result[k] = table_changes(nil, v)
        end
    end
    return next(result) and result -- return nil for an empty table (no changes)
end
return table_changes