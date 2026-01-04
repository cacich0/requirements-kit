import Foundation

// MARK: - Decision Middleware Protocol

/// Протокол для middleware, который перехватывает принятие решений
public protocol DecisionMiddleware: Sendable {
  /// Вызывается перед принятием решения
  func beforeDecision<Context: Sendable>(
    context: Context,
    decisionName: String?
  )
  
  /// Вызывается после принятия решения
  func afterDecision<Context: Sendable, Result: Sendable>(
    context: Context,
    decisionName: String?,
    result: Result?,
    duration: TimeInterval
  )
}

// MARK: - Logging Decision Middleware

/// Middleware для логирования принятия решений
public struct LoggingDecisionMiddleware: DecisionMiddleware {
  public enum LogLevel: Sendable {
    case verbose
    case info
    case warning
    case error
  }
  
  private let level: LogLevel
  private let prefix: String
  
  public init(level: LogLevel = .info, prefix: String = "[Decision]") {
    self.level = level
    self.prefix = prefix
  }
  
  public func beforeDecision<Context: Sendable>(
    context: Context,
    decisionName: String?
  ) {
    #if DEBUG
    if level == .verbose {
      let name = decisionName ?? "unnamed"
      print("\(prefix) Deciding: \(name)")
    }
    #endif
  }
  
  public func afterDecision<Context: Sendable, Result: Sendable>(
    context: Context,
    decisionName: String?,
    result: Result?,
    duration: TimeInterval
  ) {
    #if DEBUG
    let name = decisionName ?? "unnamed"
    let status = result != nil ? "✅" : "⚪️"
    let durationMs = String(format: "%.2f", duration * 1000)
    
    switch level {
    case .verbose, .info:
      print("\(prefix) \(status) \(name) (\(durationMs)ms)")
    case .warning where result == nil:
      print("\(prefix) ⚠️ \(name) returned nil")
    case .error where result == nil:
      print("\(prefix) ❌ \(name) returned nil")
    default:
      break
    }
    #endif
  }
}

// MARK: - Analytics Decision Middleware

/// Middleware для отправки аналитики о принятии решений
public struct AnalyticsDecisionMiddleware: DecisionMiddleware {
  public typealias AnalyticsHandler = @Sendable (String, [String: Any]) -> Void
  
  private let handler: AnalyticsHandler
  
  public init(handler: @escaping AnalyticsHandler) {
    self.handler = handler
  }
  
  public func beforeDecision<Context: Sendable>(
    context: Context,
    decisionName: String?
  ) {
    // Ничего не делаем до принятия решения
  }
  
  public func afterDecision<Context: Sendable, Result: Sendable>(
    context: Context,
    decisionName: String?,
    result: Result?,
    duration: TimeInterval
  ) {
    let eventName = "decision_made"
    let properties: [String: Any] = [
      "decision_name": decisionName ?? "unnamed",
      "has_result": result != nil,
      "duration_ms": duration * 1000
    ]
    
    handler(eventName, properties)
  }
}

// MARK: - Metrics Decision Middleware

/// Middleware для сбора метрик о принятии решений
public final class MetricsDecisionMiddleware: DecisionMiddleware, @unchecked Sendable {
  private let lock = NSLock()
  private var metrics: [String: DecisionMetrics] = [:]
  
  private struct DecisionMetrics {
    var totalCalls: Int = 0
    var successfulCalls: Int = 0
    var totalDuration: TimeInterval = 0
    var minDuration: TimeInterval = .infinity
    var maxDuration: TimeInterval = 0
  }
  
  public init() {}
  
  public func beforeDecision<Context: Sendable>(
    context: Context,
    decisionName: String?
  ) {
    // Ничего не делаем до принятия решения
  }
  
  public func afterDecision<Context: Sendable, Result: Sendable>(
    context: Context,
    decisionName: String?,
    result: Result?,
    duration: TimeInterval
  ) {
    let name = decisionName ?? "unnamed"
    
    lock.lock()
    defer { lock.unlock() }
    
    var metric = metrics[name] ?? DecisionMetrics()
    metric.totalCalls += 1
    if result != nil {
      metric.successfulCalls += 1
    }
    metric.totalDuration += duration
    metric.minDuration = min(metric.minDuration, duration)
    metric.maxDuration = max(metric.maxDuration, duration)
    metrics[name] = metric
  }
  
  /// Получить метрики для конкретного решения
  public func getMetrics(for name: String) -> (
    totalCalls: Int,
    successfulCalls: Int,
    averageDuration: TimeInterval,
    minDuration: TimeInterval,
    maxDuration: TimeInterval
  )? {
    lock.lock()
    defer { lock.unlock() }
    
    guard let metric = metrics[name] else { return nil }
    
    let avgDuration = metric.totalCalls > 0 
      ? metric.totalDuration / Double(metric.totalCalls)
      : 0
    
    return (
      totalCalls: metric.totalCalls,
      successfulCalls: metric.successfulCalls,
      averageDuration: avgDuration,
      minDuration: metric.minDuration == .infinity ? 0 : metric.minDuration,
      maxDuration: metric.maxDuration
    )
  }
  
  /// Получить все метрики
  public func getAllMetrics() -> [String: (totalCalls: Int, successfulCalls: Int, averageDuration: TimeInterval)] {
    lock.lock()
    defer { lock.unlock() }
    
    var result: [String: (Int, Int, TimeInterval)] = [:]
    for (name, metric) in metrics {
      let avgDuration = metric.totalCalls > 0 
        ? metric.totalDuration / Double(metric.totalCalls)
        : 0
      result[name] = (metric.totalCalls, metric.successfulCalls, avgDuration)
    }
    return result
  }
  
  /// Сбросить все метрики
  public func reset() {
    lock.lock()
    defer { lock.unlock() }
    metrics.removeAll()
  }
}

// MARK: - Расширение Decision для Middleware

extension Decision {
  /// Применяет middleware к решению
  /// - Parameter middlewares: Массив middleware
  /// - Returns: Решение с middleware
  public func with(middlewares: [any DecisionMiddleware]) -> Decision<Context, Result> {
    let original = self
    
    return Decision { context in
      let name: String? = nil // Можно добавить имя через named()
      let startTime = DispatchTime.now()
      
      // Before
      for middleware in middlewares {
        middleware.beforeDecision(context: context, decisionName: name)
      }
      
      // Decide
      let result = original.decide(context)
      
      // Calculate duration
      let endTime = DispatchTime.now()
      let duration = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
      
      // After
      for middleware in middlewares {
        middleware.afterDecision(
          context: context,
          decisionName: name,
          result: result,
          duration: duration
        )
      }
      
      return result
    }
  }
  
  /// Применяет один middleware к решению
  public func with(middleware: any DecisionMiddleware) -> Decision<Context, Result> {
    with(middlewares: [middleware])
  }
}

// MARK: - Расширение AsyncDecision для Middleware

extension AsyncDecision {
  /// Применяет middleware к асинхронному решению
  /// - Parameter middlewares: Массив middleware
  /// - Returns: Решение с middleware
  public func with(middlewares: [any DecisionMiddleware]) -> AsyncDecision<Context, Result> {
    let original = self
    
    return AsyncDecision { context in
      let name: String? = nil // Можно добавить имя через named()
      let startTime = DispatchTime.now()
      
      // Before
      for middleware in middlewares {
        middleware.beforeDecision(context: context, decisionName: name)
      }
      
      // Decide
      let result = try await original.decide(context)
      
      // Calculate duration
      let endTime = DispatchTime.now()
      let duration = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
      
      // After
      for middleware in middlewares {
        middleware.afterDecision(
          context: context,
          decisionName: name,
          result: result,
          duration: duration
        )
      }
      
      return result
    }
  }
  
  /// Применяет один middleware к асинхронному решению
  public func with(middleware: any DecisionMiddleware) -> AsyncDecision<Context, Result> {
    with(middlewares: [middleware])
  }
}

