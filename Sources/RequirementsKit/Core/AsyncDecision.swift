// MARK: - Асинхронные решения

import Foundation

/// Асинхронное решение для принятия решений, требующих async операций
/// (API вызовы, запросы к базе данных и т.д.)
public struct AsyncDecision<Context: Sendable, Result: Sendable>: Sendable {
  private let decider: @Sendable (Context) async throws -> Result?
  
  /// Создает асинхронное решение с пользовательским decider
  /// - Parameter decider: Асинхронное замыкание для принятия решения
  public init(decider: @escaping @Sendable (Context) async throws -> Result?) {
    self.decider = decider
  }
  
  /// Принимает асинхронное решение
  /// - Parameter context: Контекст для принятия решения
  /// - Returns: Результат решения или nil
  public func decide(_ context: Context) async throws -> Result? {
    try await decider(context)
  }
  
  // MARK: - Фабричные методы
  
  /// Решение, которое всегда возвращает константное значение
  /// - Parameter value: Значение для возврата
  public static func constant(_ value: Result) -> AsyncDecision<Context, Result> {
    AsyncDecision { _ in value }
  }
  
  /// Решение, которое всегда возвращает nil
  public static var never: AsyncDecision<Context, Result> {
    AsyncDecision { _ in nil }
  }
  
  /// Создает асинхронное решение из синхронного
  /// - Parameter decision: Синхронное решение
  /// - Returns: Асинхронная обертка
  public static func from(_ decision: Decision<Context, Result>) -> AsyncDecision<Context, Result> {
    let decider = decision.decide
    return AsyncDecision { context in
      decider(context)
    }
  }
  
  /// Создает асинхронное решение из замыкания
  /// - Parameter closure: Замыкание для принятия решения
  public static func from(
    _ closure: @escaping @Sendable (Context) async throws -> Result?
  ) -> AsyncDecision<Context, Result> {
    AsyncDecision(decider: closure)
  }
  
  /// Создает асинхронное решение с таймаутом
  /// - Parameters:
  ///   - timeoutSeconds: Таймаут в секундах
  ///   - decision: Асинхронное решение
  /// - Returns: Решение с таймаутом
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  public static func withTimeout(
    seconds timeoutSeconds: Double,
    _ decision: AsyncDecision<Context, Result>
  ) -> AsyncDecision<Context, Result> {
    AsyncDecision { context in
      do {
        return try await withThrowingTaskGroup(of: Result?.self) { group in
          group.addTask {
            try await decision.decide(context)
          }
          
          group.addTask {
            try await Task.sleep(for: .seconds(timeoutSeconds))
            throw AsyncDecisionError.timeout
          }
          
          guard let result = try await group.next() else {
            throw AsyncDecisionError.timeout
          }
          
          group.cancelAll()
          return result
        }
      } catch is AsyncDecisionError {
        return nil
      } catch {
        throw error
      }
    }
  }
}

// MARK: - Ошибки

/// Ошибки асинхронных решений
public enum AsyncDecisionError: Error, Sendable {
  case timeout
  case cancelled
}

// MARK: - Операторы композиции (Fallback)

extension AsyncDecision {
  /// Возвращает альтернативное решение, если текущее возвращает nil
  /// - Parameter fallbackDecision: Альтернативное решение
  /// - Returns: Композитное решение
  public func fallback(_ fallbackDecision: AsyncDecision<Context, Result>) -> AsyncDecision<Context, Result> {
    AsyncDecision { context in
      if let result = try await self.decide(context) {
        return result
      }
      return try await fallbackDecision.decide(context)
    }
  }
  
  /// Возвращает альтернативное решение, если текущее возвращает nil
  /// - Parameter fallbackDecision: Альтернативное решение
  /// - Returns: Композитное решение
  public func orFallback(to fallbackDecision: AsyncDecision<Context, Result>) -> AsyncDecision<Context, Result> {
    fallback(fallbackDecision)
  }
  
  /// Возвращает альтернативное решение из замыкания, если текущее возвращает nil
  /// - Parameter fallbackClosure: Замыкание для альтернативного решения
  /// - Returns: Композитное решение
  public func fallback(
    _ fallbackClosure: @escaping @Sendable (Context) async throws -> Result?
  ) -> AsyncDecision<Context, Result> {
    AsyncDecision { context in
      if let result = try await self.decide(context) {
        return result
      }
      return try await fallbackClosure(context)
    }
  }
  
  /// Возвращает константное значение, если текущее решение возвращает nil
  /// - Parameter defaultValue: Значение по умолчанию
  /// - Returns: Композитное решение
  public func fallbackDefault(_ defaultValue: Result) -> AsyncDecision<Context, Result> {
    AsyncDecision { context in
      try await self.decide(context) ?? defaultValue
    }
  }
  
  /// Преобразует результат решения с помощью функции трансформации
  /// - Parameter transform: Функция преобразования
  /// - Returns: Решение с преобразованным результатом
  public func map<NewResult: Sendable>(
    _ transform: @escaping @Sendable (Result) -> NewResult
  ) -> AsyncDecision<Context, NewResult> {
    AsyncDecision<Context, NewResult> { context in
      try await self.decide(context).map(transform)
    }
  }
  
  /// Преобразует результат решения с помощью асинхронной функции
  /// - Parameter transform: Асинхронная функция преобразования
  /// - Returns: Решение с преобразованным результатом
  public func asyncMap<NewResult: Sendable>(
    _ transform: @escaping @Sendable (Result) async throws -> NewResult
  ) -> AsyncDecision<Context, NewResult> {
    AsyncDecision<Context, NewResult> { context in
      if let result = try await self.decide(context) {
        return try await transform(result)
      }
      return nil
    }
  }
  
  /// Преобразует результат решения с помощью функции, которая может вернуть nil
  /// - Parameter transform: Функция преобразования
  /// - Returns: Решение с преобразованным результатом
  public func compactMap<NewResult: Sendable>(
    _ transform: @escaping @Sendable (Result) -> NewResult?
  ) -> AsyncDecision<Context, NewResult> {
    AsyncDecision<Context, NewResult> { context in
      try await self.decide(context).flatMap(transform)
    }
  }
  
  /// Преобразует результат решения с помощью асинхронной функции, которая может вернуть nil
  /// - Parameter transform: Асинхронная функция преобразования
  /// - Returns: Решение с преобразованным результатом
  public func asyncCompactMap<NewResult: Sendable>(
    _ transform: @escaping @Sendable (Result) async throws -> NewResult?
  ) -> AsyncDecision<Context, NewResult> {
    AsyncDecision<Context, NewResult> { context in
      if let result = try await self.decide(context) {
        return try await transform(result)
      }
      return nil
    }
  }
  
  /// Фильтрует результат решения по предикату
  /// - Parameter predicate: Предикат для проверки результата
  /// - Returns: Решение, которое возвращает nil, если предикат не выполнен
  public func filter(_ predicate: @escaping @Sendable (Result) -> Bool) -> AsyncDecision<Context, Result> {
    AsyncDecision { context in
      if let result = try await self.decide(context), predicate(result) {
        return result
      }
      return nil
    }
  }
  
  /// Фильтрует результат решения по асинхронному предикату
  /// - Parameter predicate: Асинхронный предикат для проверки результата
  /// - Returns: Решение, которое возвращает nil, если предикат не выполнен
  public func asyncFilter(
    _ predicate: @escaping @Sendable (Result) async throws -> Bool
  ) -> AsyncDecision<Context, Result> {
    AsyncDecision { context in
      if let result = try await self.decide(context), try await predicate(result) {
        return result
      }
      return nil
    }
  }
  
  /// Применяет следующее решение к результату предыдущего (цепочка решений)
  /// - Parameter next: Функция, которая принимает результат и возвращает новое решение
  /// - Returns: Решение с преобразованным результатом
  public func then<NewResult: Sendable>(
    _ next: @escaping @Sendable (Result) async throws -> AsyncDecision<Context, NewResult>
  ) -> AsyncDecision<Context, NewResult> {
    AsyncDecision<Context, NewResult> { context in
      guard let result = try await self.decide(context) else {
        return nil
      }
      return try await next(result).decide(context)
    }
  }
  
  /// Применяет следующее решение условно на основе результата
  /// - Parameters:
  ///   - predicate: Предикат для проверки результата
  ///   - next: Решение для применения если предикат выполнен
  /// - Returns: Решение
  public func when(
    _ predicate: @escaping @Sendable (Result) async throws -> Bool,
    then next: AsyncDecision<Context, Result>
  ) -> AsyncDecision<Context, Result> {
    AsyncDecision { context in
      guard let result = try await self.decide(context) else {
        return nil
      }
      if try await predicate(result) {
        return try await next.decide(context) ?? result
      }
      return result
    }
  }
}

// MARK: - Интеграция с Requirements

extension AsyncDecision {
  /// Создает решение на основе асинхронного требования
  /// Возвращает значение, если требование выполнено, иначе nil
  /// - Parameters:
  ///   - requirement: Асинхронное требование для проверки
  ///   - value: Значение для возврата, если требование выполнено
  /// - Returns: Решение на основе требования
  public static func when(
    _ requirement: AsyncRequirement<Context>,
    return value: Result
  ) -> AsyncDecision<Context, Result> {
    AsyncDecision { context in
      switch try await requirement.evaluate(context) {
      case .confirmed:
        return value
      case .failed:
        return nil
      }
    }
  }
  
  /// Создает решение на основе асинхронного требования с вычислением значения
  /// - Parameters:
  ///   - requirement: Асинхронное требование для проверки
  ///   - value: Замыкание для вычисления значения, если требование выполнено
  /// - Returns: Решение на основе требования
  public static func when(
    _ requirement: AsyncRequirement<Context>,
    return value: @escaping @Sendable (Context) async throws -> Result
  ) -> AsyncDecision<Context, Result> {
    AsyncDecision { context in
      switch try await requirement.evaluate(context) {
      case .confirmed:
        return try await value(context)
      case .failed:
        return nil
      }
    }
  }
  
  /// Создает решение на основе синхронного требования
  /// - Parameters:
  ///   - requirement: Синхронное требование для проверки
  ///   - value: Значение для возврата, если требование выполнено
  /// - Returns: Решение на основе требования
  public static func when(
    _ requirement: Requirement<Context>,
    return value: Result
  ) -> AsyncDecision<Context, Result> {
    AsyncDecision { context in
      switch requirement.evaluate(context) {
      case .confirmed:
        return value
      case .failed:
        return nil
      }
    }
  }
}

// MARK: - Условная логика

extension AsyncDecision {
  /// Создает решение на основе асинхронного условия
  /// - Parameters:
  ///   - condition: Асинхронное условие для проверки
  ///   - value: Значение для возврата, если условие истинно
  /// - Returns: Решение на основе условия
  public static func when(
    _ condition: @escaping @Sendable (Context) async throws -> Bool,
    return value: Result
  ) -> AsyncDecision<Context, Result> {
    AsyncDecision { context in
      try await condition(context) ? value : nil
    }
  }
  
  /// Создает решение на основе асинхронного условия с вычислением значения
  /// - Parameters:
  ///   - condition: Асинхронное условие для проверки
  ///   - value: Замыкание для вычисления значения, если условие истинно
  /// - Returns: Решение на основе условия
  public static func when(
    _ condition: @escaping @Sendable (Context) async throws -> Bool,
    return value: @escaping @Sendable (Context) async throws -> Result
  ) -> AsyncDecision<Context, Result> {
    AsyncDecision { context in
      try await condition(context) ? try await value(context) : nil
    }
  }
  
  /// Создает решение на основе отрицательного асинхронного условия
  /// - Parameters:
  ///   - condition: Асинхронное условие для проверки (решение возвращается если условие ложно)
  ///   - value: Значение для возврата, если условие ложно
  /// - Returns: Решение на основе условия
  public static func unless(
    _ condition: @escaping @Sendable (Context) async throws -> Bool,
    return value: Result
  ) -> AsyncDecision<Context, Result> {
    AsyncDecision { context in
      try await !condition(context) ? value : nil
    }
  }
  
  /// Создает решение на основе отрицательного асинхронного условия с вычислением значения
  /// - Parameters:
  ///   - condition: Асинхронное условие для проверки (решение возвращается если условие ложно)
  ///   - value: Замыкание для вычисления значения, если условие ложно
  /// - Returns: Решение на основе условия
  public static func unless(
    _ condition: @escaping @Sendable (Context) async throws -> Bool,
    return value: @escaping @Sendable (Context) async throws -> Result
  ) -> AsyncDecision<Context, Result> {
    AsyncDecision { context in
      try await !condition(context) ? try await value(context) : nil
    }
  }
}

