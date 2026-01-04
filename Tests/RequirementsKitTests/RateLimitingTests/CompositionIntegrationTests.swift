import Testing
import Foundation
@testable import RequirementsKit

struct TestUser: Sendable {
  let isLoggedIn: Bool
  let isPremium: Bool
  let balance: Double
}

// Thread-safe counter for composition tests
final class CompositionCounter: @unchecked Sendable {
  private var value = 0
  private let lock = NSLock()
  
  func increment() {
    lock.lock()
    value += 1
    lock.unlock()
  }
  
  var count: Int {
    lock.lock()
    defer { lock.unlock() }
    return value
  }
}

@Suite("Rate Limiting Composition Integration Tests")
struct CompositionIntegrationTests {
  
  // MARK: - Sync Composition Tests
  
  @Test("Rate limiting works inside #all composition")
  func rateLimitingInsideAllComposition() {
    let loginCounter = CompositionCounter()
    let premiumCounter = CompositionCounter()
    
    let requirement = Requirement<TestUser>.all {
      Requirement<TestUser> { user in
        loginCounter.increment()
        return user.isLoggedIn ? .confirmed : .failed(reason: Reason(message: "Not logged in"))
      }
      .rateLimit(maxCalls: 2, timeWindow: 1.0)
      
      Requirement<TestUser> { user in
        premiumCounter.increment()
        return user.isPremium ? .confirmed : .failed(reason: Reason(message: "Not premium"))
      }
    }
    
    let user = TestUser(isLoggedIn: true, isPremium: true, balance: 100)
    
    // Первые два вызова должны пройти
    let result1 = requirement.evaluate(user)
    let result2 = requirement.evaluate(user)
    
    #expect(result1.isConfirmed)
    #expect(result2.isConfirmed)
    #expect(loginCounter.count == 2)
    #expect(premiumCounter.count == 2)
    
    // Третий вызов должен быть заблокирован rate limiting
    let result3 = requirement.evaluate(user)
    
    #expect(result3.isFailed)
    #expect(loginCounter.count == 2) // Login не должен вызваться (rate limit)
    #expect(premiumCounter.count == 3) // Premium продолжает выполняться (all проверяет все требования)
  }
  
  @Test("Throttling works inside #all composition")
  func throttlingInsideAllComposition() {
    let counter = CompositionCounter()
    
    let requirement = Requirement<TestUser>.all {
      Requirement<TestUser>.require(\.isLoggedIn)
      
      Requirement<TestUser> { user in
        counter.increment()
        return user.isPremium ? .confirmed : .failed(reason: Reason(message: "Not premium"))
      }
      .throttle(interval: 0.5, behavior: .returnCached)
    }
    
    let user = TestUser(isLoggedIn: true, isPremium: true, balance: 100)
    
    let result1 = requirement.evaluate(user)
    let result2 = requirement.evaluate(user) // Должен вернуть кэш
    
    #expect(result1.isConfirmed)
    #expect(result2.isConfirmed)
    #expect(counter.count == 1) // Только один реальный вызов
  }
  
  @Test("Multiple rate limited requirements in composition")
  func multipleRateLimitedInComposition() {
    let counter1 = CompositionCounter()
    let counter2 = CompositionCounter()
    
    let requirement = Requirement<TestUser>.all {
      Requirement<TestUser> { _ in
        counter1.increment()
        return .confirmed
      }
      .rateLimit(maxCalls: 2, timeWindow: 1.0)
      
      Requirement<TestUser> { _ in
        counter2.increment()
        return .confirmed
      }
      .rateLimit(maxCalls: 3, timeWindow: 1.0)
    }
    
    let user = TestUser(isLoggedIn: true, isPremium: true, balance: 100)
    
    _ = requirement.evaluate(user)
    _ = requirement.evaluate(user)
    
    #expect(counter1.count == 2)
    #expect(counter2.count == 2)
    
    // Третий вызов - первый rate limit срабатывает
    let result3 = requirement.evaluate(user)
    #expect(result3.isFailed)
    #expect(counter1.count == 2) // Не увеличился (rate limit)
    #expect(counter2.count == 3) // Второе требование продолжает выполняться (all проверяет все)
  }
  
  @Test("Rate limiting on composed requirement works")
  func rateLimitingOnComposedRequirement() {
    let requirement = Requirement<TestUser>.all {
      Requirement<TestUser>.require(\.isLoggedIn)
      Requirement<TestUser>.require(\.isPremium)
    }
    .rateLimit(maxCalls: 2, timeWindow: 1.0)
    
    let user = TestUser(isLoggedIn: true, isPremium: true, balance: 100)
    
    _ = requirement.evaluate(user)
    _ = requirement.evaluate(user)
    let result3 = requirement.evaluate(user)
    
    #expect(result3.isFailed)
  }
  
  @Test("Rate limiting then throttling on composition")
  func rateLimitingThenThrottlingOnComposition() {
    let counter = CompositionCounter()
    
    // Применяем rate limiting, затем throttling
    let baseRequirement = Requirement<TestUser>.all {
      Requirement<TestUser> { user in
        counter.increment()
        return user.isLoggedIn ? .confirmed : .failed(reason: Reason(message: "Not logged"))
      }
    }
    .rateLimit(maxCalls: 5, timeWindow: 1.0, behavior: .returnCached)
    
    let throttled = Requirement<TestUser> { context in
      baseRequirement.evaluate(context)
    }
    .throttle(interval: 0.2, behavior: .returnCached)
    
    let user = TestUser(isLoggedIn: true, isPremium: true, balance: 100)
    
    // Первый вызов проходит
    let result1 = throttled.evaluate(user)
    #expect(result1.isConfirmed)
    #expect(counter.count == 1)
    
    // Второй вызов сразу - throttle возвращает кэш
    let result2 = throttled.evaluate(user)
    #expect(result2.isConfirmed)
    #expect(counter.count == 1) // Не увеличился
  }
  
  // MARK: - Async Composition Tests
  
  @Test("Async rate limiting works inside all composition")
  func asyncRateLimitingInsideAllComposition() async throws {
    let loginCounter = CompositionCounter()
    let premiumCounter = CompositionCounter()
    
    let requirement = AsyncRequirement<TestUser>.all {
      AsyncRequirement<TestUser> { user in
        loginCounter.increment()
        return user.isLoggedIn ? .confirmed : .failed(reason: Reason(message: "Not logged in"))
      }
      .rateLimit(maxCalls: 2, timeWindow: 1.0)
      
      AsyncRequirement<TestUser> { user in
        premiumCounter.increment()
        return user.isPremium ? .confirmed : .failed(reason: Reason(message: "Not premium"))
      }
    }
    
    let user = TestUser(isLoggedIn: true, isPremium: true, balance: 100)
    
    let result1 = try await requirement.evaluate(user)
    let result2 = try await requirement.evaluate(user)
    
    #expect(result1.isConfirmed)
    #expect(result2.isConfirmed)
    #expect(loginCounter.count == 2)
    #expect(premiumCounter.count == 2)
    
    let result3 = try await requirement.evaluate(user)
    
    #expect(result3.isFailed)
    #expect(loginCounter.count == 2)
  }
  
  @Test("Async throttling works inside all composition")
  func asyncThrottlingInsideAllComposition() async throws {
    let counter = CompositionCounter()
    
    let requirement = AsyncRequirement<TestUser>.all {
      AsyncRequirement<TestUser> { user in
        user.isLoggedIn ? .confirmed : .failed(reason: Reason(message: "Not logged"))
      }
      
      AsyncRequirement<TestUser> { user in
        counter.increment()
        return user.isPremium ? .confirmed : .failed(reason: Reason(message: "Not premium"))
      }
      .throttle(interval: 0.5, behavior: .returnCached)
    }
    
    let user = TestUser(isLoggedIn: true, isPremium: true, balance: 100)
    
    let result1 = try await requirement.evaluate(user)
    let result2 = try await requirement.evaluate(user)
    
    #expect(result1.isConfirmed)
    #expect(result2.isConfirmed)
    #expect(counter.count == 1)
  }
  
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  @Test("Async debouncing works inside all composition")
  func asyncDebouncingInsideAllComposition() async throws {
    let counter = CompositionCounter()
    
    let requirement = AsyncRequirement<TestUser>.all {
      AsyncRequirement<TestUser> { user in
        user.isLoggedIn ? .confirmed : .failed(reason: Reason(message: "Not logged"))
      }
      
      AsyncRequirement<TestUser> { user in
        counter.increment()
        return user.isPremium ? .confirmed : .failed(reason: Reason(message: "Not premium"))
      }
      .debounce(delay: 0.1)
    }
    
    let user = TestUser(isLoggedIn: true, isPremium: true, balance: 100)
    
    let result = try await requirement.evaluate(user)
    
    #expect(result.isConfirmed)
    #expect(counter.count == 1)
  }
  
  @Test("Async allConcurrent with rate limiting")
  func asyncAllConcurrentWithRateLimiting() async throws {
    let counter = CompositionCounter()
    
    let requirement = AsyncRequirement<TestUser>.allConcurrent {
      AsyncRequirement<TestUser> { user in
        counter.increment()
        try await Task.sleep(nanoseconds: 10_000_000)
        return user.isLoggedIn ? .confirmed : .failed(reason: Reason(message: "Not logged"))
      }
      .rateLimit(maxCalls: 3, timeWindow: 1.0)
      
      AsyncRequirement<TestUser> { user in
        user.isPremium ? .confirmed : .failed(reason: Reason(message: "Not premium"))
      }
    }
    
    let user = TestUser(isLoggedIn: true, isPremium: true, balance: 100)
    
    let result1 = try await requirement.evaluate(user)
    let result2 = try await requirement.evaluate(user)
    let result3 = try await requirement.evaluate(user)
    
    #expect(result1.isConfirmed)
    #expect(result2.isConfirmed)
    #expect(result3.isConfirmed)
    #expect(counter.count == 3)
    
    // Четвертый вызов должен быть заблокирован
    let result4 = try await requirement.evaluate(user)
    #expect(result4.isFailed)
    #expect(counter.count == 3)
  }
  
  // MARK: - Edge Cases
  
  @Test("Mixed rate limited and regular requirements")
  func mixedRateLimitedAndRegularRequirements() {
    let rateLimitedCounter = CompositionCounter()
    let regularCounter = CompositionCounter()
    
    let requirement = Requirement<TestUser>.all {
      Requirement<TestUser> { _ in
        rateLimitedCounter.increment()
        return .confirmed
      }
      .rateLimit(maxCalls: 1, timeWindow: 1.0)
      
      Requirement<TestUser> { _ in
        regularCounter.increment()
        return .confirmed
      }
    }
    
    let user = TestUser(isLoggedIn: true, isPremium: true, balance: 100)
    
    _ = requirement.evaluate(user)
    
    #expect(rateLimitedCounter.count == 1)
    #expect(regularCounter.count == 1)
    
    // Второй вызов - rate limited блокирует всю композицию
    let result2 = requirement.evaluate(user)
    
    #expect(result2.isFailed)
    #expect(rateLimitedCounter.count == 1) // Не увеличился (rate limit)
    #expect(regularCounter.count == 2) // Обычное требование продолжает выполняться (all проверяет все)
  }
}

