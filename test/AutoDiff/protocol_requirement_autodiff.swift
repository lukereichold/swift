// RUN: %target-run-simple-parse-stdlib-swift

import Swift
import StdlibUnittest

var ProtocolRequirementAutodiffTests = TestSuite("ProtocolRequirementAutodiff")

func pullback<T, U, R>(
  at x: (T, U), in f: @autodiff (T) -> (U) -> R
) -> (R.CotangentVector) -> (T.CotangentVector, U.CotangentVector)
  where T : Differentiable, U : Differentiable, R : Differentiable {
  return Builtin.autodiffApply_vjp_method(f, x.0, x.1).1
}

protocol DiffReq : Differentiable {
  @differentiable(reverse, wrt: (self, .0))
  func f(_ x: Float) -> Float
}

extension DiffReq {
  func gradF(at x: Float) -> (Self.CotangentVector, Float) {
    return pullback(at: (self, x), in: Self.f)(1)
  }
}

struct Quadratic : DiffReq, Equatable {
  typealias TangentVector = Quadratic
  typealias CotangentVector = Quadratic

  let a, b, c: Float
  init(_ a: Float, _ b: Float, _ c: Float) {
    self.a = a
    self.b = b
    self.c = c
  }

  func f(_ x: Float) -> Float {
    return a * x * x + b * x + c
  }
}

extension Quadratic : VectorNumeric {
  static var zero: Quadratic { return Quadratic(0, 0, 0) }
  static func + (lhs: Quadratic, rhs: Quadratic) -> Quadratic {
    return Quadratic(lhs.a + rhs.a, lhs.b + rhs.b, lhs.c + rhs.c)
  }
  static func - (lhs: Quadratic, rhs: Quadratic) -> Quadratic {
  return Quadratic(lhs.a + rhs.a, lhs.b + rhs.b, lhs.c + rhs.c)
}
  typealias Scalar = Float
  static func * (lhs: Float, rhs: Quadratic) -> Quadratic {
    return Quadratic(lhs * rhs.a, lhs * rhs.b, lhs * rhs.c)
  }
}

ProtocolRequirementAutodiffTests.test("Trivial") {
  expectEqual((Quadratic(0, 0, 1), 12), Quadratic(11, 12, 13).gradF(at: 0))
  expectEqual((Quadratic(1, 1, 1), 2 * 11 + 12),
              Quadratic(11, 12, 13).gradF(at: 1))
  expectEqual((Quadratic(4, 2, 1), 2 * 11 * 2 + 12),
              Quadratic(11, 12, 13).gradF(at: 2))
}

runAllTests()