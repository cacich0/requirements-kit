/// Property wrapper для расширенного доступа к результату проверки требования
///
/// Пример использования:
/// ```swift
/// @Eligibility(by: canTrade, context: userContext)
/// var tradeEligibility
///
/// if tradeEligibility.isAllowed {
///     trade()
/// } else {
///     print(tradeEligibility.reason)
/// }
/// ```
@propertyWrapper
public struct Eligibility<Context: Sendable> {
  private let requirement: Requirement<Context>
  private let context: Context
  
  /// Создает wrapper для проверки требования с доступом к причине отказа
  /// - Parameters:
  ///   - requirement: Требование для проверки
  ///   - context: Контекст для оценки
  public init(by requirement: Requirement<Context>, context: Context) {
    self.requirement = requirement
    self.context = context
  }
  
  /// Возвращает результат проверки требования
  public var wrappedValue: EligibilityResult {
    let evaluation = requirement.evaluate(context)
    return EligibilityResult(evaluation: evaluation)
  }
  
  /// Возвращает результат проверки требования (для удобного доступа через $)
  public var projectedValue: EligibilityResult {
    wrappedValue
  }
  
  /// Результат проверки требования с дополнительной информацией
  public struct EligibilityResult {
    /// Результат оценки требования
    public let evaluation: Evaluation
    
    /// Требование выполнено
    public var isAllowed: Bool {
      evaluation.isConfirmed
    }
    
    /// Требование не выполнено
    public var isDenied: Bool {
      evaluation.isFailed
    }
    
    /// Причина отказа (nil если требование выполнено)
    public var reason: Reason? {
      evaluation.reason
    }
    
    /// Все причины отказа
    public var allFailures: [Reason] {
      evaluation.allFailures
    }
    
    init(evaluation: Evaluation) {
      self.evaluation = evaluation
    }
  }
}

