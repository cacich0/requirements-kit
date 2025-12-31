import Foundation

// MARK: - Кэширование требований

/// Кэшированное требование для избежания повторных вычислений
public final class CachedRequirement<Context: Sendable & Hashable>: @unchecked Sendable {
  private let requirement: Requirement<Context>
  private var cache: [Context: CacheEntry] = [:]
  private let lock = NSLock()
  private let ttl: TimeInterval?
  
  private struct CacheEntry {
    let evaluation: Evaluation
    let timestamp: Date
  }
  
  /// Инициализатор
  /// - Parameters:
  ///   - requirement: Базовое требование
  ///   - ttl: Время жизни кэша в секундах (nil = бессрочно)
  public init(
    requirement: Requirement<Context>,
    ttl: TimeInterval? = nil
  ) {
    self.requirement = requirement
    self.ttl = ttl
  }
  
  /// Оценивает требование с использованием кэша
  /// - Parameter context: Контекст для оценки
  /// - Returns: Результат оценки
  public func evaluate(_ context: Context) -> Evaluation {
    lock.lock()
    defer { lock.unlock() }
    
    // Проверяем кэш
    if let entry = cache[context] {
      // Проверяем TTL
      if let ttl = ttl {
        let age = Date().timeIntervalSince(entry.timestamp)
        if age < ttl {
          return entry.evaluation
        }
      } else {
        return entry.evaluation
      }
    }
    
    // Вычисляем и кэшируем
    let evaluation = requirement.evaluate(context)
    cache[context] = CacheEntry(evaluation: evaluation, timestamp: Date())
    
    return evaluation
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

// MARK: - Расширение Requirement

extension Requirement where Context: Hashable {
  /// Создает кэшированную версию требования
  /// - Parameter ttl: Время жизни кэша (nil = бессрочно)
  /// - Returns: Кэшированное требование
  public func cached(ttl: TimeInterval? = nil) -> CachedRequirement<Context> {
    CachedRequirement(requirement: self, ttl: ttl)
  }
}

// MARK: - CacheStrategy

/// Стратегия кэширования
public enum CacheStrategy: Sendable {
  /// Без кэширования
  case none
  
  /// Кэширование без ограничения времени
  case forever
  
  /// Кэширование с TTL
  case ttl(TimeInterval)
  
  /// Кэширование до следующей инвалидации
  case untilInvalidated
}

// MARK: - WeakCachedRequirement

/// Кэшированное требование со слабыми ссылками на контекст
public final class WeakCachedRequirement<Context: Sendable & AnyObject & Hashable>: @unchecked Sendable {
  private let requirement: Requirement<Context>
  private var cache = NSMapTable<Context, CacheEntryWrapper>.weakToStrongObjects()
  private let lock = NSLock()
  
  private class CacheEntryWrapper {
    let evaluation: Evaluation
    init(evaluation: Evaluation) {
      self.evaluation = evaluation
    }
  }
  
  public init(requirement: Requirement<Context>) {
    self.requirement = requirement
  }
  
  public func evaluate(_ context: Context) -> Evaluation {
    lock.lock()
    defer { lock.unlock() }
    
    if let entry = cache.object(forKey: context) {
      return entry.evaluation
    }
    
    let evaluation = requirement.evaluate(context)
    cache.setObject(CacheEntryWrapper(evaluation: evaluation), forKey: context)
    
    return evaluation
  }
  
  public func invalidateAll() {
    lock.lock()
    defer { lock.unlock() }
    cache.removeAllObjects()
  }
}

