/// Property wrapper для простого Boolean-доступа к требованию
///
/// Пример использования:
/// ```swift
/// @Eligible(by: canTrade, context: userContext)
/// var canUserTrade: Bool
/// ```
@propertyWrapper
public struct Eligible<Context: Sendable> {
  private let requirement: Requirement<Context>
  private let context: Context
  
  /// Создает wrapper для проверки требования
  /// - Parameters:
  ///   - requirement: Требование для проверки
  ///   - context: Контекст для оценки
  public init(by requirement: Requirement<Context>, context: Context) {
    self.requirement = requirement
    self.context = context
  }
  
  /// Возвращает true если требование выполнено
  public var wrappedValue: Bool {
    requirement.evaluate(context).isConfirmed
  }
}

