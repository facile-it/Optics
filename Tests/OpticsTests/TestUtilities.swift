@testable import Optics
import SwiftCheck
import FunctionalKit

extension CheckerArguments {
	static func with(_ left: Int, _ right: Int, _ size: Int) -> CheckerArguments {
		return CheckerArguments(
			replay: .some((StdGen(left,right),size)))
	}
}

struct TestProduct<A,B>: Equatable, Arbitrary where A: Equatable & Arbitrary, B: Equatable & Arbitrary {
    let unwrap: Product<A,B>
    
    init(_ product: Product<A,B>) {
        self.unwrap = product
    }
    
    init(_ first: A, _ second: B) {
        self.init(Product.init(first, second))
    }
    
    static func == (lhs: TestProduct, rhs: TestProduct) -> Bool {
        return lhs.unwrap == rhs.unwrap
    }
    
    static var arbitrary: Gen<TestProduct<A, B>> {
        return Gen.compose {
            TestProduct.init($0.generate(), $0.generate())
        }
    }
    
    enum iso {
        static var product: Iso<TestProduct<A,B>,Product<A,B>> {
            return Iso<TestProduct<A,B>,Product<A,B>>.init(
                from: { $0.unwrap },
                to: { TestProduct.init($0.first, $0.second) })
        }
    }
    
    enum lens {
        static var first: Lens<TestProduct<A,B>,A> {
            return iso.product..Product.lens.firstSame
        }

        static var second: Lens<TestProduct<A,B>,B> {
            return iso.product..Product.lens.secondSame
        }
    }
}

struct TestCoproduct<A,B>: Equatable, Arbitrary where A: Equatable & Arbitrary, B: Equatable & Arbitrary {
    let unwrap: Coproduct<A,B>
    
    init(_ coproduct: Coproduct<A,B>) {
        self.unwrap = coproduct
    }
    
    static func left(_ value: A) -> TestCoproduct {
        return TestCoproduct.init(.left(value))
    }

    static func right(_ value: B) -> TestCoproduct {
        return TestCoproduct.init(.right(value))
    }

    static func == (lhs: TestCoproduct, rhs: TestCoproduct) -> Bool {
        return lhs.unwrap == rhs.unwrap
    }
    
    static var arbitrary: Gen<TestCoproduct<A, B>> {
        return Bool.arbitrary.flatMap { value in
            Gen.compose {
                value.fold(
                    onTrue: .left($0.generate()),
                    onFalse: .right($0.generate()))
            }
        }
    }
    
    enum iso {
        static var coproduct: Iso<TestCoproduct<A,B>,Coproduct<A,B>> {
            return Iso<TestCoproduct<A,B>,Coproduct<A,B>>.init(
                from: { $0.unwrap },
                to: { $0.fold(onLeft: TestCoproduct.left, onRight: TestCoproduct.right) })
        }
    }
    
    enum prism {
        static var left: Prism<TestCoproduct<A,B>,A> {
            return iso.coproduct..Coproduct.prism.leftSame
        }

        static var right: Prism<TestCoproduct<A,B>,B> {
            return iso.coproduct..Coproduct.prism.rightSame
        }
    }

}

struct Couple<A,B>: Equatable, Arbitrary where A: Equatable & Arbitrary, B: Equatable & Arbitrary {
    var a: A
    var b: B

    static func == (left: Couple, right: Couple) -> Bool {
        return left.a == right.a
            && left.b == right.b
    }

    public static var arbitrary: Gen<Couple<A, B>> {
        return Gen.compose { Couple.init(a: $0.generate(), b: $0.generate()) }
    }

    enum iso {
        static var product: Iso<Couple<A,B>,Product<A,B>> {
            return Iso<Couple<A,B>,Product<A,B>>.init(
                from: { Product.init($0.a, $0.b) },
                to: { Couple.init(a: $0.first, b: $0.second) })
        }
    }

}

struct TestProductOptional<A,B>: Equatable, Arbitrary where A: Equatable & Arbitrary, B: Equatable & Arbitrary {
    let unwrap: Product<A?,B?>

    static func == (lhs: TestProductOptional, rhs: TestProductOptional) -> Bool {
        return lhs.unwrap.first == rhs.unwrap.first
            && lhs.unwrap.second == rhs.unwrap.second
    }

    static var arbitrary: Gen<TestProductOptional<A, B>> {
        return Gen<TestProductOptional<A, B>>.compose {
            TestProductOptional.init(unwrap: Product.init(
                $0.generate(using: OptionalOf<A>.arbitrary.map { $0.getOptional }),
                $0.generate(using: OptionalOf<B>.arbitrary.map { $0.getOptional })))
        }
    }
    
    enum iso {
        static var product: Iso<TestProductOptional<A,B>,Product<A?,B?>> {
            return Iso<TestProductOptional<A,B>,Product<A?,B?>>.init(
                from: { $0.unwrap },
                to: { TestProductOptional.init(unwrap: $0) })
        }
    }
    
    enum lens {
        static var first: Lens<TestProductOptional<A,B>,A?> {
            return iso.product..Product.lens.firstSame
        }

        static var second: Lens<TestProductOptional<A,B>,B?> {
            return iso.product..Product.lens.secondSame
        }
    }
}
