import Foundation

// MARK: - Middleware Protocol

/// Протокол для middleware, который перехватывает оценку требований
public protocol RequirementMiddleware: Sendable {
  /// Вызывается перед оценкой требования
  func beforeEvaluation<Context: Sendable>(
    context: Context,
    requirementName: String?
  )
  
  /// Вызывается после оценки требования
  func afterEvaluation<Context: Sendable>(
    context: Context,
    requirementName: String?,
    result: Evaluation,
    duration: TimeInterval
  )
}

// MARK: - Logging Middleware

/// Middleware для логирования оценок требований
public struct LoggingMiddleware: RequirementMiddleware {
  public enum LogLevel: Sendable {
    case verbose
    case info
    case warning
    case error
  }
  
  private let level: LogLevel
  private let prefix: String
  
  public init(level: LogLevel = .info, prefix: String = "[Requirement]") {
    self.level = level
    self.prefix = prefix
  }
  
  public func beforeEvaluation<Context: Sendable>(
    context: Context,
    requirementName: String?
  ) {
    #if DEBUG
    if level == .verbose {
      let name = requirementName ?? "unnamed"
      print("\(prefix) Evaluating: \(name)")
    }
    #endif
  }
  
  public func afterEvaluation<Context: Sendable>(
    context: Context,
    requirementName: String?,
    result: Evaluation,
    duration: TimeInterval
  ) {
    #if DEBUG
    let name = requirementName ?? "unnamed"
    let status = result.isConfirmed ? "✅" : "❌"
    let durationMs = String(format: "%.2f", duration * 1000)
    
    switch level {
    case .verbose, .info:
      print("\(prefix) \(status) \(name) (\(durationMs)ms)")
    case .warning where result.isFailed:
      print("\(prefix) ⚠️ \(name) failed: \(result.reason?.message ?? "unknown")")
    case .error where result.isFailed:
      print("\(prefix) ❌ \(name) failed: \(result.reason?.message ?? "unknown")")
    default:
      break
    }
    #endif
  }
}

// MARK: - Analytics Middleware

/// Middleware для отправки аналитики
public struct AnalyticsMiddleware: RequirementMiddleware {
  public typealias AnalyticsHandler = @Sendable (String, [String: Any]) -> Void
  
  private let handler: AnalyticsHandler
  
  public init(handler: @escaping AnalyticsHandler) {
    self.handler = handler
  }
  
  public func beforeEvaluation<Context: Sendable>(
    context: Context,
    requirementName: String?
  ) {
    // Ничего не делаем до оценки
  }
  
  public func afterEvaluation<Context: Sendable>(
    context: Context,
    requirementName: String?,
    result: Evaluation,
    duration: TimeInterval
  ) {
    let eventName = "requirement_evaluated"
    let properties: [String: Any] = [
      "requirement_name": requirementName ?? "unnamed",
      "result": result.isConfirmed ? "confirmed" : "failed",
      "reason_code": result.reason?.code ?? "",
      "duration_ms": duration * 1000
    ]
    
    handler(eventName, properties)
  }
}

// MARK: - Расширение Requirement для Middleware

extension Requirement {
  /// Применяет middleware к требованию
  /// - Parameter middlewares: Массив middleware
  /// - Returns: Требование с middleware
  public func with(middlewares: [any RequirementMiddleware]) -> Requirement<Context> {
    let original = self
    
    return Requirement { context in
      let name: String? = nil // Можно добавить имя через named()
      let startTime = DispatchTime.now()
      
      // Before
      for middleware in middlewares {
        middleware.beforeEvaluation(context: context, requirementName: name)
      }
      
      // Evaluate
      let result = original.evaluate(context)
      
      // Calculate duration
      let endTime = DispatchTime.now()
      let duration = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
      
      // After
      for middleware in middlewares {
        middleware.afterEvaluation(
          context: context,
          requirementName: name,
          result: result,
          duration: duration
        )
      }
      
      return result
    }
  }
  
  /// Применяет один middleware к требованию
  public func with(middleware: any RequirementMiddleware) -> Requirement<Context> {
    with(middlewares: [middleware])
  }
}

