import Foundation

// MARK: - Кэширование решений

/// Кэшированное решение для избежания повторных вычислений
public final class CachedDecision<Context: Sendable & Hashable, Result: Sendable>: @unchecked Sendable {
  private let decision: Decision<Context, Result>
  private var cache: [Context: CacheEntry] = [:]
  private let lock = NSLock()
  private let ttl: TimeInterval?
  
  private struct CacheEntry {
    let result: Result?
    let timestamp: Date
  }
  
  /// Инициализатор
  /// - Parameters:
  ///   - decision: Базовое решение
  ///   - ttl: Время жизни кэша в секундах (nil = бессрочно)
  public init(
    decision: Decision<Context, Result>,
    ttl: TimeInterval? = nil
  ) {
    self.decision = decision
    self.ttl = ttl
  }
  
  /// Принимает решение с использованием кэша
  /// - Parameter context: Контекст для принятия решения
  /// - Returns: Результат решения
  public func decide(_ context: Context) -> Result? {
    lock.lock()
    defer { lock.unlock() }
    
    // Проверяем кэш
    if let entry = cache[context] {
      // Проверяем TTL
      if let ttl = ttl {
        let age = Date().timeIntervalSince(entry.timestamp)
        if age < ttl {
          return entry.result
        }
      } else {
        return entry.result
      }
    }
    
    // Вычисляем и кэшируем
    let result = decision.decide(context)
    cache[context] = CacheEntry(result: result, timestamp: Date())
    
    return result
  }
  
  /// Инвалидирует кэш для конкретного контекста
  public func invalidate(_ context: Context) {
    lock.lock()
    defer { lock.unlock() }
    cache.removeValue(forKey: context)
  }
  
  /// Очищает весь кэш
  public func invalidateAll() {
    lock.lock()
    defer { lock.unlock() }
    cache.removeAll()
  }
  
  /// Количество закэшированных записей
  public var cacheCount: Int {
    lock.lock()
    defer { lock.unlock() }
    return cache.count
  }
}

// MARK: - Расширение Decision

extension Decision where Context: Hashable {
  /// Создает кэшированную версию решения
  /// - Parameter ttl: Время жизни кэша (nil = бессрочно)
  /// - Returns: Кэшированное решение
  public func cached(ttl: TimeInterval? = nil) -> CachedDecision<Context, Result> {
    CachedDecision(decision: self, ttl: ttl)
  }
}

// MARK: - Асинхронное кэширование

/// Кэшированное асинхронное решение для избежания повторных вычислений
public actor CachedAsyncDecision<Context: Sendable & Hashable, Result: Sendable> {
  private let decision: AsyncDecision<Context, Result>
  private var cache: [Context: CacheEntry] = [:]
  private let ttl: TimeInterval?
  
  private struct CacheEntry {
    let result: Result?
    let timestamp: Date
  }
  
  /// Инициализатор
  /// - Parameters:
  ///   - decision: Базовое асинхронное решение
  ///   - ttl: Время жизни кэша в секундах (nil = бессрочно)
  public init(
    decision: AsyncDecision<Context, Result>,
    ttl: TimeInterval? = nil
  ) {
    self.decision = decision
    self.ttl = ttl
  }
  
  /// Принимает решение с использованием кэша
  /// - Parameter context: Контекст для принятия решения
  /// - Returns: Результат решения
  public func decide(_ context: Context) async throws -> Result? {
    // Проверяем кэш
    if let entry = cache[context] {
      // Проверяем TTL
      if let ttl = ttl {
        let age = Date().timeIntervalSince(entry.timestamp)
        if age < ttl {
          return entry.result
        }
      } else {
        return entry.result
      }
    }
    
    // Вычисляем и кэшируем
    let result = try await decision.decide(context)
    cache[context] = CacheEntry(result: result, timestamp: Date())
    
    return result
  }
  
  /// Инвалидирует кэш для конкретного контекста
  public func invalidate(_ context: Context) {
    cache.removeValue(forKey: context)
  }
  
  /// Очищает весь кэш
  public func invalidateAll() {
    cache.removeAll()
  }
  
  /// Количество закэшированных записей
  public var cacheCount: Int {
    cache.count
  }
}

// MARK: - Расширение AsyncDecision

extension AsyncDecision where Context: Hashable {
  /// Создает кэшированную версию асинхронного решения
  /// - Parameter ttl: Время жизни кэша (nil = бессрочно)
  /// - Returns: Кэшированное решение
  public func cached(ttl: TimeInterval? = nil) -> CachedAsyncDecision<Context, Result> {
    CachedAsyncDecision(decision: self, ttl: ttl)
  }
}

// MARK: - WeakCachedDecision

/// Кэшированное решение со слабыми ссылками на контекст (для AnyObject контекстов)
public final class WeakCachedDecision<Context: Sendable & AnyObject & Hashable, Result: Sendable>: @unchecked Sendable {
  private let decision: Decision<Context, Result>
  private var cache = NSMapTable<Context, CacheEntryWrapper>.weakToStrongObjects()
  private let lock = NSLock()
  
  private class CacheEntryWrapper {
    let result: Result?
    init(result: Result?) {
      self.result = result
    }
  }
  
  public init(decision: Decision<Context, Result>) {
    self.decision = decision
  }
  
  public func decide(_ context: Context) -> Result? {
    lock.lock()
    defer { lock.unlock() }
    
    if let entry = cache.object(forKey: context) {
      return entry.result
    }
    
    let result = decision.decide(context)
    cache.setObject(CacheEntryWrapper(result: result), forKey: context)
    
    return result
  }
  
  public func invalidateAll() {
    lock.lock()
    defer { lock.unlock() }
    cache.removeAllObjects()
  }
}

