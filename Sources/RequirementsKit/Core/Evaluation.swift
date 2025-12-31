/// Результат оценки требования.
public enum Evaluation: Sendable {
  /// Требование выполнено
  case confirmed
  
  /// Требование не выполнено
  case failed(reason: Reason)
  
  /// Возвращает true, если требование выполнено
  public var isConfirmed: Bool {
    if case .confirmed = self {
      return true
    }
    return false
  }
  
  /// Возвращает true, если требование не выполнено
  public var isFailed: Bool {
    !isConfirmed
  }
  
  /// Возвращает причину отказа, если требование не выполнено
  public var reason: Reason? {
    if case .failed(let reason) = self {
      return reason
    }
    return nil
  }
}

extension Evaluation: Equatable {
  public static func == (lhs: Evaluation, rhs: Evaluation) -> Bool {
    switch (lhs, rhs) {
    case (.confirmed, .confirmed):
      return true
    case (.failed(let lhsReason), .failed(let rhsReason)):
      return lhsReason == rhsReason
    default:
      return false
    }
  }
}

// MARK: - Сбор всех причин отказа

extension Evaluation {
  /// Возвращает все причины отказа из результата оценки
  /// Для простых требований возвращает одну причину, для составных - собирает все
  public var allFailures: [Reason] {
    if case .failed(let reason) = self {
      return [reason]
    }
    return []
  }
}

extension Requirement {
  /// Оценивает требование и возвращает все причины отказа
  /// - Parameter context: Контекст для оценки
  /// - Returns: Массив всех причин отказа (пустой если требование выполнено)
  public func allFailures(for context: Context) -> [Reason] {
    evaluate(context).allFailures
  }
}

