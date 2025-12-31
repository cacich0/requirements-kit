import Testing
@testable import RequirementsKit

struct RangeContext: Sendable {
  let age: Int
  let balance: Double
  let score: Int
  let optionalValue: Int?
}

@Suite("Range Validation Tests")
struct RangeValidationTests {
  
  // MARK: - requireInRange (ClosedRange)
  
  @Test("requireInRange (ClosedRange) проходит если значение в диапазоне")
  func testRequireInClosedRangePasses() {
    let requirement = Requirement<RangeContext>.requireInRange(\.age, 18...65)
    
    let context = RangeContext(age: 25, balance: 0, score: 0, optionalValue: nil)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireInRange (ClosedRange) проходит на границах")
  func testRequireInClosedRangeBoundaries() {
    let requirement = Requirement<RangeContext>.requireInRange(\.age, 18...65)
    
    let minContext = RangeContext(age: 18, balance: 0, score: 0, optionalValue: nil)
    let maxContext = RangeContext(age: 65, balance: 0, score: 0, optionalValue: nil)
    
    #expect(requirement.evaluate(minContext).isConfirmed)
    #expect(requirement.evaluate(maxContext).isConfirmed)
  }
  
  @Test("requireInRange (ClosedRange) не проходит если значение вне диапазона")
  func testRequireInClosedRangeFails() {
    let requirement = Requirement<RangeContext>.requireInRange(\.age, 18...65)
    
    let tooYoung = RangeContext(age: 15, balance: 0, score: 0, optionalValue: nil)
    let tooOld = RangeContext(age: 70, balance: 0, score: 0, optionalValue: nil)
    
    #expect(requirement.evaluate(tooYoung).isFailed)
    #expect(requirement.evaluate(tooOld).isFailed)
  }
  
  // MARK: - requireInRange (Range)
  
  @Test("requireInRange (Range) проходит если значение в диапазоне")
  func testRequireInRangePasses() {
    let requirement = Requirement<RangeContext>.requireInRange(\.age, 18..<65)
    
    let context = RangeContext(age: 25, balance: 0, score: 0, optionalValue: nil)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireInRange (Range) не включает верхнюю границу")
  func testRequireInRangeExcludesUpperBound() {
    let requirement = Requirement<RangeContext>.requireInRange(\.age, 18..<65)
    
    let atLowerBound = RangeContext(age: 18, balance: 0, score: 0, optionalValue: nil)
    let atUpperBound = RangeContext(age: 65, balance: 0, score: 0, optionalValue: nil)
    
    #expect(requirement.evaluate(atLowerBound).isConfirmed)
    #expect(requirement.evaluate(atUpperBound).isFailed) // 65 не включена
  }
  
  // MARK: - requirePositive
  
  @Test("requirePositive проходит для положительного значения")
  func testRequirePositivePasses() {
    let requirement = Requirement<RangeContext>.requirePositive(\.score)
    
    let context = RangeContext(age: 0, balance: 0, score: 5, optionalValue: nil)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requirePositive не проходит для нуля")
  func testRequirePositiveFailsZero() {
    let requirement = Requirement<RangeContext>.requirePositive(\.score)
    
    let context = RangeContext(age: 0, balance: 0, score: 0, optionalValue: nil)
    #expect(requirement.evaluate(context).isFailed)
  }
  
  @Test("requirePositive не проходит для отрицательного значения")
  func testRequirePositiveFailsNegative() {
    let requirement = Requirement<RangeContext>.requirePositive(\.score)
    
    let context = RangeContext(age: 0, balance: 0, score: -5, optionalValue: nil)
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - requireNonNegative
  
  @Test("requireNonNegative проходит для положительного значения")
  func testRequireNonNegativePassesPositive() {
    let requirement = Requirement<RangeContext>.requireNonNegative(\.score)
    
    let context = RangeContext(age: 0, balance: 0, score: 5, optionalValue: nil)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireNonNegative проходит для нуля")
  func testRequireNonNegativePassesZero() {
    let requirement = Requirement<RangeContext>.requireNonNegative(\.score)
    
    let context = RangeContext(age: 0, balance: 0, score: 0, optionalValue: nil)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireNonNegative не проходит для отрицательного значения")
  func testRequireNonNegativeFailsNegative() {
    let requirement = Requirement<RangeContext>.requireNonNegative(\.score)
    
    let context = RangeContext(age: 0, balance: 0, score: -1, optionalValue: nil)
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - requireNegative
  
  @Test("requireNegative проходит для отрицательного значения")
  func testRequireNegativePasses() {
    let requirement = Requirement<RangeContext>.requireNegative(\.score)
    
    let context = RangeContext(age: 0, balance: 0, score: -5, optionalValue: nil)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireNegative не проходит для нуля")
  func testRequireNegativeFailsZero() {
    let requirement = Requirement<RangeContext>.requireNegative(\.score)
    
    let context = RangeContext(age: 0, balance: 0, score: 0, optionalValue: nil)
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - requireMin
  
  @Test("requireMin проходит если значение >= min")
  func testRequireMinPasses() {
    let requirement = Requirement<RangeContext>.requireMin(\.age, 18)
    
    let context = RangeContext(age: 25, balance: 0, score: 0, optionalValue: nil)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireMin проходит при точном равенстве")
  func testRequireMinPassesEqual() {
    let requirement = Requirement<RangeContext>.requireMin(\.age, 18)
    
    let context = RangeContext(age: 18, balance: 0, score: 0, optionalValue: nil)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireMin не проходит если значение < min")
  func testRequireMinFails() {
    let requirement = Requirement<RangeContext>.requireMin(\.age, 18)
    
    let context = RangeContext(age: 15, balance: 0, score: 0, optionalValue: nil)
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - requireMax
  
  @Test("requireMax проходит если значение <= max")
  func testRequireMaxPasses() {
    let requirement = Requirement<RangeContext>.requireMax(\.age, 65)
    
    let context = RangeContext(age: 50, balance: 0, score: 0, optionalValue: nil)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireMax не проходит если значение > max")
  func testRequireMaxFails() {
    let requirement = Requirement<RangeContext>.requireMax(\.age, 65)
    
    let context = RangeContext(age: 70, balance: 0, score: 0, optionalValue: nil)
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - requireWhere (custom predicate)
  
  @Test("requireWhere проходит если предикат возвращает true")
  func testRequireWherePasses() {
    let requirement = Requirement<RangeContext>.requireWhere(\.age) { $0 % 2 == 0 }
    
    let context = RangeContext(age: 20, balance: 0, score: 0, optionalValue: nil)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireWhere не проходит если предикат возвращает false")
  func testRequireWhereFails() {
    let requirement = Requirement<RangeContext>.requireWhere(\.age) { $0 % 2 == 0 }
    
    let context = RangeContext(age: 21, balance: 0, score: 0, optionalValue: nil)
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - requireNotNil
  
  @Test("requireNotNil проходит для non-nil значения")
  func testRequireNotNilPasses() {
    let requirement = Requirement<RangeContext>.requireNotNil(\.optionalValue)
    
    let context = RangeContext(age: 0, balance: 0, score: 0, optionalValue: 42)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireNotNil не проходит для nil значения")
  func testRequireNotNilFails() {
    let requirement = Requirement<RangeContext>.requireNotNil(\.optionalValue)
    
    let context = RangeContext(age: 0, balance: 0, score: 0, optionalValue: nil)
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - requireNil
  
  @Test("requireNil проходит для nil значения")
  func testRequireNilPasses() {
    let requirement = Requirement<RangeContext>.requireNil(\.optionalValue)
    
    let context = RangeContext(age: 0, balance: 0, score: 0, optionalValue: nil)
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("requireNil не проходит для non-nil значения")
  func testRequireNilFails() {
    let requirement = Requirement<RangeContext>.requireNil(\.optionalValue)
    
    let context = RangeContext(age: 0, balance: 0, score: 0, optionalValue: 42)
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - Double значения
  
  @Test("requireInRange работает с Double")
  func testRequireInRangeDouble() {
    let requirement = Requirement<RangeContext>.requireInRange(\.balance, 0.0...1000.0)
    
    let validContext = RangeContext(age: 0, balance: 500.0, score: 0, optionalValue: nil)
    let invalidContext = RangeContext(age: 0, balance: 1500.0, score: 0, optionalValue: nil)
    
    #expect(requirement.evaluate(validContext).isConfirmed)
    #expect(requirement.evaluate(invalidContext).isFailed)
  }
}

