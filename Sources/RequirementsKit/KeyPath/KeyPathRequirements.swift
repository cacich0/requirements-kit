// MARK: - KeyPath операторы сравнения

/// Протокол для поддержки сравнений через KeyPath
public protocol KeyPathComparable {}

extension Int: KeyPathComparable {}
extension Double: KeyPathComparable {}
extension String: KeyPathComparable {}
extension Float: KeyPathComparable {}

// MARK: - Equatable

extension Requirement {
  /// Создает требование на основе сравнения значения по KeyPath с заданным значением
  /// - Parameters:
  ///   - keyPath: Путь к свойству в контексте
  ///   - value: Значение для сравнения
  public static func require<Value: Equatable & Sendable>(
    _ keyPath: KeyPath<Context, Value> & Sendable,
    equals value: Value
  ) -> Requirement<Context> {
    Requirement(evaluator: { context in
      context[keyPath: keyPath] == value 
        ? .confirmed 
        : .failed(reason: Reason(message: "Value does not equal expected"))
    })
  }
  
  /// Создает требование на основе неравенства значения по KeyPath с заданным значением
  /// - Parameters:
  ///   - keyPath: Путь к свойству в контексте
  ///   - value: Значение для сравнения
  public static func require<Value: Equatable & Sendable>(
    _ keyPath: KeyPath<Context, Value> & Sendable,
    notEquals value: Value
  ) -> Requirement<Context> {
    Requirement(evaluator: { context in
      context[keyPath: keyPath] != value 
        ? .confirmed 
        : .failed(reason: Reason(message: "Value equals unexpected value"))
    })
  }
}

// MARK: - Comparable

extension Requirement {
  /// Создает требование на основе сравнения "больше чем"
  /// - Parameters:
  ///   - keyPath: Путь к свойству в контексте
  ///   - value: Значение для сравнения
  public static func require<Value: Comparable & Sendable>(
    _ keyPath: KeyPath<Context, Value> & Sendable,
    greaterThan value: Value
  ) -> Requirement<Context> {
    Requirement(evaluator: { context in
      context[keyPath: keyPath] > value 
        ? .confirmed 
        : .failed(reason: Reason(message: "Value is not greater than expected"))
    })
  }
  
  /// Создает требование на основе сравнения "больше или равно"
  /// - Parameters:
  ///   - keyPath: Путь к свойству в контексте
  ///   - value: Значение для сравнения
  public static func require<Value: Comparable & Sendable>(
    _ keyPath: KeyPath<Context, Value> & Sendable,
    greaterThanOrEqual value: Value
  ) -> Requirement<Context> {
    Requirement(evaluator: { context in
      context[keyPath: keyPath] >= value 
        ? .confirmed 
        : .failed(reason: Reason(message: "Value is not greater than or equal to expected"))
    })
  }
  
  /// Создает требование на основе сравнения "меньше чем"
  /// - Parameters:
  ///   - keyPath: Путь к свойству в контексте
  ///   - value: Значение для сравнения
  public static func require<Value: Comparable & Sendable>(
    _ keyPath: KeyPath<Context, Value> & Sendable,
    lessThan value: Value
  ) -> Requirement<Context> {
    Requirement(evaluator: { context in
      context[keyPath: keyPath] < value 
        ? .confirmed 
        : .failed(reason: Reason(message: "Value is not less than expected"))
    })
  }
  
  /// Создает требование на основе сравнения "меньше или равно"
  /// - Parameters:
  ///   - keyPath: Путь к свойству в контексте
  ///   - value: Значение для сравнения
  public static func require<Value: Comparable & Sendable>(
    _ keyPath: KeyPath<Context, Value> & Sendable,
    lessThanOrEqual value: Value
  ) -> Requirement<Context> {
    Requirement(evaluator: { context in
      context[keyPath: keyPath] <= value 
        ? .confirmed 
        : .failed(reason: Reason(message: "Value is not less than or equal to expected"))
    })
  }
}

// MARK: - Операторы для удобного синтаксиса

/// Структура-обертка для KeyPath, позволяющая использовать операторы сравнения
public struct KeyPathExpression<Root, Value> {
  let keyPath: KeyPath<Root, Value>
  
  init(_ keyPath: KeyPath<Root, Value>) {
    self.keyPath = keyPath
  }
}

// Операторы для Equatable
public func == <Root: Sendable, Value: Equatable & Sendable>(
  lhs: KeyPath<Root, Value> & Sendable,
  rhs: Value
) -> @Sendable (Root) -> Bool {
  { context in context[keyPath: lhs] == rhs }
}

public func != <Root: Sendable, Value: Equatable & Sendable>(
  lhs: KeyPath<Root, Value> & Sendable,
  rhs: Value
) -> @Sendable (Root) -> Bool {
  { context in context[keyPath: lhs] != rhs }
}

// Операторы для Comparable
public func > <Root: Sendable, Value: Comparable & Sendable>(
  lhs: KeyPath<Root, Value> & Sendable,
  rhs: Value
) -> @Sendable (Root) -> Bool {
  { context in context[keyPath: lhs] > rhs }
}

public func >= <Root: Sendable, Value: Comparable & Sendable>(
  lhs: KeyPath<Root, Value> & Sendable,
  rhs: Value
) -> @Sendable (Root) -> Bool {
  { context in context[keyPath: lhs] >= rhs }
}

public func < <Root: Sendable, Value: Comparable & Sendable>(
  lhs: KeyPath<Root, Value> & Sendable,
  rhs: Value
) -> @Sendable (Root) -> Bool {
  { context in context[keyPath: lhs] < rhs }
}

public func <= <Root: Sendable, Value: Comparable & Sendable>(
  lhs: KeyPath<Root, Value> & Sendable,
  rhs: Value
) -> @Sendable (Root) -> Bool {
  { context in context[keyPath: lhs] <= rhs }
}

// MARK: - Расширение для удобного использования операторов

extension Requirement {
  /// Создает требование на основе KeyPath выражения с оператором
  /// Пример: .require(\.user.balance > 100)
  public static func requireExpression(_ expression: @escaping @Sendable (Context) -> Bool) -> Requirement<Context> {
    Requirement(evaluator: { context in
      expression(context) 
        ? .confirmed 
        : .failed(reason: Reason(message: "Requirement not met"))
    })
  }
}
