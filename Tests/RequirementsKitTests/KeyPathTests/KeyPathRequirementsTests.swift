import Testing
@testable import RequirementsKit

struct KeyPathContext: Sendable {
  let intValue: Int
  let stringValue: String
  let doubleValue: Double
  let boolValue: Bool
}

@Suite("KeyPath Requirements Tests")
struct KeyPathRequirementsTests {
  
  // MARK: - Equatable
  
  @Test("require с equals работает корректно для Int")
  func testRequireEqualsInt() {
    let requirement = Requirement<KeyPathContext>.require(\.intValue, equals: 42)
    
    let matchingContext = KeyPathContext(intValue: 42, stringValue: "", doubleValue: 0, boolValue: false)
    let nonMatchingContext = KeyPathContext(intValue: 10, stringValue: "", doubleValue: 0, boolValue: false)
    
    #expect(requirement.evaluate(matchingContext).isConfirmed)
    #expect(requirement.evaluate(nonMatchingContext).isFailed)
  }
  
  @Test("require с equals работает корректно для String")
  func testRequireEqualsString() {
    let requirement = Requirement<KeyPathContext>.require(\.stringValue, equals: "test")
    
    let matchingContext = KeyPathContext(intValue: 0, stringValue: "test", doubleValue: 0, boolValue: false)
    let nonMatchingContext = KeyPathContext(intValue: 0, stringValue: "other", doubleValue: 0, boolValue: false)
    
    #expect(requirement.evaluate(matchingContext).isConfirmed)
    #expect(requirement.evaluate(nonMatchingContext).isFailed)
  }
  
  @Test("require с notEquals работает корректно")
  func testRequireNotEquals() {
    let requirement = Requirement<KeyPathContext>.require(\.intValue, notEquals: 0)
    
    let matchingContext = KeyPathContext(intValue: 42, stringValue: "", doubleValue: 0, boolValue: false)
    let nonMatchingContext = KeyPathContext(intValue: 0, stringValue: "", doubleValue: 0, boolValue: false)
    
    #expect(requirement.evaluate(matchingContext).isConfirmed)
    #expect(requirement.evaluate(nonMatchingContext).isFailed)
  }
  
  // MARK: - Comparable
  
  @Test("require с greaterThan работает корректно")
  func testRequireGreaterThan() {
    let requirement = Requirement<KeyPathContext>.require(\.intValue, greaterThan: 10)
    
    let matchingContext = KeyPathContext(intValue: 15, stringValue: "", doubleValue: 0, boolValue: false)
    let nonMatchingContext = KeyPathContext(intValue: 5, stringValue: "", doubleValue: 0, boolValue: false)
    
    #expect(requirement.evaluate(matchingContext).isConfirmed)
    #expect(requirement.evaluate(nonMatchingContext).isFailed)
  }
  
  @Test("require с greaterThanOrEqual работает корректно")
  func testRequireGreaterThanOrEqual() {
    let requirement = Requirement<KeyPathContext>.require(\.intValue, greaterThanOrEqual: 10)
    
    let context1 = KeyPathContext(intValue: 15, stringValue: "", doubleValue: 0, boolValue: false)
    let context2 = KeyPathContext(intValue: 10, stringValue: "", doubleValue: 0, boolValue: false)
    let context3 = KeyPathContext(intValue: 5, stringValue: "", doubleValue: 0, boolValue: false)
    
    #expect(requirement.evaluate(context1).isConfirmed)
    #expect(requirement.evaluate(context2).isConfirmed)
    #expect(requirement.evaluate(context3).isFailed)
  }
  
  @Test("require с lessThan работает корректно")
  func testRequireLessThan() {
    let requirement = Requirement<KeyPathContext>.require(\.intValue, lessThan: 10)
    
    let matchingContext = KeyPathContext(intValue: 5, stringValue: "", doubleValue: 0, boolValue: false)
    let nonMatchingContext = KeyPathContext(intValue: 15, stringValue: "", doubleValue: 0, boolValue: false)
    
    #expect(requirement.evaluate(matchingContext).isConfirmed)
    #expect(requirement.evaluate(nonMatchingContext).isFailed)
  }
  
  @Test("require с lessThanOrEqual работает корректно")
  func testRequireLessThanOrEqual() {
    let requirement = Requirement<KeyPathContext>.require(\.intValue, lessThanOrEqual: 10)
    
    let context1 = KeyPathContext(intValue: 5, stringValue: "", doubleValue: 0, boolValue: false)
    let context2 = KeyPathContext(intValue: 10, stringValue: "", doubleValue: 0, boolValue: false)
    let context3 = KeyPathContext(intValue: 15, stringValue: "", doubleValue: 0, boolValue: false)
    
    #expect(requirement.evaluate(context1).isConfirmed)
    #expect(requirement.evaluate(context2).isConfirmed)
    #expect(requirement.evaluate(context3).isFailed)
  }
  
  // MARK: - Операторы
  
  @Test("Операторы сравнения работают с requireExpression")
  func testComparisonOperators() {
    let greaterRequirement = Requirement<KeyPathContext>.requireExpression(\.intValue > 10)
    let lessRequirement = Requirement<KeyPathContext>.requireExpression(\.intValue < 10)
    let equalsRequirement = Requirement<KeyPathContext>.requireExpression(\.intValue == 10)
    
    let context = KeyPathContext(intValue: 15, stringValue: "", doubleValue: 0, boolValue: false)
    
    #expect(greaterRequirement.evaluate(context).isConfirmed)
    #expect(lessRequirement.evaluate(context).isFailed)
    #expect(equalsRequirement.evaluate(context).isFailed)
  }
  
  @Test("Работает с Double значениями")
  func testDoubleComparison() {
    let requirement = Requirement<KeyPathContext>.requireExpression(\.doubleValue >= 3.14)
    
    let context1 = KeyPathContext(intValue: 0, stringValue: "", doubleValue: 3.14159, boolValue: false)
    let context2 = KeyPathContext(intValue: 0, stringValue: "", doubleValue: 2.0, boolValue: false)
    
    #expect(requirement.evaluate(context1).isConfirmed)
    #expect(requirement.evaluate(context2).isFailed)
  }
}

