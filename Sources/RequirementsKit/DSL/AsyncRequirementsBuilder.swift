/// Result Builder для декларативного описания асинхронных требований
@resultBuilder
public enum AsyncRequirementsBuilder<Context: Sendable> {
  
  /// Собирает блок из нескольких требований
  public static func buildBlock(_ components: [AsyncRequirement<Context>]...) -> [AsyncRequirement<Context>] {
    components.flatMap { $0 }
  }
  
  /// Преобразует одно требование в массив
  public static func buildExpression(_ expression: AsyncRequirement<Context>) -> [AsyncRequirement<Context>] {
    [expression]
  }
  
  /// Обрабатывает опциональные требования (if без else)
  public static func buildOptional(_ component: [AsyncRequirement<Context>]?) -> [AsyncRequirement<Context>] {
    component ?? []
  }
  
  /// Обрабатывает первую ветку if-else
  public static func buildEither(first component: [AsyncRequirement<Context>]) -> [AsyncRequirement<Context>] {
    component
  }
  
  /// Обрабатывает вторую ветку if-else
  public static func buildEither(second component: [AsyncRequirement<Context>]) -> [AsyncRequirement<Context>] {
    component
  }
  
  /// Обрабатывает массивы требований (for-in)
  public static func buildArray(_ components: [[AsyncRequirement<Context>]]) -> [AsyncRequirement<Context>] {
    components.flatMap { $0 }
  }
  
  /// Поддержка limited availability (if #available)
  public static func buildLimitedAvailability(_ component: [AsyncRequirement<Context>]) -> [AsyncRequirement<Context>] {
    component
  }
  
  /// Финальная трансформация результата
  public static func buildFinalResult(_ component: [AsyncRequirement<Context>]) -> [AsyncRequirement<Context>] {
    component
  }
}

// MARK: - Rate Limiting Support

extension AsyncRequirementsBuilder {
  /// Поддержка AsyncRateLimitedRequirement в builder
  public static func buildExpression(
    _ expression: AsyncRateLimitedRequirement<Context>
  ) -> [AsyncRequirement<Context>] {
    [AsyncRequirement { context in
      try await expression.evaluate(context)
    }]
  }
  
  /// Поддержка AsyncThrottledRequirement в builder
  public static func buildExpression(
    _ expression: AsyncThrottledRequirement<Context>
  ) -> [AsyncRequirement<Context>] {
    [AsyncRequirement { context in
      try await expression.evaluate(context)
    }]
  }
  
  /// Поддержка AsyncDebouncedRequirement в builder
  @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
  public static func buildExpression(
    _ expression: AsyncDebouncedRequirement<Context>
  ) -> [AsyncRequirement<Context>] {
    [AsyncRequirement { context in
      try await expression.evaluate(context)
    }]
  }
}

