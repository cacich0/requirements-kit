// MARK: - Collecting Decisions

extension Decision {
  /// Собирает все не-nil результаты из списка решений
  /// - Parameter decisions: Массив решений
  /// - Returns: Решение, которое возвращает массив всех не-nil результатов
  public static func collect(
    _ decisions: [Decision<Context, Result>]
  ) -> Decision<Context, [Result]> {
    Decision<Context, [Result]> { context in
      var results: [Result] = []
      for decision in decisions {
        if let result = decision.decide(context) {
          results.append(result)
        }
      }
      return results.isEmpty ? nil : results
    }
  }
  
  /// Собирает результаты с помощью builder
  /// - Parameter builder: Builder для создания решений
  /// - Returns: Решение, которое возвращает массив всех не-nil результатов
  public static func collect(
    @DecisionsBuilder<Context, Result> builder: () -> [Decision<Context, Result>]
  ) -> Decision<Context, [Result]> {
    let decisions = builder()
    return collect(decisions)
  }
  
  /// Применяет трансформацию ко всем результатам
  /// - Parameters:
  ///   - decisions: Массив решений
  ///   - transform: Функция трансформации массива результатов
  /// - Returns: Решение с преобразованным результатом
  public static func mapAll<R: Sendable>(
    _ decisions: [Decision<Context, Result>],
    transform: @escaping @Sendable ([Result]) -> R
  ) -> Decision<Context, R> {
    Decision<Context, R> { context in
      var results: [Result] = []
      for decision in decisions {
        if let result = decision.decide(context) {
          results.append(result)
        }
      }
      return results.isEmpty ? nil : transform(results)
    }
  }
  
  /// Применяет трансформацию ко всем результатам с использованием builder
  /// - Parameters:
  ///   - builder: Builder для создания решений
  ///   - transform: Функция трансформации массива результатов
  /// - Returns: Решение с преобразованным результатом
  public static func mapAll<R: Sendable>(
    @DecisionsBuilder<Context, Result> builder: () -> [Decision<Context, Result>],
    transform: @escaping @Sendable ([Result]) -> R
  ) -> Decision<Context, R> {
    let decisions = builder()
    return mapAll(decisions, transform: transform)
  }
}

// MARK: - Async Collecting Decisions

extension AsyncDecision {
  /// Собирает все не-nil результаты из списка асинхронных решений
  /// - Parameter decisions: Массив асинхронных решений
  /// - Returns: Решение, которое возвращает массив всех не-nil результатов
  public static func collect(
    _ decisions: [AsyncDecision<Context, Result>]
  ) -> AsyncDecision<Context, [Result]> {
    AsyncDecision<Context, [Result]> { context in
      var results: [Result] = []
      for decision in decisions {
        if let result = try await decision.decide(context) {
          results.append(result)
        }
      }
      return results.isEmpty ? nil : results
    }
  }
  
  /// Собирает результаты с помощью builder
  /// - Parameter builder: Builder для создания асинхронных решений
  /// - Returns: Решение, которое возвращает массив всех не-nil результатов
  public static func collect(
    @AsyncDecisionsBuilder<Context, Result> builder: () -> [AsyncDecision<Context, Result>]
  ) -> AsyncDecision<Context, [Result]> {
    let decisions = builder()
    return collect(decisions)
  }
  
  /// Применяет трансформацию ко всем результатам
  /// - Parameters:
  ///   - decisions: Массив асинхронных решений
  ///   - transform: Функция трансформации массива результатов
  /// - Returns: Решение с преобразованным результатом
  public static func mapAll<R: Sendable>(
    _ decisions: [AsyncDecision<Context, Result>],
    transform: @escaping @Sendable ([Result]) -> R
  ) -> AsyncDecision<Context, R> {
    AsyncDecision<Context, R> { context in
      var results: [Result] = []
      for decision in decisions {
        if let result = try await decision.decide(context) {
          results.append(result)
        }
      }
      return results.isEmpty ? nil : transform(results)
    }
  }
  
  /// Применяет трансформацию ко всем результатам с использованием builder
  /// - Parameters:
  ///   - builder: Builder для создания асинхронных решений
  ///   - transform: Функция трансформации массива результатов
  /// - Returns: Решение с преобразованным результатом
  public static func mapAll<R: Sendable>(
    @AsyncDecisionsBuilder<Context, Result> builder: () -> [AsyncDecision<Context, Result>],
    transform: @escaping @Sendable ([Result]) -> R
  ) -> AsyncDecision<Context, R> {
    let decisions = builder()
    return mapAll(decisions, transform: transform)
  }
}

