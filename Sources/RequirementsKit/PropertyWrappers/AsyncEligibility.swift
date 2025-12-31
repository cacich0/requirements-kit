// MARK: - Async Eligibility Property Wrapper

/// Property wrapper для асинхронной проверки доступа
/// Предоставляет доступ к результату асинхронной проверки требования
///
/// Использование:
/// ```swift
/// class UserService {
///   @AsyncEligibility(
///     by: hasValidSubscription,
///     context: userContext
///   )
///   var subscriptionCheck
/// }
///
/// // Проверка:
/// let result = await userService.$subscriptionCheck.check()
/// if result.isAllowed {
///   // proceed
/// }
/// ```
@propertyWrapper
public struct AsyncEligibility<Context: Sendable>: Sendable {
  private let requirement: AsyncRequirement<Context>
  private let context: Context
  
  /// Результат проверки асинхронного требования
  public struct Result: Sendable {
    public let isAllowed: Bool
    public let reason: Reason?
    
    public init(isAllowed: Bool, reason: Reason? = nil) {
      self.isAllowed = isAllowed
      self.reason = reason
    }
    
    public static func from(_ evaluation: Evaluation) -> Result {
      switch evaluation {
      case .confirmed:
        return Result(isAllowed: true)
      case .failed(let reason):
        return Result(isAllowed: false, reason: reason)
      }
    }
  }
  
  /// Инициализатор
  /// - Parameters:
  ///   - requirement: Асинхронное требование для проверки
  ///   - context: Контекст для проверки
  public init(by requirement: AsyncRequirement<Context>, context: Context) {
    self.requirement = requirement
    self.context = context
  }
  
  public var wrappedValue: AsyncEligibility<Context> {
    self
  }
  
  public var projectedValue: AsyncEligibility<Context> {
    self
  }
  
  /// Выполняет асинхронную проверку требования
  /// - Returns: Результат проверки
  public func check() async throws -> Result {
    let evaluation = try await requirement.evaluate(context)
    return Result.from(evaluation)
  }
  
  /// Выполняет проверку и возвращает булево значение
  /// - Returns: true если требование выполнено
  public func isAllowed() async throws -> Bool {
    let result = try await check()
    return result.isAllowed
  }
  
  /// Выполняет проверку с обработкой ошибок
  /// - Parameter defaultValue: Значение по умолчанию при ошибке
  /// - Returns: Результат или значение по умолчанию
  public func checkOrDefault(_ defaultValue: Result = Result(isAllowed: false)) async -> Result {
    do {
      return try await check()
    } catch {
      return defaultValue
    }
  }
}

// MARK: - Convenience initializers

extension AsyncEligibility {
  /// Создает AsyncEligibility из синхронного требования
  /// - Parameters:
  ///   - requirement: Синхронное требование
  ///   - context: Контекст
  public init(by requirement: Requirement<Context>, context: Context) {
    self.requirement = AsyncRequirement.from(requirement)
    self.context = context
  }
}

