import Testing
@testable import RequirementsKit

struct TestContext: Sendable {
  let isLoggedIn: Bool
  let balance: Int
  let isPremium: Bool
}

@Suite("Requirement Tests")
struct RequirementTests {
  
  @Test("Requirement.always всегда возвращает confirmed")
  func testAlwaysRequirement() {
    let requirement = Requirement<TestContext>.always
    let context = TestContext(isLoggedIn: false, balance: 0, isPremium: false)
    
    let result = requirement.evaluate(context)
    #expect(result.isConfirmed)
  }
  
  @Test("Requirement.never всегда возвращает failed")
  func testNeverRequirement() {
    let reason = Reason(message: "Never allowed")
    let requirement = Requirement<TestContext>.never(reason: reason)
    let context = TestContext(isLoggedIn: true, balance: 100, isPremium: true)
    
    let result = requirement.evaluate(context)
    #expect(result.isFailed)
    #expect(result.reason == reason)
  }
  
  @Test("Requirement с KeyPath к Bool работает корректно")
  func testRequireKeyPathBool() {
    let requirement = Requirement<TestContext>.require(\.isLoggedIn)
    
    let loggedInContext = TestContext(isLoggedIn: true, balance: 0, isPremium: false)
    let loggedOutContext = TestContext(isLoggedIn: false, balance: 0, isPremium: false)
    
    #expect(requirement.evaluate(loggedInContext).isConfirmed)
    #expect(requirement.evaluate(loggedOutContext).isFailed)
  }
  
  @Test("Requirement с выражением работает корректно")
  func testRequireExpression() {
    let requirement = Requirement<TestContext>.requireExpression { $0.balance > 100 }
    
    let richContext = TestContext(isLoggedIn: true, balance: 150, isPremium: false)
    let poorContext = TestContext(isLoggedIn: true, balance: 50, isPremium: false)
    
    #expect(requirement.evaluate(richContext).isConfirmed)
    #expect(requirement.evaluate(poorContext).isFailed)
  }
  
  @Test("because() метод устанавливает кастомную причину")
  func testBecauseMethod() {
    let requirement = Requirement<TestContext>
      .require(\.isLoggedIn)
      .because(code: "auth_required", message: "Требуется авторизация")
    
    let context = TestContext(isLoggedIn: false, balance: 0, isPremium: false)
    let result = requirement.evaluate(context)
    
    #expect(result.isFailed)
    #expect(result.reason?.code == "auth_required")
    #expect(result.reason?.message == "Требуется авторизация")
  }
  
  @Test("because() с одним параметром работает корректно")
  func testBecauseShorthand() {
    let requirement = Requirement<TestContext>
      .require(\.isPremium)
      .because("Требуется Premium подписка")
    
    let context = TestContext(isLoggedIn: true, balance: 100, isPremium: false)
    let result = requirement.evaluate(context)
    
    #expect(result.isFailed)
    #expect(result.reason?.message == "Требуется Premium подписка")
  }
  
  @Test("allFailures возвращает причины отказа")
  func testAllFailures() {
    let requirement = Requirement<TestContext>
      .require(\.isLoggedIn)
      .because("Not logged in")
    
    let context = TestContext(isLoggedIn: false, balance: 0, isPremium: false)
    let failures = requirement.allFailures(for: context)
    
    #expect(failures.count == 1)
    #expect(failures[0].message == "Not logged in")
  }
}
