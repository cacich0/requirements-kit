import Foundation

// MARK: - Трассировка требований

/// Результат трассировки оценки требования
public struct RequirementTrace: Sendable {
  /// Путь оценки (имена вложенных требований)
  public let path: [String]
  
  /// Результат оценки
  public let evaluation: Evaluation
  
  /// Длительность оценки
  public let duration: TimeInterval
  
  /// Время оценки
  public let timestamp: Date
  
  /// Вложенные трассировки (для композитных требований)
  public let children: [RequirementTrace]
  
  public init(
    path: [String] = [],
    evaluation: Evaluation,
    duration: TimeInterval,
    timestamp: Date = Date(),
    children: [RequirementTrace] = []
  ) {
    self.path = path
    self.evaluation = evaluation
    self.duration = duration
    self.timestamp = timestamp
    self.children = children
  }
}

// MARK: - TracedRequirement

/// Требование с поддержкой трассировки
public struct TracedRequirement<Context: Sendable>: Sendable {
  private let requirement: Requirement<Context>
  private let name: String
  
  public init(requirement: Requirement<Context>, name: String = "root") {
    self.requirement = requirement
    self.name = name
  }
  
  /// Оценивает требование и возвращает трассировку
  public func evaluateWithTrace(_ context: Context) -> (Evaluation, RequirementTrace) {
    let startTime = DispatchTime.now()
    let result = requirement.evaluate(context)
    let endTime = DispatchTime.now()
    
    let duration = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
    
    let trace = RequirementTrace(
      path: [name],
      evaluation: result,
      duration: duration
    )
    
    return (result, trace)
  }
  
  /// Оценивает требование (без трассировки)
  public func evaluate(_ context: Context) -> Evaluation {
    requirement.evaluate(context)
  }
}

// MARK: - Расширение Requirement

extension Requirement {
  /// Создает трассируемую версию требования
  /// - Parameter name: Имя для трассировки
  /// - Returns: Трассируемое требование
  public func traced(name: String = "requirement") -> TracedRequirement<Context> {
    TracedRequirement(requirement: self, name: name)
  }
}

// MARK: - PerformanceMetrics

/// Метрики производительности оценки
public struct PerformanceMetrics: Sendable {
  /// Длительность оценки в секундах
  public let duration: TimeInterval
  
  /// Количество оценок
  public let evaluationCount: Int
  
  /// Средняя длительность
  public let averageDuration: TimeInterval
  
  /// Максимальная длительность
  public let maxDuration: TimeInterval
  
  /// Минимальная длительность
  public let minDuration: TimeInterval
  
  public init(
    duration: TimeInterval,
    evaluationCount: Int = 1,
    averageDuration: TimeInterval? = nil,
    maxDuration: TimeInterval? = nil,
    minDuration: TimeInterval? = nil
  ) {
    self.duration = duration
    self.evaluationCount = evaluationCount
    self.averageDuration = averageDuration ?? duration
    self.maxDuration = maxDuration ?? duration
    self.minDuration = minDuration ?? duration
  }
}

// MARK: - ProfiledRequirement

/// Требование с профилированием производительности
public final class ProfiledRequirement<Context: Sendable>: @unchecked Sendable {
  private let requirement: Requirement<Context>
  private var durations: [TimeInterval] = []
  private let lock = NSLock()
  
  public init(requirement: Requirement<Context>) {
    self.requirement = requirement
  }
  
  /// Оценивает требование и возвращает метрики
  public func evaluateWithMetrics(_ context: Context) -> (Evaluation, PerformanceMetrics) {
    let startTime = DispatchTime.now()
    let result = requirement.evaluate(context)
    let endTime = DispatchTime.now()
    
    let duration = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
    
    lock.lock()
    durations.append(duration)
    let metrics = PerformanceMetrics(
      duration: duration,
      evaluationCount: durations.count,
      averageDuration: durations.reduce(0, +) / Double(durations.count),
      maxDuration: durations.max() ?? duration,
      minDuration: durations.min() ?? duration
    )
    lock.unlock()
    
    return (result, metrics)
  }
  
  /// Текущие метрики
  public var metrics: PerformanceMetrics? {
    lock.lock()
    defer { lock.unlock() }
    
    guard !durations.isEmpty else { return nil }
    
    return PerformanceMetrics(
      duration: durations.last!,
      evaluationCount: durations.count,
      averageDuration: durations.reduce(0, +) / Double(durations.count),
      maxDuration: durations.max()!,
      minDuration: durations.min()!
    )
  }
  
  /// Сбрасывает статистику
  public func reset() {
    lock.lock()
    defer { lock.unlock() }
    durations.removeAll()
  }
}

// MARK: - Расширение для профилирования

extension Requirement {
  /// Создает профилируемую версию требования
  public func profiled() -> ProfiledRequirement<Context> {
    ProfiledRequirement(requirement: self)
  }
}

