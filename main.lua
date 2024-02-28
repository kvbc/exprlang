--[[

types:
    number
    bool
    struct:
        [number, bool, number]

        [x number, y bool]
    
    function:
        [number] => []

variables:
    a := 3
    a number = 5

functions:
        ([number] => []){

        }

main[] => [] = {

}

main := ([] => []){

}

]]

require "lex"

local function test(str)
    return function()
        print(str)
    end
end

local x = "123"
local f = test(x)
x = "456"
f()

-- Lex("test")