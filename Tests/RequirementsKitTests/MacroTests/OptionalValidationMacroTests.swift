import Testing
@testable import RequirementsKit

struct OptionalMacroContext: Sendable {
  let userId: String?
  let email: String?
  let age: Int?
  let tempData: String?
  let optionalValue: Double?
}

@Suite("Optional Validation Macro Tests")
struct OptionalValidationMacroTests {
  
  // MARK: - #requireNonNil
  
  @Test("#requireNonNil проходит когда значение не nil")
  func testRequireNonNilPasses() {
    let requirement: Requirement<OptionalMacroContext> = #requireNonNil(\.userId)
    
    let context = OptionalMacroContext(
      userId: "user123",
      email: nil,
      age: nil,
      tempData: nil,
      optionalValue: nil
    )
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("#requireNonNil не проходит когда значение nil")
  func testRequireNonNilFails() {
    let requirement: Requirement<OptionalMacroContext> = #requireNonNil(\.userId)
    
    let context = OptionalMacroContext(
      userId: nil,
      email: nil,
      age: nil,
      tempData: nil,
      optionalValue: nil
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - #requireNil
  
  @Test("#requireNil проходит когда значение nil")
  func testRequireNilPasses() {
    let requirement: Requirement<OptionalMacroContext> = #requireNil(\.tempData)
    
    let context = OptionalMacroContext(
      userId: nil,
      email: nil,
      age: nil,
      tempData: nil,
      optionalValue: nil
    )
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("#requireNil не проходит когда значение не nil")
  func testRequireNilFails() {
    let requirement: Requirement<OptionalMacroContext> = #requireNil(\.tempData)
    
    let context = OptionalMacroContext(
      userId: nil,
      email: nil,
      age: nil,
      tempData: "data",
      optionalValue: nil
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  // MARK: - #requireSome с предикатом
  
  @Test("#requireSome проходит когда значение удовлетворяет предикату")
  func testRequireSomePasses() {
    let requirement: Requirement<OptionalMacroContext> = #requireSome(\.age, where: { $0 >= 18 })
    
    let context = OptionalMacroContext(
      userId: nil,
      email: nil,
      age: 25,
      tempData: nil,
      optionalValue: nil
    )
    #expect(requirement.evaluate(context).isConfirmed)
  }
  
  @Test("#requireSome не проходит когда значение nil")
  func testRequireSomeFailsNil() {
    let requirement: Requirement<OptionalMacroContext> = #requireSome(\.age, where: { $0 >= 18 })
    
    let context = OptionalMacroContext(
      userId: nil,
      email: nil,
      age: nil,
      tempData: nil,
      optionalValue: nil
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  @Test("#requireSome не проходит когда предикат не удовлетворен")
  func testRequireSomeFailsPredicate() {
    let requirement: Requirement<OptionalMacroContext> = #requireSome(\.age, where: { $0 >= 18 })
    
    let context = OptionalMacroContext(
      userId: nil,
      email: nil,
      age: 15,
      tempData: nil,
      optionalValue: nil
    )
    #expect(requirement.evaluate(context).isFailed)
  }
  
  @Test("#requireSome работает с Double")
  func testRequireSomeWithDouble() {
    let requirement: Requirement<OptionalMacroContext> = #requireSome(\.optionalValue, where: { $0 > 0.0 })
    
    let validContext = OptionalMacroContext(
      userId: nil,
      email: nil,
      age: nil,
      tempData: nil,
      optionalValue: 10.5
    )
    #expect(requirement.evaluate(validContext).isConfirmed)
    
    let invalidContext = OptionalMacroContext(
      userId: nil,
      email: nil,
      age: nil,
      tempData: nil,
      optionalValue: -5.0
    )
    #expect(requirement.evaluate(invalidContext).isFailed)
  }
  
  @Test("#requireSome работает со String")
  func testRequireSomeWithString() {
    let requirement: Requirement<OptionalMacroContext> = #requireSome(\.email, where: { $0.contains("@") })
    
    let validContext = OptionalMacroContext(
      userId: nil,
      email: "user@example.com",
      age: nil,
      tempData: nil,
      optionalValue: nil
    )
    #expect(requirement.evaluate(validContext).isConfirmed)
    
    let invalidContext = OptionalMacroContext(
      userId: nil,
      email: "notanemail",
      age: nil,
      tempData: nil,
      optionalValue: nil
    )
    #expect(requirement.evaluate(invalidContext).isFailed)
  }
  
  // MARK: - Композиция макросов Optional
  
  @Test("Композиция макросов Optional работает")
  func testComposedOptionalValidation() {
    let requirement: Requirement<OptionalMacroContext> = #all {
      #requireNonNil(\.userId)
      #requireNonNil(\.email)
      #requireNil(\.tempData)
    }
    
    let validContext = OptionalMacroContext(
      userId: "user123",
      email: "user@example.com",
      age: nil,
      tempData: nil,
      optionalValue: nil
    )
    #expect(requirement.evaluate(validContext).isConfirmed)
    
    let invalidContext = OptionalMacroContext(
      userId: nil,
      email: "user@example.com",
      age: nil,
      tempData: nil,
      optionalValue: nil
    )
    #expect(requirement.evaluate(invalidContext).isFailed)
  }
  
  @Test("Комбинация Optional макросов с условиями")
  func testOptionalMacrosWithConditions() {
    struct TestContext: Sendable {
      let premium: Bool
      let userId: String?
    }
    
    let requirement: Requirement<TestContext> = #when(\.premium) {
      #requireNonNil(\.userId)
    }
    
    let premiumContext = TestContext(premium: true, userId: "user123")
    #expect(requirement.evaluate(premiumContext).isConfirmed)
    
    let freeContext = TestContext(premium: false, userId: nil)
    #expect(requirement.evaluate(freeContext).isConfirmed)
    
    let invalidPremiumContext = TestContext(premium: true, userId: nil)
    #expect(requirement.evaluate(invalidPremiumContext).isFailed)
  }
}

