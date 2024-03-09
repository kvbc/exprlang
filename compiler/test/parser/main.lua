require "Source"
require "SourcePos"
require "SourceRange"
require "Lexer"
require "Token"
require "Parser"
local AST = require "AST"
local ParserTests = require "test.parser.ParserTests"
local ParserTest = require "test.parser.ParserTest"
local deepcompare = require "lib.deepcompare"
local dedent = require "lib.dedent"


local parserTests = ParserTests.New()

---@nodiscard
---@param startLn integer
---@param startCol integer
---@param endLn integer
---@param endCol integer
---@return SourceRange
local function sourceRange(startLn, startCol, endLn, endCol)
    return SourceRange.From(startLn, startCol, endLn, endCol)
end

local EMPTY_AST = AST.NodeExprBlock.New({}, sourceRange(1,1, 1,1))

---@param name string
---@param sourceCode string
---@param expectedAST ASTNodeExprBlock?
local function addTest(name, sourceCode, expectedAST)
    local expectErrors = false
    if expectedAST == nil then
        expectedAST = EMPTY_AST
        expectErrors = true
    end
    parserTests:Add(ParserTest.New(name, sourceCode, expectedAST, expectErrors))
end

--[[
--
-- Test Start
--
--]]

addTest(
    "empty source",
    "",
    EMPTY_AST
)

--
-- Expr : Assign
--

addTest(
    "expr assign name", dedent
    [[
        xyz = 3
    ]],
    AST.NodeExprBlock.New(
        {
            AST.NodeExprAssign.New(
                AST.NodeExprName.New("xyz", sourceRange(1,1, 1,3)),
                AST.NodeExprLiteralNumber.New(3, sourceRange(1,7, 1,7)),
                sourceRange(1,1, 1,7)
            ),
        }, 
        sourceRange(1,1, 1,7)
    )
)

addTest(
    "expr assign bin 2", dedent
    [[
        abc.def = "text"
    ]],
    AST.NodeExprBlock.New(
        {

        },
        sourceRange(1,1, 1,16)
    )
)

--[[
--
-- Test End
--
--]]

parserTests:Test()