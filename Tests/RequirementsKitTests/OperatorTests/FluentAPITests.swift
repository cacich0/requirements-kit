import Testing
@testable import RequirementsKit

struct FluentContext: Sendable {
  let isLoggedIn: Bool
  let isVerified: Bool
  let isAdmin: Bool
  let balance: Int
}

@Suite("Fluent API Tests")
struct FluentAPITests {
  
  // MARK: - .and() метод
  
  @Test(".and() с требованием работает")
  func testAndWithRequirement() {
    let req1 = Requirement<FluentContext>.require(\.isLoggedIn)
    let req2 = Requirement<FluentContext>.require(\.isVerified)
    
    let combined = req1.and(req2)
    
    let both = FluentContext(isLoggedIn: true, isVerified: true, isAdmin: false, balance: 0)
    let one = FluentContext(isLoggedIn: true, isVerified: false, isAdmin: false, balance: 0)
    
    #expect(combined.evaluate(both).isConfirmed)
    #expect(combined.evaluate(one).isFailed)
  }
  
  @Test(".and() с KeyPath работает")
  func testAndWithKeyPath() {
    let combined = Requirement<FluentContext>
      .require(\.isLoggedIn)
      .and(\.isVerified)
    
    let both = FluentContext(isLoggedIn: true, isVerified: true, isAdmin: false, balance: 0)
    let one = FluentContext(isLoggedIn: true, isVerified: false, isAdmin: false, balance: 0)
    
    #expect(combined.evaluate(both).isConfirmed)
    #expect(combined.evaluate(one).isFailed)
  }
  
  // MARK: - .or() метод
  
  @Test(".or() с требованием работает")
  func testOrWithRequirement() {
    let req1 = Requirement<FluentContext>.require(\.isLoggedIn)
    let req2 = Requirement<FluentContext>.require(\.isAdmin)
    
    let combined = req1.or(req2)
    
    let neither = FluentContext(isLoggedIn: false, isVerified: false, isAdmin: false, balance: 0)
    let one = FluentContext(isLoggedIn: false, isVerified: false, isAdmin: true, balance: 0)
    
    #expect(combined.evaluate(neither).isFailed)
    #expect(combined.evaluate(one).isConfirmed)
  }
  
  @Test(".or() с KeyPath работает")
  func testOrWithKeyPath() {
    let combined = Requirement<FluentContext>
      .require(\.isLoggedIn)
      .or(\.isAdmin)
    
    let admin = FluentContext(isLoggedIn: false, isVerified: false, isAdmin: true, balance: 0)
    #expect(combined.evaluate(admin).isConfirmed)
  }
  
  // MARK: - .check() метод
  
  @Test(".check() возвращает Bool")
  func testCheck() {
    let requirement = Requirement<FluentContext>.require(\.isLoggedIn)
    
    let loggedIn = FluentContext(isLoggedIn: true, isVerified: false, isAdmin: false, balance: 0)
    let loggedOut = FluentContext(isLoggedIn: false, isVerified: false, isAdmin: false, balance: 0)
    
    #expect(requirement.check(loggedIn) == true)
    #expect(requirement.check(loggedOut) == false)
  }
  
  // MARK: - .require() метод (throws)
  
  @Test(".require() не выбрасывает ошибку при confirmed")
  func testRequireNoThrow() throws {
    let requirement = Requirement<FluentContext>.require(\.isLoggedIn)
    let context = FluentContext(isLoggedIn: true, isVerified: false, isAdmin: false, balance: 0)
    
    #expect(throws: Never.self) {
      try requirement.require(context)
    }
  }
  
  @Test(".require() выбрасывает RequirementError при failed")
  func testRequireThrows() {
    let requirement = Requirement<FluentContext>.require(\.isLoggedIn)
    let context = FluentContext(isLoggedIn: false, isVerified: false, isAdmin: false, balance: 0)
    
    #expect(throws: RequirementError.self) {
      try requirement.require(context)
    }
  }
  
  // MARK: - Requirement.predicate()
  
  @Test("Requirement.predicate() создает требование из предиката")
  func testPredicate() {
    let requirement = Requirement<FluentContext>.predicate { $0.balance > 100 }
    
    let rich = FluentContext(isLoggedIn: true, isVerified: false, isAdmin: false, balance: 150)
    let poor = FluentContext(isLoggedIn: true, isVerified: false, isAdmin: false, balance: 50)
    
    #expect(requirement.evaluate(rich).isConfirmed)
    #expect(requirement.evaluate(poor).isFailed)
  }
  
  // MARK: - RequirementChain
  
  @Test("RequirementChain builder работает")
  func testRequirementChain() {
    var chain = RequirementChain<FluentContext>()
    chain.add(Requirement.require(\.isLoggedIn))
    chain.add(\.isVerified)
    
    let allRequirement = chain.buildAll()
    
    let both = FluentContext(isLoggedIn: true, isVerified: true, isAdmin: false, balance: 0)
    let one = FluentContext(isLoggedIn: true, isVerified: false, isAdmin: false, balance: 0)
    
    #expect(allRequirement.evaluate(both).isConfirmed)
    #expect(allRequirement.evaluate(one).isFailed)
  }
  
  @Test("RequirementChain.buildAny() работает")
  func testRequirementChainBuildAny() {
    var chain = RequirementChain<FluentContext>()
    chain.add(\.isLoggedIn)
    chain.add(\.isAdmin)
    
    let anyRequirement = chain.buildAny()
    
    let neither = FluentContext(isLoggedIn: false, isVerified: false, isAdmin: false, balance: 0)
    let one = FluentContext(isLoggedIn: false, isVerified: false, isAdmin: true, balance: 0)
    
    #expect(anyRequirement.evaluate(neither).isFailed)
    #expect(anyRequirement.evaluate(one).isConfirmed)
  }
  
  // MARK: - Цепочки методов
  
  @Test("цепочка fluent методов работает")
  func testFluentChain() {
    let requirement = Requirement<FluentContext>
      .require(\.isLoggedIn)
      .and(\.isVerified)
      .or(\.isAdmin)
      .because("Access denied")
    
    // isLoggedIn && isVerified -> confirmed
    let verified = FluentContext(isLoggedIn: true, isVerified: true, isAdmin: false, balance: 0)
    #expect(requirement.evaluate(verified).isConfirmed)
    
    // isAdmin -> confirmed (через or)
    let admin = FluentContext(isLoggedIn: false, isVerified: false, isAdmin: true, balance: 0)
    #expect(requirement.evaluate(admin).isConfirmed)
    
    // Ничего -> failed с кастомным сообщением
    let none = FluentContext(isLoggedIn: false, isVerified: false, isAdmin: false, balance: 0)
    let result = requirement.evaluate(none)
    #expect(result.isFailed)
    #expect(result.reason?.message == "Access denied")
  }
}

