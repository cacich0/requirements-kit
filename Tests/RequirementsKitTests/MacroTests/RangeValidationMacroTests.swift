import Testing
@testable import RequirementsKit

struct RangeMacroContext: Sendable {
  let age: Int
  let temperature: Double
  let score: Int
  let amount: Double
  let rating: Int
}

@Suite("Range Validation Macro Tests")
struct RangeValidationMacroTests {
  
  // MARK: - #requireInRange с Int
  
  @Test("#requireInRange проходит когда значение в диапазоне (Int)")
  func testRequireInRangeIntPasses() {
    let requirement: Requirement<RangeMacroContext> = #requireInRange(\.age, 18...120)
    
    let context = RangeMacroContext(
      age: 25,
      temperature: 0.0,
      score: 0,
      amount: 0.0,
      rating: 0
    )
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("#requireInRange не проходит когда значение ниже диапазона (Int)")
  func testRequireInRangeIntFailsLow() {
    let requirement: Requirement<RangeMacroContext> = #requireInRange(\.age, 18...120)
    
    let context = RangeMacroContext(
      age: 15,
      temperature: 0.0,
      score: 0,
      amount: 0.0,
      rating: 0
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  @Test("#requireInRange не проходит когда значение выше диапазона (Int)")
  func testRequireInRangeIntFailsHigh() {
    let requirement: Requirement<RangeMacroContext> = #requireInRange(\.age, 18...120)
    
    let context = RangeMacroContext(
      age: 150,
      temperature: 0.0,
      score: 0,
      amount: 0.0,
      rating: 0
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  @Test("#requireInRange работает с граничными значениями (Int)")
  func testRequireInRangeIntBoundary() {
    let requirement: Requirement<RangeMacroContext> = #requireInRange(\.age, 18...120)
    
    let contextMin = RangeMacroContext(
      age: 18,
      temperature: 0.0,
      score: 0,
      amount: 0.0,
      rating: 0
    )
    #expect(requirement.evaluate(contextMin).isConfirmed)
    
    let contextMax = RangeMacroContext(
      age: 120,
      temperature: 0.0,
      score: 0,
      amount: 0.0,
      rating: 0
    )
    #expect(requirement.evaluate(contextMax).isConfirmed)
  }
  
  // MARK: - #requireInRange с Double
  
  @Test("#requireInRange проходит когда значение в диапазоне (Double)")
  func testRequireInRangeDoublePasses() {
    let requirement: Requirement<RangeMacroContext> = #requireInRange(\.temperature, -40.0...50.0)
    
    let context = RangeMacroContext(
      age: 0,
      temperature: 20.5,
      score: 0,
      amount: 0.0,
      rating: 0
    )
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("#requireInRange не проходит когда значение вне диапазона (Double)")
  func testRequireInRangeDoubleFails() {
    let requirement: Requirement<RangeMacroContext> = #requireInRange(\.temperature, -40.0...50.0)
    
    let context = RangeMacroContext(
      age: 0,
      temperature: 60.0,
      score: 0,
      amount: 0.0,
      rating: 0
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - #requireBetween с Int
  
  @Test("#requireBetween проходит когда значение между min и max (Int)")
  func testRequireBetweenIntPasses() {
    let requirement: Requirement<RangeMacroContext> = #requireBetween(\.score, min: 0, max: 100)
    
    let context = RangeMacroContext(
      age: 0,
      temperature: 0.0,
      score: 75,
      amount: 0.0,
      rating: 0
    )
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("#requireBetween не проходит когда значение ниже min (Int)")
  func testRequireBetweenIntFailsLow() {
    let requirement: Requirement<RangeMacroContext> = #requireBetween(\.score, min: 0, max: 100)
    
    let context = RangeMacroContext(
      age: 0,
      temperature: 0.0,
      score: -10,
      amount: 0.0,
      rating: 0
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  @Test("#requireBetween не проходит когда значение выше max (Int)")
  func testRequireBetweenIntFailsHigh() {
    let requirement: Requirement<RangeMacroContext> = #requireBetween(\.score, min: 0, max: 100)
    
    let context = RangeMacroContext(
      age: 0,
      temperature: 0.0,
      score: 150,
      amount: 0.0,
      rating: 0
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  @Test("#requireBetween работает с граничными значениями (Int)")
  func testRequireBetweenIntBoundary() {
    let requirement: Requirement<RangeMacroContext> = #requireBetween(\.score, min: 0, max: 100)
    
    let contextMin = RangeMacroContext(
      age: 0,
      temperature: 0.0,
      score: 0,
      amount: 0.0,
      rating: 0
    )
    #expect(requirement.evaluate(contextMin).isConfirmed)
    
    let contextMax = RangeMacroContext(
      age: 0,
      temperature: 0.0,
      score: 100,
      amount: 0.0,
      rating: 0
    )
    #expect(requirement.evaluate(contextMax).isConfirmed)
  }
  
  // MARK: - #requireBetween с Double
  
  @Test("#requireBetween проходит когда значение между min и max (Double)")
  func testRequireBetweenDoublePasses() {
    let requirement: Requirement<RangeMacroContext> = #requireBetween(\.amount, min: 10.0, max: 1000.0)
    
    let context = RangeMacroContext(
      age: 0,
      temperature: 0.0,
      score: 0,
      amount: 500.5,
      rating: 0
    )
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("#requireBetween не проходит когда значение вне диапазона (Double)")
  func testRequireBetweenDoubleFails() {
    let requirement: Requirement<RangeMacroContext> = #requireBetween(\.amount, min: 10.0, max: 1000.0)
    
    let context = RangeMacroContext(
      age: 0,
      temperature: 0.0,
      score: 0,
      amount: 5.0,
      rating: 0
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - Композиция макросов диапазонов
  
  @Test("Композиция макросов диапазонов работает")
  func testComposedRangeValidation() {
    let requirement: Requirement<RangeMacroContext> = #all {
      #requireInRange(\.age, 18...120)
      #requireBetween(\.score, min: 0, max: 100)
      #requireInRange(\.rating, 1...5)
    }
    
    let validContext = RangeMacroContext(
      age: 25,
      temperature: 0.0,
      score: 85,
      amount: 0.0,
      rating: 4
    )
    #expect(requirement.evaluate(validContext).isConfirmed)
    
    let invalidContext = RangeMacroContext(
      age: 15,
      temperature: 0.0,
      score: 85,
      amount: 0.0,
      rating: 4
    )
    #expect(requirement.evaluate(invalidContext).isFailed)
  }
  
  @Test("Комбинация макросов диапазонов с условиями")
  func testRangeMacrosWithConditions() {
    struct TestContext: Sendable {
      let isPremium: Bool
      let discount: Int
    }
    
    let requirement: Requirement<TestContext> = #when(\.isPremium) {
      #requireBetween(\.discount, min: 10, max: 50)
    }
    
    let premiumContext = TestContext(isPremium: true, discount: 20)
    #expect(requirement.evaluate(premiumContext).isConfirmed)
    
    let freeContext = TestContext(isPremium: false, discount: 0)
    #expect(requirement.evaluate(freeContext).isConfirmed)
    
    let invalidPremiumContext = TestContext(isPremium: true, discount: 5)
    #expect(requirement.evaluate(invalidPremiumContext).isFailed)
  }
  
  // MARK: - Комбинация разных типов макросов
  
  @Test("Комбинация макросов диапазонов и строк")
  func testRangeMacrosWithStringMacros() {
    struct TestContext: Sendable {
      let age: Int
      let username: String
    }
    
    let requirement: Requirement<TestContext> = #all {
      #requireInRange(\.age, 13...100)
      #requireMinLength(\.username, 3)
      #requireMaxLength(\.username, 20)
    }
    
    let validContext = TestContext(age: 25, username: "john")
    #expect(requirement.evaluate(validContext).isConfirmed)
    
    let invalidAge = TestContext(age: 10, username: "john")
    #expect(requirement.evaluate(invalidAge).isFailed)
    
    let invalidUsername = TestContext(age: 25, username: "jo")
    #expect(requirement.evaluate(invalidUsername).isFailed)
  }
}

