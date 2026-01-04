import Foundation

// MARK: - Трассировка решений

/// Результат трассировки принятия решения
public struct DecisionTrace<Result: Sendable>: Sendable {
  /// Путь принятия решения (имена вложенных решений)
  public let path: [String]
  
  /// Результат решения
  public let result: Result?
  
  /// Длительность принятия решения
  public let duration: TimeInterval
  
  /// Время принятия решения
  public let timestamp: Date
  
  /// Вложенные трассировки (для композитных решений)
  public let children: [DecisionTrace<Result>]
  
  public init(
    path: [String] = [],
    result: Result?,
    duration: TimeInterval,
    timestamp: Date = Date(),
    children: [DecisionTrace<Result>] = []
  ) {
    self.path = path
    self.result = result
    self.duration = duration
    self.timestamp = timestamp
    self.children = children
  }
}

// MARK: - TracedDecision

/// Решение с поддержкой трассировки
public struct TracedDecision<Context: Sendable, Result: Sendable>: Sendable {
  private let decision: Decision<Context, Result>
  private let name: String
  
  public init(decision: Decision<Context, Result>, name: String = "root") {
    self.decision = decision
    self.name = name
  }
  
  /// Принимает решение и возвращает трассировку
  public func decideWithTrace(_ context: Context) -> (Result?, DecisionTrace<Result>) {
    let startTime = DispatchTime.now()
    let result = decision.decide(context)
    let endTime = DispatchTime.now()
    
    let duration = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
    
    let trace = DecisionTrace<Result>(
      path: [name],
      result: result,
      duration: duration
    )
    
    return (result, trace)
  }
  
  /// Принимает решение (без трассировки)
  public func decide(_ context: Context) -> Result? {
    decision.decide(context)
  }
}

// MARK: - TracedAsyncDecision

/// Асинхронное решение с поддержкой трассировки
public struct TracedAsyncDecision<Context: Sendable, Result: Sendable>: Sendable {
  private let decision: AsyncDecision<Context, Result>
  private let name: String
  
  public init(decision: AsyncDecision<Context, Result>, name: String = "root") {
    self.decision = decision
    self.name = name
  }
  
  /// Принимает асинхронное решение и возвращает трассировку
  public func decideWithTrace(_ context: Context) async throws -> (Result?, DecisionTrace<Result>) {
    let startTime = DispatchTime.now()
    let result = try await decision.decide(context)
    let endTime = DispatchTime.now()
    
    let duration = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
    
    let trace = DecisionTrace<Result>(
      path: [name],
      result: result,
      duration: duration
    )
    
    return (result, trace)
  }
  
  /// Принимает решение (без трассировки)
  public func decide(_ context: Context) async throws -> Result? {
    try await decision.decide(context)
  }
}

// MARK: - Расширение Decision

extension Decision {
  /// Создает трассируемую версию решения
  /// - Parameter name: Имя для трассировки
  /// - Returns: Трассируемое решение
  public func traced(name: String = "decision") -> TracedDecision<Context, Result> {
    TracedDecision(decision: self, name: name)
  }
}

// MARK: - Расширение AsyncDecision

extension AsyncDecision {
  /// Создает трассируемую версию асинхронного решения
  /// - Parameter name: Имя для трассировки
  /// - Returns: Трассируемое решение
  public func traced(name: String = "decision") -> TracedAsyncDecision<Context, Result> {
    TracedAsyncDecision(decision: self, name: name)
  }
}

// MARK: - DecisionPerformanceMetrics

/// Метрики производительности принятия решения
public struct DecisionPerformanceMetrics: Sendable {
  /// Длительность принятия решения в секундах
  public let duration: TimeInterval
  
  /// Количество принятий решений
  public let decisionCount: Int
  
  /// Средняя длительность
  public let averageDuration: TimeInterval
  
  /// Максимальная длительность
  public let maxDuration: TimeInterval
  
  /// Минимальная длительность
  public let minDuration: TimeInterval
  
  /// Количество успешных решений (не nil)
  public let successCount: Int
  
  public init(
    duration: TimeInterval,
    decisionCount: Int = 1,
    averageDuration: TimeInterval? = nil,
    maxDuration: TimeInterval? = nil,
    minDuration: TimeInterval? = nil,
    successCount: Int = 0
  ) {
    self.duration = duration
    self.decisionCount = decisionCount
    self.averageDuration = averageDuration ?? duration
    self.maxDuration = maxDuration ?? duration
    self.minDuration = minDuration ?? duration
    self.successCount = successCount
  }
}

// MARK: - ProfiledDecision

/// Решение с профилированием производительности
public final class ProfiledDecision<Context: Sendable, Result: Sendable>: @unchecked Sendable {
  private let decision: Decision<Context, Result>
  private var durations: [TimeInterval] = []
  private var successfulDecisions: Int = 0
  private let lock = NSLock()
  
  public init(decision: Decision<Context, Result>) {
    self.decision = decision
  }
  
  /// Принимает решение и возвращает метрики
  public func decideWithMetrics(_ context: Context) -> (Result?, DecisionPerformanceMetrics) {
    let startTime = DispatchTime.now()
    let result = decision.decide(context)
    let endTime = DispatchTime.now()
    
    let duration = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
    
    lock.lock()
    durations.append(duration)
    if result != nil {
      successfulDecisions += 1
    }
    let metrics = DecisionPerformanceMetrics(
      duration: duration,
      decisionCount: durations.count,
      averageDuration: durations.reduce(0, +) / Double(durations.count),
      maxDuration: durations.max() ?? duration,
      minDuration: durations.min() ?? duration,
      successCount: successfulDecisions
    )
    lock.unlock()
    
    return (result, metrics)
  }
  
  /// Принимает решение без возврата метрик
  public func decide(_ context: Context) -> Result? {
    let (result, _) = decideWithMetrics(context)
    return result
  }
  
  /// Текущие метрики
  public var metrics: DecisionPerformanceMetrics? {
    lock.lock()
    defer { lock.unlock() }
    
    guard !durations.isEmpty else { return nil }
    
    return DecisionPerformanceMetrics(
      duration: durations.last!,
      decisionCount: durations.count,
      averageDuration: durations.reduce(0, +) / Double(durations.count),
      maxDuration: durations.max()!,
      minDuration: durations.min()!,
      successCount: successfulDecisions
    )
  }
  
  /// Сбрасывает статистику
  public func reset() {
    lock.lock()
    defer { lock.unlock() }
    durations.removeAll()
    successfulDecisions = 0
  }
}

// MARK: - ProfiledAsyncDecision

/// Асинхронное решение с профилированием производительности
public actor ProfiledAsyncDecision<Context: Sendable, Result: Sendable> {
  private let decision: AsyncDecision<Context, Result>
  private var durations: [TimeInterval] = []
  private var successfulDecisions: Int = 0
  
  public init(decision: AsyncDecision<Context, Result>) {
    self.decision = decision
  }
  
  /// Принимает решение и возвращает метрики
  public func decideWithMetrics(_ context: Context) async throws -> (Result?, DecisionPerformanceMetrics) {
    let startTime = DispatchTime.now()
    let result = try await decision.decide(context)
    let endTime = DispatchTime.now()
    
    let duration = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
    
    durations.append(duration)
    if result != nil {
      successfulDecisions += 1
    }
    let metrics = DecisionPerformanceMetrics(
      duration: duration,
      decisionCount: durations.count,
      averageDuration: durations.reduce(0, +) / Double(durations.count),
      maxDuration: durations.max() ?? duration,
      minDuration: durations.min() ?? duration,
      successCount: successfulDecisions
    )
    
    return (result, metrics)
  }
  
  /// Принимает решение без возврата метрик
  public func decide(_ context: Context) async throws -> Result? {
    let (result, _) = try await decideWithMetrics(context)
    return result
  }
  
  /// Текущие метрики
  public var metrics: DecisionPerformanceMetrics? {
    guard !durations.isEmpty else { return nil }
    
    return DecisionPerformanceMetrics(
      duration: durations.last!,
      decisionCount: durations.count,
      averageDuration: durations.reduce(0, +) / Double(durations.count),
      maxDuration: durations.max()!,
      minDuration: durations.min()!,
      successCount: successfulDecisions
    )
  }
  
  /// Сбрасывает статистику
  public func reset() {
    durations.removeAll()
    successfulDecisions = 0
  }
}

// MARK: - Расширение для профилирования

extension Decision {
  /// Создает профилируемую версию решения
  public func profiled() -> ProfiledDecision<Context, Result> {
    ProfiledDecision(decision: self)
  }
}

extension AsyncDecision {
  /// Создает профилируемую версию асинхронного решения
  public func profiled() -> ProfiledAsyncDecision<Context, Result> {
    ProfiledAsyncDecision(decision: self)
  }
}

