import Testing
@testable import RequirementsKit

struct AsyncTestContext: Sendable {
  let isLoggedIn: Bool
  let balance: Int
  let isPremium: Bool
}

@Suite("AsyncRequirement Tests")
struct AsyncRequirementTests {
  
  // MARK: - Фабричные методы
  
  @Test("AsyncRequirement.always всегда возвращает confirmed")
  func testAlwaysRequirement() async throws {
    let requirement = AsyncRequirement<AsyncTestContext>.always
    let context = AsyncTestContext(isLoggedIn: false, balance: 0, isPremium: false)
    
    let result = try await requirement.evaluate(context)
    #expect(result.isConfirmed)
  }
  
  @Test("AsyncRequirement.never всегда возвращает failed")
  func testNeverRequirement() async throws {
    let requirement = AsyncRequirement<AsyncTestContext>.never
    let context = AsyncTestContext(isLoggedIn: true, balance: 100, isPremium: true)
    
    let result = try await requirement.evaluate(context)
    #expect(result.isFailed)
    #expect(result.reason?.code == "never")
  }
  
  // MARK: - Конвертация из синхронного
  
  @Test("AsyncRequirement.from() конвертирует синхронное требование")
  func testFromSyncRequirement() async throws {
    let syncRequirement = Requirement<AsyncTestContext>.require(\.isLoggedIn)
    let asyncRequirement = AsyncRequirement.from(syncRequirement)
    
    let loggedInContext = AsyncTestContext(isLoggedIn: true, balance: 0, isPremium: false)
    let loggedOutContext = AsyncTestContext(isLoggedIn: false, balance: 0, isPremium: false)
    
    let result1 = try await asyncRequirement.evaluate(loggedInContext)
    let result2 = try await asyncRequirement.evaluate(loggedOutContext)
    
    #expect(result1.isConfirmed)
    #expect(result2.isFailed)
  }
  
  // MARK: - Кастомные async требования
  
  @available(iOS 16.0, *)
  @Test("AsyncRequirement с кастомным evaluator работает")
  func testCustomAsyncEvaluator() async throws {
    let requirement = AsyncRequirement<AsyncTestContext> { context in
      // Симуляция async операции
      try await Task.sleep(for: .milliseconds(10))
      return context.balance > 100 ? .confirmed : .failed(reason: Reason(message: "Insufficient balance"))
    }
    
    let richContext = AsyncTestContext(isLoggedIn: true, balance: 150, isPremium: false)
    let poorContext = AsyncTestContext(isLoggedIn: true, balance: 50, isPremium: false)
    
    let result1 = try await requirement.evaluate(richContext)
    let result2 = try await requirement.evaluate(poorContext)
    
    #expect(result1.isConfirmed)
    #expect(result2.isFailed)
  }
  
  // MARK: - because()
  
  @Test("because() устанавливает кастомную причину для async требования")
  func testBecause() async throws {
    let requirement = AsyncRequirement<AsyncTestContext>.never
      .because(code: "custom_code", message: "Custom message")
    
    let context = AsyncTestContext(isLoggedIn: true, balance: 100, isPremium: true)
    let result = try await requirement.evaluate(context)
    
    #expect(result.isFailed)
    #expect(result.reason?.code == "custom_code")
    #expect(result.reason?.message == "Custom message")
  }
  
  @Test("because() с Reason работает корректно")
  func testBecauseWithReason() async throws {
    let reason = Reason(code: "test", message: "Test reason")
    let requirement = AsyncRequirement<AsyncTestContext>.never.because(reason)
    
    let context = AsyncTestContext(isLoggedIn: true, balance: 100, isPremium: true)
    let result = try await requirement.evaluate(context)
    
    #expect(result.reason?.code == "test")
  }
  
  // MARK: - Композиция: all
  
  @Test("AsyncRequirement.all возвращает confirmed когда все требования выполнены")
  func testAllConfirmed() async throws {
    let req1 = AsyncRequirement<AsyncTestContext>.from(Requirement.require(\.isLoggedIn))
    let req2 = AsyncRequirement<AsyncTestContext>.from(Requirement.require(\.isPremium))
    
    let combined = AsyncRequirement.all([req1, req2])
    let context = AsyncTestContext(isLoggedIn: true, balance: 0, isPremium: true)
    
    let result = try await combined.evaluate(context)
    #expect(result.isConfirmed)
  }
  
  @Test("AsyncRequirement.all возвращает failed если одно требование не выполнено")
  func testAllFailed() async throws {
    let req1 = AsyncRequirement<AsyncTestContext>.from(Requirement.require(\.isLoggedIn))
    let req2 = AsyncRequirement<AsyncTestContext>.from(Requirement.require(\.isPremium))
    
    let combined = AsyncRequirement.all([req1, req2])
    let context = AsyncTestContext(isLoggedIn: true, balance: 0, isPremium: false)
    
    let result = try await combined.evaluate(context)
    #expect(result.isFailed)
  }
  
  // MARK: - Композиция: any
  
  @Test("AsyncRequirement.any возвращает confirmed если хотя бы одно требование выполнено")
  func testAnyConfirmed() async throws {
    let req1 = AsyncRequirement<AsyncTestContext>.from(Requirement.require(\.isLoggedIn))
    let req2 = AsyncRequirement<AsyncTestContext>.from(Requirement.require(\.isPremium))
    
    let combined = AsyncRequirement.any([req1, req2])
    let context = AsyncTestContext(isLoggedIn: true, balance: 0, isPremium: false)
    
    let result = try await combined.evaluate(context)
    #expect(result.isConfirmed)
  }
  
  @Test("AsyncRequirement.any возвращает failed если ни одно требование не выполнено")
  func testAnyFailed() async throws {
    let req1 = AsyncRequirement<AsyncTestContext>.from(Requirement.require(\.isLoggedIn))
    let req2 = AsyncRequirement<AsyncTestContext>.from(Requirement.require(\.isPremium))
    
    let combined = AsyncRequirement.any([req1, req2])
    let context = AsyncTestContext(isLoggedIn: false, balance: 0, isPremium: false)
    
    let result = try await combined.evaluate(context)
    #expect(result.isFailed)
  }
  
  // MARK: - Композиция: not
  
  @Test("AsyncRequirement.not инвертирует результат")
  func testNot() async throws {
    let requirement = AsyncRequirement<AsyncTestContext>.from(Requirement.require(\.isLoggedIn))
    let inverted = AsyncRequirement.not(requirement)
    
    let loggedInContext = AsyncTestContext(isLoggedIn: true, balance: 0, isPremium: false)
    let loggedOutContext = AsyncTestContext(isLoggedIn: false, balance: 0, isPremium: false)
    
    let result1 = try await inverted.evaluate(loggedInContext)
    let result2 = try await inverted.evaluate(loggedOutContext)
    
    #expect(result1.isFailed)
    #expect(result2.isConfirmed)
  }
  
  @Test(".not() fluent метод работает")
  func testNotFluent() async throws {
    let requirement = AsyncRequirement<AsyncTestContext>.from(Requirement.require(\.isLoggedIn)).not()
    
    let context = AsyncTestContext(isLoggedIn: false, balance: 0, isPremium: false)
    let result = try await requirement.evaluate(context)
    
    #expect(result.isConfirmed)
  }
  
  // MARK: - Concurrent композиция
  
  @available(iOS 16.0, *)
  @Test("AsyncRequirement.allConcurrent выполняет проверки параллельно")
  func testAllConcurrent() async throws {
    let req1 = AsyncRequirement<AsyncTestContext> { _ in
      try await Task.sleep(for: .milliseconds(10))
      return .confirmed
    }
    let req2 = AsyncRequirement<AsyncTestContext> { _ in
      try await Task.sleep(for: .milliseconds(10))
      return .confirmed
    }
    
    let combined = AsyncRequirement.allConcurrent([req1, req2])
    let context = AsyncTestContext(isLoggedIn: true, balance: 0, isPremium: true)
    
    let result = try await combined.evaluate(context)
    #expect(result.isConfirmed)
  }
  
  @available(iOS 16.0, *)
  @Test("AsyncRequirement.anyConcurrent возвращает первый успешный")
  func testAnyConcurrent() async throws {
    let req1 = AsyncRequirement<AsyncTestContext> { _ in
      try await Task.sleep(for: .milliseconds(50))
      return .confirmed
    }
    let req2 = AsyncRequirement<AsyncTestContext>.never
    
    let combined = AsyncRequirement.anyConcurrent([req1, req2])
    let context = AsyncTestContext(isLoggedIn: true, balance: 0, isPremium: true)
    
    let result = try await combined.evaluate(context)
    #expect(result.isConfirmed)
  }
}

