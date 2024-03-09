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
---@param endLn integer?
---@param endCol integer?
---@return SourceRange
local function sourceRange(startLn, startCol, endLn, endCol)
    if endLn  == nil then endLn  = startLn end
    if endCol == nil then endCol = startCol end
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
-- Test
--
--]]

addTest(
    "empty source",
    "",
    EMPTY_AST
)

--[[
--
-- Test :: Individual
--
--]]

--
-- Expr
--

addTest(
    "expr group", dedent
    [[
        2 * (1 + 3)
    ]],
    AST.NodeExprBlock.New(
        {
            AST.NodeExprBinary.New(
                AST.NodeExprLiteralNumber.New(2, sourceRange(1,1)),
                '*',
                AST.NodeExprBinary.New(
                    AST.NodeExprLiteralNumber.New(1, sourceRange(1,6)),
                    '+',
                    AST.NodeExprLiteralNumber.New(3, sourceRange(1,10)),
                    sourceRange(1,6, 1,10)
                ),
                sourceRange(1,1, 1,10)
            )
        },
        sourceRange(1,1, 1,11)
    )
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
    "expr assign bin", dedent
    [[
        abc.def = "text"
    ]],
    AST.NodeExprBlock.New(
        {
            AST.NodeExprAssign.New(
                AST.NodeExprBinary.New(
                    AST.NodeExprName.New("abc", sourceRange(1,1, 1,3)),
                    '.',
                    "def",
                    sourceRange(1,1, 1,7)
                ),
                AST.NodeExprLiteralString.New("text", sourceRange(1,11, 1,16)),
                sourceRange(1,1, 1,16)
            )
        },
        sourceRange(1,1, 1,16)
    )
)

--
-- Expr : Binary
--

addTest(
    "expr binary", dedent
    [[
        1 + 2 + 3
        a.b:c
        4 * 5 + 6
    ]],
    AST.NodeExprBlock.New(
        {
            AST.NodeExprBinary.New(
                AST.NodeExprLiteralNumber.New(1, sourceRange(1,1, 1,1)),
                '+',
                AST.NodeExprBinary.New(
                    AST.NodeExprLiteralNumber.New(2, sourceRange(1,5, 1,5)),
                    '+',
                    AST.NodeExprLiteralNumber.New(3, sourceRange(1,9, 1,9)),
                    sourceRange(1,5, 1,9)
                ),
                sourceRange(1,1, 1,9)
            ),
            AST.NodeExprBinary.New(
                AST.NodeExprBinary.New(
                    AST.NodeExprName.New('a', sourceRange(2,1, 2,1)),
                    '.',
                    "b",
                    sourceRange(2,1, 2,3)
                ),
                ':',
                "c",
                sourceRange(2,1, 2,5)
            ),
            AST.NodeExprBinary.New(
                AST.NodeExprBinary.New(
                    AST.NodeExprLiteralNumber.New(4, sourceRange(3,1, 3,1)),
                    '*',
                    AST.NodeExprLiteralNumber.New(5, sourceRange(3,5, 3,5)),
                    sourceRange(3,1, 3,5)
                ),
                '+',
                AST.NodeExprLiteralNumber.New(6, sourceRange(3,9, 3,9)),
                sourceRange(3,1, 3,9)
            ),
        },
        sourceRange(1,1, 3,9)
    )
)

--
-- Expr : Block
--

addTest(
    "expr block", dedent
    [[
        {
            1
            2
        }
    ]],
    AST.NodeExprBlock.New(
        {
            AST.NodeExprBlock.New(
                {
                    AST.NodeExprLiteralNumber.New(1, sourceRange(2,5)),
                    AST.NodeExprLiteralNumber.New(2, sourceRange(3,5)),
                },
                sourceRange(1,1, 4,1)
            )
        },
        sourceRange(1,1, 4,1)
    )
)

--
-- Expr : Call
--

--TODO
-- addTest(
--     "expr call", dedent
--     [[

--     ]]
-- )

--[[
--
-- Test End
--
--]]

parserTests:Test()