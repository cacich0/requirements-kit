// MARK: - NOT (Инверсия требования)

extension Requirement {
  /// Создает требование, которое является инверсией переданного требования
  /// - Parameter requirement: Требование для инверсии
  /// - Returns: Требование, которое выполнено если переданное требование не выполнено, и наоборот
  public static func not(_ requirement: Requirement<Context>) -> Requirement<Context> {
    Requirement { context in
      let result = requirement.evaluate(context)
      
      switch result {
      case .confirmed:
        return .failed(reason: Reason(
          code: "not_failed",
          message: "Requirement should not be met"
        ))
      case .failed:
        return .confirmed
      }
    }
  }
  
  /// Добавляет метод инверсии к требованию (fluent API)
  /// - Returns: Инвертированное требование
  public func not() -> Requirement<Context> {
    Requirement.not(self)
  }
}

