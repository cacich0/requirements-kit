import Foundation

// MARK: - Throttled Requirement

/// Требование с throttling - ограничение частоты вызовов
///
/// Throttling позволяет выполнять требование не чаще, чем раз в указанный интервал.
/// В отличие от rate limiting, throttling просто пропускает вызовы, если прошло
/// недостаточно времени с момента последнего выполнения.
public final class ThrottledRequirement<Context: Sendable>: @unchecked Sendable {
  private let requirement: Requirement<Context>
  private let interval: TimeInterval
  private let behavior: ThrottleBehavior
  
  private var lastCallTime: Date?
  private var lastResult: Evaluation?
  private let lock = NSLock()
  
  /// Инициализатор
  /// - Parameters:
  ///   - requirement: Базовое требование
  ///   - interval: Минимальный интервал между вызовами в секундах
  ///   - behavior: Поведение при слишком частых вызовах
  public init(
    requirement: Requirement<Context>,
    interval: TimeInterval,
    behavior: ThrottleBehavior = .default
  ) {
    self.requirement = requirement
    self.interval = interval
    self.behavior = behavior
  }
  
  /// Оценивает требование с учетом throttling
  /// - Parameter context: Контекст для оценки
  /// - Returns: Результат оценки
  public func evaluate(_ context: Context) -> Evaluation {
    lock.lock()
    defer { lock.unlock() }
    
    let now = Date()
    
    // Проверяем, прошло ли достаточно времени с последнего вызова
    if let lastCall = lastCallTime {
      let timeSinceLastCall = now.timeIntervalSince(lastCall)
      if timeSinceLastCall < interval {
        // Недостаточно времени прошло, применяем behavior
        return handleThrottled()
      }
    }
    
    // Обновляем время последнего вызова
    lastCallTime = now
    
    // Выполняем проверку
    let result = requirement.evaluate(context)
    
    // Сохраняем результат для кэширования
    lastResult = result
    
    return result
  }
  
  private func handleThrottled() -> Evaluation {
    switch behavior {
    case .returnFailed(let reason):
      return .failed(reason: reason)
      
    case .returnCached:
      // Возвращаем последний результат или .confirmed, если его нет
      return lastResult ?? .confirmed
      
    case .skip:
      // Пропускаем проверку
      return .confirmed
    }
  }
  
  /// Сбрасывает состояние throttling
  public func reset() {
    lock.lock()
    defer { lock.unlock() }
    lastCallTime = nil
    lastResult = nil
  }
  
  /// Время в секундах до следующего доступного вызова
  public var timeUntilNextCall: TimeInterval {
    lock.lock()
    defer { lock.unlock() }
    
    guard let lastCall = lastCallTime else {
      return 0
    }
    
    let timeSinceLastCall = Date().timeIntervalSince(lastCall)
    let remaining = interval - timeSinceLastCall
    return max(0, remaining)
  }
}

// MARK: - Async Throttled Requirement

/// Асинхронное требование с throttling
public actor AsyncThrottledRequirement<Context: Sendable> {
  private let requirement: AsyncRequirement<Context>
  private let interval: TimeInterval
  private let behavior: ThrottleBehavior
  
  private var lastCallTime: Date?
  private var lastResult: Evaluation?
  
  /// Инициализатор
  /// - Parameters:
  ///   - requirement: Базовое асинхронное требование
  ///   - interval: Минимальный интервал между вызовами в секундах
  ///   - behavior: Поведение при слишком частых вызовах
  public init(
    requirement: AsyncRequirement<Context>,
    interval: TimeInterval,
    behavior: ThrottleBehavior = .default
  ) {
    self.requirement = requirement
    self.interval = interval
    self.behavior = behavior
  }
  
  /// Оценивает требование с учетом throttling
  /// - Parameter context: Контекст для оценки
  /// - Returns: Результат оценки
  public func evaluate(_ context: Context) async throws -> Evaluation {
    let now = Date()
    
    // Проверяем, прошло ли достаточно времени с последнего вызова
    if let lastCall = lastCallTime {
      let timeSinceLastCall = now.timeIntervalSince(lastCall)
      if timeSinceLastCall < interval {
        // Недостаточно времени прошло, применяем behavior
        return handleThrottled()
      }
    }
    
    // Обновляем время последнего вызова
    lastCallTime = now
    
    // Выполняем проверку
    let result = try await requirement.evaluate(context)
    
    // Сохраняем результат для кэширования
    lastResult = result
    
    return result
  }
  
  private func handleThrottled() -> Evaluation {
    switch behavior {
    case .returnFailed(let reason):
      return .failed(reason: reason)
      
    case .returnCached:
      // Возвращаем последний результат или .confirmed, если его нет
      return lastResult ?? .confirmed
      
    case .skip:
      // Пропускаем проверку
      return .confirmed
    }
  }
  
  /// Сбрасывает состояние throttling
  public func reset() {
    lastCallTime = nil
    lastResult = nil
  }
  
  /// Время в секундах до следующего доступного вызова
  public var timeUntilNextCall: TimeInterval {
    get async {
      guard let lastCall = lastCallTime else {
        return 0
      }
      
      let timeSinceLastCall = Date().timeIntervalSince(lastCall)
      let remaining = interval - timeSinceLastCall
      return max(0, remaining)
    }
  }
}

// MARK: - Расширения

extension Requirement {
  /// Создает требование с throttling
  /// - Parameters:
  ///   - interval: Минимальный интервал между вызовами в секундах
  ///   - behavior: Поведение при слишком частых вызовах
  /// - Returns: Требование с throttling
  public func throttle(
    interval: TimeInterval,
    behavior: ThrottleBehavior = .default
  ) -> ThrottledRequirement<Context> {
    ThrottledRequirement(
      requirement: self,
      interval: interval,
      behavior: behavior
    )
  }
}

extension AsyncRequirement {
  /// Создает асинхронное требование с throttling
  /// - Parameters:
  ///   - interval: Минимальный интервал между вызовами в секундах
  ///   - behavior: Поведение при слишком частых вызовах
  /// - Returns: Требование с throttling
  public func throttle(
    interval: TimeInterval,
    behavior: ThrottleBehavior = .default
  ) -> AsyncThrottledRequirement<Context> {
    AsyncThrottledRequirement(
      requirement: self,
      interval: interval,
      behavior: behavior
    )
  }
}

