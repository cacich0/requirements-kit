import Testing
import Foundation
@testable import RequirementsKit

// Thread-safe counter for tests
final class Counter: @unchecked Sendable {
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

@Suite("Throttle Tests")
struct ThrottleTests {
  
  // MARK: - Sync Throttle Tests
  
  @Test("Throttle allows first call")
  func throttleAllowsFirstCall() {
    let counter = Counter()
    let requirement = Requirement<String> { _ in
      counter.increment()
      return .confirmed
    }
    
    let throttled = requirement.throttle(interval: 0.1)
    
    let result = throttled.evaluate("test")
    
    #expect(result == .confirmed)
    #expect(counter.count == 1)
  }
  
  @Test("Throttle blocks subsequent calls within interval")
  func throttleBlocksSubsequentCallsWithinInterval() {
    let counter = Counter()
    let requirement = Requirement<String> { _ in
      counter.increment()
      return .confirmed
    }
    
    let throttled = requirement.throttle(
      interval: 0.5,
      behavior: .returnFailed(Reason(message: "Throttled"))
    )
    
    let result1 = throttled.evaluate("test")
    let result2 = throttled.evaluate("test")
    
    #expect(result1 == .confirmed)
    #expect(result2.isFailed)
    #expect(counter.count == 1)
  }
  
  @Test("Throttle allows call after interval")
  func throttleAllowsCallAfterInterval() {
    let counter = Counter()
    let requirement = Requirement<String> { _ in
      counter.increment()
      return .confirmed
    }
    
    let throttled = requirement.throttle(interval: 0.1)
    
    _ = throttled.evaluate("test")
    Thread.sleep(forTimeInterval: 0.15)
    let result = throttled.evaluate("test")
    
    #expect(result == .confirmed)
    #expect(counter.count == 2)
  }
  
  @Test("Throttle behavior: returnCached")
  func throttleBehaviorReturnCached() {
    let counter = Counter()
    let requirement = Requirement<String> { _ in
      counter.increment()
      return .confirmed
    }
    
    let throttled = requirement.throttle(
      interval: 1.0,
      behavior: .returnCached
    )
    
    let result1 = throttled.evaluate("test")
    let result2 = throttled.evaluate("test")
    
    #expect(result1 == .confirmed)
    #expect(result2 == .confirmed)
    #expect(counter.count == 1)
  }
  
  @Test("Throttle behavior: skip")
  func throttleBehaviorSkip() {
    let counter = Counter()
    let requirement = Requirement<String> { _ in
      counter.increment()
      return .confirmed
    }
    
    let throttled = requirement.throttle(
      interval: 1.0,
      behavior: .skip
    )
    
    let result1 = throttled.evaluate("test")
    let result2 = throttled.evaluate("test")
    
    #expect(result1 == .confirmed)
    #expect(result2 == .confirmed)
    #expect(counter.count == 1)
  }
  
  @Test("Throttle reset clears state")
  func throttleReset() {
    let counter = Counter()
    let requirement = Requirement<String> { _ in
      counter.increment()
      return .confirmed
    }
    
    let throttled = requirement.throttle(interval: 10.0)
    
    _ = throttled.evaluate("test")
    throttled.reset()
    let result = throttled.evaluate("test")
    
    #expect(result == .confirmed)
    #expect(counter.count == 2)
  }
  
  @Test("Throttle timeUntilNextCall works correctly")
  func throttleTimeUntilNextCall() {
    let requirement = Requirement<String> { _ in .confirmed }
    let throttled = requirement.throttle(interval: 1.0)
    
    #expect(throttled.timeUntilNextCall == 0.0)
    
    _ = throttled.evaluate("test")
    let timeRemaining = throttled.timeUntilNextCall
    
    #expect(timeRemaining > 0.9)
    #expect(timeRemaining <= 1.0)
  }
  
  // MARK: - Async Throttle Tests
  
  @Test("Async throttle allows first call")
  func asyncThrottleAllowsFirstCall() async throws {
    let counter = Counter()
    let requirement = AsyncRequirement<String> { _ in
      counter.increment()
      return .confirmed
    }
    
    let throttled = requirement.throttle(interval: 0.1)
    
    let result = try await throttled.evaluate("test")
    
    #expect(result == .confirmed)
    #expect(counter.count == 1)
  }
  
  @Test("Async throttle blocks subsequent calls within interval")
  func asyncThrottleBlocksSubsequentCallsWithinInterval() async throws {
    let counter = Counter()
    let requirement = AsyncRequirement<String> { _ in
      counter.increment()
      return .confirmed
    }
    
    let throttled = requirement.throttle(
      interval: 0.5,
      behavior: .returnFailed(Reason(message: "Throttled"))
    )
    
    let result1 = try await throttled.evaluate("test")
    let result2 = try await throttled.evaluate("test")
    
    #expect(result1 == .confirmed)
    #expect(result2.isFailed)
    #expect(counter.count == 1)
  }
  
  @Test("Async throttle allows call after interval")
  func asyncThrottleAllowsCallAfterInterval() async throws {
    let counter = Counter()
    let requirement = AsyncRequirement<String> { _ in
      counter.increment()
      return .confirmed
    }
    
    let throttled = requirement.throttle(interval: 0.1)
    
    _ = try await throttled.evaluate("test")
    try await Task.sleep(nanoseconds: 150_000_000)
    let result = try await throttled.evaluate("test")
    
    #expect(result == .confirmed)
    #expect(counter.count == 2)
  }
  
  @Test("Async throttle behavior: returnCached")
  func asyncThrottleBehaviorReturnCached() async throws {
    let counter = Counter()
    let requirement = AsyncRequirement<String> { _ in
      counter.increment()
      return .confirmed
    }
    
    let throttled = requirement.throttle(
      interval: 1.0,
      behavior: .returnCached
    )
    
    let result1 = try await throttled.evaluate("test")
    let result2 = try await throttled.evaluate("test")
    
    #expect(result1 == .confirmed)
    #expect(result2 == .confirmed)
    #expect(counter.count == 1)
  }
  
  @Test("Async throttle reset clears state")
  func asyncThrottleReset() async throws {
    let counter = Counter()
    let requirement = AsyncRequirement<String> { _ in
      counter.increment()
      return .confirmed
    }
    
    let throttled = requirement.throttle(interval: 10.0)
    
    _ = try await throttled.evaluate("test")
    await throttled.reset()
    let result = try await throttled.evaluate("test")
    
    #expect(result == .confirmed)
    #expect(counter.count == 2)
  }
  
  @Test("Async throttle timeUntilNextCall works correctly")
  func asyncThrottleTimeUntilNextCall() async throws {
    let requirement = AsyncRequirement<String> { _ in .confirmed }
    let throttled = requirement.throttle(interval: 1.0)
    
    var timeRemaining = await throttled.timeUntilNextCall
    #expect(timeRemaining == 0.0)
    
    _ = try await throttled.evaluate("test")
    timeRemaining = await throttled.timeUntilNextCall
    
    #expect(timeRemaining > 0.9)
    #expect(timeRemaining <= 1.0)
  }
  
  // MARK: - Thread Safety
  
  @Test("Throttle is thread-safe")
  func throttleThreadSafety() async {
    let counter = Counter()
    let requirement = Requirement<Int> { _ in
      counter.increment()
      return .confirmed
    }
    
    let throttled = requirement.throttle(
      interval: 0.5,
      behavior: .skip
    )
    
    await withTaskGroup(of: Void.self) { group in
      for _ in 0..<100 {
        group.addTask {
          _ = throttled.evaluate(42)
        }
      }
    }
    
    #expect(counter.count == 1)
  }
}
