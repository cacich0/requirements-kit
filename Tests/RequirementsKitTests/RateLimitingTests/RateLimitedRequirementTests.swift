import Testing
import Foundation
@testable import RequirementsKit

// Thread-safe counter for tests
final class ThreadSafeCounter: @unchecked Sendable {
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

@Suite("Rate Limited Requirement Tests")
struct RateLimitedRequirementTests {
  
  // MARK: - Basic Functionality
  
  @Test("Rate limit allows calls within limit")
  func rateLimitAllowsCallsWithinLimit() {
    let counter = ThreadSafeCounter()
    let requirement = Requirement<String> { _ in
      counter.increment()
      return .confirmed
    }
    
    let rateLimited = requirement.rateLimit(
      maxCalls: 3,
      timeWindow: 1.0
    )
    
    let result1 = rateLimited.evaluate("test")
    let result2 = rateLimited.evaluate("test")
    let result3 = rateLimited.evaluate("test")
    
    #expect(result1 == .confirmed)
    #expect(result2 == .confirmed)
    #expect(result3 == .confirmed)
    #expect(counter.count == 3)
  }
  
  @Test("Rate limit blocks calls exceeding limit")
  func rateLimitBlocksCallsExceedingLimit() {
    let counter = ThreadSafeCounter()
    let requirement = Requirement<String> { _ in
      counter.increment()
      return .confirmed
    }
    
    let rateLimited = requirement.rateLimit(
      maxCalls: 2,
      timeWindow: 1.0,
      behavior: .default
    )
    
    _ = rateLimited.evaluate("test")
    _ = rateLimited.evaluate("test")
    let result3 = rateLimited.evaluate("test")
    
    #expect(result3.isFailed)
    #expect(counter.count == 2)
  }
  
  // MARK: - Behavior Tests
  
  @Test("Rate limit behavior: returnFailed")
  func rateLimitBehaviorReturnFailed() {
    let requirement = Requirement<String> { _ in .confirmed }
    let customReason = Reason(code: "custom_limit", message: "Too many requests")
    
    let rateLimited = requirement.rateLimit(
      maxCalls: 1,
      timeWindow: 1.0,
      behavior: .returnFailed(customReason)
    )
    
    _ = rateLimited.evaluate("test")
    let result = rateLimited.evaluate("test")
    
    #expect(result.isFailed)
    #expect(result.reason?.code == "custom_limit")
    #expect(result.reason?.message == "Too many requests")
  }
  
  @Test("Rate limit behavior: returnCached")
  func rateLimitBehaviorReturnCached() {
    let requirement = Requirement<String> { _ in .confirmed }
    
    let rateLimited = requirement.rateLimit(
      maxCalls: 1,
      timeWindow: 1.0,
      behavior: .returnCached
    )
    
    let result1 = rateLimited.evaluate("test")
    let result2 = rateLimited.evaluate("test")
    
    #expect(result1 == .confirmed)
    #expect(result2 == .confirmed)
  }
  
  @Test("Rate limit behavior: skip")
  func rateLimitBehaviorSkip() {
    let counter = ThreadSafeCounter()
    let requirement = Requirement<String> { _ in
      counter.increment()
      return .confirmed
    }
    
    let rateLimited = requirement.rateLimit(
      maxCalls: 1,
      timeWindow: 1.0,
      behavior: .skip
    )
    
    let result1 = rateLimited.evaluate("test")
    let result2 = rateLimited.evaluate("test")
    
    #expect(result1 == .confirmed)
    #expect(result2 == .confirmed)
    #expect(counter.count == 1)
  }
  
  // MARK: - Time Window Tests
  
  @Test("Rate limit resets after time window")
  func rateLimitResetsAfterTimeWindow() {
    let counter = ThreadSafeCounter()
    let requirement = Requirement<String> { _ in
      counter.increment()
      return .confirmed
    }
    
    let rateLimited = requirement.rateLimit(
      maxCalls: 2,
      timeWindow: 0.1
    )
    
    _ = rateLimited.evaluate("test")
    _ = rateLimited.evaluate("test")
    
    Thread.sleep(forTimeInterval: 0.15)
    
    let result = rateLimited.evaluate("test")
    
    #expect(result == .confirmed)
    #expect(counter.count == 3)
  }
  
  @Test("Rate limit sliding window works correctly")
  func rateLimitSlidingWindow() {
    let counter = ThreadSafeCounter()
    let requirement = Requirement<String> { _ in
      counter.increment()
      return .confirmed
    }
    
    let rateLimited = requirement.rateLimit(
      maxCalls: 2,
      timeWindow: 0.2
    )
    
    _ = rateLimited.evaluate("test")
    Thread.sleep(forTimeInterval: 0.1)
    _ = rateLimited.evaluate("test")
    Thread.sleep(forTimeInterval: 0.11)
    
    let result = rateLimited.evaluate("test")
    
    #expect(result == .confirmed)
    #expect(counter.count == 3)
  }
  
  // MARK: - Reset Tests
  
  @Test("Rate limit reset clears counters")
  func rateLimitReset() {
    let requirement = Requirement<String> { _ in .confirmed }
    
    let rateLimited = requirement.rateLimit(
      maxCalls: 1,
      timeWindow: 10.0
    )
    
    _ = rateLimited.evaluate("test")
    rateLimited.reset()
    let result = rateLimited.evaluate("test")
    
    #expect(result == .confirmed)
  }
  
  // MARK: - Current Call Count
  
  @Test("Current call count tracks calls correctly")
  func currentCallCount() {
    let requirement = Requirement<String> { _ in .confirmed }
    
    let rateLimited = requirement.rateLimit(
      maxCalls: 3,
      timeWindow: 1.0
    )
    
    #expect(rateLimited.currentCallCount == 0)
    
    _ = rateLimited.evaluate("test")
    #expect(rateLimited.currentCallCount == 1)
    
    _ = rateLimited.evaluate("test")
    #expect(rateLimited.currentCallCount == 2)
    
    _ = rateLimited.evaluate("test")
    #expect(rateLimited.currentCallCount == 3)
  }
  
  // MARK: - Thread Safety
  
  @Test("Rate limit is thread-safe")
  func rateLimitThreadSafety() async {
    let requirement = Requirement<Int> { _ in .confirmed }
    
    let rateLimited = requirement.rateLimit(
      maxCalls: 100,
      timeWindow: 1.0
    )
    
    await withTaskGroup(of: Void.self) { group in
      for _ in 0..<100 {
        group.addTask {
          _ = rateLimited.evaluate(42)
        }
      }
    }
    
    #expect(rateLimited.currentCallCount == 100)
  }
  
  // MARK: - Failed Requirements
  
  @Test("Rate limit with failed requirement caches failure")
  func rateLimitWithFailedRequirement() {
    let requirement = Requirement<String> { _ in
      .failed(reason: Reason(message: "Validation failed"))
    }
    
    let rateLimited = requirement.rateLimit(
      maxCalls: 2,
      timeWindow: 1.0,
      behavior: .returnCached
    )
    
    let result1 = rateLimited.evaluate("test")
    let result2 = rateLimited.evaluate("test")
    
    #expect(result1.isFailed)
    #expect(result2.isFailed)
  }
}

