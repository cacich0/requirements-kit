import Testing
import Foundation
@testable import RequirementsKit

// Thread-safe counter for async tests
final class AsyncCounter: @unchecked Sendable {
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

@Suite("Async Rate Limited Requirement Tests")
struct AsyncRateLimitedRequirementTests {
  
  // MARK: - Basic Functionality
  
  @Test("Async rate limit allows calls within limit")
  func asyncRateLimitAllowsCallsWithinLimit() async throws {
    let counter = AsyncCounter()
    let requirement = AsyncRequirement<String> { _ in
      counter.increment()
      return .confirmed
    }
    
    let rateLimited = requirement.rateLimit(
      maxCalls: 3,
      timeWindow: 1.0
    )
    
    let result1 = try await rateLimited.evaluate("test")
    let result2 = try await rateLimited.evaluate("test")
    let result3 = try await rateLimited.evaluate("test")
    
    #expect(result1 == .confirmed)
    #expect(result2 == .confirmed)
    #expect(result3 == .confirmed)
    #expect(counter.count == 3)
  }
  
  @Test("Async rate limit blocks calls exceeding limit")
  func asyncRateLimitBlocksCallsExceedingLimit() async throws {
    let counter = AsyncCounter()
    let requirement = AsyncRequirement<String> { _ in
      counter.increment()
      return .confirmed
    }
    
    let rateLimited = requirement.rateLimit(
      maxCalls: 2,
      timeWindow: 1.0,
      behavior: .default
    )
    
    _ = try await rateLimited.evaluate("test")
    _ = try await rateLimited.evaluate("test")
    let result3 = try await rateLimited.evaluate("test")
    
    #expect(result3.isFailed)
    #expect(counter.count == 2)
  }
  
  // MARK: - Behavior Tests
  
  @Test("Async rate limit behavior: returnFailed")
  func asyncRateLimitBehaviorReturnFailed() async throws {
    let requirement = AsyncRequirement<String> { _ in .confirmed }
    let customReason = Reason(code: "async_limit", message: "Too many async requests")
    
    let rateLimited = requirement.rateLimit(
      maxCalls: 1,
      timeWindow: 1.0,
      behavior: .returnFailed(customReason)
    )
    
    _ = try await rateLimited.evaluate("test")
    let result = try await rateLimited.evaluate("test")
    
    #expect(result.isFailed)
    #expect(result.reason?.code == "async_limit")
    #expect(result.reason?.message == "Too many async requests")
  }
  
  @Test("Async rate limit behavior: returnCached")
  func asyncRateLimitBehaviorReturnCached() async throws {
    let requirement = AsyncRequirement<String> { _ in .confirmed }
    
    let rateLimited = requirement.rateLimit(
      maxCalls: 1,
      timeWindow: 1.0,
      behavior: .returnCached
    )
    
    let result1 = try await rateLimited.evaluate("test")
    let result2 = try await rateLimited.evaluate("test")
    
    #expect(result1 == .confirmed)
    #expect(result2 == .confirmed)
  }
  
  @Test("Async rate limit behavior: skip")
  func asyncRateLimitBehaviorSkip() async throws {
    let counter = AsyncCounter()
    let requirement = AsyncRequirement<String> { _ in
      counter.increment()
      return .confirmed
    }
    
    let rateLimited = requirement.rateLimit(
      maxCalls: 1,
      timeWindow: 1.0,
      behavior: .skip
    )
    
    let result1 = try await rateLimited.evaluate("test")
    let result2 = try await rateLimited.evaluate("test")
    
    #expect(result1 == .confirmed)
    #expect(result2 == .confirmed)
    #expect(counter.count == 1)
  }
  
  // MARK: - Time Window Tests
  
  @Test("Async rate limit resets after time window")
  func asyncRateLimitResetsAfterTimeWindow() async throws {
    let counter = AsyncCounter()
    let requirement = AsyncRequirement<String> { _ in
      counter.increment()
      return .confirmed
    }
    
    let rateLimited = requirement.rateLimit(
      maxCalls: 2,
      timeWindow: 0.1
    )
    
    _ = try await rateLimited.evaluate("test")
    _ = try await rateLimited.evaluate("test")
    
    try await Task.sleep(nanoseconds: 150_000_000)
    
    let result = try await rateLimited.evaluate("test")
    
    #expect(result == .confirmed)
    #expect(counter.count == 3)
  }
  
  // MARK: - Reset Tests
  
  @Test("Async rate limit reset clears counters")
  func asyncRateLimitReset() async throws {
    let requirement = AsyncRequirement<String> { _ in .confirmed }
    
    let rateLimited = requirement.rateLimit(
      maxCalls: 1,
      timeWindow: 10.0
    )
    
    _ = try await rateLimited.evaluate("test")
    await rateLimited.reset()
    let result = try await rateLimited.evaluate("test")
    
    #expect(result == .confirmed)
  }
  
  // MARK: - Current Call Count
  
  @Test("Async current call count tracks calls correctly")
  func asyncCurrentCallCount() async throws {
    let requirement = AsyncRequirement<String> { _ in .confirmed }
    
    let rateLimited = requirement.rateLimit(
      maxCalls: 3,
      timeWindow: 1.0
    )
    
    var count = await rateLimited.currentCallCount
    #expect(count == 0)
    
    _ = try await rateLimited.evaluate("test")
    count = await rateLimited.currentCallCount
    #expect(count == 1)
    
    _ = try await rateLimited.evaluate("test")
    count = await rateLimited.currentCallCount
    #expect(count == 2)
  }
  
  // MARK: - Concurrent Calls
  
  @Test("Async rate limit handles concurrent calls")
  func asyncRateLimitConcurrentCalls() async throws {
    let requirement = AsyncRequirement<Int> { _ in
      try await Task.sleep(nanoseconds: 10_000_000)
      return .confirmed
    }
    
    let rateLimited = requirement.rateLimit(
      maxCalls: 50,
      timeWindow: 1.0
    )
    
    try await withThrowingTaskGroup(of: Evaluation.self) { group in
      for _ in 0..<50 {
        group.addTask {
          try await rateLimited.evaluate(42)
        }
      }
      
      var confirmedCount = 0
      for try await result in group {
        if result.isConfirmed {
          confirmedCount += 1
        }
      }
      
      #expect(confirmedCount == 50)
    }
  }
  
  // MARK: - Error Handling
  
  @Test("Async rate limit with throwing requirement")
  func asyncRateLimitWithThrowingRequirement() async throws {
    enum TestError: Error {
      case testFailure
    }
    
    let counter = AsyncCounter()
    let requirement = AsyncRequirement<String> { _ in
      counter.increment()
      throw TestError.testFailure
    }
    
    let rateLimited = requirement.rateLimit(
      maxCalls: 2,
      timeWindow: 1.0
    )
    
    await #expect(throws: TestError.self) {
      _ = try await rateLimited.evaluate("test")
    }
    
    #expect(counter.count == 1)
  }
}

