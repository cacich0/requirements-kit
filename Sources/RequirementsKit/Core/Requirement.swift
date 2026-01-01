/// Бизнес-требование, которое может быть проверено для заданного контекста.
public struct Requirement<Context: Sendable>: Sendable {
  private let evaluator: @Sendable (Context) -> Evaluation
  
  /// Создает требование с пользовательской логикой оценки
  /// - Parameter evaluator: Функция, которая принимает контекст и возвращает результат оценки
  public init(evaluator: @escaping @Sendable (Context) -> Evaluation) {
    self.evaluator = evaluator
  }
  
  /// Оценивает требование для заданного контекста
  /// - Parameter context: Контекст для оценки
  /// - Returns: Результат оценки требования
  public func evaluate(_ context: Context) -> Evaluation {
    evaluator(context)
  }
}

// MARK: - Базовые фабричные методы

extension Requirement {
  /// Создает требование, которое всегда выполнено
  public static var always: Requirement<Context> {
    Requirement { _ in .confirmed }
  }
  
  /// Создает требование, которое никогда не выполнено
  /// - Parameter reason: Причина отказа
  public static func never(reason: Reason) -> Requirement<Context> {
    Requirement { _ in .failed(reason: reason) }
  }
  
  /// Создает требование на основе KeyPath к Boolean значению
  /// - Parameter keyPath: Путь к булевому свойству в контексте
  public static func require(_ keyPath: KeyPath<Context, Bool> & Sendable) -> Requirement<Context> {
    Requirement(evaluator: { context in
      context[keyPath: keyPath] ? .confirmed : .failed(reason: Reason(message: "Requirement not met"))
    })
  }
}

// MARK: - Optional значения

extension Requirement {
  /// Создает требование для проверки Optional значения с предикатом
  /// - Parameters:
  ///   - keyPath: Путь к Optional свойству
  ///   - predicate: Предикат для проверки значения
  /// - Returns: Требование
  public static func requireSome<Value: Sendable>(
    _ keyPath: KeyPath<Context, Value?> & Sendable,
    where predicate: @escaping @Sendable (Value) -> Bool
  ) -> Requirement<Context> {
    Requirement { context in
      if let value = context[keyPath: keyPath] {
        return predicate(value)
          ? .confirmed
          : .failed(reason: Reason(
              code: "optional.predicate_failed",
              message: "Optional value does not satisfy predicate"
            ))
      } else {
        return .failed(reason: Reason(
          code: "optional.is_nil",
          message: "Optional value is nil"
        ))
      }
    }
  }
}

// MARK: - Описание причин отказа

extension Requirement {
  /// Добавляет явное описание причины отказа к требованию
  /// - Parameters:
  ///   - code: Код причины
  ///   - message: Сообщение о причине
  /// - Returns: Требование с заданной причиной отказа
  public func because(code: String, message: String) -> Requirement<Context> {
    let customReason = Reason(code: code, message: message)
    return Requirement { context in
      let result = self.evaluate(context)
      if case .failed = result {
        return .failed(reason: customReason)
      }
      return result
    }
  }
  
  /// Добавляет описание причины отказа к требованию (код генерируется автоматически)
  /// - Parameter message: Сообщение о причине
  /// - Returns: Требование с заданной причиной отказа
  public func because(_ message: String) -> Requirement<Context> {
    let customReason = Reason(message: message)
    return Requirement { context in
      let result = self.evaluate(context)
      if case .failed = result {
        return .failed(reason: customReason)
      }
      return result
    }
  }
}

