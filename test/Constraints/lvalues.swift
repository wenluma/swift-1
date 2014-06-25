// RUN: %swift -parse -verify %s

func f0(inout x: Int) {}
func f1<T>(inout x: T) {}
func f2(inout x: X) {}
func f2(inout x: Double) {}

class Reftype {
  var property: Double { get {} set {} }
}

struct X {
  subscript(i: Int) -> Float { get {} set {} }

  var property: Double { get {} set {} }

  func genuflect() {}
}

struct Y {
  subscript(i: Int) -> Float { get {} set {} }
  subscript(f: Float) -> Int { get {} set {} }
}

var i : Int
var f : Float
var x : X
var y : Y

@assignment func +=(inout lhs: X, rhs : X) {}
@assignment func +=(inout lhs: Double, rhs : Double) {}
@assignment @prefix func ++(inout rhs: X) {}
@assignment @postfix func ++(inout lhs: X) {}

f0(&i)
f1(&i)
f1(&x[i])
f1(&x.property)
f1(&y[i])

// Missing '&'
f0(i) // expected-error{{passing value of type 'Int' to an inout parameter requires explicit '&'}}{{4-4=&}}
f1(y[i]) // expected-error{{passing value of type 'Float' to an inout parameter requires explicit '&'}}

// Assignment operators
x += x
++x

var yi = y[i]

// Non-settable lvalues
// FIXME: better diagnostic!

var non_settable_x : X {
  return x
}

struct Z {
  var non_settable_x: X { get {} }
  var non_settable_reftype: Reftype { get {} }
  var settable_x : X

  subscript(i: Int) -> Double { get {} }
  subscript((i: Int, j: Int)) -> X { get {} }
}

var z : Z

func fz() -> Z {}
func fref() -> Reftype {}

// non-settable var is non-settable:
// - assignment
non_settable_x = x // expected-error{{}}
// - inout (mono)
f2(&non_settable_x) // expected-error{{}}
// - inout (generic)
f1(&non_settable_x) // expected-error{{}}
// - inout assignment
non_settable_x += x // expected-error{{}}
++non_settable_x // expected-error{{}}

// non-settable property is non-settable:
z.non_settable_x = x // expected-error{{}}
f2(&z.non_settable_x) // expected-error{{}}
f1(&z.non_settable_x) // expected-error{{}}
z.non_settable_x += x // expected-error{{}}
++z.non_settable_x // expected-error{{}}

// non-settable subscript is non-settable:
z[0] = 0.0 // expected-error{{}}
f2(&z[0]) // expected-error{{}}
f1(&z[0]) // expected-error{{}}
z[0] += 0.0 // expected-error{{}}
++z[0] // expected-error{{}}

// settable property of an rvalue value type is non-settable:
fz().settable_x = x // expected-error{{}}
f2(&fz().settable_x) // expected-error{{}}
f1(&fz().settable_x) // expected-error{{}}
fz().settable_x += x // expected-error{{}}
++fz().settable_x // expected-error{{}}

// settable property of an rvalue reference type IS SETTABLE:
fref().property = 0.0
f2(&fref().property)
f1(&fref().property)
fref().property += 0.0
++fref().property

// settable property of a non-settable value type is non-settable:
z.non_settable_x.property = 1.0 // expected-error{{}}
f2(&z.non_settable_x.property) // expected-error{{}}
f1(&z.non_settable_x.property) // expected-error{{}}
z.non_settable_x.property += 1.0 // expected-error{{}}
++z.non_settable_x.property // expected-error{{}}

// settable property of a non-settable reference type IS SETTABLE:
z.non_settable_reftype.property = 1.0
f2(&z.non_settable_reftype.property)
f1(&z.non_settable_reftype.property)
z.non_settable_reftype.property += 1.0
++z.non_settable_reftype.property

// regressions with non-settable subscripts in value contexts
z[0] == 0
var d : Double
d = z[0]

// regressions with subscripts that return generic types
var xs:[X]
var _ = xs[0].property

struct A<T> {
    subscript(i: Int) -> T { get {} }
}

struct B {
    subscript(i: Int) -> Int { get {} }
}

var a:A<B>

var _ = a[0][0]

// Instance members of struct metatypes.
struct FooStruct {
  func instanceFunc0() {}
}

struct FooBarStruct {
  @conversion func __conversion() -> FooStruct { }
}

func testFooStruct() {
  FooStruct.instanceFunc0(FooStruct())()
  FooStruct.instanceFunc0(FooBarStruct())()
}

// Don't load from explicit lvalues.
func takesInt(x: Int) {} // expected-note{{in initialization of parameter 'x'}}
func testInOut(inout arg: Int) {
  var x : Int
  takesInt(&x) // expected-error{{'inout Int' is not convertible to 'Int'}}
}

// Don't infer inout types.
var ir = &i // expected-error{{type 'inout Int' of variable is not materializable}} \
            // expected-error{{reference to 'Int' not used to initialize a inout parameter}}
var ir2 = ((&i)) // expected-error{{type 'inout Int' of variable is not materializable}} \
                 // expected-error{{reference to 'Int' not used to initialize a inout parameter}}

// <rdar://problem/17133089>
func takeArrayRef(inout x:Array<String>) { }

// FIXME: Poor diagnostic.
takeArrayRef(["asdf", "1234"]) // expected-error{{cannot convert the expression's type '()' to type 'StringLiteralConvertible'}}
