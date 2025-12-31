// MARK: - Типизированные причины отказа

/// Протокол для типизированных причин отказа
///
/// Позволяет создавать enum-based причины отказа с типобезопасностью
///
/// Использование:
/// ```swift
/// enum AuthFailure: FailureReason {
///   case notLoggedIn
///   case sessionExpired
///   case insufficientPermissions
///
///   var code: String {
///     switch self {
///     case .notLoggedIn: return "auth.not_logged_in"
///     case .sessionExpired: return "auth.session_expired"
///     case .insufficientPermissions: return "auth.insufficient_permissions"
///     }
///   }
///
///   var message: String {
///     switch self {
///     case .notLoggedIn: return "Please log in to continue"
///     case .sessionExpired: return "Your session has expired"
///     case .insufficientPermissions: return "You don't have permission"
///     }
///   }
/// }
/// ```
public protocol FailureReason: Hashable, Sendable {
  /// Уникальный код причины
  var code: String { get }
  
  /// Человекочитаемое сообщение
  var message: String { get }
  
  /// Уровень серьезности
  var severity: Severity { get }
}

// Значение по умолчанию для severity
extension FailureReason {
  public var severity: Severity { .error }
}

// MARK: - Severity (Уровень серьезности)

/// Уровень серьезности причины отказа
public enum Severity: Int, Comparable, Sendable {
  /// Информационное сообщение (не блокирует)
  case info = 0
  
  /// Предупреждение (не блокирует, но требует внимания)
  case warning = 1
  
  /// Ошибка (блокирует действие)
  case error = 2
  
  /// Критическая ошибка (требует немедленного внимания)
  case critical = 3
  
  public static func < (lhs: Severity, rhs: Severity) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

// MARK: - Reason conformance

extension Reason: FailureReason {
  public var severity: Severity { .error }
}

// MARK: - TypedEvaluation

/// Результат оценки с типизированной причиной отказа
public enum TypedEvaluation<Failure: FailureReason>: Sendable where Failure: Sendable {
  case confirmed
  case failed(reason: Failure)
  
  /// Требование выполнено
  public var isConfirmed: Bool {
    if case .confirmed = self { return true }
    return false
  }
  
  /// Требование не выполнено
  public var isFailed: Bool {
    !isConfirmed
  }
  
  /// Причина отказа (nil если требование выполнено)
  public var reason: Failure? {
    if case let .failed(reason) = self { return reason }
    return nil
  }
  
  /// Конвертирует в стандартный Evaluation
  public func toEvaluation() -> Evaluation {
    switch self {
    case .confirmed:
      return .confirmed
    case .failed(let reason):
      return .failed(reason: Reason(code: reason.code, message: reason.message))
    }
  }
}

// MARK: - TypedRequirement

/// Требование с типизированной причиной отказа
public struct TypedRequirement<Context: Sendable, Failure: FailureReason>: Sendable where Failure: Sendable {
  private let evaluator: @Sendable (Context) -> TypedEvaluation<Failure>
  
  /// Создает типизированное требование
  public init(evaluator: @escaping @Sendable (Context) -> TypedEvaluation<Failure>) {
    self.evaluator = evaluator
  }
  
  /// Оценивает требование
  public func evaluate(_ context: Context) -> TypedEvaluation<Failure> {
    evaluator(context)
  }
  
  /// Конвертирует в обычное требование
  public func toRequirement() -> Requirement<Context> {
    Requirement { context in
      self.evaluate(context).toEvaluation()
    }
  }
}

// MARK: - Фабричные методы для TypedRequirement

extension TypedRequirement {
  /// Всегда подтвержденное требование
  public static var always: TypedRequirement<Context, Failure> {
    TypedRequirement { _ in .confirmed }
  }
  
  /// Всегда отклоненное требование
  public static func never(reason: Failure) -> TypedRequirement<Context, Failure> {
    TypedRequirement { _ in .failed(reason: reason) }
  }
  
  /// Создает требование из KeyPath и причины
  public static func require(
    _ keyPath: KeyPath<Context, Bool> & Sendable,
    or failure: Failure
  ) -> TypedRequirement<Context, Failure> {
    TypedRequirement { context in
      context[keyPath: keyPath] ? .confirmed : .failed(reason: failure)
    }
  }
  
  /// Создает требование из предиката
  public static func predicate(
    _ predicate: @escaping @Sendable (Context) -> Bool,
    or failure: Failure
  ) -> TypedRequirement<Context, Failure> {
    TypedRequirement { context in
      predicate(context) ? .confirmed : .failed(reason: failure)
    }
  }
}

// MARK: - Расширение Requirement для типизированных причин

extension Requirement {
  /// Добавляет типизированную причину отказа
  /// - Parameter failure: Типизированная причина
  /// - Returns: Требование с обновленной причиной
  public func becauseTyped<Failure: FailureReason>(_ failure: Failure) -> Requirement<Context> {
    let original = self
    return Requirement { context in
      let result = original.evaluate(context)
      if case .failed = result {
        return .failed(reason: Reason(code: failure.code, message: failure.message))
      }
      return result
    }
  }
}

// MARK: - Группы причин

/// Базовые причины отказа для общего использования
public enum CommonFailure: FailureReason {
  case notMet
  case conditionFailed(String)
  case valueOutOfRange
  case missingValue
  case invalidState
  
  public var code: String {
    switch self {
    case .notMet: return "requirement.not_met"
    case .conditionFailed: return "requirement.condition_failed"
    case .valueOutOfRange: return "requirement.value_out_of_range"
    case .missingValue: return "requirement.missing_value"
    case .invalidState: return "requirement.invalid_state"
    }
  }
  
  public var message: String {
    switch self {
    case .notMet: return "Requirement was not met"
    case .conditionFailed(let condition): return "Condition failed: \(condition)"
    case .valueOutOfRange: return "Value is out of acceptable range"
    case .missingValue: return "Required value is missing"
    case .invalidState: return "Invalid state for this operation"
    }
  }
}

