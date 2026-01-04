import Foundation

// MARK: - Async Rate Limited Requirement

/// Асинхронное требование с ограничением частоты вызовов (rate limiting)
///
/// Ограничивает количество асинхронных вызовов за определенный период времени.
/// Использует actor для thread-safety.
public actor AsyncRateLimitedRequirement<Context: Sendable> {
  private let requirement: AsyncRequirement<Context>
  private let maxCalls: Int
  private let timeWindow: TimeInterval
  private let behavior: RateLimitBehavior
  
  private var callTimestamps: [Date] = []
  private var lastSuccessfulResult: Evaluation?
  
  /// Инициализатор
  /// - Parameters:
  ///   - requirement: Базовое асинхронное требование
  ///   - maxCalls: Максимальное количество вызовов
  ///   - timeWindow: Временное окно в секундах
  ///   - behavior: Поведение при превышении лимита
  public init(
    requirement: AsyncRequirement<Context>,
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
  public func evaluate(_ context: Context) async throws -> Evaluation {
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
    let result = try await requirement.evaluate(context)
    
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
    callTimestamps.removeAll()
    lastSuccessfulResult = nil
  }
  
  /// Количество вызовов в текущем окне
  public var currentCallCount: Int {
    get async {
      let now = Date()
      let cutoffTime = now.addingTimeInterval(-timeWindow)
      callTimestamps.removeAll { $0 < cutoffTime }
      return callTimestamps.count
    }
  }
}

// MARK: - Расширение AsyncRequirement

extension AsyncRequirement {
  /// Создает асинхронное требование с ограничением частоты вызовов
  /// - Parameters:
  ///   - maxCalls: Максимальное количество вызовов
  ///   - timeWindow: Временное окно в секундах
  ///   - behavior: Поведение при превышении лимита
  /// - Returns: Требование с rate limiting
  public func rateLimit(
    maxCalls: Int,
    timeWindow: TimeInterval,
    behavior: RateLimitBehavior = .default
  ) -> AsyncRateLimitedRequirement<Context> {
    AsyncRateLimitedRequirement(
      requirement: self,
      maxCalls: maxCalls,
      timeWindow: timeWindow,
      behavior: behavior
    )
  }
}

