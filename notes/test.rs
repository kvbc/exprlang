/*

Types:
- number
- struct
- function

Functions:
    macro add {a + b}

    #comp add := ast { a + b }
    x := add[a=1; b=2]
    // same as
    x := {a + b}[a=1; b=2]

    y := {
        a * a
    }[
        a = 3
    ]

    x := ([] => []) ast(a + b)

    macro add {a + b}[a number; b number]

    x := add[a = 3; b = 3]

    [a number; b number]{a + b}[a=3; b=3]

    add [a number; b number] => number {a + b}
    
    fun  {a + b}

    fun add = a + b

    fun main[] => [] {



    }

    add := fun{ print['adding...'] }

    mul := fun[a num, b num] { a * b }
    mul := fun[a num, b num] num { a * b }
    
    mul[a num, b num] -> num ::= { a * b }



Is 'fun' an arith op?
fun {
    print['hello']
}
fun [num] -> num {

}

*/

fun {
    a + b
}

add := fun 3 + 5
add := fun print["adding..."]

add := fun [a num, b num] -> num { a + b }

add := ([a num, b num] -> num) fun a + b

add := (fun a + b) as [a num, b num] -> num

add := cast [a num, b num] -> num fun a + b

add := cast[[a num, b num] -> num, fun a + b]

add := (a + b) as [a num, b num] -> num

add := [a num, b num] -> num { a + b }

add := [a num, b num] -> num (a + b)

b bool = true
n num = num b

A := []
A.DoubleX = [a] -> [] a.x = a.x * 2
a := [x: 3]
A.DoubleX[a]

a:DoubleX[]

table := [
    func: [self, a, b] -> [] {
        self + a + b
    }
]
table.func[1, 2, 3]
1:func[2, 3]

a := [x: 3] ref A
a:DoubleX[]

x := 3 ref Number
s := x:tostring[]

macro Num := [n] -> [] { n for Number }
x := Num[3]

(1 ref table):func[2, 3]



A := []
A.aMethod := [self] -> [] ...

B := [] ref A
B.bMethod := [self] -> [] ...

b := [] ref B
b:aMethod()


# idk
log := [prefix num, ...args num] -> [] {

}