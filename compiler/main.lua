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

require "Lexer"
require "Parser"
require "Source"
require "SourcePos"
require "SourceRange"
require "interpret.Interpreter"
require "interpret.Variable" 
local dedent = require "lib.dedent"
local pprint = require "lib.pprint"

-- func [num] -> num = { a }
local src = [[

test := fun [num] -> num {
    print["testing!"]
}
test[]

]]

local source = Source.New(src)
local sourcePos = SourcePos.New(3, 5)
-- print(sourcePos:ToString(dedent [[
--     long message
--     with long
--     multiple lines
-- -- ]]))
-- print(sourcePos:ToString())

---@param errors string[]
local function printErrors(errors)
    for _,error in ipairs(errors) do
        print(error)
        print()
    end
end

-- local startSourcePos = SourcePos.New(2, 5)
-- local endSourcePos = SourcePos.New(5, 4)
-- local sourceRange = SourceRange.New(startSourcePos, endSourcePos)
-- print(sourceRange:ToString(source, "message\n1\n2\n3\nabc\ndef"))

local lexer = Lexer.New(source)
local tokens = lexer:Lex()
print('\nLexer Errors\n')
printErrors(lexer.Errors)
print('\nTokens\n')
-- lexer:PrintTokens(tokens)
lexer:PrintTokensCompact(tokens)

local parser = Parser.New(source, tokens)
local ast = parser:parse()
print('\nParse Errors\n')
printErrors(parser.Errors)
print('\nAST\n')
pprint(ast)

-- Lex("test")

if ast then
    local interpreter = Interpreter.New(ast)
    table.insert(
        interpreter.GlobalScope.Variables,
        Variable.New("print", function(...)
            io.write("> ", pprint.pformat(...), '\n')
        end)
    )
    print('\nInterpret Result\n')
    interpreter:Interpret()
    print('\nInterpret Errors\n')
    printErrors(interpreter.Errors)
end