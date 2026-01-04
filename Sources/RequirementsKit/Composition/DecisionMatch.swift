// MARK: - Switch-style Decision Composition

extension Decision {
  /// Switch-подобное сопоставление по KeyPath
  /// - Parameters:
  ///   - keyPath: KeyPath к значению для сопоставления
  ///   - cases: Словарь значений и соответствующих решений
  ///   - defaultDecision: Решение по умолчанию, если ничего не совпало
  /// - Returns: Решение на основе сопоставления
  public static func match<Key: Equatable & Sendable>(
    keyPath: KeyPath<Context, Key> & Sendable,
    cases: [Key: Decision<Context, Result>],
    default defaultDecision: Decision<Context, Result>? = nil
  ) -> Decision<Context, Result> {
    Decision { context in
      let key = context[keyPath: keyPath]
      if let decision = cases[key] {
        return decision.decide(context)
      }
      return defaultDecision?.decide(context)
    }
  }
  
  /// Switch-подобное сопоставление с предикатами
  /// - Parameters:
  ///   - cases: Массив кортежей (предикат, решение)
  ///   - defaultDecision: Решение по умолчанию, если ничего не совпало
  /// - Returns: Решение на основе первого совпадения
  public static func match(
    cases: [(@Sendable (Context) -> Bool, Decision<Context, Result>)],
    default defaultDecision: Decision<Context, Result>? = nil
  ) -> Decision<Context, Result> {
    Decision { context in
      for (predicate, decision) in cases {
        if predicate(context) {
          return decision.decide(context)
        }
      }
      return defaultDecision?.decide(context)
    }
  }
  
  /// Switch-подобное сопоставление с builder для cases
  /// - Parameters:
  ///   - keyPath: KeyPath к значению для сопоставления
  ///   - casesBuilder: Builder для создания пар (ключ, решение)
  ///   - defaultDecision: Решение по умолчанию
  /// - Returns: Решение на основе сопоставления
  public static func match<Key: Equatable & Hashable & Sendable>(
    keyPath: KeyPath<Context, Key> & Sendable,
    @MatchCasesBuilder<Context, Key, Result> casesBuilder: () -> [(Key, Decision<Context, Result>)],
    default defaultDecision: Decision<Context, Result>? = nil
  ) -> Decision<Context, Result> {
    let casesArray = casesBuilder()
    let casesDict = Dictionary(uniqueKeysWithValues: casesArray)
    return match(keyPath: keyPath, cases: casesDict, default: defaultDecision)
  }
}

// MARK: - Async Switch-style Decision Composition

extension AsyncDecision {
  /// Switch-подобное сопоставление по KeyPath для асинхронных решений
  /// - Parameters:
  ///   - keyPath: KeyPath к значению для сопоставления
  ///   - cases: Словарь значений и соответствующих решений
  ///   - defaultDecision: Решение по умолчанию, если ничего не совпало
  /// - Returns: Решение на основе сопоставления
  public static func match<Key: Equatable & Sendable>(
    keyPath: KeyPath<Context, Key> & Sendable,
    cases: [Key: AsyncDecision<Context, Result>],
    default defaultDecision: AsyncDecision<Context, Result>? = nil
  ) -> AsyncDecision<Context, Result> {
    AsyncDecision { context in
      let key = context[keyPath: keyPath]
      if let decision = cases[key] {
        return try await decision.decide(context)
      }
      return try await defaultDecision?.decide(context)
    }
  }
  
  /// Switch-подобное сопоставление с асинхронными предикатами
  /// - Parameters:
  ///   - cases: Массив кортежей (предикат, решение)
  ///   - defaultDecision: Решение по умолчанию, если ничего не совпало
  /// - Returns: Решение на основе первого совпадения
  public static func match(
    cases: [(@Sendable (Context) async throws -> Bool, AsyncDecision<Context, Result>)],
    default defaultDecision: AsyncDecision<Context, Result>? = nil
  ) -> AsyncDecision<Context, Result> {
    AsyncDecision { context in
      for (predicate, decision) in cases {
        if try await predicate(context) {
          return try await decision.decide(context)
        }
      }
      return try await defaultDecision?.decide(context)
    }
  }
  
  /// Switch-подобное сопоставление с builder для cases
  /// - Parameters:
  ///   - keyPath: KeyPath к значению для сопоставления
  ///   - casesBuilder: Builder для создания пар (ключ, решение)
  ///   - defaultDecision: Решение по умолчанию
  /// - Returns: Решение на основе сопоставления
  public static func match<Key: Equatable & Hashable & Sendable>(
    keyPath: KeyPath<Context, Key> & Sendable,
    @AsyncMatchCasesBuilder<Context, Key, Result> casesBuilder: () -> [(Key, AsyncDecision<Context, Result>)],
    default defaultDecision: AsyncDecision<Context, Result>? = nil
  ) -> AsyncDecision<Context, Result> {
    let casesArray = casesBuilder()
    let casesDict = Dictionary(uniqueKeysWithValues: casesArray)
    return match(keyPath: keyPath, cases: casesDict, default: defaultDecision)
  }
}

// MARK: - Match Cases Builder

/// Result builder для создания match cases
@resultBuilder
public struct MatchCasesBuilder<Context: Sendable, Key: Equatable & Hashable & Sendable, Result: Sendable> {
  public static func buildBlock(_ components: (Key, Decision<Context, Result>)...) -> [(Key, Decision<Context, Result>)] {
    Array(components)
  }
  
  public static func buildExpression(_ expression: (Key, Decision<Context, Result>)) -> (Key, Decision<Context, Result>) {
    expression
  }
}

/// Result builder для создания async match cases
@resultBuilder
public struct AsyncMatchCasesBuilder<Context: Sendable, Key: Equatable & Hashable & Sendable, Result: Sendable> {
  public static func buildBlock(_ components: (Key, AsyncDecision<Context, Result>)...) -> [(Key, AsyncDecision<Context, Result>)] {
    Array(components)
  }
  
  public static func buildExpression(_ expression: (Key, AsyncDecision<Context, Result>)) -> (Key, AsyncDecision<Context, Result>) {
    expression
  }
}

