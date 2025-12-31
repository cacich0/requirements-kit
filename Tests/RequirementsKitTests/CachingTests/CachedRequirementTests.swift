import Testing
import Foundation
@testable import RequirementsKit

struct CacheContext: Sendable, Hashable {
  let userId: Int
  let isActive: Bool
}

/// Класс-счетчик для обхода Sendable ограничений в тестах
final class EvaluationCounter: @unchecked Sendable {
  var count = 0
  func increment() { count += 1 }
}

@Suite("CachedRequirement Tests")
struct CachedRequirementTests {
  
  // MARK: - Базовое кэширование
  
  @Test("кэширует результат для одинакового контекста")
  func testCachesResult() {
    let counter = EvaluationCounter()
    
    let requirement = Requirement<CacheContext> { context in
      counter.increment()
      return context.isActive ? .confirmed : .failed(reason: Reason(message: "Not active"))
    }
    
    let cached = CachedRequirement(requirement: requirement)
    let context = CacheContext(userId: 1, isActive: true)
    
    // Первый вызов - оценка
    _ = cached.evaluate(context)
    #expect(counter.count == 1)
    
    // Второй вызов - из кэша
    _ = cached.evaluate(context)
    #expect(counter.count == 1)
    
    // Третий вызов - из кэша
    _ = cached.evaluate(context)
    #expect(counter.count == 1)
  }
  
  @Test("разные контексты кэшируются отдельно")
  func testDifferentContextsCachedSeparately() {
    let counter = EvaluationCounter()
    
    let requirement = Requirement<CacheContext> { context in
      counter.increment()
      return context.isActive ? .confirmed : .failed(reason: Reason(message: "Not active"))
    }
    
    let cached = CachedRequirement(requirement: requirement)
    let context1 = CacheContext(userId: 1, isActive: true)
    let context2 = CacheContext(userId: 2, isActive: true)
    
    _ = cached.evaluate(context1)
    _ = cached.evaluate(context2)
    
    #expect(counter.count == 2)
    
    // Повторные вызовы из кэша
    _ = cached.evaluate(context1)
    _ = cached.evaluate(context2)
    
    #expect(counter.count == 2)
  }
  
  // MARK: - TTL
  
  @available(iOS 16.0, *)
  @Test("TTL истекает и вызывает повторную оценку")
  func testTTLExpiration() async throws {
    let counter = EvaluationCounter()
    
    let requirement = Requirement<CacheContext> { context in
      counter.increment()
      return .confirmed
    }
    
    let cached = CachedRequirement(requirement: requirement, ttl: 0.1) // 100ms TTL
    let context = CacheContext(userId: 1, isActive: true)
    
    // Первый вызов
    _ = cached.evaluate(context)
    #expect(counter.count == 1)
    
    // Сразу из кэша
    _ = cached.evaluate(context)
    #expect(counter.count == 1)
    
    // Ждем истечения TTL
    try await Task.sleep(for: .milliseconds(150))
    
    // После истечения TTL - новая оценка
    _ = cached.evaluate(context)
    #expect(counter.count == 2)
  }
  
  @available(iOS 16.0, *)
  @Test("без TTL кэш не истекает")
  func testNoTTL() async throws {
    let counter = EvaluationCounter()
    
    let requirement = Requirement<CacheContext> { context in
      counter.increment()
      return .confirmed
    }
    
    let cached = CachedRequirement(requirement: requirement, ttl: nil)
    let context = CacheContext(userId: 1, isActive: true)
    
    _ = cached.evaluate(context)
    try await Task.sleep(for: .milliseconds(50))
    _ = cached.evaluate(context)
    
    #expect(counter.count == 1)
  }
  
  // MARK: - Invalidation
  
  @Test("invalidate() очищает кэш для конкретного контекста")
  func testInvalidateSpecific() {
    let counter = EvaluationCounter()
    
    let requirement = Requirement<CacheContext> { _ in
      counter.increment()
      return .confirmed
    }
    
    let cached = CachedRequirement(requirement: requirement)
    let context1 = CacheContext(userId: 1, isActive: true)
    let context2 = CacheContext(userId: 2, isActive: true)
    
    _ = cached.evaluate(context1)
    _ = cached.evaluate(context2)
    #expect(counter.count == 2)
    
    // Инвалидируем только context1
    cached.invalidate(context1)
    
    _ = cached.evaluate(context1) // Новая оценка
    _ = cached.evaluate(context2) // Из кэша
    
    #expect(counter.count == 3)
  }
  
  @Test("invalidateAll() очищает весь кэш")
  func testInvalidateAll() {
    let counter = EvaluationCounter()
    
    let requirement = Requirement<CacheContext> { _ in
      counter.increment()
      return .confirmed
    }
    
    let cached = CachedRequirement(requirement: requirement)
    let context1 = CacheContext(userId: 1, isActive: true)
    let context2 = CacheContext(userId: 2, isActive: true)
    
    _ = cached.evaluate(context1)
    _ = cached.evaluate(context2)
    #expect(counter.count == 2)
    
    cached.invalidateAll()
    
    _ = cached.evaluate(context1)
    _ = cached.evaluate(context2)
    
    #expect(counter.count == 4)
  }
  
  // MARK: - cacheCount
  
  @Test("cacheCount возвращает количество закэшированных записей")
  func testCacheCount() {
    let requirement = Requirement<CacheContext>.always
    let cached = CachedRequirement(requirement: requirement)
    
    #expect(cached.cacheCount == 0)
    
    _ = cached.evaluate(CacheContext(userId: 1, isActive: true))
    #expect(cached.cacheCount == 1)
    
    _ = cached.evaluate(CacheContext(userId: 2, isActive: true))
    #expect(cached.cacheCount == 2)
    
    // Повторный вызов не увеличивает count
    _ = cached.evaluate(CacheContext(userId: 1, isActive: true))
    #expect(cached.cacheCount == 2)
    
    cached.invalidateAll()
    #expect(cached.cacheCount == 0)
  }
  
  // MARK: - .cached() extension
  
  @Test(".cached() extension создает CachedRequirement")
  func testCachedExtension() {
    let requirement = Requirement<CacheContext>.require(\.isActive)
    let cached = requirement.cached(ttl: 60)
    
    let context = CacheContext(userId: 1, isActive: true)
    let result = cached.evaluate(context)
    
    #expect(result.isConfirmed)
  }
}

