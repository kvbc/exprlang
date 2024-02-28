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
require "Source"
require "SourcePos"
require "SourceRange"
local dedent = require "lib.dedent"

local src = [[

this is my source code
and this is mid
hello !
end :)

]]

local source = Source.New(src)
local sourcePos = SourcePos.New(source, 3, 5)
-- print(sourcePos:ToString(dedent [[
--     long message
--     with long
--     multiple lines
-- -- ]]))
-- print(sourcePos:ToString())

local startSourcePos = SourcePos.New(source, 2, 5)
local endSourcePos = SourcePos.New(source, 5, 4)
local sourceRange = SourceRange.New(startSourcePos, endSourcePos)
print(sourceRange:ToString("message"))

-- Lex("test")