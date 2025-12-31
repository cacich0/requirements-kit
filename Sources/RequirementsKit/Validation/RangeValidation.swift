// MARK: - Валидация диапазонов

extension Requirement {
  /// Проверяет, что значение находится в диапазоне (ClosedRange)
  /// - Parameters:
  ///   - keyPath: Путь к значению
  ///   - range: Допустимый диапазон (включительно)
  /// - Returns: Требование
  public static func requireInRange<Value: Comparable & Sendable>(
    _ keyPath: KeyPath<Context, Value> & Sendable,
    _ range: ClosedRange<Value>
  ) -> Requirement<Context> {
    Requirement { context in
      let value = context[keyPath: keyPath]
      
      return range.contains(value)
        ? .confirmed
        : .failed(reason: Reason(
            code: "value.out_of_range",
            message: "Value must be between \(range.lowerBound) and \(range.upperBound)"
          ))
    }
  }
  
  /// Проверяет, что значение находится в диапазоне (Range)
  /// - Parameters:
  ///   - keyPath: Путь к значению
  ///   - range: Допустимый диапазон (не включая верхнюю границу)
  /// - Returns: Требование
  public static func requireInRange<Value: Comparable & Sendable>(
    _ keyPath: KeyPath<Context, Value> & Sendable,
    _ range: Range<Value>
  ) -> Requirement<Context> {
    Requirement { context in
      let value = context[keyPath: keyPath]
      
      return range.contains(value)
        ? .confirmed
        : .failed(reason: Reason(
            code: "value.out_of_range",
            message: "Value is out of acceptable range"
          ))
    }
  }
  
  /// Проверяет, что значение положительное
  /// - Parameter keyPath: Путь к числовому значению
  /// - Returns: Требование
  public static func requirePositive<Value: Comparable & SignedNumeric & Sendable>(
    _ keyPath: KeyPath<Context, Value> & Sendable
  ) -> Requirement<Context> where Value: ExpressibleByIntegerLiteral {
    Requirement { context in
      let value = context[keyPath: keyPath]
      
      return value > 0
        ? .confirmed
        : .failed(reason: Reason(
            code: "value.not_positive",
            message: "Value must be positive"
          ))
    }
  }
  
  /// Проверяет, что значение неотрицательное
  /// - Parameter keyPath: Путь к числовому значению
  /// - Returns: Требование
  public static func requireNonNegative<Value: Comparable & SignedNumeric & Sendable>(
    _ keyPath: KeyPath<Context, Value> & Sendable
  ) -> Requirement<Context> where Value: ExpressibleByIntegerLiteral {
    Requirement { context in
      let value = context[keyPath: keyPath]
      
      return value >= 0
        ? .confirmed
        : .failed(reason: Reason(
            code: "value.negative",
            message: "Value must be non-negative"
          ))
    }
  }
  
  /// Проверяет, что значение отрицательное
  /// - Parameter keyPath: Путь к числовому значению
  /// - Returns: Требование
  public static func requireNegative<Value: Comparable & SignedNumeric & Sendable>(
    _ keyPath: KeyPath<Context, Value> & Sendable
  ) -> Requirement<Context> where Value: ExpressibleByIntegerLiteral {
    Requirement { context in
      let value = context[keyPath: keyPath]
      
      return value < 0
        ? .confirmed
        : .failed(reason: Reason(
            code: "value.not_negative",
            message: "Value must be negative"
          ))
    }
  }
  
  /// Проверяет минимальное значение
  /// - Parameters:
  ///   - keyPath: Путь к значению
  ///   - minimum: Минимальное значение
  /// - Returns: Требование
  public static func requireMin<Value: Comparable & Sendable>(
    _ keyPath: KeyPath<Context, Value> & Sendable,
    _ minimum: Value
  ) -> Requirement<Context> {
    Requirement { context in
      let value = context[keyPath: keyPath]
      
      return value >= minimum
        ? .confirmed
        : .failed(reason: Reason(
            code: "value.below_minimum",
            message: "Value must be at least \(minimum)"
          ))
    }
  }
  
  /// Проверяет максимальное значение
  /// - Parameters:
  ///   - keyPath: Путь к значению
  ///   - maximum: Максимальное значение
  /// - Returns: Требование
  public static func requireMax<Value: Comparable & Sendable>(
    _ keyPath: KeyPath<Context, Value> & Sendable,
    _ maximum: Value
  ) -> Requirement<Context> {
    Requirement { context in
      let value = context[keyPath: keyPath]
      
      return value <= maximum
        ? .confirmed
        : .failed(reason: Reason(
            code: "value.above_maximum",
            message: "Value must be at most \(maximum)"
          ))
    }
  }
  
  /// Проверяет значение с кастомным предикатом
  /// - Parameters:
  ///   - keyPath: Путь к значению
  ///   - predicate: Предикат для проверки
  ///   - message: Сообщение об ошибке
  /// - Returns: Требование
  public static func requireWhere<Value: Sendable>(
    _ keyPath: KeyPath<Context, Value> & Sendable,
    _ predicate: @escaping @Sendable (Value) -> Bool,
    message: String = "Custom validation failed"
  ) -> Requirement<Context> {
    Requirement { context in
      let value = context[keyPath: keyPath]
      
      return predicate(value)
        ? .confirmed
        : .failed(reason: Reason(
            code: "value.custom_validation_failed",
            message: message
          ))
    }
  }
}

// MARK: - Optional валидация

extension Requirement {
  /// Проверяет, что опциональное значение не nil
  /// - Parameter keyPath: Путь к опциональному значению
  /// - Returns: Требование
  public static func requireNotNil<Value: Sendable>(
    _ keyPath: KeyPath<Context, Value?> & Sendable
  ) -> Requirement<Context> {
    Requirement { context in
      let value = context[keyPath: keyPath]
      
      return value != nil
        ? .confirmed
        : .failed(reason: Reason(
            code: "value.nil",
            message: "Value must not be nil"
          ))
    }
  }
  
  /// Проверяет, что опциональное значение nil
  /// - Parameter keyPath: Путь к опциональному значению
  /// - Returns: Требование
  public static func requireNil<Value: Sendable>(
    _ keyPath: KeyPath<Context, Value?> & Sendable
  ) -> Requirement<Context> {
    Requirement { context in
      let value = context[keyPath: keyPath]
      
      return value == nil
        ? .confirmed
        : .failed(reason: Reason(
            code: "value.not_nil",
            message: "Value must be nil"
          ))
    }
  }
}

