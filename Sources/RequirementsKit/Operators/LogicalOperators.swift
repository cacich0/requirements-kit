// MARK: - Логические операторы для Requirement

/// Оператор AND (&&) для требований
/// - Parameters:
///   - lhs: Первое требование
///   - rhs: Второе требование
/// - Returns: Композитное требование, где оба должны быть выполнены
public func && <Context: Sendable>(
  lhs: Requirement<Context>,
  rhs: Requirement<Context>
) -> Requirement<Context> {
  Requirement.all([lhs, rhs])
}

/// Оператор OR (||) для требований
/// - Parameters:
///   - lhs: Первое требование
///   - rhs: Второе требование
/// - Returns: Композитное требование, где хотя бы одно должно быть выполнено
public func || <Context: Sendable>(
  lhs: Requirement<Context>,
  rhs: Requirement<Context>
) -> Requirement<Context> {
  Requirement.any([lhs, rhs])
}

/// Оператор NOT (!) для требований
/// - Parameter requirement: Требование для инверсии
/// - Returns: Инвертированное требование
public prefix func ! <Context: Sendable>(
  requirement: Requirement<Context>
) -> Requirement<Context> {
  Requirement.not(requirement)
}

// MARK: - Логические операторы для AsyncRequirement

/// Оператор AND (&&) для асинхронных требований
public func && <Context: Sendable>(
  lhs: AsyncRequirement<Context>,
  rhs: AsyncRequirement<Context>
) -> AsyncRequirement<Context> {
  AsyncRequirement.all([lhs, rhs])
}

/// Оператор OR (||) для асинхронных требований
public func || <Context: Sendable>(
  lhs: AsyncRequirement<Context>,
  rhs: AsyncRequirement<Context>
) -> AsyncRequirement<Context> {
  AsyncRequirement.any([lhs, rhs])
}

/// Оператор NOT (!) для асинхронных требований
public prefix func ! <Context: Sendable>(
  requirement: AsyncRequirement<Context>
) -> AsyncRequirement<Context> {
  AsyncRequirement.not(requirement)
}

// MARK: - Комбинированные операторы

/// Оператор AND между синхронным и асинхронным требованием
public func && <Context: Sendable>(
  lhs: Requirement<Context>,
  rhs: AsyncRequirement<Context>
) -> AsyncRequirement<Context> {
  AsyncRequirement.all([AsyncRequirement.from(lhs), rhs])
}

/// Оператор AND между асинхронным и синхронным требованием
public func && <Context: Sendable>(
  lhs: AsyncRequirement<Context>,
  rhs: Requirement<Context>
) -> AsyncRequirement<Context> {
  AsyncRequirement.all([lhs, AsyncRequirement.from(rhs)])
}

/// Оператор OR между синхронным и асинхронным требованием
public func || <Context: Sendable>(
  lhs: Requirement<Context>,
  rhs: AsyncRequirement<Context>
) -> AsyncRequirement<Context> {
  AsyncRequirement.any([AsyncRequirement.from(lhs), rhs])
}

/// Оператор OR между асинхронным и синхронным требованием
public func || <Context: Sendable>(
  lhs: AsyncRequirement<Context>,
  rhs: Requirement<Context>
) -> AsyncRequirement<Context> {
  AsyncRequirement.any([lhs, AsyncRequirement.from(rhs)])
}

// MARK: - Операторы для Decision

/// Коалесцирующий оператор для Decision (аналог fallbackDefault)
/// - Parameters:
///   - lhs: Решение
///   - rhs: Значение по умолчанию
/// - Returns: Решение, которое всегда возвращает значение
public func ?? <Context: Sendable, Result: Sendable>(
  lhs: Decision<Context, Result>,
  rhs: Result
) -> Decision<Context, Result> {
  lhs.fallbackDefault(rhs)
}

/// Коалесцирующий оператор для AsyncDecision (аналог fallbackDefault)
/// - Parameters:
///   - lhs: Асинхронное решение
///   - rhs: Значение по умолчанию
/// - Returns: Решение, которое всегда возвращает значение
public func ?? <Context: Sendable, Result: Sendable>(
  lhs: AsyncDecision<Context, Result>,
  rhs: Result
) -> AsyncDecision<Context, Result> {
  lhs.fallbackDefault(rhs)
}

