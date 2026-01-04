import Foundation

// MARK: - Rate Limited Requirement

/// Требование с ограничением частоты вызовов (rate limiting)
///
/// Ограничивает количество вызовов за определенный период времени.
/// Например: максимум 10 вызовов за 60 секунд.
public final class RateLimitedRequirement<Context: Sendable>: @unchecked Sendable {
  private let requirement: Requirement<Context>
  private let maxCalls: Int
  private let timeWindow: TimeInterval
  private let behavior: RateLimitBehavior
  
  private var callTimestamps: [Date] = []
  private var lastSuccessfulResult: Evaluation?
  private let lock = NSLock()
  
  /// Инициализатор
  /// - Parameters:
  ///   - requirement: Базовое требование
  ///   - maxCalls: Максимальное количество вызовов
  ///   - timeWindow: Временное окно в секундах
  ///   - behavior: Поведение при превышении лимита
  public init(
    requirement: Requirement<Context>,
    maxCalls: Int,
    timeWindow: TimeInterval,
    behavior: RateLimitBehavior = .default
  ) {
    self.requirement = requirement
    self.maxCalls = maxCalls
    self.timeWindow = timeWindow
    self.behavior = behavior
  }
  
  /// Оценивает требование с учетом rate limiting
  /// - Parameter context: Контекст для оценки
  /// - Returns: Результат оценки
  public func evaluate(_ context: Context) -> Evaluation {
    lock.lock()
    defer { lock.unlock() }
    
    let now = Date()
    
    // Очищаем устаревшие timestamps (старше timeWindow)
    let cutoffTime = now.addingTimeInterval(-timeWindow)
    callTimestamps.removeAll { $0 < cutoffTime }
    
    // Проверяем лимит
    if callTimestamps.count >= maxCalls {
      // Превышен лимит, применяем behavior
      return handleRateLimitExceeded()
    }
    
    // Добавляем текущий timestamp
    callTimestamps.append(now)
    
    // Выполняем проверку
    let result = requirement.evaluate(context)
    
    // Сохраняем успешный результат для кэширования
    if case .confirmed = result {
      lastSuccessfulResult = result
    }
    
    return result
  }
  
  private func handleRateLimitExceeded() -> Evaluation {
    switch behavior {
    case .returnFailed(let reason):
      return .failed(reason: reason)
      
    case .returnCached:
      // Возвращаем последний успешный результат или .confirmed, если его нет
      return lastSuccessfulResult ?? .confirmed
      
    case .skip:
      // Пропускаем проверку
      return .confirmed
    }
  }
  
  /// Сбрасывает счетчики вызовов
  public func reset() {
    lock.lock()
    defer { lock.unlock() }
    callTimestamps.removeAll()
    lastSuccessfulResult = nil
  }
  
  /// Количество вызовов в текущем окне
  public var currentCallCount: Int {
    lock.lock()
    defer { lock.unlock() }
    
    let now = Date()
    let cutoffTime = now.addingTimeInterval(-timeWindow)
    callTimestamps.removeAll { $0 < cutoffTime }
    
    return callTimestamps.count
  }
}

// MARK: - Расширение Requirement

extension Requirement {
  /// Создает требование с ограничением частоты вызовов
  /// - Parameters:
  ///   - maxCalls: Максимальное количество вызовов
  ///   - timeWindow: Временное окно в секундах
  ///   - behavior: Поведение при превышении лимита
  /// - Returns: Требование с rate limiting
  public func rateLimit(
    maxCalls: Int,
    timeWindow: TimeInterval,
    behavior: RateLimitBehavior = .default
  ) -> RateLimitedRequirement<Context> {
    RateLimitedRequirement(
      requirement: self,
      maxCalls: maxCalls,
      timeWindow: timeWindow,
      behavior: behavior
    )
  }
}

