/// Решение, которое может быть принято на основе контекста.
/// В отличие от `Requirement`, возвращает конкретное значение типа `Result?`
/// вместо булевой проверки.
public struct Decision<Context: Sendable, Result: Sendable>: Sendable {
  private let decider: @Sendable (Context) -> Result?
  
  /// Создает решение с пользовательской логикой принятия решения
  /// - Parameter decider: Функция, которая принимает контекст и возвращает результат или nil
  public init(decider: @escaping @Sendable (Context) -> Result?) {
    self.decider = decider
  }
  
  /// Принимает решение для заданного контекста
  /// - Parameter context: Контекст для принятия решения
  /// - Returns: Результат решения или nil, если решение не может быть принято
  public func decide(_ context: Context) -> Result? {
    decider(context)
  }
}

// MARK: - Базовые фабричные методы

extension Decision {
  /// Создает решение, которое всегда возвращает константное значение
  /// - Parameter value: Значение для возврата
  public static func constant(_ value: Result) -> Decision<Context, Result> {
    Decision { _ in value }
  }
  
  /// Создает решение, которое всегда возвращает nil
  public static var never: Decision<Context, Result> {
    Decision { _ in nil }
  }
  
  /// Создает решение из замыкания
  /// - Parameter closure: Замыкание для принятия решения
  public static func from(_ closure: @escaping @Sendable (Context) -> Result?) -> Decision<Context, Result> {
    Decision(decider: closure)
  }
}

// MARK: - Операторы композиции (Fallback)

extension Decision {
  /// Возвращает альтернативное решение, если текущее возвращает nil
  /// - Parameter fallbackDecision: Альтернативное решение
  /// - Returns: Композитное решение
  public func fallback(_ fallbackDecision: Decision<Context, Result>) -> Decision<Context, Result> {
    Decision { context in
      if let result = self.decide(context) {
        return result
      }
      return fallbackDecision.decide(context)
    }
  }
  
  /// Возвращает альтернативное решение, если текущее возвращает nil
  /// - Parameter fallbackDecision: Альтернативное решение
  /// - Returns: Композитное решение
  public func orFallback(to fallbackDecision: Decision<Context, Result>) -> Decision<Context, Result> {
    fallback(fallbackDecision)
  }
  
  /// Возвращает альтернативное решение из замыкания, если текущее возвращает nil
  /// - Parameter fallbackClosure: Замыкание для альтернативного решения
  /// - Returns: Композитное решение
  public func fallback(_ fallbackClosure: @escaping @Sendable (Context) -> Result?) -> Decision<Context, Result> {
    Decision { context in
      if let result = self.decide(context) {
        return result
      }
      return fallbackClosure(context)
    }
  }
  
  /// Возвращает константное значение, если текущее решение возвращает nil
  /// - Parameter defaultValue: Значение по умолчанию
  /// - Returns: Композитное решение
  public func fallbackDefault(_ defaultValue: Result) -> Decision<Context, Result> {
    Decision { context in
      self.decide(context) ?? defaultValue
    }
  }
  
  /// Преобразует результат решения с помощью функции трансформации
  /// - Parameter transform: Функция преобразования
  /// - Returns: Решение с преобразованным результатом
  public func map<NewResult: Sendable>(
    _ transform: @escaping @Sendable (Result) -> NewResult
  ) -> Decision<Context, NewResult> {
    Decision<Context, NewResult> { context in
      self.decide(context).map(transform)
    }
  }
  
  /// Преобразует результат решения с помощью функции, которая может вернуть nil
  /// - Parameter transform: Функция преобразования
  /// - Returns: Решение с преобразованным результатом
  public func compactMap<NewResult: Sendable>(
    _ transform: @escaping @Sendable (Result) -> NewResult?
  ) -> Decision<Context, NewResult> {
    Decision<Context, NewResult> { context in
      self.decide(context).flatMap(transform)
    }
  }
  
  /// Фильтрует результат решения по предикату
  /// - Parameter predicate: Предикат для проверки результата
  /// - Returns: Решение, которое возвращает nil, если предикат не выполнен
  public func filter(_ predicate: @escaping @Sendable (Result) -> Bool) -> Decision<Context, Result> {
    Decision { context in
      if let result = self.decide(context), predicate(result) {
        return result
      }
      return nil
    }
  }
  
  /// Применяет следующее решение к результату предыдущего (цепочка решений)
  /// - Parameter next: Функция, которая принимает результат и возвращает новое решение
  /// - Returns: Решение с преобразованным результатом
  public func then<NewResult: Sendable>(
    _ next: @escaping @Sendable (Result) -> Decision<Context, NewResult>
  ) -> Decision<Context, NewResult> {
    Decision<Context, NewResult> { context in
      guard let result = self.decide(context) else {
        return nil
      }
      return next(result).decide(context)
    }
  }
  
  /// Применяет следующее решение условно на основе результата
  /// - Parameters:
  ///   - predicate: Предикат для проверки результата
  ///   - next: Решение для применения если предикат выполнен
  /// - Returns: Решение
  public func when(
    _ predicate: @escaping @Sendable (Result) -> Bool,
    then next: Decision<Context, Result>
  ) -> Decision<Context, Result> {
    Decision { context in
      guard let result = self.decide(context) else {
        return nil
      }
      if predicate(result) {
        return next.decide(context) ?? result
      }
      return result
    }
  }
}

// MARK: - Интеграция с Requirements

extension Decision {
  /// Создает решение на основе требования
  /// Возвращает значение, если требование выполнено, иначе nil
  /// - Parameters:
  ///   - requirement: Требование для проверки
  ///   - value: Значение для возврата, если требование выполнено
  /// - Returns: Решение на основе требования
  public static func when(
    _ requirement: Requirement<Context>,
    return value: Result
  ) -> Decision<Context, Result> {
    Decision { context in
      switch requirement.evaluate(context) {
      case .confirmed:
        return value
      case .failed:
        return nil
      }
    }
  }
  
  /// Создает решение на основе требования с вычислением значения
  /// - Parameters:
  ///   - requirement: Требование для проверки
  ///   - value: Замыкание для вычисления значения, если требование выполнено
  /// - Returns: Решение на основе требования
  public static func when(
    _ requirement: Requirement<Context>,
    return value: @escaping @Sendable (Context) -> Result
  ) -> Decision<Context, Result> {
    Decision { context in
      switch requirement.evaluate(context) {
      case .confirmed:
        return value(context)
      case .failed:
        return nil
      }
    }
  }
}

// MARK: - Условная логика

extension Decision {
  /// Создает решение на основе условия
  /// - Parameters:
  ///   - condition: Условие для проверки
  ///   - value: Значение для возврата, если условие истинно
  /// - Returns: Решение на основе условия
  public static func when(
    _ condition: @escaping @Sendable (Context) -> Bool,
    return value: Result
  ) -> Decision<Context, Result> {
    Decision { context in
      condition(context) ? value : nil
    }
  }
  
  /// Создает решение на основе условия с вычислением значения
  /// - Parameters:
  ///   - condition: Условие для проверки
  ///   - value: Замыкание для вычисления значения, если условие истинно
  /// - Returns: Решение на основе условия
  public static func when(
    _ condition: @escaping @Sendable (Context) -> Bool,
    return value: @escaping @Sendable (Context) -> Result
  ) -> Decision<Context, Result> {
    Decision { context in
      condition(context) ? value(context) : nil
    }
  }
  
  /// Создает решение на основе отрицательного условия
  /// - Parameters:
  ///   - condition: Условие для проверки (решение возвращается если условие ложно)
  ///   - value: Значение для возврата, если условие ложно
  /// - Returns: Решение на основе условия
  public static func unless(
    _ condition: @escaping @Sendable (Context) -> Bool,
    return value: Result
  ) -> Decision<Context, Result> {
    Decision { context in
      !condition(context) ? value : nil
    }
  }
  
  /// Создает решение на основе отрицательного условия с вычислением значения
  /// - Parameters:
  ///   - condition: Условие для проверки (решение возвращается если условие ложно)
  ///   - value: Замыкание для вычисления значения, если условие ложно
  /// - Returns: Решение на основе условия
  public static func unless(
    _ condition: @escaping @Sendable (Context) -> Bool,
    return value: @escaping @Sendable (Context) -> Result
  ) -> Decision<Context, Result> {
    Decision { context in
      !condition(context) ? value(context) : nil
    }
  }
}

