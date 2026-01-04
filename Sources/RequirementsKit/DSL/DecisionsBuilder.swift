// MARK: - Result Builder для Decision

/// Result builder для создания цепочек решений с использованием DSL синтаксиса
@resultBuilder
public struct DecisionsBuilder<Context: Sendable, Result: Sendable> {
  /// Строит блок из одного решения
  public static func buildBlock(_ decision: Decision<Context, Result>) -> Decision<Context, Result> {
    decision
  }
  
  /// Строит блок из нескольких решений (первое совпадение)
  public static func buildBlock(_ decisions: Decision<Context, Result>...) -> Decision<Context, Result> {
    Decision { context in
      for decision in decisions {
        if let result = decision.decide(context) {
          return result
        }
      }
      return nil
    }
  }
  
  /// Поддержка условных блоков (if)
  public static func buildOptional(_ decision: Decision<Context, Result>?) -> Decision<Context, Result> {
    decision ?? .never
  }
  
  /// Поддержка условных блоков (if-else) - первая ветка
  public static func buildEither(first decision: Decision<Context, Result>) -> Decision<Context, Result> {
    decision
  }
  
  /// Поддержка условных блоков (if-else) - вторая ветка
  public static func buildEither(second decision: Decision<Context, Result>) -> Decision<Context, Result> {
    decision
  }
  
  /// Поддержка массивов решений
  public static func buildArray(_ decisions: [Decision<Context, Result>]) -> Decision<Context, Result> {
    Decision { context in
      for decision in decisions {
        if let result = decision.decide(context) {
          return result
        }
      }
      return nil
    }
  }
  
  /// Поддержка выражений
  public static func buildExpression(_ decision: Decision<Context, Result>) -> Decision<Context, Result> {
    decision
  }
  
  /// Поддержка ограниченной доступности (if #available)
  public static func buildLimitedAvailability(_ decision: Decision<Context, Result>) -> Decision<Context, Result> {
    decision
  }
}

// MARK: - Методы для использования builder

extension Decision {
  /// Создает решение из нескольких решений, возвращая первое совпадение
  /// - Parameter builder: Builder для создания решений
  /// - Returns: Композитное решение
  public static func firstMatch(
    @DecisionsBuilder<Context, Result> builder: () -> Decision<Context, Result>
  ) -> Decision<Context, Result> {
    builder()
  }
}

// MARK: - Result Builder для AsyncDecision

/// Result builder для создания цепочек асинхронных решений с использованием DSL синтаксиса
@resultBuilder
public struct AsyncDecisionsBuilder<Context: Sendable, Result: Sendable> {
  /// Строит блок из одного решения
  public static func buildBlock(
    _ decision: AsyncDecision<Context, Result>
  ) -> AsyncDecision<Context, Result> {
    decision
  }
  
  /// Строит блок из нескольких решений (первое совпадение)
  public static func buildBlock(
    _ decisions: AsyncDecision<Context, Result>...
  ) -> AsyncDecision<Context, Result> {
    AsyncDecision { context in
      for decision in decisions {
        if let result = try await decision.decide(context) {
          return result
        }
      }
      return nil
    }
  }
  
  /// Поддержка условных блоков (if)
  public static func buildOptional(
    _ decision: AsyncDecision<Context, Result>?
  ) -> AsyncDecision<Context, Result> {
    decision ?? .never
  }
  
  /// Поддержка условных блоков (if-else) - первая ветка
  public static func buildEither(
    first decision: AsyncDecision<Context, Result>
  ) -> AsyncDecision<Context, Result> {
    decision
  }
  
  /// Поддержка условных блоков (if-else) - вторая ветка
  public static func buildEither(
    second decision: AsyncDecision<Context, Result>
  ) -> AsyncDecision<Context, Result> {
    decision
  }
  
  /// Поддержка массивов решений
  public static func buildArray(
    _ decisions: [AsyncDecision<Context, Result>]
  ) -> AsyncDecision<Context, Result> {
    AsyncDecision { context in
      for decision in decisions {
        if let result = try await decision.decide(context) {
          return result
        }
      }
      return nil
    }
  }
  
  /// Поддержка выражений
  public static func buildExpression(
    _ decision: AsyncDecision<Context, Result>
  ) -> AsyncDecision<Context, Result> {
    decision
  }
  
  /// Поддержка ограниченной доступности (if #available)
  public static func buildLimitedAvailability(
    _ decision: AsyncDecision<Context, Result>
  ) -> AsyncDecision<Context, Result> {
    decision
  }
}

// MARK: - Методы для использования async builder

extension AsyncDecision {
  /// Создает асинхронное решение из нескольких решений, возвращая первое совпадение
  /// - Parameter builder: Builder для создания решений
  /// - Returns: Композитное решение
  public static func firstMatch(
    @AsyncDecisionsBuilder<Context, Result> builder: () -> AsyncDecision<Context, Result>
  ) -> AsyncDecision<Context, Result> {
    builder()
  }
}

